Include %occSAX

Class MessageBank.MessageResend Extends Ens.Enterprise.Portal.MessageResend
{

ClassMethod DebugStatus(pSC As %Status) As %Status
{
	Set tMessage = $SYSTEM.Status.GetOneErrorText(pSC)
	Quit ..DebugTEST(tMessage)
}

ClassMethod DebugTEST(pMessage As %String = "") As %Status
{
	Write pMessage,!
	Quit $$$OK
}

ClassMethod FindWebIPAddress(
	Output pSC As %Status,
	Output pMachine As %String,
	Output pInstance As %String,
	Output pNamespace As %String) As %String
{
	Set tNode = ""
	Set tQuery = ""
	Set tQuery($Increment(tQuery)) = "SELECT"
	Set tQuery($Increment(tQuery)) = "ID1, Clone, ID, IPAddr, IPAddress, Instance, Iteration, Machine, Name, Namespace, Port, TimeConnected, TimeCreated, TimeUpdated, WebIPAddr, WebPort, WebServer, WebURLRoot"
	Set tQuery($Increment(tQuery)) = "FROM Ens_Enterprise_MsgBank.Node"
	Set tQuery($Increment(tQuery)) = "ORDER BY TimeUpdated DESC"
	Set tStatement = ##class(%SQL.Statement).%New()
	Set pSC = tStatement.%Prepare(.tQuery)  // Create a cached query
	If $$$ISERR(pSC) { Quit tNode }
	Write "Default Select Mode = ",tStatement.%SelectMode,!  // 0=Logical, 1=ODBC, 2=Display
	#dim tResult As %SQL.StatementResult
	Set tResult = tStatement.%Execute()
	IF (tResult.%SQLCODE=0) { WRITE !,"Created a query",! }
	ELSEIF (tResult.%SQLCODE=-361) { WRITE !,"Query exists: ",tResult.%Message }
	ELSE { WRITE !,"CREATE QUERY error: ",tResult.%SQLCODE," ",tResult.%Message QUIT tNode}
 	While tResult.%Next() {
		Set tNode = tResult.ID
		Set pMachine = tResult.Machine
		Set pInstance = tResult.Instance
		Set pNamespace = tResult.Namespace
		Set tFindMsgBankNode = pMachine_"|"_pInstance_"|"_pNamespace
		If (tFindMsgBankNode = "") { Continue }
		Set pWebIPAddress = $Get(^Ens.MsgBankSvr("ClientIPs",tFindMsgBankNode))
		If (pWebIPAddress = "") { Continue }
		If (pWebIPAddress '= "") { Quit }
	}
	Write "tNode = ",tNode,!
	Write "pMachine = ",pMachine,!
	Write "pInstance = ",pInstance,!
	Write "pNamespace = ",pNamespace,!
	Quit $Get(pWebIPAddress)
}

ClassMethod GetClientStatus(
	pClientWebIPAddress As %String = 0,
	pUrl As %String = "/csp/user/cache_status.cxw",
	pTimeout As %Integer = 3) As %Status
{
	#define maxRetries 2
	Set tErrorCount = 0
	If (pClientWebIPAddress = 0) Set pClientWebIPAddress = "127.0.0.1:52773"
	Set tServer = $Piece(pClientWebIPAddress,":",1)
	Set tPort = $Piece(pClientWebIPAddress,":",2)
	Do {
		Set tRetryFlag = 0
		Set pResponse = $$$NULLOREF
		Set tRequest = ##class(%Net.HttpRequest).%New()

		// InitiateAuthentication does not exist in HealthShare versions
		Try {
			//Supported schemes are Negotiate, NTLM and Basic.
			Set tRequest.InitiateAuthentication = "Basic"
			Set tRequest.Username = "_SYSTEM"
			Set tRequest.Password = "SYS"
		} Catch {
		}

		Set tRequest.Port = tPort
		If (tServer '= "") Set tRequest.Server = tServer
		Set tRequest.Timeout = pTimeout
		Set type = "GET"
		Set location = $Get(pUrl)
		Set test = 0
		Set reset = 1
		Set tSC = tRequest.Send(type,location,test,reset)
		If $$$ISERR(tSC) Do ..DebugStatus(tSC)
		Set pResponse = tRequest.HttpResponse
		If $IsObject(pResponse) {
			If (pResponse.StatusCode '= 200) {
				Do ..DebugTEST("StatusCode = "_pResponse.StatusCode)
				Do ..DebugTEST("ReasonPhrase = "_pResponse.ReasonPhrase)
			}
			If (pResponse.StatusCode = 500) {  // Internal Server Error
				If $Increment(tErrorCount) <= $$$maxRetries Set tRetryFlag = 1
			}
		} Else {
			If $$$ISERR(tSC) { Continue }
			Do ..DebugTEST("HttpResponse = "_pResponse)
		}
	} While tRetryFlag

	If $IsObject(pResponse) {
		#dim tDataStream As %Stream.GlobalBinary
		Set tDataStream = pResponse.Data
		Set tDataString = tDataStream.Read(.len,.sc)
		If $$$ISOK(sc) {
			Do ..DebugTEST("tDataString = "_tDataString)
		} Else {
			Do ..DebugTEST("Data = "_pResponse.Data)
			Do ..DebugTEST("len = "_$Get(len))
			Do ..DebugStatus(sc)
		}
	}
	If ($Get(tDataString) = "SUCCESS") {
		Set tSC	= $$$OK
	} Else {
		If $$$ISOK(tSC) Set tSC = $$$ERROR($$$GeneralError,$Get(tDataString))
	}
	Quit tSC
}

ClassMethod GetResendClient(
	Output pSC As %Status,
	Output pWebIPAddress As %String) As %String
{
	Set tClient = ""
	Set tQuery = "SELECT * FROM Ens_Enterprise.MonitorClient"
	Set tStatement = ##class(%SQL.Statement).%New()
	Set pSC = tStatement.%Prepare(.tQuery)  // Create a cached query
	If $$$ISERR(pSC) { Quit tClient }
	Write "Default Select Mode = ",tStatement.%SelectMode,!  // 0=Logical, 1=ODBC, 2=Display
	#dim tResult As %SQL.StatementResult
	Set tResult = tStatement.%Execute()
	IF (tResult.%SQLCODE=0) { WRITE !,"Created a query",! }
	ELSEIF (tResult.%SQLCODE=-361) { WRITE !,"Query exists: ",tResult.%Message }
	ELSE { WRITE !,"CREATE QUERY error: ",tResult.%SQLCODE," ",tResult.%Message QUIT tClient}
 	While tResult.%Next() {
		Set tClient = tResult.ID
		Set pWebIPAddress = tResult.WebIPAddress
		Set pSC = ..GetClientStatus(pWebIPAddress)
		If $$$ISOK(pSC) Quit  // Found one
		Set pWebIPAddress = ""
		Set tClient = ""
	}
	Write "tClient = ",tClient,!
	Write "pWebIPAddress = ",pWebIPAddress,!
	Quit tClient
}

/// Do not consider Incomplete Messages from the latest period
ClassMethod GetResendStopDateTime(pSeconds As %String = -1800) As %String
{
	Set tNow = $ZDATETIME($HOROLOG,3,1)
	Set tReturn = ##class(Utility).AddDateTimeDiff(tNow,pSeconds,"SQL_TSI_SECOND")
	Quit tReturn
}

ClassMethod IdentiKey(
	pKey As %String = 1,
	pResendDelay As %String) As %Status
{
	Set pSeconds = 0 - $Get(pResendDelay,1800)
	Set pStart = "1840-12-31 12:00:00"
	Set pStop = ..GetResendStopDateTime(pSeconds)
	Set tNow = $ZDATETIME($HOROLOG,3,1)
	Write tNow,!
	Set tClient = ..GetResendClient(.tSC)
	Set tCount = 0
	Set tResendCount = 0
	Set tKey = pKey
	Set tQuery = ""
	Set tQuery($Increment(tQuery)) = "SELECT * FROM Ens_Enterprise_MsgBank.MessageHeader"
	Set tQuery($Increment(tQuery)) = "WHERE TimeCreated >= ? AND"
	Set tQuery($Increment(tQuery)) = "TimeCreated <= ?"
	ZW tQuery
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSC = tStatement.%Prepare(.tQuery)  // Create a cached query
	If $$$ISERR(tSC) { Quit tSC }
	Write "Default Select Mode = ",tStatement.%SelectMode,!  // 0=Logical, 1=ODBC, 2=Display
	#dim tResult As %SQL.StatementResult
	Set tResult = tStatement.%Execute($Get(pStart),$Get(pStop))
	IF (tResult.%SQLCODE=0) { WRITE !,"Created a query",! }
	ELSEIF (tResult.%SQLCODE=-361) { WRITE !,"Query exists: ",tResult.%Message }
	ELSE { WRITE !,"CREATE QUERY error: ",tResult.%SQLCODE," ",tResult.%Message QUIT 0}
 	While tResult.%Next() {
	 	If $Increment(tCount)
		If tResult.Status = 9 { Continue }  // Skip Completed
		If tResult.Status = "Completed" { Continue }  // Skip Completed
		If tResult.TargetConfigName = "Ens.Alert" { Continue }  // Ens.Alert
		If tResult.TargetConfigName = "Ens.AlertNotification" { Continue }  // Ens.AlertNotification
		If tResult.SourceConfigName = "Ens.AlertNotification" { Continue }  // Ens.AlertNotification
		Set tMsgId = tResult.ID
		Set tTarget = tResult.TargetConfigName
		// Check if Resent successfully previously
		Set tMsgResendCount = $Get(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,"cnt"))
		If tMsgResendCount {
			Set tMsgResendStatus = $Get(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"sc"))
			If $$$ISOK(tMsgResendStatus) { Continue }  // Already resent successfully
		}
		Set tMsgResendCount = $Increment(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,"cnt"))
		Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId) = tResult.ID
		Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"newnode") = tClient_"|"_tTarget
		Set tResendCount = $Increment(tResendCount)
	}
	Write "tCount = ",tCount,!
	Write "tResendCount = ",tResendCount,!
	Set tNow = $ZDATETIME($HOROLOG,3,1)
	Write tNow,!
	Quit $$$OK
}

