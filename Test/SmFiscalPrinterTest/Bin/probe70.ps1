$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
Write-Host "FMFlags=$($d.FMFlags) LicPresent=$($d.LicenseIsPresent) CapOpen=$($d.CapOpenCheck)"
try { $d.ITSLicenseTrial = $true; Write-Host "set ITSLicenseTrial" } catch { Write-Host "ITS set err $_" }
try { $d.UseLicenses = $false; Write-Host "set UseLicenses false" } catch { Write-Host "UseLicenses err $_" }
try { $d.CashControlEnabled = $false } catch {}
$d.CheckType = 0
Write-Host "OpenCheck=$($d.OpenCheck()) $($d.ResultCodeDescription)"
# Try after ReadFeatureLicenses
$d.ReadFeatureLicenses() | Out-Null
Write-Host "After RFL Comm=$($d.LicenseCommercialStatus) Open=$($d.OpenCheck()) $($d.ResultCodeDescription)"
# Enumerate more props
$d | Get-Member -MemberType Property | Where-Object { $_.Name -match 'Lic|Cash|Model|CapOpen|Trial|Guard' } | ForEach-Object {
  $n=$_.Name
  try { Write-Host ("{0}={1}" -f $n, $d.$n) } catch {}
}
