$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
Write-Host "Mode=$($d.ECRMode) CapOpenCheck=$($d.CapOpenCheck) CapFN=$($d.CapFiscalStorage)"
# MethodSupported?
try {
  $d.MethodName = "OpenCheck"
  Write-Host "MethodSupported OpenCheck=$($d.MethodSupported) rc=$($d.ResultCode)"
} catch { Write-Host "MethodSupported err $_" }
try {
  $d.MethodName = "FNOpenCheck"
  Write-Host "MethodSupported FNOpenCheck=$($d.MethodSupported)"
} catch { Write-Host "FNOpenCheck MS err $_" }
try {
  $d.MethodName = "FNOperation"
  Write-Host "MethodSupported FNOperation=$($d.MethodSupported)"
} catch {}

# FNOpenCheck with CheckType
foreach ($ct in @(0,1)) {
  $d.CheckType = $ct
  try {
    $rc = $d.FNOpenCheck()
    Write-Host "FNOpenCheck ct=$ct rc=$rc $($d.ResultCodeDescription)"
  } catch { Write-Host "FNOpenCheck ct=$ct err $_" }
}

# FNOperation without open
$d.Quantity = 1; $d.Price = 10; $d.Summ1 = 10; $d.Department = 1; $d.CheckType = 1
$d.PaymentTypeSign = 4; $d.PaymentItemSign = 1; $d.StringForPrinting = "item"
try { $d.TaxValueEnabled = $false } catch {}
$rc = $d.FNOperation()
Write-Host "FNOperation=$rc $($d.ResultCodeDescription)"