ClassMethod MakeClient(pWebIPAddress As %String = "") As %Status
{
	Set tSC = $$$OK
	If ($Get(pWebIPAddress) = "") {
		Set pWebIPAddress = ..FindWebIPAddress(.tSC,.tMachine,.tInstance,.tNamespace)
	}
	Set tPort = $Piece(pWebIPAddress,":",2)
	If (tPort = "") {
		Set tPort = ..TestFindPort(pWebIPAddress)
		If (tPort > 0) {
			Set $Piece(pWebIPAddress,":",2) = tPort
		}
		Write "tPort = ",tPort,!
	}
	Set tClient = ##class(Ens.Enterprise.MonitorClient).%New()
	Set tClient.HomePage = "%25CSP.Portal.Home.zen"
	Set tClient.HomePath = "/csp/dmlss_hc/"
	Set tClient.Name = pWebIPAddress
	Set tClient.Namespace = "DMLSS_HC"
	Set tClient.SOAPCredentials = "HS_Services"
	Set tClient.SSLCheckServerIdentity = 1
	Set tClient.Version = "2020.1.0.215.1."
	Set tClient.WebIPAddress = pWebIPAddress
	Set tSC = tClient.%Save()
	Quit tSC
}

ClassMethod Purge() As %Status
{
	/*
	ClassMethod Purge(
		Output pDeletedCount As %Integer,
		pDaysToKeep As %Integer = 7,
		pKeepIntegrity As %Boolean = 1,
		pBodiesToo As %Boolean = 1,
		pBitmapChunkLimit As %Integer = 500) As %Status
	*/
	Set tSC = ##class(Ens.Enterprise.MsgBank.MessageHeader).Purge(.pDeletedCount)
	Quit $$$OK
}

