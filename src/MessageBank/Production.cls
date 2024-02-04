Class MessageBank.Production Extends Ens.Enterprise.MsgBank.Production
{

/// Override this in your Production class to do setup before the Production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	Set tHost = $SYSTEM.INetInfo.LocalHostName()
	Set tHostIPAddr = ##class(Utility).GetHostIPAddr()
	Set tIncrement = $Increment(^HS.Local.VFC75.MessageBank)
	Set ^HS.Local.VFC75.MessageBank(tIncrement) = "Start^"_tHost_"^"_tHostIPAddr_"^"_$Get(pTimeStarted)
	Quit $$$OK
}

/// Override this in your Production class to do cleanup after the Production stops
ClassMethod OnStop(pTimeStarted As %String, pForced As %Boolean)
{
	Set tHost = $SYSTEM.INetInfo.LocalHostName()
	Set tHostIPAddr = ##class(Utility).GetHostIPAddr()
	Set tIncrement = $Increment(^HS.Local.VFC75.MessageBank)
	Set ^HS.Local.VFC75.MessageBank(tIncrement) = "Stop^"_tHost_"^"_tHostIPAddr_"^"_$Get(pTimeStarted)_"^"_$Get(pForced)
	Quit
}

XData ProductionDefinition
{
<Production Name="MessageBank.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="MonitorService" Category="" ClassName="Ens.Enterprise.MonitorService" PoolSize="1" Enabled="true" Foreground="false" Comment="Populates global ^IRIS.Temp.Ens.EntMonitorStatus by polling namespaces from Systems List every CallInterval seconds" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
    <Setting Target="Host" Name="AlertGracePeriod">0</Setting>
    <Setting Target="Host" Name="AlertOnError">0</Setting>
    <Setting Target="Host" Name="ArchiveIO">0</Setting>
    <Setting Target="Adapter" Name="CallInterval">10</Setting>
  </Item>
  <Item Name="MsgBankService" Category="" ClassName="Ens.Enterprise.MsgBank.TCPService" PoolSize="100" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">20</Setting>
    <Setting Target="Host" Name="AlertGracePeriod">0</Setting>
    <Setting Target="Host" Name="AlertOnError">0</Setting>
    <Setting Target="Host" Name="ArchiveIO">0</Setting>
    <Setting Target="Adapter" Name="Endian">Big</Setting>
    <Setting Target="Adapter" Name="UseFileStream">0</Setting>
    <Setting Target="Adapter" Name="JobPerConnection">1</Setting>
    <Setting Target="Adapter" Name="AllowedIPAddresses"></Setting>
    <Setting Target="Adapter" Name="QSize">100</Setting>
    <Setting Target="Adapter" Name="CallInterval">5</Setting>
    <Setting Target="Adapter" Name="Port">9192</Setting>
    <Setting Target="Adapter" Name="StayConnected">-1</Setting>
    <Setting Target="Adapter" Name="ReadTimeout">10</Setting>
    <Setting Target="Adapter" Name="SSLConfig"></Setting>
    <Setting Target="Host" Name="BankHelperClass">MessageBank.BankHelperClass</Setting>
  </Item>
</Production>
}

}
