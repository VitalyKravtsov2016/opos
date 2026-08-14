$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()

function Show($tag) {
  Write-Host ("[$tag] VerProp exists?")
  try { Write-Host ("  LicenseVersion=$($d.LicenseVersion)") } catch { Write-Host "  no LicenseVersion" }
  try { Write-Host ("  Comm=$($d.LicenseCommercialStatus) Sub=$($d.LicenseSubscriptionStatus) Valid=$($d.LicenseValidationStatus) INN=$($d.LicenseINN)") } catch { Write-Host "  status err $_" }
  Write-Host ("  License=$($d.License.Substring(0,[Math]::Min(40,$d.License.Length)))...")
}

# Write all FF then read
$d.License = ("FF" * 64)
$d.DigitalSign = ("11" * 64)
[void]$d.WriteFeatureLicenses()
Show 'after write FF'

# Change emulator won't store - read returns zeros from emu
[void]$d.ReadFeatureLicenses()
Show 'after read'

# Try client-side parse: set License and call something
$d.License = ("01" + ("FF" * 63))
Show 'set license 01FF..'

# OpenCheck still?
$d.CheckType = 0
Write-Host ("OpenCheck=$($d.OpenCheck()) $($d.ResultCodeDescription)")
$d.CheckType = 1
Write-Host ("FNOpenCheck=$($d.FNOpenCheck()) $($d.ResultCodeDescription)")
