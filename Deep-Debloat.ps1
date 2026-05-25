<#
.SYNOPSIS
    Script de Debloat Avançado e Otimização Extrema para Windows 11 Home (Corporativo).
.DESCRIPTION
    Remove bloatware pré-instalado do Windows (UWP apps inúteis), limita uso de CPU do Windows Defender,
    desativa widgets, feeds de notícias, telemetria avançada, GameDVR (gravação em segundo plano Xbox)
    e impede o Microsoft Edge de rodar em segundo plano após ser fechado.
.NOTES
    Compatível com Windows 11 Home / Pro. Executar como Administrador.
#>

# 1. Privilégios de Administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Solicitando privilégios de Administrador..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "==========================================================" -ForegroundColor Red
Write-Host "        DEBLOAT AVANÇADO & OTIMIZAÇÃO EXTREMA             " -ForegroundColor Red
Write-Host "==========================================================" -ForegroundColor Red

# 2. Remover Bloatware Pré-instalado (UWP Apps Desnecessários)
Write-Host "[1/5] Desinstalando Bloatware do Windows (Xbox, Clima, Notícias, Spotify)..." -ForegroundColor Yellow
$BloatwareList = @(
    "*Microsoft.BingNews*", 
    "*Microsoft.BingWeather*", 
    "*Clipchamp.Clipchamp*", 
    "*Microsoft.GamingApp*", 
    "*Microsoft.GetHelp*", 
    "*Microsoft.Getstarted*", 
    "*Microsoft.MicrosoftOfficeHub*", 
    "*Microsoft.MixedReality.Portal*", 
    "*Microsoft.People*", 
    "*Microsoft.SkypeApp*", 
    "*Microsoft.MicrosoftSolitaireCollection*", 
    "*SpotifyAB.SpotifyMusic*", 
    "*Microsoft.Todos*", 
    "*Microsoft.YourPhone*", 
    "*Microsoft.ZuneMusic*", 
    "*Microsoft.ZuneVideo*", 
    "*Microsoft.Xbox*",
    "*Microsoft.XboxGamingOverlay*",
    "*Microsoft.XboxSpeechToTextOverlay*",
    "*Microsoft.549981C3F5F10*" # Cortana
)

foreach ($app in $BloatwareList) {
    Write-Host "      - Removendo $app..." -ForegroundColor DarkGray
    Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $app } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# 3. Limitar Uso de CPU do Windows Defender durante Varreduras
Write-Host "[2/5] Limitando uso de CPU do Windows Defender em segundo plano para 25%..." -ForegroundColor Yellow
# Evita que o Defender consuma 100% de CPU e congele a máquina durante verificações automáticas
try {
    Set-MpPreference -ScanAvgCpuLimit 25 -ErrorAction SilentlyContinue
    Write-Host "      - Limite de CPU do Defender definido para 25%." -ForegroundColor DarkGray
} catch {}

# 4. Desativar Componentes de Consumo Inúteis (Widgets, Feeds, Spotlight)
Write-Host "[3/5] Desativando Widgets, Feeds de Notícias e Sugestões da Microsoft..." -ForegroundColor Yellow
$RegPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsFeeds"
)
foreach ($path in $RegPaths) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsFeeds" -Name "EnableFeeds" -Value 0 -Force -ErrorAction SilentlyContinue # Desativa Widgets

# 5. Impedir Microsoft Edge de rodar em Segundo Plano (Economiza muita RAM)
Write-Host "[4/5] Impedindo Microsoft Edge de pré-iniciar e rodar em segundo plano..." -ForegroundColor Yellow
$EdgePolicies = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main",
    "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader"
)
foreach ($path in $EdgePolicies) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "AllowPrelaunch" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" -Name "AllowTabPreloading" -Value 0 -Force -ErrorAction SilentlyContinue

# Desativar inicialização automática do Edge
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "MicrosoftEdgeAutoLaunch" -Value 0 -ErrorAction SilentlyContinue

# 6. Desativar Gravação em Segundo Plano Xbox (GameDVR)
Write-Host "[5/5] Desativando gravação em segundo plano de jogos (Xbox GameDVR)..." -ForegroundColor Yellow
$GameConfig = "HKCU:\System\GameConfigStore"
if (Test-Path $GameConfig) {
    Set-ItemProperty -Path $GameConfig -Name "GameDVR_Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
}
$GameDVRPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
if (-not (Test-Path $GameDVRPolicy)) { New-Item -Path $GameDVRPolicy -Force | Out-Null }
Set-ItemProperty -Path $GameDVRPolicy -Name "AllowGameDVR" -Value 0 -Force -ErrorAction SilentlyContinue

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   DEBLOAT E OTIMIZAÇÃO EXTREMA APLICADOS COM SUCESSO!     " -ForegroundColor Green
Write-Host "   RECOMENDA-SE REINICIAR A MÁQUINA!                      " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Start-Sleep -Seconds 5