ClassMethod PurgeNodes() As %Status
{
	Kill ^Ens.EntMsgBank.NodeD,^Ens.EntMsgBank.NodeI,^Ens.EntMsgBank.NodeS
	Quit $$$OK
}

ClassMethod Resend(pResendDelay As %String) As %Status
{
	If $SYSTEM.Mirror.IsMember(),'$SYSTEM.Mirror.IsPrimary() Quit $SYSTEM.Status.Error($$$AccessDenied)
	Lock ^Ens.Enterprise.MsgBank("Resend"):1
	If '$TEST { Quit $SYSTEM.Status.Error($$$AccessDenied) }
	Set tClientId = ..GetResendClient()
	If (tClientId = "") Set tSC = ..MakeClient(.pWeb)
	Set pKey = 1
	Set tSC = ..IdentiKey(pKey,pResendDelay)
	Set tSC = ..ResendAll()
	LOCK  // Release all locks
	Quit $$$OK
}

/// Method ReallyResend() As %String [ ZenMethod ]
ClassMethod ResendAll() As %Status
{
	Set tSomeErrors = 0
	Set tHeadOfQueue = 0  // Flag to indicate whether messages should be resent as the head of the queue.
	Set tDirection = 1  // $select(..HeadOfQueue: -1, 1: 1)
	Set tKey = 1
	Set tCount = 0
	Set tMsgId = ""
	For {
		Set tMsgId = $Order(^HS.Local.VFC75.ResendIDs(tKey,tMsgId),tDirection)
		Quit:(tMsgId = "")
		// Purge if tMsgId not found in its original table
		Set tHeader=##class(Ens.Enterprise.MsgBank.MessageHeader).%OpenId(tMsgId,,.tSC)
		If '$IsObject(tHeader) {
			Kill ^HS.Local.VFC75.ResendIDs(tKey,tMsgId)
			Continue
		}
		// Check if Resent successfully previously
		Set tMsgResendCount = $Get(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,"cnt"))
		If tMsgResendCount {
			Set tMsgResendStatus = $Get(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"sc"))
			If $$$ISOK(tMsgResendStatus) { Continue }  // Already resent successfully
		}
		// When tNewTarget is blank the old target is used
		//Set tNewTarget = $select((..NewTarget '= "")||(..newTargetConfig '= ""): ..NewTarget_"|"_..newTargetConfig, 1: $get(^IRIS.Temp.ResendIDs(tKey,tMsgId,"newnode")))
		Set tNewTarget = $Get(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"newnode"))
		Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"before") = $Now()
		Set tSC = ##class(Ens.Enterprise.MsgBank.MessageHeader).ResendDuplicatedMessage(.tWSClients,tMsgId,.tNewHeaderId,tNewTarget,,,tHeadOfQueue)
		//Set tSC = ..ResendDuplicatedMessage(.tWSClients,tMsgId,.tNewHeaderId,tNewTarget,,,tHeadOfQueue)
		Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"rafter") = $Now()
		Set tMsgResendCount = $Get(^HS.Local.VFC75.ResendIDs(tKey,tMsgId,"cnt"))
		If $$$ISERR(tSC) {
			Set tSomeErrors = 1
			Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"sc") = tSC
			Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"new") = ""
		}
		Else {
			Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"sc") = $$$OK
			Set ^HS.Local.VFC75.ResendIDs(tKey,tMsgId,tMsgResendCount,"new") = tNewHeaderId
		}
		If $Increment(tCount) { Continue }
	}
	Set tNow = $ZDATETIME($HOROLOG,3,1)
	Write tNow,!
	If tSomeErrors {
		Write "Could not resend all messages; check Resend Status for results.",!
	}
	Write tCount," message resend(s) attempted",!
	Quit ""
}

