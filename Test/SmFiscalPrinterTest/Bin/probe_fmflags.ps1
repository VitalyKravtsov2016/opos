$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType = 0
$d.ComNumber = 12
try { $d.BaudRate = 115200 } catch { $d.BaudRate = 6 }
$d.Timeout = 1000
$d.Password = 1
[void]$d.Connect()
$rc = $d.GetECRStatus()
Write-Host ("GetECRStatus=" + $rc + " FMFlags=" + $d.FMFlags + " LicenseIsPresent=" + $d.LicenseIsPresent)
# model params commercial/leg
foreach ($n in @(0x63, 0x64, 99, 100)) {
  try {
    $d.ModelParamNumber = $n
    $rc = $d.ReadModelParamValue()
    Write-Host ("ModelParam 0x{0:X} rc={1} value={2} desc={3}" -f $n, $rc, $d.ModelParamValue, $d.ModelParamDescription)
  } catch {
    Write-Host ("ModelParam 0x{0:X} err {1}" -f $n, $_)
  }
}
try {
  $rc = $d.ReadFeatureLicenses()
  Write-Host ("ReadFeatureLicenses=" + $rc + " License=" + $d.License + " LicenseVersion=" + $d.LicenseVersion + " Commercial=" + $d.LicenseCommercialStatus + " Sub=" + $d.LicenseSubscriptionStatus + " Valid=" + $d.LicenseValidationStatus)
} catch { Write-Host ("ReadFeatureLicenses err " + $_) }
$d.CheckType = 0
$rc = $d.OpenCheck()
Write-Host ("OpenCheck=" + $rc + " " + $d.ResultCodeDescription)
$d.Quantity = 1; $d.Price = 10; $d.Summ1 = 10; $d.Department = 1; $d.CheckType = 1
$d.PaymentTypeSign = 4; $d.PaymentItemSign = 1; $d.StringForPrinting = "item"
try { $d.TaxValueEnabled = $false } catch {}
$rc = $d.FNOperation()
Write-Host ("FNOperation=" + $rc + " " + $d.ResultCodeDescription)
