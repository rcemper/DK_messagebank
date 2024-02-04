Class MessageBank.ResendTask Extends %SYS.Task.Definition
{

Parameter TaskName = "Message Bank Resend";

/// Time (in seconds) to wait before a message can be resent
Property ResendDelay As %ZEN.Datatype.string [ InitialExpression = 1800 ];

Method OnTask() As %Status
{
	Quit ##class(MessageResend).Resend(..ResendDelay)
}

}
