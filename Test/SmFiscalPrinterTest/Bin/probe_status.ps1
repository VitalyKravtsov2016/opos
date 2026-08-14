$ErrorActionPreference = 'Continue'
$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType = 0
$d.ComNumber = 12
# BaudRate is enum index in PosCenter; 6 = 115200
$d.BaudRate = 6
$d.Timeout = 3000
$d.Password = 30
Write-Host ("Connect=" + $d.Connect() + " rc=" + $d.ResultCode + " " + $d.ResultCodeDescription)
Write-Host ("UModel=" + $d.UModel + " ModelID=" + $d.ModelID + " CapOpenCheck=" + $d.CapOpenCheck)
$d.Password = 30
$rc = $d.GetECRStatus()
Write-Host ("GetECRStatus(pwd30)=" + $rc + " FMFlags=" + $d.FMFlags + " LicenseIsPresent=" + $d.LicenseIsPresent + " Mode=" + $d.ECRMode + " " + $d.ResultCodeDescription)
$d.Password = 1
$rc = $d.GetECRStatus()
Write-Host ("GetECRStatus(pwd1)=" + $rc + " FMFlags=" + $d.FMFlags + " LicenseIsPresent=" + $d.LicenseIsPresent + " Mode=" + $d.ECRMode + " " + $d.ResultCodeDescription)
Write-Host ("FM1=" + $d.FM1IsPresent + " DayOpen=" + $d.IsFMSessionOpen + " Lic=" + $d.LicenseIsPresent)
try {
  $rc = $d.ReadFeatureLicenses()
  Write-Host ("ReadFeatureLicenses=" + $rc + " License=[" + $d.License + "] Ver=" + $d.LicenseVersion + " Comm=[" + $d.LicenseCommercialStatus + "] Sub=[" + $d.LicenseSubscriptionStatus + "] Valid=" + $d.LicenseValidationStatus + " " + $d.ResultCodeDescription)
} catch { Write-Host ("ReadFeatureLicenses err " + $_) }
$d.CheckType = 0
$rc = $d.OpenCheck()
Write-Host ("OpenCheck=" + $rc + " " + $d.ResultCodeDescription)
$d.Quantity = 1; $d.Price = 10; $d.Summ1 = 10; $d.Department = 1; $d.CheckType = 1
$d.PaymentTypeSign = 4; $d.PaymentItemSign = 1; $d.StringForPrinting = "item"
try { $d.TaxValueEnabled = $false } catch {}
$rc = $d.FNOperation()
Write-Host ("FNOperation=" + $rc + " " + $d.ResultCodeDescription)
