$ErrorActionPreference = 'Continue'
$d = New-Object -ComObject Addin.KKTDrv
Write-Host ("ModelsCount=" + $d.ModelsCount)
$max = [Math]::Min(200, [int]$d.ModelsCount)
for ($i = 0; $i -lt $max; $i++) {
  $d.ModelIndex = $i
  $name = [string]$d.ModelNames
  $id = $d.ModelID
  # match RR by code page independent: look for model ids from doc
  if (@(3,13,14,15,31,45,103,113,114,115) -contains $id -or $name -like '*RR*' -or $name -like '*PP-*') {
    Write-Host ("IDX=$i ID=$id Name=$name")
  }
}
foreach ($id in @(3,13,14,15,31,45,27)) {
  try {
    $d.ModelID = $id
    Write-Host ("Set ID=$id -> ModelID=$($d.ModelID) Names=$($d.ModelNames)")
  } catch {
    Write-Host ("Set ID=$id err $_")
  }
}
