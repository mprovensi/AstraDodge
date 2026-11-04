# Cria a CHAVE DE LANÇAMENTO (upload key) do Astra Dodge. Rode UMA vez, no PowerShell:
#   powershell -ExecutionPolicy Bypass -File tools\criar_chave_release.ps1
# O keytool vai pedir uma senha e alguns dados (nome, cidade...). A senha NUNCA vai para o
# projeto/Git. Guarde a senha e FAÇA BACKUP do arquivo .keystore (ex.: num pendrive/nuvem):
# sem ele não dá para publicar atualizações (só pedindo reset da chave ao Google).
$dir = Join-Path $env:USERPROFILE ".astradodge"
New-Item -ItemType Directory -Force $dir | Out-Null
$keystore = Join-Path $dir "astradodge-release.keystore"
if (Test-Path $keystore) {
    Write-Host "Já existe uma chave em $keystore — não vou sobrescrever."
    exit 1
}
& "C:\Program Files\Java\jdk-21\bin\keytool.exe" -genkeypair -v -keystore $keystore `
    -alias astradodge -keyalg RSA -keysize 2048 -validity 10000
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Chave criada em: $keystore"
    Write-Host "FAÇA BACKUP desse arquivo e guarde a senha."
}
