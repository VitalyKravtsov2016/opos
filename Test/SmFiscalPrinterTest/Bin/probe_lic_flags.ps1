$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType = 0
$d.ComNumber = 12
try { $d.BaudRate = 115200 } catch { $d.BaudRate = 6 }
$d.Timeout = 1000
$d.Password = 1
[void]$d.Connect()
Write-Host ("UModel=" + $d.UModel + " CapOpenCheck=" + $d.CapOpenCheck + " LicenseIsPresent=" + $d.LicenseIsPresent)
$d.CheckType = 0
$rc = $d.OpenCheck()
Write-Host ("OpenCheck=" + $rc + " " + $d.ResultCodeDescription)
$d.Quantity = 1
$d.Price = 10
$d.Summ1 = 10
$d.Department = 1
$d.CheckType = 1
$d.PaymentTypeSign = 4
$d.PaymentItemSign = 1
$d.StringForPrinting = "item"
try { $d.TaxValueEnabled = $false } catch {}
$rc = $d.FNOperation()
Write-Host ("FNOperation=" + $rc + " " + $d.ResultCodeDescription)
