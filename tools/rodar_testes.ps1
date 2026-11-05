# Roda a BATERIA COMPLETA de testes do Astra Dodge e mostra um resumo.
#   powershell -ExecutionPolicy Bypass -File tools\rodar_testes.ps1
# Leva ~10 min (o bot joga a campanha inteira, o Infinito, o Desafio etc.).
# Sai com código 1 se algum teste falhar (o Godot não para sozinho num "assert" falho, por isso
# o script procura "SCRIPT ERROR" na saída). É a mesma checagem do GitHub (.github/workflows/testes.yml).
$godot = $env:GODOT
if (-not $godot) {
    $godot = "C:\Users\mprov\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
}
$project = Split-Path $PSScriptRoot -Parent
$log = Join-Path $env:TEMP "astradodge_testes.log"

Write-Host "Importando recursos..."
& $godot --headless --path $project --import *> $null
Write-Host "Rodando os testes (cerca de 10 minutos)..."
& $godot --headless --path $project --script res://tests/smoke_test.gd *> $log

$lines = Get-Content $log
$ok = $lines | Where-Object { $_ -match " OK( \||$)" }
$fail = $lines | Where-Object { $_ -match "SCRIPT ERROR|Assertion failed" }
Write-Host ""
Write-Host ("Passaram: {0}" -f $ok.Count)
foreach ($l in $ok) { Write-Host ("  OK  " + ($l -split '\|')[0].Trim()) }
if ($fail.Count -gt 0) {
    Write-Host ""
    Write-Host ("FALHARAM: {0}" -f $fail.Count) -ForegroundColor Red
    $i = 0
    foreach ($l in $lines) {
        if ($l -match "SCRIPT ERROR|Assertion failed") {
            Write-Host ("  " + $l) -ForegroundColor Red
            if ($i + 1 -lt $lines.Count) { Write-Host ("  " + $lines[$i + 1]) -ForegroundColor DarkRed }
        }
        $i++
    }
    Write-Host ("Log completo: " + $log)
    exit 1
}
Write-Host ""
Write-Host "TODOS OS TESTES PASSARAM" -ForegroundColor Green
exit 0