/// Copied from Ens.Enterprise.MsgBank.MessageHeader 
/// Invoke a SOAP call to resend a message on the chosen MsgBank client node / SOAP Resend service provider.
/// There must exist a MonitorClient configured that matches the WebAddress of the chosen NodeId
ClassMethod ResendDuplicatedMessage(
	ByRef pWSClientObjs,
	pBankHeaderId As %String,
	Output pNewHeaderId As %String,
	pNewTarget As %String = "",
	pNewBody As %RegisteredObject = {$$$NULLOREF},
	pNewSource As %String = "",
	pHeadOfQueue As %Boolean = 0,
	pUseOriginalClientBody As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, pNewHeaderId=""
	Set tHeader=##class(Ens.Enterprise.MsgBank.MessageHeader).%OpenId(pBankHeaderId,,.tSC)
	If '$IsObject(tHeader) Quit $$$ERROR($$$EnsErrGeneral,"Can not open banked message header "_pBankHeaderId_"; status "_$$$StatusDisplayString(tSC))

	Set tCli=$P(pNewTarget,"|",1,$L(pNewTarget,"|")-1)
	Set tTarg=$P(pNewTarget,"|",$L(pNewTarget,"|"))

	If tHeader.Type = $$$eMessageTypeRequest {
		Set tHeader.CorrespondingMessageId = ""
	} Else {
		Quit:""'=tTarg $$$ERROR($$$EnsErrGeneral,"Cannot send response messages to new target")
	}
	Quit:""'=pNewSource&&(""'=tHeader.ReturnQueueName) $$$ERROR($$$EnsErrGeneral,"Cannot override source for synchronous request message "_pBankHeaderId)

	If ""'=tCli {
		Set tSameNode=(tCli=$G(^Ens.MsgBankSvr("nodemap",tHeader.NodeId)))
	} Else { 
		Set tCli=$G(^Ens.MsgBankSvr("nodemap",tHeader.NodeId)), tSameNode=1
		Quit:""=tCli $$$ERROR($$$EnsErrGeneral,"No configured client found for node "_tHeader.NodeId_" in attempt to resend MsgBank message "_pBankHeaderId)
	}
	Set tOldSessionId = tHeader.SessionId
	#; Resent messages from Message Bank start a fresh session regardless whether resending from the same node they originated on
	Set tHeader.SessionId = ""
	Set tHeader.CorrespondingMessageId = ""

	#; Get cached WebService client object or construct a new one
	Set tWSClient=$G(pWSClientObjs(tCli))  If '$IsObject(tWSClient) {
		Set tClient=##class(Ens.Enterprise.MonitorClient).%OpenId(tCli)
		Set tWSClient=##class(%CSP.Monitor.Client).%New()
		Set tWSClient.Location=tClient.GetURLPath(1)_"_CSP.Monitor.Server.cls"
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tCredObj,$$$CurrentClass,"Ens.Config.Credentials",tClient.SOAPCredentials)  Quit:$$$ISERR(tSC) tSC
		#;Set:$IsObject(tCredObj) pWSClient.HttpUsername=tCredObj.Username, pWSClient.HttpPassword=tCredObj.Password
		Do:$IsObject(tCredObj)&&(""'=tCredObj.Username) tWSClient.WSSecurityLogin(tCredObj.Username,tCredObj.Password)
		Set tWSClient.SSLConfiguration=tClient.SSLConfig
		Set tWSClient.SSLCheckServerIdentity=tClient.SSLCheckServerIdentity
		Set pWSClientObjs(tCli)=tWSClient, pWSClientObjs(tCli,"creds")=tClient.SOAPCredentials, pWSClientObjs(tCli,"webip")=tClient.WebIPAddress
	} Else {
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tCredObj,$$$CurrentClass,"Ens.Config.Credentials",$G(pWSClientObjs(tCli,"creds")))  Quit:$$$ISERR(tSC) tSC
		#;Set:$IsObject(tCredObj) pWSClient.HttpUsername=tCredObj.Username, pWSClient.HttpPassword=tCredObj.Password
		Do:$IsObject(tCredObj)&&(""'=tCredObj.Username) tWSClient.WSSecurityLogin(tCredObj.Username,tCredObj.Password)
	}
	#; If we are asking the MsgBank client's web service to use the original body object, we provide the original node name as a safety check
	Set tNodeName=##class(Ens.Enterprise.MsgBank.Node).GetNodeName(tHeader.NodeId)
	Set tNodeClientId=tHeader.ClientId
	Set tUseOriginalNodeRef = tHeader.NodeId
	If tSameNode {
		If pUseOriginalClientBody {
			#; Prefix node ID with "+" so client system can check whether the node IDs match for resend
			Set tUseOriginalNodeRef = "+"_tHeader.NodeId
		}
	} Else {
		Set tNodeClientId=tNodeName_":"_tNodeClientId
	}
	#; Use new body if provided
	If ""'=pNewBody {
		If '$IsObject(pNewBody) {
			Set tHeader.MessageBodyClassName=""
			Set tHeader.MessageBodyId=pNewBody
		} Else {
			Set tHeader.MessageBodyClassName=$classname(pNewBody)
			If pNewBody.%IsA("%Library.Persistent")||pNewBody.%IsA("%Stream.Object") Set tSC=pNewBody.%Save()
			If $$$ISOK(tSC) Set tSC=pNewBody.%GetSwizzleObject(0,.tOID)
			Quit:$$$ISERR(tSC) tSC
			Set tHeader.MessageBodyId=$$$oidPrimary(tOID)
		}
	}
	Set tBodyClass=tHeader.MessageBodyClassName, tBodyId=tHeader.MessageBodyId
	If tHeader.MessageBodyClassName="" {
		If ""=tHeader.MessageBodyId {
			Set tBodyType="Empty"
		} Else {
			Set tBodyType="String"
		}
	} ElseIf $classmethod(tBodyClass,"%Extends","%SerialObject") {
		Set tBodyType="Serial"
	} Else {
		Set tBody = $classmethod(tBodyClass,"%OpenId",tBodyId)
		Quit:'$IsObject(tBody) $$$ERROR($$$EnsErrGeneral,"Unable to instantiate banked MessageBody for banked Header #"_pBankHeaderId_" with body class "_tBodyClass_" and body Id "_tBodyId)
		Set tBodyType=$S(
			tBody.%Extends("EnsLib.EDI.Document"):"VDoc"
			,tBody.%Extends("Ens.StreamContainer"):"CData"
			,tBody.%Extends("%Stream.Object"):
				$S(tHeader.ClientBodyClassName=tBodyClass:"SData",1:"XMLStream")
			,tBody.%Extends("%XML.Adaptor"):"XML"
			,1:"Other")
	}
	$$$sysTRACE("Resending banked message "_pBankHeaderId_" with body "_tBodyId_" of type "_tBodyType_"/"_tBodyClass_$S(tHeader.ClientBodyClassName=tBodyClass:"",1:"/"_tHeader.ClientBodyClassName)_" from client system '"_tCli_"' at address "_$G(pWSClientObjs(tCli,"webip"))_" with credentials '"_$G(pWSClientObjs(tCli,"creds"))_"'")
	
	#; Fix up the banked header's properties and XMLExport it (we won't save the changes we make to it)
	Set tHeader.MessageBodyClassName=tHeader.ClientBodyClassName
	Set tHeader.MessageBodyId=tHeader.ClientBodyId
	Set tSC=tHeader.XMLExportToStream(.xmlHeader)  Quit:""=tSC tSC	

	Set tStream=##class(%GlobalBinaryStream).%New()
	If tBodyType="VDoc" {
		Do tStream.Write("<VDoc DocType='"_tBody.DocType_"'><![CDATA[")
		Set tSC=tBody.OutputToLibraryStream(tStream)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></VDoc>")
	} ElseIf tBodyType="CData" {
		Do tStream.Write("<CData Type='"_tBody.Type_"' Size='"_tBody.Stream.Size_"' Filename='"_$ZCVT(tBody.OriginalFilename,"O","XML")_"'><![CDATA[")
		Set tSC=tStream.CopyFrom(tBody.Stream)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></CData>")
	} ElseIf tBodyType="SData" {
		Do tStream.Write("<SData Size='"_tBody.Size_"'><![CDATA[")
		Set tSC=tStream.CopyFrom(tBody)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></SData>")
	} ElseIf tBodyType="XMLStream" {
		Do tStream.Write("<XML Size='"_tBody.Size_"'><![CDATA[")

		/*	Check to see if has XML declaration. If so leave. If not add and convert to UTF-8
			Check code based on %XML.SAX.StreamAdapter
		*/
		Do tBody.Rewind()
	 	#dim tXMLDeclaration = tBody.Read(100)
	 	Do tBody.Rewind()		
		#; If has BOM or begins <?xml leave as is
		If ($Ascii(tXMLDeclaration)=$$$UNIVAL) ||
			($Extract(tXMLDeclaration,1,3)=$$$UTF8BOM) ||
			($Extract(tXMLDeclaration,1,5)="<?xml" ) {
				Set tSC=tStream.CopyFrom(tBody)  Quit:$$$ISERR(tSC) tSC
		} Else {
			Do tStream.Write("<?xml version='1.0' encoding='UTF-8'?>")
			While 'tBody.AtEnd {
    			Do tStream.Write($ZCVT(tBody.Read(10000),"O","UTF8"))
  			}
  			Do tBody.Rewind()
		}
		
		Do tStream.WriteLine("]]></XML>")
	} ElseIf tBodyType="XML" {
		Do tStream.Write("<XML><![CDATA[")
		Set tSC=tBody.XMLExportToStream(tStream)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></XML>")
	} ElseIf tBodyType="Serial" {
		Do tStream.Write("<Serial Size='"_$L(tBodyId)_"'/>")
	} ElseIf tBodyType="String" {
		Do tStream.Write("<String/>")
	} ElseIf tBodyType="Empty" {
		Do tStream.Write("<Empty/>")
	} Else {
		$$$LOGWARNING("Unsupported message type "_tBodyType_" - not resending "_tHeader.MessageBodyClassName_" "_tBodyId)
		Do tStream.WriteLine("<NoExport/>")
	}
	#; Call the Resend WebService
	Try {
		Set tNewHeaderId=tWSClient.ResendDuplicatedMessage(tNodeClientId, xmlHeader, tTarg, tStream, pNewSource, pHeadOfQueue, tUseOriginalNodeRef)
		Set tNode=$P(tNewHeaderId,","), tNewHeaderId=$P(tNewHeaderId,",",2,99)
		&sql(Select ID Into :tNodeId From Ens_Enterprise_MsgBank.Node Where Name=:tNode)
		If SQLCODE'=0 { ; Handle case where nothing found
			;Set:SQLCODE tNodeId=tHeader.NodeId
			Set tNodeId=-99
		}
		Set pNewHeaderId=tNodeId_tNewHeaderId
		// Interlink child and parent sessions; note client ID for children
		Set ^Ens.MsgBank.Sessions("child",tOldSessionId,pNewHeaderId)=tCli
		Set ^Ens.MsgBank.Sessions("parent",pNewHeaderId,tOldSessionId)=""		
	} Catch errobj {
		Set errText=$S("<ZSOAP>"=errobj.Name:$$$StatusDisplayString(%objlasterror), 1:errobj.AsSystemError())
		Set tSC=$$$ERROR($$$EnsErrGeneral,errText)
 	}
	Quit tSC
}

