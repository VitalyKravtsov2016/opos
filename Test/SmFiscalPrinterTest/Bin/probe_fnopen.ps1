$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
Write-Host ("LicPresent=" + $d.LicenseIsPresent + " CapOpenCheck=" + $d.CapOpenCheck + " FMFlags=" + $d.FMFlags)
$rc=$d.ReadFeatureLicenses(); Write-Host ("ReadFeatureLicenses=$rc Lic=[" + $d.License + "] Ver=" + $d.LicenseVersion + " Comm=[" + $d.LicenseCommercialStatus + "] Sub=[" + $d.LicenseSubscriptionStatus + "] Valid=" + $d.LicenseValidationStatus + " " + $d.ResultCodeDescription)
try { $rc=$d.FNOpenCheck(); Write-Host ("FNOpenCheck=$rc " + $d.ResultCodeDescription) } catch { Write-Host "FNOpenCheck err $_" }
$d.CheckType=0; $rc=$d.OpenCheck(); Write-Host ("OpenCheck=$rc " + $d.ResultCodeDescription)
# props that might gate
foreach ($p in @('ITSLicenseTrial','KKTLicense','LicenseNumber','UseLicenses','CashControlEnabled','EnableCashCore','LD1CCapOpenCheck')) {
  try { $v = $d.$p; Write-Host ("PROP $p=$v") } catch { }
}
