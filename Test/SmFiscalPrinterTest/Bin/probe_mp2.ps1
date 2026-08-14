$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
# mpCapCashCore=0x1C, mpCapFN=0x47, mpCapFN11=0x50, mpCapMapping22=0x57
# and try 0x62,0x63,0x64,0x65 for new license params
$nums = @(0x1C,0x15,0x16,0x17,0x47,0x50,0x57,0x58,0x5C,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6A)
foreach ($n in $nums) {
  $d.ModelParamNumber = $n
  $rc = $d.ReadModelParamValue()
  $d.ReadModelParamDescription() | Out-Null
  Write-Host ("0x{0:X2}({1}) rc={2} val=[{3}]" -f $n,$n,$rc,$d.ModelParamValue)
}
Write-Host "OpenCheck=$($d.OpenCheck()) $($d.ResultCodeDescription)"