ClassMethod TestFindPort(pWeb As %String = "") As %Integer
{
	Set tReturn = -1
	Set pUrl = "/csp/user/cache_status.cxw"
	Set pTimeout = 0.1
	If (pWeb = "") Set pWeb = "localhost"
	Set tServer = $Piece(pWeb,":",1)
	Set tPort = $Piece(pWeb,":",2)
	If (tPort = "") Set tPort = 32768
	For {
		Set tClient = tServer_":"_tPort
		Set tSC = ..GetClientStatus(tClient,pUrl,pTimeout)
		If $$$ISOK(tSC) { Set tReturn = tPort Quit }
		If ($Increment(tPort) > 99999) { Quit }
	}
	Quit tReturn
}

ClassMethod TestPurgeClients() As %Status
{
	Set tQuery = "SELECT * FROM Ens_Enterprise.MonitorClient"
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tSC = tStatement.%Prepare(.tQuery)  // Create a cached query
	If $$$ISERR(tSC) { Quit tSC }
	Write "Default Select Mode = ",tStatement.%SelectMode,!  // 0=Logical, 1=ODBC, 2=Display
	#dim tResult As %SQL.StatementResult
	Set tResult = tStatement.%Execute()
	IF (tResult.%SQLCODE=0) { WRITE !,"Created a query",! }
	ELSEIF (tResult.%SQLCODE=-361) { WRITE !,"Query exists: ",tResult.%Message }
	ELSE { WRITE !,"CREATE QUERY error: ",tResult.%SQLCODE," ",tResult.%Message QUIT tSC}
 	While tResult.%Next() {
		Set tClient = tResult.ID
		Do ..DebugTEST("tClient = "_tClient)
		Set tWebIPAddress = tResult.WebIPAddress
		Set tSC = ..GetClientStatus(tWebIPAddress)
		Do ..DebugStatus(tSC)
		If $$$ISERR(tSC) {
			Set tSC = ##class(Ens.Enterprise.MonitorClient).%DeleteId(tClient)
			Do ..DebugStatus(tSC)
		}
		Continue
	}
	Quit tSC
}

}
