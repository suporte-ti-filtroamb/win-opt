<#
.SYNOPSIS
    Script de Otimização de Performance e Debloat para Windows 11 Home (Ambiente Corporativo).
.DESCRIPTION
    Realiza limpeza profunda, desativa telemetria (via Registro, compatível com Windows Home),
    desativa serviços pesados, remove pesquisa do Bing no menu iniciar e ajusta o plano de energia.
.NOTES
    Compatível com Windows 11 Home / Pro.
#>

# 1. Privilégios de Administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Solicitando privilégios de Administrador..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   OTIMIZADOR DE PERFORMANCE - WINDOWS 11 HOME (CORP)   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 2. Desativar Telemetria e Coleta de Dados (Via Registro para Win 11 Home)
Write-Host "[1/6] Desativando Telemetria e Rastreamento corporativo..." -ForegroundColor Yellow
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
)
foreach ($path in $RegistryPaths) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Force -ErrorAction SilentlyContinue
}

# Desativar experiências de telemetria adicionais
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue

# 3. Remover Pesquisa do Bing no Menu Iniciar (Melhora muito o lag do Menu Iniciar)
Write-Host "[2/6] Removendo buscas do Bing do Menu Iniciar..." -ForegroundColor Yellow
$SearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $SearchPath)) { New-Item -Path $SearchPath -Force | Out-Null }
Set-ItemProperty -Path $SearchPath -Name "BingSearchEnabled" -Value 0 -Force -ErrorAction SilentlyContinue

$ExplorerPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $ExplorerPath)) { New-Item -Path $ExplorerPath -Force | Out-Null }
Set-ItemProperty -Path $ExplorerPath -Name "DisableSearchBoxSuggestions" -Value 1 -Force -ErrorAction SilentlyContinue

# 4. Desativar Serviços Pesados (SysMain / Windows Search se desejado)
# Nota: Windows Search é mantido ativo para não quebrar buscas locais corporativas de arquivos, mas o SysMain (Superfetch) é desativado para evitar gargalo de disco.
Write-Host "[3/6] Desativando SysMain (Superfetch) para poupar I/O de disco..." -ForegroundColor Yellow
if (Get-Service -Name "SysMain" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
}

# 5. Forçar Plano de Energia de Alto Desempenho
Write-Host "[4/6] Configurando Energia para Alto Desempenho..." -ForegroundColor Yellow
# Executa os comandos redirecionando erros para o null, já que alguns hardwares (como laptops com Modern Standby S0) bloqueiam planos personalizados
try {
    & powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >$null 2>&1
    & powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >$null 2>&1
} catch {
    # Ignora silenciosamente se o hardware não der suporte
}

# 6. Limpeza Geral de Arquivos Temporários, Cache e DNS (Silencioso e à prova de falhas)
Write-Host "[5/6] Executando Limpeza Geral de Temporários..." -ForegroundColor Yellow
$TempPaths = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:WINDIR\Prefetch",
    "$env:WINDIR\SoftwareDistribution\Download"
)
foreach ($folder in $TempPaths) {
    if (Test-Path $folder) {
        # Obtém itens recursivamente e remove individualmente num bloco try/catch para evitar erros se um arquivo sumir no meio do processo
        Get-ChildItem -Path $folder -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            } catch {
                # Ignora silenciosamente arquivos bloqueados ou já deletados
            }
        }
    }
}
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Clear-DnsClientCache -ErrorAction SilentlyContinue

# 7. Otimização de Efeitos Visuais (Priorizar Desempenho)
Write-Host "[6/6] Ajustando Efeitos Visuais para melhor resposta do sistema..." -ForegroundColor Yellow
$VisualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $VisualFXPath)) { New-Item -Path $VisualFXPath -Force | Out-Null }
Set-ItemProperty -Path $VisualFXPath -Name "VisualFXSetting" -Value 2 -Force -ErrorAction SilentlyContinue

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   OTIMIZAÇÃO CONCLUÍDA! RECOMENTA-SE REINICIAR A MÁQUINA!  " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Start-Sleep -Seconds 5
