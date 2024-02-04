Class MessageBank.ResendStatus Extends %Persistent [ StorageStrategy = NewStorage1 ]
{

Index NewIndex1 On (Key, MsgId, ResendAttempt) [ IdKey, PrimaryKey, Unique ];

Property Key As %String [ Required ];

Property MsgId As %String [ Required ];

Property NewMsgId As %String;

Property NewTarget As %String;

Property ResendAfter As %String;

Property ResendAttempt As %String;

Property ResendBefore As %String;

Property ResendStatus As %Status;

Property zResendCalc As %Integer [ Calculated, SqlComputeCode = {set {*}=##class(MessageBank.Utility).GetDateTimeDiff({ResendBefore},{ResendAfter})}, SqlComputed ];

Property zResendCount As %Integer [ Calculated, SqlComputeCode = {set {*}=##class(MessageBank.ResendStatus).GetResendCount({Key},{MsgId})}, SqlComputed ];

ClassMethod GetResendCount(
	pKey As %String,
	pMsgId As %String) As %String
{
	Set tReturn = ""
	If ($Get(pKey) = "") Quit tReturn
	If ($Get(pMsgId) = "") Quit tReturn
	Set tReturn = $Get(^HS.Local.VFC75.ResendIDs(pKey,pMsgId,"cnt"))
	Quit tReturn
}

Storage NewStorage1
{
<SQLMap name="Map1">
<Data name="NewMsgId">
<Delimiter>"^"</Delimiter>
<Node>"new"</Node>
<Piece>1</Piece>
</Data>
<Data name="NewTarget">
<Delimiter>"^"</Delimiter>
<Node>"newnode"</Node>
<Piece>1</Piece>
</Data>
<Data name="ResendAfter">
<Delimiter>"^"</Delimiter>
<Node>"rafter"</Node>
<Piece>1</Piece>
</Data>
<Data name="ResendBefore">
<Delimiter>"^"</Delimiter>
<Node>"before"</Node>
<Piece>1</Piece>
</Data>
<Data name="ResendStatus">
<Delimiter>"^"</Delimiter>
<Node>"sc"</Node>
<Piece>1</Piece>
</Data>
<Global>^HS.Local.VFC75.ResendIDs</Global>
<Subscript name="1">
<Expression>{Key}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{MsgId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{ResendAttempt}</Expression>
<StartValue>1</StartValue>
<StopValue>999999</StopValue>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^HS.Local.VFC75.ResendIDsS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
