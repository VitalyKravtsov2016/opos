$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
Write-Host ("Connect=" + $d.Connect())
Write-Host ("UModel=" + $d.UModel + " ModelID=" + $d.ModelID + " ModelsCount=" + $d.ModelsCount)
Write-Host ("UDescription=" + $d.UDescription)
Write-Host ("CapOpenCheck=" + $d.CapOpenCheck + " LicenseIsPresent=" + $d.LicenseIsPresent)
Write-Host ("LicenseCommercialStatus=[" + $d.LicenseCommercialStatus + "] Sub=[" + $d.LicenseSubscriptionStatus + "] Valid=" + $d.LicenseValidationStatus + " Ver=" + $d.LicenseVersion)
for ($i=0; $i -lt [Math]::Min(20, $d.ModelsCount); $i++) {
  $d.ModelIndex = $i
  Write-Host ("Model[$i] ID=" + $d.ModelID + " Names=" + $d.ModelNames)
}
# Try forcing licensed model ids
foreach ($mid in @(0,1,27,76,251)) {
  try {
    $d.ModelID = $mid
    $d.CheckType = 0
    $rc = $d.OpenCheck()
    Write-Host ("OpenCheck ModelID=$mid rc=$rc " + $d.ResultCodeDescription)
  } catch { Write-Host ("OpenCheck ModelID=$mid err $_") }
}
# Try ReadLicense / Set license from file
try {
  $licTxt = (Get-Content -LiteralPath 'C:\Program Files (x86)\PosCenter\DrvKKT\Bin\DrvFR.lic' -Raw).Trim()
  $d.License = $licTxt
  Write-Host ("Set License len=" + $licTxt.Length + " LicenseIsPresent=" + $d.LicenseIsPresent)
  $rc = $d.WriteLicense(); Write-Host ("WriteLicense=" + $rc + " " + $d.ResultCodeDescription)
} catch { Write-Host ("WriteLicense err $_") }
try { $rc = $d.ReadLicense(); Write-Host ("ReadLicense=" + $rc + " License=[" + $d.License + "]") } catch { Write-Host $_ }
try { $rc = $d.ReadKKTLicenses(); Write-Host ("ReadKKTLicenses=" + $rc) } catch { Write-Host $_ }
