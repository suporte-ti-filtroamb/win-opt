<#
.SYNOPSIS
    Script de Diagnóstico Rápido de Hardware para Windows.
.DESCRIPTION
    Exibe de forma limpa e organizada informações do Sistema Operacional, Processador,
    Memória RAM, Discos (identificando SSD vs HDD) e GPU.
.NOTES
    Compatível com Windows 8, 10 e 11.
#>

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "               INFORMAÇÕES DE HARDWARE                     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Sistema Operacional
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    Write-Host "Sistema Operacional: " -NoNewline
    Write-Host "$($os.Caption) ($($os.OSArchitecture))" -ForegroundColor Green
} catch {}

# 2. Fabricante e Modelo
try {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    Write-Host "Fabricante / Modelo: " -NoNewline
    Write-Host "$($cs.Manufacturer) - $($cs.Model)" -ForegroundColor Green
} catch {}

# 3. Processador (CPU)
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    Write-Host "Processador (CPU):   " -NoNewline
    Write-Host "$($cpu.Name.Trim())" -ForegroundColor Green
} catch {}

# 4. Memória RAM
try {
    $ram = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    Write-Host "Memória RAM Total:   " -NoNewline
    Write-Host "$ram GB" -ForegroundColor Green
} catch {}

# 5. Placa de Vídeo (GPU)
try {
    $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    foreach ($gpu in $gpus) {
        Write-Host "Placa de Vídeo (GPU):" -NoNewline
        Write-Host " $($gpu.Name)" -ForegroundColor Green
    }
} catch {}

# 6. Discos de Armazenamento (SSD vs HDD)
Write-Host "`nDiscos e Partições:" -ForegroundColor Yellow
try {
    Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
        $size = [Math]::Round($_.Size / 1GB, 0)
        # Identifica o tipo de mídia de forma limpa
        $mediaType = $_.MediaType
        if (-not $mediaType) { $mediaType = "Não identificado" }
        
        Write-Host "  - Disco $($_.DeviceId): " -NoNewline
        Write-Host "$($_.Model.Trim()) " -NoNewline
        Write-Host "[$mediaType] " -ForegroundColor Cyan -NoNewline
        Write-Host "- $size GB" -ForegroundColor Green
    }
} catch {
    # Fallback caso Get-PhysicalDisk falhe (em VMs antigas ou drivers genéricos)
    Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | ForEach-Object {
        $size = [Math]::Round($_.Size / 1GB, 0)
        Write-Host "  - Disco $($_.Index): $($_.Model.Trim()) - $size GB" -ForegroundColor Green
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
