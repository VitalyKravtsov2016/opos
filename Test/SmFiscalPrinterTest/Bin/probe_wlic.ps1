$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
# Craft license v1-ish payload as hex (64 bytes)
# Try: ver=1, then commercial end date 2030-12-31 as unix or BCD, leg date, INN
function Set-Lic([string]$hex) {
  $d.License = $hex
  $d.DigitalSign = ("00" * 64)
  try { $d.LicenseVersion = 1 } catch {}
  try { $d.ECRDate = [datetime]"2030-12-31" } catch {}
  try { $d.LicenseINN = "1234567890" } catch {}
  try { $d.LicenseCommercialStatus = "2030-12-31" } catch {}
  try { $d.LicenseSubscriptionStatus = "2030-12-31" } catch {}
  $rc = $d.WriteFeatureLicenses()
  Write-Host ("WriteFeatureLicenses=$rc $($d.ResultCodeDescription)")
}
# First see what Write sends with minimal props
$d.License = ("FF" * 64)
$d.DigitalSign = ("AA" * 64)
try { $d.LicenseVersion = 1 } catch { Write-Host "set ver err $_" }
$rc = $d.WriteFeatureLicenses()
Write-Host ("Write FF=$rc $($d.ResultCodeDescription)")
