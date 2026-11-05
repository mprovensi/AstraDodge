# DEPLOY de teste: roda a BATERIA COMPLETA e, só se TUDO passar, gera o APK e instala em todos
# os celulares conectados por USB. Se algum teste falhar, não instala nada.
#   powershell -ExecutionPolicy Bypass -File tools\deploy_dev.ps1
# (A cada envio ao GitHub a mesma bateria também roda sozinha: .github/workflows/testes.yml.)
$project = Split-Path $PSScriptRoot -Parent
$godot = $env:GODOT
if (-not $godot) {
    $godot = "C:\Users\mprov\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
}
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

& (Join-Path $PSScriptRoot "rodar_testes.ps1")
if ($LASTEXITCODE -ne 0) {
    Write-Host "DEPLOY CANCELADO: há testes falhando." -ForegroundColor Red
    exit 1
}

Write-Host "Gerando o APK..."
& $godot --headless --path $project --export-debug Android "build/AstraDodge-debug.apk" *> $null
$apk = Join-Path $project "build\AstraDodge-debug.apk"
if (-not (Test-Path $apk)) {
    Write-Host "Falha ao gerar o APK." -ForegroundColor Red
    exit 1
}
$devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" } | ForEach-Object { ($_ -split "\t")[0] }
if (-not $devices) {
    Write-Host "APK pronto em build\AstraDodge-debug.apk (nenhum celular conectado)."
    exit 0
}
foreach ($d in $devices) {
    Write-Host "Instalando em $d..."
    & $adb -s $d install -r $apk
}
Write-Host "DEPLOY OK" -ForegroundColor Green
