$d = New-Object -ComObject Addin.DrvFR
$d.ConnectionType=0; $d.ComNumber=12; $d.BaudRate=6; $d.Timeout=2000; $d.Password=30
[void]$d.Connect()
# Read model params around license bits
foreach ($n in @(23,43,47,54,55,56,57,58,0x63,0x64,99,100)) {
  $d.ModelParamNumber = $n
  $rc = $d.ReadModelParamValue()
  $rd = $d.ReadModelParamDescription()
  Write-Host ("Param {0}=0x{0:X} rc={1}/{2} value=[{3}] desc=[{4}]" -f $n, $rc, $rd, $d.ModelParamValue, $d.ModelParamDescription)
}
# Search descriptions containing license
for ($i=0; $i -lt [Math]::Min(200, $d.ModelParamCount); $i++) {
  $d.ModelParamIndex = $i
  $d.ReadModelParamDescription() | Out-Null
  $desc = [string]$d.ModelParamDescription
  if ($desc -match '??????|Licen|???????|???????????') {
    $d.ReadModelParamValue() | Out-Null
    Write-Host ("IDX $i Num=$($d.ModelParamNumber) Val=$($d.ModelParamValue) Desc=$desc")
  }
}
