Class MessageBank.Utility
{

ClassMethod AddDateTimeDiff(
	pTS1 As %String,
	pDiff As %Integer,
	pTSI As %String = "SQL_TSI_SECOND") As %String
{
	Set c = ","
	Set q = "'"
	Set pQuery = "SELECT {fn TIMESTAMPADD("_pTSI_c_pDiff_c_q_pTS1_q_")}"
	Set tSC = ..ExecuteQueryOneValue(pQuery,.pResult)
	Quit $Get(pResult,"<undefined>")
}

ClassMethod ExecuteQueryOneValue(
	pQuery As %String,
	ByRef pResult As %String) As %Status
{
	Set pResult = ""
	Set rs = ##class(%ResultSet).%New()
	Set tSC = rs.Prepare(pQuery)
	If $$$ISOK(tSC) {
		Set tSC = rs.Execute()
		If $$$ISOK(tSC), rs.Next() Set pResult = rs.GetData(1)
	}
	Do rs.Close()
	Set rs = ""
	Quit tSC
}

ClassMethod GetDateTimeDiff(
	pTS1 As %String,
	pTS2 As %String,
	pTSI As %String = "SQL_TSI_SECOND") As %String
{
	Set c = ","
	Set q = "'"
	Set pQuery = "SELECT {fn TIMESTAMPDIFF("_pTSI_c_q_pTS1_q_c_q_pTS2_q_")}"
	Set tSC = ..ExecuteQueryOneValue(pQuery,.pResult)
	Quit $Get(pResult,"<undefined>")
}

ClassMethod GetHostIPAddr(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	//Set tHostIPAddr = $P($zu(54,13,$zu(54,0)),",")
	Set tHostinfoPath = "/hostinfo/"
	Set tHostinfoFile = "host.config"
	Set tFile = tHostinfoPath_tHostinfoFile
	If ##class(%File).DirectoryExists(tHostinfoPath) {
		If ##class(%File).Exists(tFile) {
			Set tF = ##class(%File).%New(tFile)
			If $IsObject(tF) {
				Set tSC = tF.Open("R")
				If $$$ISOK(tSC) {
					Set tHostIPAddr = tF.Read()
					Do tF.Close()
					Set tF = ""
				} Else {
					//Set pSC = $SYSTEM.Status.Error($$$GeneralError,tFile_" unknown error 1")
				}
			} Else {
				//Set pSC = $SYSTEM.Status.Error($$$GeneralError,tFile_" unknown error 2")
			}
		} Else {
			//Set pSC = $SYSTEM.Status.Error($$$GeneralError,tHostinfoFile_" not found")
		}
	} Else {
		//Set pSC = $SYSTEM.Status.Error($$$GeneralError,tHostinfoPath_" not found")
	}
	Quit $Get(tHostIPAddr)
}

}
