$d = New-Object -ComObject Addin.KKTDrv
$d.ConnectionType = 0
$d.ComNumber = 12
$d.BaudRate = 6
$d.Timeout = 2000
$d.Password = 30
Write-Host ("Connect=" + $d.Connect() + " rc=" + $d.ResultCode)
Write-Host ("UModel=" + $d.UModel + " ModelID=" + $d.ModelID)
Write-Host ("UDescription=[" + $d.UDescription + "]")
Write-Host ("CapOpenCheck=" + $d.CapOpenCheck)
