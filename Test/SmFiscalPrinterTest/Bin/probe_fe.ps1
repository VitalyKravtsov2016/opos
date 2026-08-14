$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
Write-Host ("LicPresent=$($d.LicenseIsPresent) FMFlags=$($d.FMFlags)")
$rc=$d.ReadFeatureLicenses()
Write-Host ("ReadFeatureLicenses=$rc desc=$($d.ResultCodeDescription)")
Write-Host ("License=[$($d.License)] Ver=$($d.LicenseVersion) Comm=[$($d.LicenseCommercialStatus)] Sub=[$($d.LicenseSubscriptionStatus)] Valid=$($d.LicenseValidationStatus)")
$d.CheckType=0
Write-Host ("OpenCheck=$($d.OpenCheck()) $($d.ResultCodeDescription)")
