# Gera o pacote de LANÇAMENTO (.aab) para a Google Play, assinado com a chave criada por
# tools\criar_chave_release.ps1. Rode no PowerShell:
#   powershell -ExecutionPolicy Bypass -File tools\exportar_release.ps1
# Pede a senha da chave (não fica salva em lugar nenhum). Na 1ª vez o Gradle baixa as
# ferramentas de build do Android (alguns minutos; precisa de internet).
# Saída: build\AstraDodge-release.aab  (o seletor FASES (DEV) não existe nesta versão).
$godot = "C:\Users\mprov\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$project = Split-Path $PSScriptRoot -Parent
$keystore = Join-Path $env:USERPROFILE ".astradodge\astradodge-release.keystore"
if (-not (Test-Path $keystore)) {
    Write-Host "Chave não encontrada. Crie primeiro: tools\criar_chave_release.ps1"
    exit 1
}
$secure = Read-Host "Senha da chave de lançamento" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $keystore
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "astradodge"
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    & $godot --headless --path $project --install-android-build-template `
        --export-release "Android Release" "build/AstraDodge-release.aab"
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
}
if (Test-Path (Join-Path $project "build\AstraDodge-release.aab")) {
    Write-Host "Pronto: build\AstraDodge-release.aab"
}
