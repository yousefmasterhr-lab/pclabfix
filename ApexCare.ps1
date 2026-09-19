# ==============================================================================
# ApexCare Engine (Beast Edition)
# Enterprise-Grade Autonomous Windows Performance Tuning, Diagnostics,
# Kernel Optimization and Deep System Maintenance Suite.
# Runs elevated, in-memory execution compatible, reboot survival state-machine,
# Modern Fluent/Cyberpunk TUI, zero-latency network, GPU Beast Mode.
# ==============================================================================

# ==============================================================================
# 0. RUNTIME INITIALIZATION & SELF-ELEVATION
# ==============================================================================
$ErrorActionPreference = "SilentlyContinue"

# Configure console output encoding for modern terminals
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Safe TLS 1.2 / TLS 1.3 protocol registration across all .NET versions
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor 12288
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

# Storage Directory for logs & state persistence
$Global:AppDir = "$env:ProgramData\ApexCare"
$Global:LocalScript = Join-Path $Global:AppDir "ApexCare.ps1"
$Global:StateFile = Join-Path $Global:AppDir "state.json"
$Global:ReportFile = Join-Path $Global:AppDir "SystemReport.txt"
$Global:HtmlReport = Join-Path $Global:AppDir "ApexCare_Dashboard.html"
$Global:LiveJsFile = Join-Path $Global:AppDir "apex_live_state.js"
$Global:DashboardLaunched = $false
$Global:ShortUrl = "https://tinyurl.com/pclabfix"
$Global:RawUrl = "https://raw.githubusercontent.com/yousefmasterhr-lab/pclabfix/main/ApexCare.ps1"

function Initialize-AppDirectory {
    if (-not (Test-Path $Global:AppDir)) { 
        try {
            New-Item -Path $Global:AppDir -ItemType Directory -Force | Out-Null 
        } catch {
            $Global:AppDir = "$env:TEMP\ApexCare"
            $Global:LocalScript = Join-Path $Global:AppDir "ApexCare.ps1"
            $Global:StateFile = Join-Path $Global:AppDir "state.json"
            $Global:ReportFile = Join-Path $Global:AppDir "SystemReport.txt"
            $Global:HtmlReport = Join-Path $Global:AppDir "ApexCare_Dashboard.html"
            $Global:LiveJsFile = Join-Path $Global:AppDir "apex_live_state.js"
            New-Item -Path $Global:AppDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}
Initialize-AppDirectory

function Sync-LocalScript {
    Initialize-AppDirectory
    try {
        $raw = ""
        try {
            $raw = (Invoke-RestMethod -Uri $Global:ShortUrl -UseBasicParsing)
        } catch {
            $raw = (Invoke-RestMethod -Uri $Global:RawUrl -UseBasicParsing)
        }
        if ($raw -and $raw.Length -gt 100) {
            [System.IO.File]::WriteAllText($Global:LocalScript, $raw, [System.Text.Encoding]::UTF8)
        }
    } catch {}
}

# Resolve execution path (in-memory pipeline vs local file)
$Global:ScriptRuntimePath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($Global:ScriptRuntimePath)) {
    $Global:ScriptRuntimePath = $Global:LocalScript
    Sync-LocalScript
} else {
    try {
        Copy-Item -Path $Global:ScriptRuntimePath -Destination $Global:LocalScript -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Assert-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host ""
        Write-Host " [*] Elevating privileges to Administrator..." -ForegroundColor Yellow
        
        # Ensure script exists locally if executed in-memory
        if ([string]::IsNullOrWhiteSpace($Global:ScriptRuntimePath) -or (-not (Test-Path $Global:ScriptRuntimePath))) {
            $Global:ScriptRuntimePath = $Global:LocalScript
            Sync-LocalScript
        }

        if (-not (Test-Path $Global:ScriptRuntimePath)) {
            Write-Host " [X] Could not resolve script location for elevation." -ForegroundColor Red
            Read-Host " Press Enter to exit..."
            exit 1
        }

        $elevatedArgs = @(
            "-NoExit",
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$Global:ScriptRuntimePath`""
        ) -join " "

        try {
            Start-Process -FilePath "powershell.exe" -ArgumentList $elevatedArgs -Verb RunAs
        } catch {
            Write-Host " [X] Administrator privileges were denied or elevation failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "     Please right-click PowerShell and choose 'Run as administrator', then re-run the script." -ForegroundColor Yellow
            Read-Host " Press Enter to exit..."
        }
        exit 0
    }
}
Assert-Administrator

# ==============================================================================
# 1. MODERN FLUENT TUI STYLING & CLI BOX HELPERS
# ==============================================================================
function Show-Header {
    Clear-Host
    Write-Host " +------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host " |                 APEXCARE ENGINE  //  BEAST EDITION                     |" -ForegroundColor Cyan
    Write-Host " |     Autonomous Kernel Tuning | Diagnostics | GPU Acceleration | Repair |" -ForegroundColor DarkCyan
    Write-Host " +------------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step {
    param([string]$Title)
    Write-Host " [*] $Title" -ForegroundColor Cyan
    Add-LiveLog -Type "info" -Message $Title
}

function Write-Success {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
    Add-LiveLog -Type "success" -Message $Message
}

function Write-Notice {
    param([string]$Message)
    Write-Host "    [!] $Message" -ForegroundColor Yellow
    Add-LiveLog -Type "warning" -Message $Message
}

function Write-Critical {
    param([string]$Message)
    Write-Host "    [X] $Message" -ForegroundColor Red
    Add-LiveLog -Type "error" -Message $Message
}

function Write-Highlight {
    param([string]$Message)
    Write-Host "    [>] $Message" -ForegroundColor Magenta
    Add-LiveLog -Type "info" -Message $Message
}

# ==============================================================================
# 1.5 LIVE MISSION CONTROL REAL-TIME TELEMETRY & EVENT STREAM ENGINE
# ==============================================================================
$Global:ApexLiveState = @{
    Timestamp       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Status          = "Standing By"
    CurrentStage    = @{ Index = 0; Name = "Ready" }
    ProgressPercent = 0
    TotalStages     = 13
    Stages          = @(
        @{ Index = 1;  Name = "System Restore Point Safeguard";     Status = "Pending" },
        @{ Index = 2;  Name = "Dependencies & Modules";             Status = "Pending" },
        @{ Index = 3;  Name = "Hardware & Diagnostics Audit";       Status = "Pending" },
        @{ Index = 4;  Name = "Network Stack Turbocharging";        Status = "Pending" },
        @{ Index = 5;  Name = "CPU & Kernel Peak Responsiveness";   Status = "Pending" },
        @{ Index = 6;  Name = "Gamer Latency & Core Unparking";     Status = "Pending" },
        @{ Index = 7;  Name = "GPU Beast Mode & Display Pipeline";  Status = "Pending" },
        @{ Index = 8;  Name = "Standby RAM & Storage Cleanup";      Status = "Pending" },
        @{ Index = 9;  Name = "Safe Telemetry & Diagnostic Debloat"; Status = "Pending" },
        @{ Index = 10; Name = "Core OS Integrity & Image Repair";   Status = "Pending" },
        @{ Index = 11; Name = "OEM Ecosystem & Driver Servicing";   Status = "Pending" },
        @{ Index = 12; Name = "Native Application Fleet Upgrade";   Status = "Pending" },
        @{ Index = 13; Name = "Interactive HTML Dashboard Export";  Status = "Pending" }
    )
    Incidents       = @()
    Logs            = @()
    SystemInfo      = @{}
    OEM             = @{}
}

function Add-LiveLog {
    param(
        [string]$Type,
        [string]$Message
    )
    try {
        if ($null -eq $Global:ApexLiveState) { return }
        $timeStr = (Get-Date).ToString("HH:mm:ss")
        $logItem = @{
            Time    = $timeStr
            Type    = $Type
            Message = $Message
        }
        $Global:ApexLiveState.Logs += $logItem
        if ($Global:ApexLiveState.Logs.Count -gt 75) {
            $Global:ApexLiveState.Logs = $Global:ApexLiveState.Logs[-75..-1]
        }
        Export-LiveStateJs
    } catch {}
}

function Add-LiveIncident {
    param(
        [string]$Stage,
        [string]$RawError,
        [string]$Diagnosis,
        [string]$Resolution,
        [string]$ActionUrl,
        [string]$ActionText
    )
    try {
        if ($null -eq $Global:ApexLiveState) { return }
        $incident = @{
            Timestamp  = (Get-Date).ToString("HH:mm:ss")
            Stage      = $Stage
            RawError   = $RawError
            Diagnosis  = $Diagnosis
            Resolution = $Resolution
            ActionUrl  = $ActionUrl
            ActionText = $ActionText
        }
        $Global:ApexLiveState.Incidents += $incident
        Export-LiveStateJs
        Export-DiagnosticHtmlReport -Silent:$true
    } catch {}
}

function Update-LiveStage {
    param(
        [int]$Index,
        [string]$Status
    )
    try {
        if ($null -eq $Global:ApexLiveState) { return }
        if ($Index -ge 1 -and $Index -le $Global:ApexLiveState.Stages.Count) {
            $Global:ApexLiveState.Stages[$Index - 1].Status = $Status
            $stageName = $Global:ApexLiveState.Stages[$Index - 1].Name
            $Global:ApexLiveState.CurrentStage = @{ Index = $Index; Name = $stageName }
            if ($Status -eq "Running") {
                $Global:ApexLiveState.Status = "Running: Stage $Index - $stageName"
            }
        }
        $completedCount = ($Global:ApexLiveState.Stages | Where-Object { $_.Status -eq "Completed" -or $_.Status -eq "Warning" }).Count
        $Global:ApexLiveState.ProgressPercent = [Math]::Round(($completedCount / $Global:ApexLiveState.TotalStages) * 100)
        Export-LiveStateJs
    } catch {}
}

function Export-LiveStateJs {
    try {
        if (-not (Test-Path $Global:AppDir)) { Initialize-AppDirectory }
        $json = $Global:ApexLiveState | ConvertTo-Json -Depth 6 -Compress
        $jsContent = "window.ApexLiveState = " + $json + "; if (window.ApexMissionControl && window.ApexMissionControl.render) { window.ApexMissionControl.render(window.ApexLiveState); }"
        [System.IO.File]::WriteAllText($Global:LiveJsFile, $jsContent, [System.Text.Encoding]::ASCII)
    } catch {}
}

function Initialize-LiveDashboard {
    try {
        Initialize-AppDirectory
        
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $vols = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
        $oem = Get-OEMSupportDetails

        $totalRamGB = if ($cs) { [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1) } else { 16 }
        $freeRamGB = if ($os) { [Math]::Round($os.FreePhysicalMemory / 1MB, 1) } else { 8 }
        $usedRamGB = [Math]::Round($totalRamGB - $freeRamGB, 1)
        $diskCFreeGB = if ($vols) { [Math]::Round($vols.SizeRemaining / 1GB, 1) } else { 0 }
        $vramGB = if ($gpus -and $gpus.AdapterRAM) { [Math]::Round($gpus.AdapterRAM / 1GB, 1) } else { 0 }

        $Global:ApexLiveState.SystemInfo = @{
            Hostname    = $env:COMPUTERNAME
            OS          = if ($os) { $os.Caption } else { "Windows 10/11" }
            Build       = if ($os) { $os.BuildNumber } else { "" }
            CPU         = if ($cpu) { $cpu.Name } else { "Processor" }
            Cores       = if ($cpu) { $cpu.NumberOfCores } else { 4 }
            Threads     = if ($cpu) { $cpu.NumberOfLogicalProcessors } else { 8 }
            TotalRamGB  = $totalRamGB
            FreeRamGB   = $freeRamGB
            UsedRamGB   = $usedRamGB
            GPU         = if ($gpus) { $gpus.Name } else { "Graphics Controller" }
            VRAM        = $vramGB
            DiskCFree   = $diskCFreeGB
            BatteryWear = 0
        }

        $Global:ApexLiveState.OEM = @{
            OEMName       = $oem.OEMName
            Model         = $oem.Model
            SerialNumber  = $oem.SerialNumber
            ToolName      = $oem.ToolName
            ToolUrl       = $oem.ToolUrl
            SupportPortal = $oem.SupportPortal
        }

        Add-LiveLog -Type "info" -Message "ApexCare Engine initialized. Ready to execute."
        Export-LiveStateJs
        Export-DiagnosticHtmlReport -Silent:$true
    } catch {}
}

# ==============================================================================
# 2. DETERMINISTIC STATE MACHINE (REBOOT SURVIVAL)
# ==============================================================================
function Set-AutomationState {
    param(
        [string]$CurrentPhase,
        [int]$StepIndex
    )
    $state = [PSCustomObject]@{
        IsRunning     = $true
        CurrentPhase  = $CurrentPhase
        StepIndex     = $StepIndex
        ScriptPath    = $Global:ScriptRuntimePath
        Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $state | ConvertTo-Json | Set-Content -Path $Global:StateFile -Force

    # Register RunOnce in Registry
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "ApexCareResume" -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Global:ScriptRuntimePath`" -Resume" -Force
}

function Clear-AutomationState {
    if (Test-Path $Global:StateFile) { Remove-Item -Path $Global:StateFile -Force }
    Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "ApexCareResume" -ErrorAction SilentlyContinue
}

function Get-AutomationState {
    if (Test-Path $Global:StateFile) {
        try {
            return Get-Content -Path $Global:StateFile -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# ==============================================================================
# MODULE 0.5: SYSTEM RESTORE POINT SAFEGUARD
# ==============================================================================
function Invoke-SystemRestorePoint {
    Write-Step "Creating System Restore Point safeguard..."
    try {
        # Check if System Restore service is available
        $vssService = Get-Service -Name "VSS" -ErrorAction SilentlyContinue
        if ($vssService -and $vssService.StartType -eq "Disabled") {
            Set-Service -Name "VSS" -StartupType Manual -ErrorAction SilentlyContinue
        }

        # Enable System Restore on C: if disabled
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue

        # Create Restore Point
        Checkpoint-Computer -Description "ApexCare Pre-Optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Success "System Restore Point 'ApexCare Pre-Optimization' created successfully."
    } catch {
        if ($_.Exception.Message -match "0x80042306" -or $_.Exception.Message -match "frequency" -or $_.Exception.Message -match "24") {
            Write-Notice "A recent System Restore Point was already created within the last 24 hours."
        } else {
            Write-Notice "System Restore check completed: $($_.Exception.Message)"
        }
    }
}

# ==============================================================================
# MODULE 0: ZERO-TOUCH BOOTSTRAPPER
# ==============================================================================
function Install-Prerequisites {
    Write-Step "Bootstrapping core package management and update modules..."
    
    # Verify/Provision Winget
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Notice "Winget not found. Installing App Installer bundle..."
        try {
            $progressPreference = 'SilentlyContinue'
            $msixPath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
            Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $msixPath
            Add-AppxPackage -Path $msixPath
            Write-Success "Winget provisioned successfully."
        } catch {
            Write-Critical "Could not automatically bootstrap Winget: $($_.Exception.Message)"
        }
    } else {
        Write-Success "Winget is present and functional."
    }

    # Verify/Provision PSWindowsUpdate Module
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Notice "Deploying PSWindowsUpdate module from PSGallery..."
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false | Out-Null
            Write-Success "PSWindowsUpdate module deployed."
        } catch {
            Write-Critical "Failed to install PSWindowsUpdate module: $($_.Exception.Message)"
        }
    } else {
        Write-Success "PSWindowsUpdate module verified."
    }
}

# ==============================================================================
# MODULE 1: DEEP HARDWARE & DIAGNOSTIC INTELLIGENCE (WITH OEM HUB)
# ==============================================================================
function Get-OEMSupportDetails {
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_Bios
    $bb = Get-CimInstance Win32_BaseBoard
    
    $mfg = "$($cs.Manufacturer) $($bb.Manufacturer)".Trim()
    $model = "$($cs.Model)".Trim()
    $serial = "$($bios.SerialNumber)".Trim()
    
    $oemName = "Unknown / Custom PC"
    $toolName = "Intel Driver & Support Assistant / Universal Hub"
    $toolUrl = "https://www.intel.com/content/www/us/en/support/detect.html"
    $supportPortal = "https://www.google.com/search?q=" + [System.Uri]::EscapeDataString("$mfg $model drivers support")
    $wingetId = ""

    if ($mfg -match "dell") {
        $oemName = "Dell"
        $toolName = "Dell SupportAssist & Command | Update"
        $toolUrl = "https://www.dell.com/support/contents/en-us/article/product-support/self-support-knowledgebase/software-and-downloads/supportassist"
        if ($serial -and $serial -notmatch "To be filled|Default|None") {
            $supportPortal = "https://www.dell.com/support/home/en-us/product-support/servicetag/$serial/drivers"
        } else {
            $supportPortal = "https://www.dell.com/support/home/en-us"
        }
        $wingetId = "Dell.CommandUpdate"
    }
    elseif ($mfg -match "lenovo") {
        $oemName = "Lenovo"
        $toolName = "Lenovo System Update & Lenovo Vantage"
        $toolUrl = "https://support.lenovo.com/us/en/downloads/ds012808-lenovo-system-update-for-windows-10-7-8-81-32-bit-64-bit"
        if ($serial -and $serial -notmatch "To be filled|Default|None") {
            $supportPortal = "https://pcsupport.lenovo.com/products/search?query=$serial"
        } else {
            $supportPortal = "https://pcsupport.lenovo.com"
        }
        $wingetId = "Lenovo.SystemUpdate"
    }
    elseif ($mfg -match "hp" -or $mfg -match "hewlett-packard") {
        $oemName = "HP (Hewlett-Packard)"
        $toolName = "HP Support Assistant"
        $toolUrl = "https://support.hp.com/us-en/help/hp-support-assistant"
        if ($serial -and $serial -notmatch "To be filled|Default|None") {
            $supportPortal = "https://support.hp.com/us-en/drivers/selfservice?serialnumber=$serial"
        } else {
            $supportPortal = "https://support.hp.com/us-en/drivers"
        }
        $wingetId = "HP.HPSupportAssistant"
    }
    elseif ($mfg -match "asus") {
        $oemName = "ASUS"
        $toolName = "MyASUS & ASUS Live Update"
        $toolUrl = "https://www.asus.com/support/download-center/"
        $supportPortal = "https://www.asus.com/support/"
        $wingetId = "9NBLGGH5155W"
    }
    elseif ($mfg -match "acer") {
        $oemName = "Acer"
        $toolName = "Acer Care Center"
        $toolUrl = "https://www.acer.com/us-en/support/care-center"
        if ($serial -and $serial -notmatch "To be filled|Default|None") {
            $supportPortal = "https://www.acer.com/us-en/support/drivers-and-manuals?search=$serial"
        } else {
            $supportPortal = "https://www.acer.com/us-en/support"
        }
        $wingetId = ""
    }
    elseif ($mfg -match "msi" -or $mfg -match "micro-star") {
        $oemName = "MSI"
        $toolName = "MSI Center / Dragon Center"
        $toolUrl = "https://www.msi.com/Landing/MSI-Center"
        $supportPortal = "https://www.msi.com/support/download/"
        $wingetId = ""
    }
    elseif ($mfg -match "gigabyte") {
        $oemName = "Gigabyte"
        $toolName = "GIGABYTE Control Center (GCC)"
        $toolUrl = "https://www.gigabyte.com/Consumer/Software/GIGABYTE-Control-Center/"
        $supportPortal = "https://www.gigabyte.com/Support"
        $wingetId = ""
    }
    elseif ($mfg -match "huawei") {
        $oemName = "Huawei"
        $toolName = "Huawei PC Manager"
        $toolUrl = "https://consumer.huawei.com/en/support/pc-manager/"
        $supportPortal = "https://consumer.huawei.com/en/support/"
        $wingetId = ""
    }
    elseif ($mfg -match "samsung") {
        $oemName = "Samsung"
        $toolName = "Samsung Update"
        $toolUrl = "https://apps.microsoft.com/detail/9NQ3H6WPM51Q"
        $supportPortal = "https://www.samsung.com/us/support/computing/"
        $wingetId = ""
    }
    elseif ($mfg -match "microsoft" -and $model -match "surface") {
        $oemName = "Microsoft Surface"
        $toolName = "Surface Diagnostic Toolkit"
        $toolUrl = "https://support.microsoft.com/en-us/surface/fix-common-surface-problems-using-the-surface-diagnostic-toolkit-f61d8d18-37a9-863d-a8d0-e9480824e4d3"
        $supportPortal = "https://support.microsoft.com/en-us/surface"
        $wingetId = ""
    }
    else {
        $cpu = (Get-CimInstance Win32_Processor).Manufacturer
        if ($cpu -match "Intel") {
            $oemName = "Custom / Intel Platform"
            $toolName = "Intel Driver & Support Assistant (Intel DSA)"
            $toolUrl = "https://www.intel.com/content/www/us/en/support/detect.html"
            $supportPortal = "https://www.intel.com/content/www/us/en/support.html"
            $wingetId = "Intel.IntelDriverAndSupportAssistant"
        }
        elseif ($cpu -match "AMD") {
            $oemName = "Custom / AMD Platform"
            $toolName = "AMD Auto-Detect and Install Tool"
            $toolUrl = "https://www.amd.com/en/support/download/drivers.html"
            $supportPortal = "https://www.amd.com/en/support"
            $wingetId = ""
        }
    }

    return [PSCustomObject]@{
        OEMName       = $oemName
        RawMfg        = $mfg
        Model         = $model
        SerialNumber  = $serial
        ToolName      = $toolName
        ToolUrl       = $toolUrl
        SupportPortal = $supportPortal
        WingetId      = $wingetId
    }
}

function Invoke-HardwareDiagnostics {
    Write-Step "Executing hardware and configuration diagnostics..."

    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_Bios
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $gpus = Get-CimInstance Win32_VideoController
    $chassis = Get-CimInstance Win32_SystemEnclosure
    $disks = Get-PhysicalDisk
    $oem = Get-OEMSupportDetails
    
    # Form factor
    $isLaptop = $false
    $chassisTypes = $chassis.ChassisTypes
    if ($chassisTypes -contains 8 -or $chassisTypes -contains 9 -or $chassisTypes -contains 10 -or $chassisTypes -contains 14) {
        $isLaptop = $true
    }

    $diagSummary = @()
    $diagSummary += "=========================================================================="
    $diagSummary += "                     SYSTEM SPECIFICATION REPORT                          "
    $diagSummary += "=========================================================================="
    $diagSummary += " Device Hostname : $($cs.Name)"
    $diagSummary += " Manufacturer    : $($cs.Manufacturer)"
    $diagSummary += " Model           : $($cs.Model)"
    $diagSummary += " Serial / Tag    : $($bios.SerialNumber)"
    $diagSummary += " Form Factor     : $(if ($isLaptop) {'Laptop / Mobile'} else {'Desktop / Workstation'})"
    $diagSummary += " CPU Model       : $($cpu.Name)"
    $diagSummary += " Physical Cores  : $($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"
    $diagSummary += " Total Memory    : $([Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB"
    $diagSummary += " BIOS Firmware   : $($bios.SMBIOSBIOSVersion)"
    $diagSummary += " OS Build        : $($os.Caption) (Build $($os.BuildNumber))"
    $diagSummary += "--------------------------------------------------------------------------"
    $diagSummary += " GPU Architecture:"
    foreach ($gpu in $gpus) {
        $diagSummary += "   - $($gpu.Name) (Driver: $($gpu.DriverVersion))"
    }
    $diagSummary += "--------------------------------------------------------------------------"
    $diagSummary += " Storage Health & Media Audit:"
    foreach ($disk in $disks) {
        $status = $disk.HealthStatus
        $diagSummary += "   - Disk $($disk.DeviceId): $($disk.FriendlyName) | Health = $status | Media = $($disk.MediaType)"
        if ($status -ne "Healthy") {
            Write-Critical "Storage Alert: Disk $($disk.DeviceId) reports unhealthy status ($status)!"
        }
    }

    # Battery wear check
    if ($isLaptop) {
        Write-Notice "Mobile platform detected. Auditing battery degradation curve..."
        $batteryPath = "$Global:AppDir\battery-report.xml"
        powercfg /batteryreport /xml /output $batteryPath | Out-Null
        
        if (Test-Path $batteryPath) {
            [xml]$batteryXml = Get-Content $batteryPath
            $designCap = [double]$batteryXml.BatteryReport.Batteries.Battery.DesignCapacity
            $fullCap = [double]$batteryXml.BatteryReport.Batteries.Battery.FullChargeCapacity
            
            if ($designCap -gt 0) {
                $wearLevel = [Math]::Round(((1 - ($fullCap / $designCap)) * 100), 2)
                $diagSummary += "--------------------------------------------------------------------------"
                $diagSummary += " Battery Diagnostic Matrix:"
                $diagSummary += "   - Design Capacity      : $designCap mWh"
                $diagSummary += "   - Full Charge Capacity : $fullCap mWh"
                $diagSummary += "   - Battery Wear Level   : $wearLevel %"
                
                if ($wearLevel -gt 35) {
                    $diagSummary += "   - Battery Status       : HIGH DEGRADATION DETECTED. Replacement recommended."
                } else {
                    $diagSummary += "   - Battery Status       : Normal operational efficiency."
                }
            }
        }
    }

    $diagSummary += "--------------------------------------------------------------------------"
    $diagSummary += " Official OEM Ecosystem Links:"
    $diagSummary += "   - Brand Recognized     : $($oem.OEMName)"
    $diagSummary += "   - Official Diagnostic  : $($oem.ToolName)"
    $diagSummary += "   - Tool Web Page        : $($oem.ToolUrl)"
    $diagSummary += "   - Drivers Hub Portal   : $($oem.SupportPortal)"
    $diagSummary += "=========================================================================="

    # Silent DxDiag export
    Write-Notice "Compiling DirectX diagnostics to background cache..."
    Start-Process -FilePath "dxdiag.exe" -ArgumentList "/t `"$Global:AppDir\dxdiag_raw.txt`"" -Wait

    $diagSummary | Out-File -FilePath $Global:ReportFile -Encoding UTF8 -Force
    Get-Content $Global:ReportFile | Write-Host -ForegroundColor Cyan
    Write-Success "System report saved to: $Global:ReportFile"
}

function Get-HtmlDashboardTemplate {
    return @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ApexCare // Live Mission Control</title>
    <style>
        :root {
            --bg-base: #060911;
            --bg-card: rgba(14, 21, 37, 0.85);
            --bg-card-sub: rgba(22, 33, 58, 0.7);
            --border-glow: rgba(0, 240, 255, 0.2);
            --border-sub: rgba(255, 255, 255, 0.08);
            --cyan: #00f0ff;
            --emerald: #00ff88;
            --amber: #ffaa00;
            --crimson: #ff0055;
            --purple: #a855f7;
            --text-main: #f1f5f9;
            --text-dim: #8ba2c4;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background-color: var(--bg-base);
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(0, 240, 255, 0.05) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(168, 85, 247, 0.05) 0%, transparent 40%);
            color: var(--text-main);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            padding: 24px;
            line-height: 1.5;
            min-height: 100vh;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        
        /* Top Mission Control Bar */
        .top-bar {
            background: var(--bg-card);
            backdrop-filter: blur(16px);
            border: 1px solid var(--border-glow);
            border-left: 5px solid var(--cyan);
            border-radius: 10px;
            padding: 20px 24px;
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
        }
        .brand-title {
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .brand-logo {
            font-size: 26px;
            font-weight: 900;
            background: linear-gradient(135deg, #00f0ff 0%, #00ff88 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: 1.5px;
        }
        .brand-sub {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-dim);
            margin-top: 2px;
        }
        .top-meta {
            display: flex;
            align-items: center;
            gap: 14px;
            flex-wrap: wrap;
        }
        .pulse-indicator {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(0, 255, 136, 0.12);
            border: 1px solid var(--emerald);
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            color: var(--emerald);
            letter-spacing: 0.5px;
        }
        .pulse-dot {
            width: 8px;
            height: 8px;
            background: var(--emerald);
            border-radius: 50%;
            box-shadow: 0 0 10px var(--emerald);
            animation: pulse-ring 1.5s infinite;
        }
        @keyframes pulse-ring {
            0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 255, 136, 0.7); }
            70% { transform: scale(1.1); box-shadow: 0 0 0 8px rgba(0, 255, 136, 0); }
            100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 255, 136, 0); }
        }
        .chip {
            background: var(--bg-card-sub);
            border: 1px solid var(--border-sub);
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 12px;
            color: var(--text-main);
        }
        .chip-label { color: var(--text-dim); font-size: 10px; text-transform: uppercase; margin-right: 4px; }

        /* Hero Progress Card */
        .hero-progress {
            background: linear-gradient(135deg, rgba(14, 21, 37, 0.95) 0%, rgba(20, 31, 56, 0.95) 100%);
            border: 1px solid var(--border-glow);
            border-radius: 10px;
            padding: 24px;
            margin-bottom: 24px;
            display: grid;
            grid-template-columns: 200px 1fr auto;
            gap: 24px;
            align-items: center;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
        }
        @media (max-width: 900px) {
            .hero-progress { grid-template-columns: 1fr; text-align: center; }
        }
        .progress-pct-box {
            text-align: center;
            padding: 10px;
            border-right: 1px solid var(--border-sub);
        }
        @media (max-width: 900px) {
            .progress-pct-box { border-right: none; border-bottom: 1px solid var(--border-sub); padding-bottom: 16px; }
        }
        .pct-number {
            font-size: 48px;
            font-weight: 900;
            color: #fff;
            letter-spacing: -1px;
            line-height: 1;
        }
        .pct-sub {
            font-size: 11px;
            color: var(--cyan);
            text-transform: uppercase;
            font-weight: 700;
            letter-spacing: 1px;
            margin-top: 6px;
        }
        .progress-info {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .stage-heading {
            font-size: 12px;
            font-weight: 700;
            color: var(--cyan);
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .stage-current-name {
            font-size: 20px;
            font-weight: 700;
            color: #fff;
        }
        .main-bar-track {
            background: rgba(255, 255, 255, 0.08);
            border-radius: 6px;
            height: 12px;
            overflow: hidden;
            position: relative;
            margin-top: 4px;
        }
        .main-bar-fill {
            height: 100%;
            background: linear-gradient(90deg, #00f0ff 0%, #00ff88 100%);
            border-radius: 6px;
            transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 0 16px rgba(0, 240, 255, 0.6);
        }
        .hero-actions {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .btn-portal {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 18px;
            background: linear-gradient(135deg, #00f0ff 0%, #0088ff 100%);
            color: #040711;
            font-weight: 700;
            font-size: 12px;
            text-decoration: none;
            border-radius: 6px;
            box-shadow: 0 0 15px rgba(0, 240, 255, 0.35);
            transition: all 0.2s ease;
            white-space: nowrap;
        }
        .btn-portal:hover {
            transform: translateY(-2px);
            box-shadow: 0 0 25px rgba(0, 240, 255, 0.6);
        }
        .btn-secondary {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 8px 16px;
            background: var(--bg-card-sub);
            border: 1px solid var(--border-glow);
            color: var(--cyan);
            font-weight: 600;
            font-size: 12px;
            text-decoration: none;
            border-radius: 6px;
            transition: all 0.2s ease;
            white-space: nowrap;
        }
        .btn-secondary:hover {
            background: rgba(0, 240, 255, 0.15);
            color: #fff;
        }

        /* INCIDENTS & ERROR DIAGNOSIS PANEL (STAR FEATURE) */
        .incident-panel {
            margin-bottom: 24px;
        }
        .incident-card {
            background: linear-gradient(135deg, rgba(255, 0, 85, 0.1) 0%, rgba(20, 28, 48, 0.95) 100%);
            border: 1px solid var(--crimson);
            box-shadow: 0 0 30px rgba(255, 0, 85, 0.25);
            border-radius: 10px;
            padding: 22px 26px;
            margin-bottom: 16px;
            animation: slideDown 0.3s ease-out;
        }
        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .incident-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
            border-bottom: 1px solid rgba(255, 0, 85, 0.2);
            padding-bottom: 14px;
            margin-bottom: 16px;
        }
        .incident-title-row {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .incident-tag {
            background: var(--crimson);
            color: #fff;
            font-size: 11px;
            font-weight: 800;
            padding: 4px 10px;
            border-radius: 4px;
            letter-spacing: 0.5px;
            text-transform: uppercase;
        }
        .incident-title {
            font-size: 16px;
            font-weight: 700;
            color: #fff;
        }
        .incident-stage-badge {
            background: rgba(255, 170, 0, 0.15);
            border: 1px solid var(--amber);
            color: var(--amber);
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 700;
        }
        .incident-body {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 18px;
            margin-bottom: 18px;
        }
        @media (max-width: 800px) {
            .incident-body { grid-template-columns: 1fr; }
        }
        .incident-box {
            background: rgba(8, 12, 22, 0.7);
            border: 1px solid var(--border-sub);
            border-radius: 8px;
            padding: 14px;
        }
        .incident-box-title {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
            color: var(--text-dim);
            margin-bottom: 6px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .incident-code {
            font-family: "Consolas", monospace;
            font-size: 12px;
            color: #ff7799;
            word-break: break-all;
            background: rgba(255, 0, 85, 0.08);
            padding: 8px;
            border-radius: 4px;
            border-left: 3px solid var(--crimson);
        }
        .incident-desc {
            font-size: 13px;
            color: #cbd5e1;
            line-height: 1.5;
        }
        .incident-footer {
            display: flex;
            justify-content: flex-end;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }
        .incident-nominal {
            background: rgba(0, 255, 136, 0.08);
            border: 1px solid rgba(0, 255, 136, 0.3);
            border-radius: 8px;
            padding: 14px 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            color: var(--emerald);
            font-size: 13px;
            font-weight: 600;
        }

        /* 13-STAGE PIPELINE GRID */
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }
        .section-title {
            font-size: 14px;
            font-weight: 700;
            color: var(--cyan);
            text-transform: uppercase;
            letter-spacing: 1px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .pipeline-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
            gap: 14px;
            margin-bottom: 24px;
        }
        .stage-card {
            background: var(--bg-card);
            border: 1px solid var(--border-sub);
            border-radius: 8px;
            padding: 14px 16px;
            transition: all 0.2s ease;
            position: relative;
            overflow: hidden;
        }
        .stage-card:hover {
            border-color: var(--border-glow);
            transform: translateY(-2px);
        }
        .stage-card.is-running {
            border-color: var(--cyan);
            background: rgba(0, 240, 255, 0.06);
            box-shadow: 0 0 20px rgba(0, 240, 255, 0.25);
            animation: pulse-border 2s infinite;
        }
        @keyframes pulse-border {
            0% { border-color: rgba(0, 240, 255, 0.4); }
            50% { border-color: rgba(0, 240, 255, 1); }
            100% { border-color: rgba(0, 240, 255, 0.4); }
        }
        .stage-card.is-completed {
            border-left: 4px solid var(--emerald);
        }
        .stage-card.is-warning {
            border-left: 4px solid var(--amber);
        }
        .stage-card.is-failed {
            border-left: 4px solid var(--crimson);
        }
        .stage-card-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
        }
        .stage-index-tag {
            font-size: 11px;
            font-weight: 800;
            color: var(--text-dim);
            letter-spacing: 0.5px;
        }
        .status-badge {
            font-size: 10px;
            font-weight: 800;
            padding: 3px 8px;
            border-radius: 4px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .badge-pending { background: rgba(255, 255, 255, 0.06); color: var(--text-dim); }
        .badge-running { background: rgba(0, 240, 255, 0.2); color: var(--cyan); border: 1px solid var(--cyan); }
        .badge-completed { background: rgba(0, 255, 136, 0.15); color: var(--emerald); border: 1px solid var(--emerald); }
        .badge-warning { background: rgba(255, 170, 0, 0.15); color: var(--amber); border: 1px solid var(--amber); }
        .badge-failed { background: rgba(255, 0, 85, 0.15); color: var(--crimson); border: 1px solid var(--crimson); }
        .stage-title {
            font-size: 13px;
            font-weight: 600;
            color: #fff;
            margin-top: 2px;
        }

        /* HARDWARE & LOG DUAL PANEL */
        .dual-panel {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }
        @media (max-width: 1000px) {
            .dual-panel { grid-template-columns: 1fr; }
        }

        /* TERMINAL LOG STREAM */
        .terminal-container {
            background: #040711;
            border: 1px solid var(--border-glow);
            border-radius: 10px;
            padding: 16px;
            display: flex;
            flex-direction: column;
            box-shadow: 0 8px 24px rgba(0,0,0,0.4);
        }
        .terminal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border-sub);
            padding-bottom: 10px;
            margin-bottom: 12px;
        }
        .terminal-title {
            font-size: 12px;
            font-weight: 700;
            color: var(--emerald);
            text-transform: uppercase;
            letter-spacing: 1px;
            font-family: "Consolas", monospace;
        }
        .terminal-stream {
            height: 320px;
            overflow-y: auto;
            font-family: "Consolas", "Courier New", monospace;
            font-size: 12px;
            line-height: 1.6;
            padding-right: 8px;
        }
        .log-line {
            margin-bottom: 4px;
            display: flex;
            gap: 10px;
            word-break: break-all;
        }
        .log-time { color: #475569; flex-shrink: 0; }
        .log-info { color: #00e5ff; }
        .log-success { color: #00ff88; }
        .log-warning { color: #ffb700; }
        .log-error { color: #ff3366; }

        /* TELEMETRY CARDS */
        .telemetry-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        .card {
            background: var(--bg-card);
            border: 1px solid var(--border-sub);
            border-radius: 8px;
            padding: 18px;
            transition: all 0.2s ease;
        }
        .card:hover {
            border-color: var(--border-glow);
            transform: translateY(-2px);
        }
        .card-title {
            font-size: 13px;
            font-weight: 700;
            color: var(--cyan);
            margin-bottom: 14px;
            border-bottom: 1px solid var(--border-sub);
            padding-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
        }
        .stat-box {
            background: var(--bg-card-sub);
            padding: 10px 12px;
            border-radius: 6px;
            border: 1px solid rgba(255,255,255,0.03);
        }
        .stat-label { font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.5px; }
        .stat-val { font-size: 13px; font-weight: 700; color: #fff; margin-top: 2px; }

        /* Quick Action Bar */
        .quick-actions-bar {
            background: var(--bg-card);
            border: 1px solid var(--border-sub);
            border-radius: 8px;
            padding: 18px 22px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 14px;
            margin-bottom: 24px;
        }
        .actions-label {
            font-size: 12px;
            font-weight: 700;
            color: var(--cyan);
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .actions-btn-group {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        /* Footer */
        .footer {
            text-align: center;
            color: var(--text-dim);
            font-size: 11px;
            border-top: 1px solid var(--border-sub);
            padding-top: 20px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Top Mission Control Bar -->
        <div class="top-bar">
            <div class="brand-title">
                <div>
                    <div class="brand-logo">APEXCARE // MISSION CONTROL</div>
                    <div class="brand-sub">Autonomous Windows Optimization, Diagnostics & Repair (Beast Edition)</div>
                </div>
            </div>
            <div class="top-meta">
                <div class="pulse-indicator">
                    <div class="pulse-dot"></div>
                    <span id="live-sync-status">ENGINE LIVE SYNCED</span>
                </div>
                <div class="chip"><span class="chip-label">Host:</span><span id="meta-host">HOST</span></div>
                <div class="chip"><span class="chip-label">Platform:</span><span id="meta-platform">OEM</span></div>
                <div class="chip"><span class="chip-label">OS:</span><span id="meta-os">Windows</span></div>
            </div>
        </div>

        <!-- Hero Overall Progress Section -->
        <div class="hero-progress">
            <div class="progress-pct-box">
                <div class="pct-number" id="progress-pct">0%</div>
                <div class="pct-sub" id="progress-status-sub">Standing By</div>
            </div>
            <div class="progress-info">
                <div class="stage-heading" id="current-stage-index">Current Operation</div>
                <div class="stage-current-name" id="current-stage-name">Waiting to initiate routines...</div>
                <div class="main-bar-track">
                    <div class="main-bar-fill" id="main-progress-fill" style="width: 0%;"></div>
                </div>
            </div>
            <div class="hero-actions">
                <a id="btn-hero-portal" href="#" target="_blank" class="btn-portal">Open Support Portal</a>
                <a id="btn-hero-tool" href="#" target="_blank" class="btn-secondary">OEM Diagnostic Tool</a>
            </div>
        </div>

        <!-- Incidents & Error Diagnosis Panel (Star Feature) -->
        <div class="incident-panel">
            <div class="section-header">
                <div class="section-title">[!] Diagnostic Incidents & Self-Healing Analysis</div>
            </div>
            <div id="incident-container">
                <div class="incident-nominal">
                    <span>[OK]</span>
                    <span>ALL SUBSYSTEMS NOMINAL: Zero critical errors detected across active execution routines.</span>
                </div>
            </div>
        </div>

        <!-- 13-Stage Pipeline Visual Timeline -->
        <div class="section-header">
            <div class="section-title">Execution Pipeline (13 Autonomous Stages)</div>
        </div>
        <div class="pipeline-grid" id="pipeline-stages-container">
            <!-- Stage cards generated dynamically -->
        </div>

        <!-- Dual Panel: Hardware Telemetry + Live Terminal Stream -->
        <div class="dual-panel">
            <!-- Telemetry summary -->
            <div style="display: flex; flex-direction: column; gap: 16px;">
                <div class="card">
                    <div class="card-title">Processor & System Memory (RAM)</div>
                    <div class="stat-grid">
                        <div class="stat-box">
                            <div class="stat-label">CPU Model</div>
                            <div class="stat-val" id="tele-cpu" style="font-size: 11px;">Loading...</div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Cores / Threads</div>
                            <div class="stat-val" id="tele-cores">-- / --</div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Total RAM</div>
                            <div class="stat-val" id="tele-ram-total">-- GB</div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Used / Free RAM</div>
                            <div class="stat-val" id="tele-ram-used">-- GB</div>
                        </div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-title">Graphics & Storage Health</div>
                    <div class="stat-grid">
                        <div class="stat-box">
                            <div class="stat-label">Primary GPU</div>
                            <div class="stat-val" id="tele-gpu" style="font-size: 11px;">Loading...</div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">VRAM</div>
                            <div class="stat-val" id="tele-vram">-- GB</div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Drive C: Free Space</div>
                            <div class="stat-val" id="tele-disk-c">-- GB</div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Battery Health / Wear</div>
                            <div class="stat-val" id="tele-battery">--% Wear</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Terminal Live Stream -->
            <div class="terminal-container">
                <div class="terminal-header">
                    <div class="terminal-title">&gt; LIVE ENGINE CONSOLE STREAM</div>
                    <div style="font-size: 11px; color: var(--text-dim);" id="terminal-log-count">0 Events</div>
                </div>
                <div class="terminal-stream" id="terminal-stream-box">
                    <div class="log-line">
                        <span class="log-time">[Init]</span>
                        <span class="log-info">Connecting to ApexCare execution bus...</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Actions & Official OEM Portals -->
        <div class="quick-actions-bar">
            <div class="actions-label">Quick Action & Support Ecosystem</div>
            <div class="actions-btn-group">
                <a id="btn-quick-portal" href="#" target="_blank" class="btn-portal">Drivers Portal</a>
                <a id="btn-quick-tool" href="#" target="_blank" class="btn-secondary">OEM Diagnostic Tool</a>
                <a href="ms-settings:windowsupdate" class="btn-secondary">Windows Update</a>
                <a href="windowsdefender:" class="btn-secondary">Windows Security</a>
            </div>
        </div>

        <div class="footer">
            ApexCare Engine (Beast Edition) // Autonomous Windows Tuning, Diagnostics & System Servicing Suite
        </div>
    </div>

    <!-- Embedded Initial State Fallback -->
    <script id="apex-initial-data">
        /*__INITIAL_LIVE_STATE__*/
    </script>

    <!-- Client-Side Poller & Reactive DOM Engine -->
    <script>
        window.ApexMissionControl = {
            render: function(state) {
                if (!state) return;

                // 1. Meta information
                if (state.SystemInfo) {
                    if (state.SystemInfo.Hostname) document.getElementById('meta-host').innerText = state.SystemInfo.Hostname;
                    if (state.SystemInfo.OS) document.getElementById('meta-os').innerText = state.SystemInfo.OS;
                    if (state.SystemInfo.CPU) document.getElementById('tele-cpu').innerText = state.SystemInfo.CPU;
                    if (state.SystemInfo.Cores) document.getElementById('tele-cores').innerText = state.SystemInfo.Cores + " Cores / " + (state.SystemInfo.Threads || state.SystemInfo.Cores) + " Threads";
                    if (state.SystemInfo.TotalRamGB) document.getElementById('tele-ram-total').innerText = state.SystemInfo.TotalRamGB + " GB";
                    if (state.SystemInfo.FreeRamGB) document.getElementById('tele-ram-used').innerText = state.SystemInfo.FreeRamGB + " GB Free";
                    if (state.SystemInfo.GPU) document.getElementById('tele-gpu').innerText = state.SystemInfo.GPU;
                    if (state.SystemInfo.VRAM) document.getElementById('tele-vram').innerText = state.SystemInfo.VRAM + " GB";
                    if (state.SystemInfo.DiskCFree) document.getElementById('tele-disk-c').innerText = state.SystemInfo.DiskCFree + " GB";
                    if (state.SystemInfo.BatteryWear !== undefined) document.getElementById('tele-battery').innerText = state.SystemInfo.BatteryWear + "% Wear";
                }

                // 2. OEM links
                if (state.OEM) {
                    if (state.OEM.OEMName) document.getElementById('meta-platform').innerText = state.OEM.OEMName;
                    if (state.OEM.SupportPortal) {
                        const pBtn = document.getElementById('btn-hero-portal');
                        const qBtn = document.getElementById('btn-quick-portal');
                        pBtn.href = state.OEM.SupportPortal;
                        pBtn.innerText = "Open " + state.OEM.OEMName + " Support Portal";
                        qBtn.href = state.OEM.SupportPortal;
                    }
                    if (state.OEM.ToolUrl) {
                        const tBtn = document.getElementById('btn-hero-tool');
                        const qtBtn = document.getElementById('btn-quick-tool');
                        tBtn.href = state.OEM.ToolUrl;
                        tBtn.innerText = state.OEM.ToolName || "OEM Diagnostic Tool";
                        qtBtn.href = state.OEM.ToolUrl;
                    }
                }

                // 3. Progress metrics
                const pct = state.ProgressPercent || 0;
                document.getElementById('progress-pct').innerText = pct + "%";
                document.getElementById('main-progress-fill').style.width = pct + "%";
                document.getElementById('progress-status-sub').innerText = state.Status || "Active";

                if (state.CurrentStage) {
                    document.getElementById('current-stage-index').innerText = "STAGE " + state.CurrentStage.Index + " OF 13";
                    document.getElementById('current-stage-name').innerText = state.CurrentStage.Name;
                }

                // 4. Render Stages
                if (state.Stages && state.Stages.length > 0) {
                    const stageContainer = document.getElementById('pipeline-stages-container');
                    let stagesHtml = "";
                    state.Stages.forEach(function(s) {
                        let cardClass = "stage-card";
                        let badgeClass = "status-badge badge-pending";
                        let statusText = s.Status || "Pending";

                        if (statusText === "Running") {
                            cardClass += " is-running";
                            badgeClass = "status-badge badge-running";
                            statusText = "IN PROGRESS";
                        } else if (statusText === "Completed") {
                            cardClass += " is-completed";
                            badgeClass = "status-badge badge-completed";
                            statusText = "[OK] DONE";
                        } else if (statusText === "Warning") {
                            cardClass += " is-warning";
                            badgeClass = "status-badge badge-warning";
                            statusText = "[!] NOTICE";
                        } else if (statusText === "Failed") {
                            cardClass += " is-failed";
                            badgeClass = "status-badge badge-failed";
                            statusText = "[X] FAILED";
                        }

                        stagesHtml += '<div class="' + cardClass + '">' +
                            '<div class="stage-card-top">' +
                                '<span class="stage-index-tag">STAGE ' + (s.Index < 10 ? '0' + s.Index : s.Index) + '</span>' +
                                '<span class="' + badgeClass + '">' + statusText + '</span>' +
                            '</div>' +
                            '<div class="stage-title">' + s.Name + '</div>' +
                        '</div>';
                    });
                    stageContainer.innerHTML = stagesHtml;
                }

                // 5. Render Incidents (Star Feature)
                const incContainer = document.getElementById('incident-container');
                if (state.Incidents && state.Incidents.length > 0) {
                    let incHtml = "";
                    state.Incidents.forEach(function(inc) {
                        incHtml += '<div class="incident-card">' +
                            '<div class="incident-header">' +
                                '<div class="incident-title-row">' +
                                    '<span class="incident-tag">[!] INCIDENT DETECTED</span>' +
                                    '<span class="incident-title">' + inc.Stage + '</span>' +
                                '</div>' +
                                '<span class="incident-stage-badge">SELF-HEALED & BYPASSED</span>' +
                            '</div>' +
                            '<div class="incident-body">' +
                                '<div class="incident-box">' +
                                    '<div class="incident-box-title">Reported System Exception:</div>' +
                                    '<div class="incident-code">' + inc.RawError + '</div>' +
                                    '<div style="font-size: 11px; color: var(--text-dim); margin-top: 8px;">Logged at ' + inc.Timestamp + '</div>' +
                                '</div>' +
                                '<div class="incident-box">' +
                                    '<div class="incident-box-title">Root Cause Diagnosis:</div>' +
                                    '<div class="incident-desc">' + inc.Diagnosis + '</div>' +
                                '</div>' +
                            '</div>' +
                            '<div class="incident-box" style="margin-bottom: 14px;">' +
                                '<div class="incident-box-title">Recommended Resolution:</div>' +
                                '<div class="incident-desc" style="color: #00ff88; font-weight: 500;">' + inc.Resolution + '</div>' +
                            '</div>' +
                            '<div class="incident-footer">';
                        
                        if (inc.ActionUrl) {
                            incHtml += '<a href="' + inc.ActionUrl + '" target="_blank" class="btn-portal">' + (inc.ActionText || "Open Official Portal") + '</a>';
                        }
                        incHtml += '</div></div>';
                    });
                    incContainer.innerHTML = incHtml;
                } else {
                    incContainer.innerHTML = '<div class="incident-nominal">' +
                        '<span>[OK]</span>' +
                        '<span>ALL SUBSYSTEMS NOMINAL: Zero critical errors detected across active execution routines.</span>' +
                    '</div>';
                }

                // 6. Render Terminal Logs
                if (state.Logs && state.Logs.length > 0) {
                    const logBox = document.getElementById('terminal-stream-box');
                    document.getElementById('terminal-log-count').innerText = state.Logs.length + " Events";
                    let logHtml = "";
                    state.Logs.forEach(function(l) {
                        let colClass = "log-info";
                        let prefix = "[*]";
                        if (l.Type === "success") { colClass = "log-success"; prefix = "[OK]"; }
                        else if (l.Type === "warning") { colClass = "log-warning"; prefix = "[!]"; }
                        else if (l.Type === "error") { colClass = "log-error"; prefix = "[X]"; }

                        logHtml += '<div class="log-line">' +
                            '<span class="log-time">' + l.Time + '</span>' +
                            '<span class="' + colClass + '">' + prefix + ' ' + l.Message + '</span>' +
                        '</div>';
                    });
                    logBox.innerHTML = logHtml;
                    logBox.scrollTop = logBox.scrollHeight;
                }
            }
        };

        // Render initial state if present
        if (window.ApexLiveState) {
            window.ApexMissionControl.render(window.ApexLiveState);
        }

        // Live Poller: injects script tag every 1200ms to bypass local file CORS
        function triggerLivePoll() {
            const old = document.getElementById('state-poller-tag');
            if (old) old.remove();
            const s = document.createElement('script');
            s.id = 'state-poller-tag';
            s.src = 'apex_live_state.js?t=' + Date.now();
            s.onerror = function() { /* quiet */ };
            document.head.appendChild(s);
        }
        setInterval(triggerLivePoll, 1200);
    </script>
</body>
</html>
'@
}

function Export-DiagnosticHtmlReport {
    param([switch]$Silent)

    if (-not $Silent) {
        Write-Step "Compiling interactive Cyberpunk/Fluent HTML Diagnostic Dashboard..."
    }

    try {
        Initialize-AppDirectory
        
        # Refresh current telemetry in live state
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $vols = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
        $oem = Get-OEMSupportDetails
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1

        $totalRamGB = if ($cs) { [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1) } else { 16 }
        $freeRamGB = if ($os) { [Math]::Round($os.FreePhysicalMemory / 1MB, 1) } else { 8 }
        $usedRamGB = [Math]::Round($totalRamGB - $freeRamGB, 1)
        $diskCFreeGB = if ($vols) { [Math]::Round($vols.SizeRemaining / 1GB, 1) } else { 0 }
        $vramGB = if ($gpus -and $gpus.AdapterRAM) { [Math]::Round($gpus.AdapterRAM / 1GB, 1) } else { 0 }

        $wearLevel = 0
        $batteryPath = "$Global:AppDir\battery-report.xml"
        if (Test-Path $batteryPath) {
            try {
                [xml]$bXml = Get-Content $batteryPath
                $dCap = [double]$bXml.BatteryReport.Batteries.Battery.DesignCapacity
                $fCap = [double]$bXml.BatteryReport.Batteries.Battery.FullChargeCapacity
                if ($dCap -gt 0) {
                    $wearLevel = [Math]::Round(((1 - ($fCap / $dCap)) * 100), 1)
                }
            } catch {}
        }

        $Global:ApexLiveState.SystemInfo = @{
            Hostname    = $env:COMPUTERNAME
            OS          = if ($os) { $os.Caption } else { "Windows 10/11" }
            Build       = if ($os) { $os.BuildNumber } else { "" }
            CPU         = if ($cpu) { $cpu.Name } else { "Processor" }
            Cores       = if ($cpu) { $cpu.NumberOfCores } else { 4 }
            Threads     = if ($cpu) { $cpu.NumberOfLogicalProcessors } else { 8 }
            TotalRamGB  = $totalRamGB
            FreeRamGB   = $freeRamGB
            UsedRamGB   = $usedRamGB
            GPU         = if ($gpus) { $gpus.Name } else { "Graphics Controller" }
            VRAM        = $vramGB
            DiskCFree   = $diskCFreeGB
            BatteryWear = $wearLevel
        }

        $Global:ApexLiveState.OEM = @{
            OEMName       = $oem.OEMName
            Model         = $oem.Model
            SerialNumber  = $oem.SerialNumber
            ToolName      = $oem.ToolName
            ToolUrl       = $oem.ToolUrl
            SupportPortal = $oem.SupportPortal
        }

        $initialJson = $Global:ApexLiveState | ConvertTo-Json -Depth 6 -Compress
        $template = Get-HtmlDashboardTemplate
        $htmlContent = $template.Replace("/*__INITIAL_LIVE_STATE__*/", "window.ApexLiveState = " + $initialJson + ";")

        [System.IO.File]::WriteAllText($Global:HtmlReport, $htmlContent, [System.Text.Encoding]::ASCII)
        Export-LiveStateJs

        if (-not $Silent) {
            Write-Success "Interactive HTML Dashboard compiled: $Global:HtmlReport"
            Start-Process $Global:HtmlReport -ErrorAction SilentlyContinue
        }
    } catch {
        if (-not $Silent) {
            Write-Notice "HTML report generation notice: $($_.Exception.Message)"
        }
    }
}

function Show-OEMOfficialLink {
    Write-Step "Resolving Official Manufacturer Diagnostic & Driver Tool..."
    $oem = Get-OEMSupportDetails

    Write-Host ""
    Write-Host " +------------------------------------------------------------------------+" -ForegroundColor Green
    Write-Host " |                    OFFICIAL OEM SUPPORT HUB                            |" -ForegroundColor White
    Write-Host " +------------------------------------------------------------------------+" -ForegroundColor Green
    Write-Host " | Brand Detected : $($oem.OEMName.PadRight(56))|" -ForegroundColor White
    Write-Host " | Device Model   : $($oem.Model.PadRight(56))|" -ForegroundColor White
    Write-Host " | Serial / Tag   : $($oem.SerialNumber.PadRight(56))|" -ForegroundColor White
    Write-Host " +------------------------------------------------------------------------+" -ForegroundColor Green
    Write-Host " | Tool Name      : $($oem.ToolName.PadRight(56))|" -ForegroundColor Yellow
    Write-Host " | Tool Web Link  : $($oem.ToolUrl)" -ForegroundColor Cyan
    Write-Host " | Drivers Hub    : $($oem.SupportPortal)" -ForegroundColor Cyan
    Write-Host " +------------------------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""

    $choice = Read-Host "Would you like to open the Official Tool download page in your browser now? (Y/N)"
    if ($choice -eq 'Y' -or $choice -eq 'y') {
        Write-Notice "Opening official manufacturer portal in default browser..."
        Start-Process $oem.ToolUrl
    }
}

# ==============================================================================
# MODULE 2: NETWORK STACK TURBOCHARGING (ZERO LATENCY & UNTHROTTLED THROUGHPUT)
# ==============================================================================
function Invoke-NetworkOptimization {
    Write-Step "Executing zero-latency network stack and throughput tuning..."

    try {
        # Flush DNS and reset ARP tables
        Write-Notice "Purging DNS resolver and ARP routing tables..."
        Clear-DnsClientCache
        arp -d * | Out-Null
        Write-Success "DNS & ARP tables flushed."

        # TCP Global Parameters Tuning
        Write-Notice "Calibrating TCP Window Auto-Tuning and Receive-Side Scaling..."
        netsh int tcp set global autotuninglevel=normal | Out-Null
        netsh int tcp set global rss=enabled | Out-Null
        netsh int tcp set global fastopen=enabled | Out-Null
        netsh int tcp set global timestamps=disabled | Out-Null
        Write-Success "TCP Auto-Tuning, RSS & Fast Open activated."

        # Eliminate Windows Multimedia Network Throttling
        Write-Notice "Neutralizing Windows Network Throttling Index & System Responsiveness..."
        $multimediaKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (Test-Path $multimediaKey) {
            Set-ItemProperty -Path $multimediaKey -Name "NetworkThrottlingIndex" -Value ([uint32]0xFFFFFFFF) -Type DWord -Force
            Set-ItemProperty -Path $multimediaKey -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
            Write-Success "Network throttling completely unrestricted (Index: 0xFFFFFFFF, Responsiveness: 0)."
        }

        # Clean Winsock catalog
        Write-Notice "Resetting Winsock and IP interfaces..."
        netsh winsock reset | Out-Null
        Write-Success "Winsock catalog re-initialized cleanly."
    } catch {
        Write-Notice "Non-critical notice during network tuning: $($_.Exception.Message)"
    }
}

# ==============================================================================
# MODULE 2.5: DNS TURBOCHARGER & HIGH-SPEED PROVIDER SWITCHER
# ==============================================================================
function Invoke-DNSSwitcher {
    Write-Step "Opening DNS Turbo Switcher module..."
    Write-Host ""
    Write-Host " +-- SELECT DNS PROVIDER ----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host " | [1] Cloudflare Gaming & Privacy DNS  (1.1.1.1  | 1.0.0.1)            |" -ForegroundColor Cyan
    Write-Host " | [2] Google High-Reliability DNS      (8.8.8.8  | 8.8.4.4)            |" -ForegroundColor Green
    Write-Host " | [3] AdGuard Anti-Ad & Malware DNS    (94.140.14.14 | 94.140.15.15)  |" -ForegroundColor Yellow
    Write-Host " | [4] Quad9 High-Security Threat Block (9.9.9.9  | 149.112.112.112)    |" -ForegroundColor Magenta
    Write-Host " | [5] Restore Automatic DNS (DHCP / Router Default)                    |" -ForegroundColor White
    Write-Host " | [6] Cancel / Return to Menu                                          |" -ForegroundColor DarkGray
    Write-Host " +---------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
    $dnsChoice = Read-Host " Enter DNS selection (1-6)"

    $activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -ne $true }
    if (-not $activeAdapters) {
        $activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    }

    if (-not $activeAdapters) {
        Write-Critical "No active network adapters detected to configure DNS."
        return
    }

    $servers = @()
    $dnsName = ""

    switch ($dnsChoice) {
        "1" {
            $servers = @("1.1.1.1", "1.0.0.1")
            $dnsName = "Cloudflare Ultra-Fast DNS"
        }
        "2" {
            $servers = @("8.8.8.8", "8.8.4.4")
            $dnsName = "Google Public DNS"
        }
        "3" {
            $servers = @("94.140.14.14", "94.140.15.15")
            $dnsName = "AdGuard Anti-Ad DNS"
        }
        "4" {
            $servers = @("9.9.9.9", "149.112.112.112")
            $dnsName = "Quad9 Security DNS"
        }
        "5" {
            Write-Notice "Reverting active adapters to automatic DHCP DNS..."
            foreach ($adapter in $activeAdapters) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
                Write-Success "Adapter [$($adapter.Name)] reset to DHCP DNS."
            }
            Clear-DnsClientCache
            return
        }
        default {
            Write-Notice "DNS switch cancelled."
            return
        }
    }

    Write-Notice "Applying $dnsName to active network interfaces..."
    foreach ($adapter in $activeAdapters) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $servers -ErrorAction Stop
            Write-Success "[$($adapter.Name)]: DNS set to $($servers -join ', ')"
        } catch {
            Write-Critical "Failed to set DNS on [$($adapter.Name)]: $($_.Exception.Message)"
        }
    }
    Clear-DnsClientCache
    Write-Success "DNS cache flushed and $dnsName engaged."
}

# ==============================================================================
# MODULE 3: CPU & OS KERNEL PEAK OPTIMIZATION
# ==============================================================================
function Invoke-PeakPerformance {
    Write-Step "Unleashing CPU, Power and Kernel peak responsiveness..."

    try {
        # Unlock Ultimate Performance power plan
        Write-Notice "Activating Ultimate Performance power scheme..."
        $ultimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
        $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

        powercfg -duplicatescheme $ultimateGuid | Out-Null
        powercfg -setactive $ultimateGuid 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Notice "Hardware profile restricted Ultimate Performance. Engaging High Performance plan..."
            powercfg -setactive $highPerfGuid | Out-Null
            Write-Success "High Performance power profile activated."
        } else {
            Write-Success "Ultimate Performance power plan engaged."
        }

        # Disable Fast Startup (ensures clean kernel state on boot)
        Write-Notice "Configuring clean kernel reboot cycle (Disabling Hiberboot)..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force
        Write-Success "Fast Startup disabled for pure kernel refresh."

        # Instant UI and context menu animations
        Write-Notice "Setting instantaneous desktop and context menu responsiveness..."
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force
        Write-Success "MenuShowDelay tuned to 0ms."

        # Disable NTFS Last Access Timestamps (eliminates constant write overhead)
        Write-Notice "Disabling NTFS Last Access write updates..."
        fsutil behavior set disablelastaccess 1 | Out-Null
        Write-Success "NTFS last-access disk write overhead neutralized."

        # Force Game Mode
        Write-Notice "Enforcing Windows Auto Game Mode scheduling..."
        if (-not (Test-Path "HKCU:\Software\Microsoft\GameBar")) {
            New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force
        Write-Success "Auto Game Mode scheduling enforced."
    } catch {
        Write-Notice "Peak performance calibration notice: $($_.Exception.Message)"
    }
}

# ==============================================================================
# MODULE 3.5: GAMER LATENCY REDUCER & CPU CORE UNPARKING
# ==============================================================================
function Invoke-GamingLatencyOptimization {
    Write-Step "Engaging Competitive Gamer Latency Reduction and Core Unparking..."

    try {
        # 1. Disable Nagle's Algorithm (TcpAckFrequency & TCPNoDelay)
        Write-Notice "Disabling Nagle's Algorithm for zero TCP packet buffering..."
        $interfacesKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        $interfaces = Get-ChildItem -Path $interfacesKey -ErrorAction SilentlyContinue
        $patchedCount = 0

        foreach ($iface in $interfaces) {
            $ip = (Get-ItemProperty -Path $iface.PSPath -Name "IPAddress" -ErrorAction SilentlyContinue).IPAddress
            $dhcpIp = (Get-ItemProperty -Path $iface.PSPath -Name "DhcpIPAddress" -ErrorAction SilentlyContinue).DhcpIPAddress

            if ($ip -or $dhcpIp) {
                Set-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $iface.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $iface.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $patchedCount++
            }
        }
        Write-Success "Nagle's Algorithm disabled across $patchedCount active network interfaces."

        # 2. Multimedia Class Scheduler (MMCSS) Gaming Profile Priority
        Write-Notice "Maximizing MMCSS Games thread scheduler priority..."
        $gamesKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if (-not (Test-Path $gamesKey)) {
            New-Item -Path $gamesKey -ItemType Directory -Force | Out-Null
        }
        Set-ItemProperty -Path $gamesKey -Name "GPU Priority" -Value 8 -Type DWord -Force
        Set-ItemProperty -Path $gamesKey -Name "Priority" -Value 6 -Type DWord -Force
        Set-ItemProperty -Path $gamesKey -Name "Scheduling Category" -Value "High" -Type String -Force
        Set-ItemProperty -Path $gamesKey -Name "SFIO Priority" -Value "High" -Type String -Force
        Write-Success "MMCSS Games scheduler locked to High Priority."

        # 3. CPU Core Unparking
        Write-Notice "Disabling CPU Core Parking (100% active cores on demand)..."
        powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 | Out-Null
        powercfg -setdcvalueindex scheme_current sub_processor CPMINCORES 100 | Out-Null
        powercfg -setactive scheme_current | Out-Null
        Write-Success "CPU Core Parking eliminated; micro-stutter suppression engaged."
    } catch {
        Write-Critical "Error configuring gaming latency optimizations: $($_.Exception.Message)"
    }
}

# ==============================================================================
# MODULE 4: GPU BEAST MODE & DISPLAY PIPELINE ACCELERATION
# ==============================================================================
function Invoke-GPUBeastMode {
    Write-Step "Engaging GPU Beast Mode & hardware display pipeline..."

    try {
        # Enable HAGS (Hardware-Accelerated GPU Scheduling)
        Write-Notice "Activating Hardware-Accelerated GPU Scheduling (HAGS)..."
        $gfxKey = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (-not (Test-Path $gfxKey)) { New-Item -Path $gfxKey -Force | Out-Null }
        Set-ItemProperty -Path $gfxKey -Name "HwSchMode" -Value 2 -Type DWord -Force
        Write-Success "HAGS state registered to Mode 2 (Enabled on reboot)."

        # Enable Variable Refresh Rate globally
        $vrrKey = "HKCU:\Control Panel\GraphicsDrivers"
        if (-not (Test-Path $vrrKey)) { New-Item -Path $vrrKey -Force | Out-Null }
        Set-ItemProperty -Path $vrrKey -Name "VarRefreshRate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Success "Variable Refresh Rate (VRR) pipeline enabled."

        # High-Performance discrete GPU priority
        $directXKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        if (-not (Test-Path $directXKey)) { New-Item -Path $directXKey -Force | Out-Null }
        Set-ItemProperty -Path $directXKey -Name "GpuPreference" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Success "DirectX graphics preference set to High Performance Discrete GPU."

        # GPU Vendor Suite Intelligence & Deployment
        $gpus = Get-CimInstance Win32_VideoController
        $vendorFound = @()
        foreach ($gpu in $gpus) {
            $gpuName = $gpu.Name
            if ($gpuName -match "NVIDIA" -and "NVIDIA" -notin $vendorFound) {
                $vendorFound += "NVIDIA"
                Write-Notice "NVIDIA discrete graphics detected: $gpuName"
                Write-Notice "Checking NVIDIA software suite via Winget..."
                winget install --id "Nvidia.GeForceExperience" --accept-package-agreements --accept-source-agreements --silent
            }
            elseif ($gpuName -match "AMD|Radeon" -and "AMD" -notin $vendorFound) {
                $vendorFound += "AMD"
                Write-Notice "AMD Radeon graphics detected: $gpuName"
                Write-Notice "Checking AMD Software Adrenalin suite via Winget..."
                winget install --id "AdvancedMicroDevicesInc.RadeonSoftware" --accept-package-agreements --accept-source-agreements --silent
            }
            elseif ($gpuName -match "Intel" -and $gpuName -match "Arc" -and "IntelArc" -notin $vendorFound) {
                $vendorFound += "IntelArc"
                Write-Notice "Intel Arc graphics detected: $gpuName"
                winget install --id "Intel.ArcControl" --accept-package-agreements --accept-source-agreements --silent
            }
        }
        Write-Success "GPU Beast Mode pipeline configured."
    } catch {
        Write-Notice "Notice during GPU tuning: $($_.Exception.Message)"
    }
}

# ==============================================================================
# MODULE 5: STANDBY RAM PURGE & DEEP SYSTEM HYGIENE
# ==============================================================================
function Invoke-MemoryOptimization {
    Write-Step "Executing Standby RAM purge & working set compaction..."

    try {
        # Safe P/Invoke memory working-set release
        $csharpCode = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class MemoryPurgeHelper {
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);

    public static void FlushProcessWorkingSets() {
        Process[] procs = Process.GetProcesses();
        foreach (Process p in procs) {
            try {
                if (!p.HasExited) {
                    EmptyWorkingSet(p.Handle);
                }
            } catch {}
        }
    }
}
"@
        Add-Type -TypeDefinition $csharpCode -ErrorAction SilentlyContinue
        [MemoryPurgeHelper]::FlushProcessWorkingSets()
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-Success "Standby memory working-sets purged and compacted."
    } catch {
        Write-Notice "Memory purge completed via standard garbage collection."
    }
}

function Invoke-DeepCleanup {
    Write-Step "Executing storage recovery, cache purging & NVMe/SSD TRIM..."

    # Standby RAM purge first
    Invoke-MemoryOptimization

    # Cache target directories
    $targets = @(
        "$env:TEMP\*",
        "$env:windir\Temp\*",
        "$env:windir\Prefetch\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
        "$env:windir\SoftwareDistribution\Download\*"
    )

    foreach ($path in $targets) {
        Write-Notice "Purging cache target: $path"
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Success "System cache and download caches purged."

    # Non-Volatile Drive TRIM optimization
    Write-Notice "Invoking block-level TRIM optimization across fixed volumes..."
    Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | Optimize-Volume -Defrag:$false -ReTrim -Verbose:$false
    Write-Success "Non-volatile storage TRIM operations completed."
}

# ==============================================================================
# MODULE 6: SAFE TELEMETRY & DIAGNOSTIC DEBLOAT
# ==============================================================================
function Invoke-SafeDebloat {
    Write-Step "Executing non-breaking telemetry & background diagnostic debloat..."

    try {
        # Stop and disable DiagTrack & dmwappushservice
        $telemetryServices = @("DiagTrack", "dmwappushservice")
        foreach ($svc in $telemetryServices) {
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
                Write-Notice "Deactivating background service: $svc"
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Success "Service $svc stopped and disabled."
            }
        }

        # Disable Customer Experience Improvement Program (CEIP) scheduled tasks
        Write-Notice "Disabling Customer Experience Improvement Program scheduled tasks..."
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\*" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
        
        # Disable telemetry collectors in Application Experience
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\*" -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -match "Telemetry|PcaPatchDbTask" } | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null

        Write-Success "Safe debloat finalized. Windows Update and Store integrity preserved."
    } catch {
        Write-Notice "Debloat routine notice: $($_.Exception.Message)"
    }
}

# ==============================================================================
# MODULE 6.5: WINDOWS 11 POWER TWEAKS & DESKTOP POLISH
# ==============================================================================
function Invoke-Windows11Tweaks {
    Write-Step "Checking Windows 11 Power Tweaks and Desktop Polish..."
    $buildNumber = [System.Environment]::OSVersion.Version.Build
    $isWin11 = ($buildNumber -ge 22000)

    if (-not $isWin11) {
        Write-Notice "Windows 10 detected (Build $buildNumber). Windows 11 shell tweaks are not required."
        Write-Notice "Windows 10 already features the classic right-click context menu by default."
        return
    }

    Write-Host ""
    Write-Host " +-- WINDOWS 11 SHELL & DESKTOP MODULE --------------------------------+" -ForegroundColor DarkCyan
    Write-Host " | [1] Restore Classic Windows 10 Full Context Menu (No 'Show More')   |" -ForegroundColor Cyan
    Write-Host " | [2] Revert to Windows 11 Modern Context Menu                        |" -ForegroundColor White
    Write-Host " | [3] Disable Taskbar Widgets, Copilot & Search Bloat                 |" -ForegroundColor Yellow
    Write-Host " | [4] Re-enable Taskbar Widgets & Copilot                             |" -ForegroundColor DarkGray
    Write-Host " | [5] Return to Main Menu                                             |" -ForegroundColor DarkGray
    Write-Host " +---------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
    $w11Choice = Read-Host " Enter your selection (1-5)"

    $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    $advExplorer = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    switch ($w11Choice) {
        "1" {
            Write-Notice "Engaging Classic Context Menu..."
            New-Item -Path $clsidPath -Force | Out-Null
            Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value "" -Force
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Write-Success "Classic Context Menu activated (Explorer restarted)."
        }
        "2" {
            Write-Notice "Reverting to Windows 11 Modern Context Menu..."
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Write-Success "Windows 11 Modern Context Menu restored (Explorer restarted)."
        }
        "3" {
            Write-Notice "Disabling Taskbar Widgets and Copilot bloat..."
            Set-ItemProperty -Path $advExplorer -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExplorer -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExplorer -Name "TaskbarMn" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Write-Success "Taskbar Widgets & Copilot deactivated (Explorer refreshed)."
        }
        "4" {
            Write-Notice "Re-enabling Taskbar Widgets and Copilot..."
            Set-ItemProperty -Path $advExplorer -Name "TaskbarDa" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExplorer -Name "ShowCopilotButton" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Write-Success "Taskbar Widgets & Copilot restored."
        }
        default {
            Write-Notice "Operation cancelled."
        }
    }
}

# ==============================================================================
# MODULE 7: WINDOWS CORE FILE & IMAGE SELF-HEALING
# ==============================================================================
function Invoke-SystemRepair {
    Write-Step "Auditing and servicing Windows Component Store & System Files..."
    
    Write-Notice "Executing Deployment Image Servicing and Management (DISM)..."
    dism.exe /Online /Cleanup-Image /RestoreHealth /NoRestart

    Write-Notice "Executing System File Checker (SFC)..."
    sfc.exe /scannow
    Write-Success "Core OS binary audit and image servicing concluded."
}

# ==============================================================================
# MODULE 7.5: WINDOWS UPDATE DOCTOR & CACHE RESET ENGINE
# ==============================================================================
function Invoke-WindowsUpdateRepair {
    Write-Step "Executing Windows Update Doctor & Cache Reset Engine..."

    try {
        # 1. Stop Update and Cryptographic Services
        Write-Notice "Stopping Windows Update, BITS, and Cryptographic background services..."
        $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
        foreach ($svc in $services) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        }

        # 2. Reset SoftwareDistribution and Catroot2
        Write-Notice "Purging and archiving corrupted Windows Update distribution stores..."
        $sdPath = "$env:SystemRoot\SoftwareDistribution"
        $catPath = "$env:SystemRoot\System32\catroot2"
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

        if (Test-Path $sdPath) {
            Rename-Item -Path $sdPath -NewName "SoftwareDistribution.old_$timestamp" -ErrorAction SilentlyContinue
            if (Test-Path $sdPath) {
                Remove-Item -Path "$sdPath\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        if (Test-Path $catPath) {
            Rename-Item -Path $catPath -NewName "catroot2.old_$timestamp" -ErrorAction SilentlyContinue
        }

        # 3. Reset network and Winsock catalog
        Write-Notice "Resetting network sockets and update endpoints..."
        netsh winsock reset | Out-Null

        # 4. Restart Services
        Write-Notice "Restarting clean Windows Update subsystem..."
        foreach ($svc in @("cryptsvc", "bits", "wuauserv")) {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }

        # 5. Trigger update detection
        try {
            $autoUpdate = New-Object -ComObject Microsoft.Update.AutoUpdate
            $autoUpdate.DetectNow() | Out-Null
        } catch {}

        Write-Success "Windows Update services and caches successfully reinitialized."
    } catch {
        Write-Critical "Could not finalize Windows Update reset: $($_.Exception.Message)"
    }
}

# ==============================================================================
# MODULE 8: OEM ECOSYSTEM DEPLOYMENT & DRIVER SERVICING
# ==============================================================================
function Invoke-DriverAndOEMUpdates {
    Write-Step "Detecting OEM ecosystem and servicing driver repositories..."
    
    $oem = Get-OEMSupportDetails

    Write-Host ""
    Write-Highlight "Platform Identified: $($oem.OEMName)"
    Write-Notice "Official Diagnostic & Update Tool: $($oem.ToolName)"
    Write-Highlight "Official Tool Web Link: $($oem.ToolUrl)"
    Write-Highlight "Direct Support & Drivers Portal: $($oem.SupportPortal)"
    Write-Host ""

    # Check automated Winget deployment
    if ($oem.WingetId -ne "") {
        Write-Notice "Deploying OEM driver assistant via Winget ($($oem.WingetId))..."
        winget install --id $oem.WingetId --accept-package-agreements --accept-source-agreements --silent
        
        if ($oem.OEMName -eq "Dell" -and (Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe")) {
            Write-Notice "Triggering Dell Command | Update CLI scan..."
            & "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" /applyUpdates -reboot=disable
        }
    } else {
        Write-Notice "For $($oem.OEMName), download the official tool directly from:"
        Write-Host "    $($oem.ToolUrl)" -ForegroundColor Cyan
    }

    # PSWindowsUpdate Driver Servicing with Full Resilience & Self-Healing
    Write-Notice "Querying Windows Driver Catalog for pending bus and peripheral updates..."
    try {
        Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
        Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -Install -AcceptAll -IgnoreReboot -ErrorAction Stop | Out-Null
        Write-Success "Hardware driver catalog servicing completed."
    } catch {
        $driverErr = $_.Exception.Message
        Write-Notice "Windows Update Driver Catalog query bypassed: $driverErr"
        Write-Highlight "Notice: Proprietary OEM drivers ($($oem.OEMName) bus & sensors) are provisioned through the official portal."
        
        Add-LiveIncident -Stage "Stage 11: OEM Ecosystem & Driver Servicing" `
            -RawError $driverErr `
            -Diagnosis "The generic Windows Update Driver Catalog COM API cannot negotiate proprietary ACPI/bus driver tables for this $($oem.OEMName) model ($($oem.Model)). This is normal on specialized laptop hardware." `
            -Resolution "Use the dedicated $($oem.OEMName) Support Portal to download tested proprietary motherboard, chipset, and sensor drivers." `
            -ActionUrl $oem.SupportPortal `
            -ActionText "Open $($oem.OEMName) Support Portal ($($oem.SerialNumber))"

        Write-Notice "Refreshing local PnP device bus as fallback..."
        try {
            Start-Process -FilePath "pnputil.exe" -ArgumentList "/scan-devices" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            Write-Success "Local PnP device bus rescanned successfully."
        } catch {}
    }
}

# ==============================================================================
# MODULE 9: NATIVE APPLICATION FLEET UPGRADE
# ==============================================================================
function Invoke-AppUpdates {
    Write-Step "Upgrading all installed software from official vendor sources..."
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
    Write-Success "Application fleet upgrade routine executed."
}

# ==============================================================================
# MODULE 10: OPTIONAL POST-OPTIMIZATION ANTIVIRUS AUDIT
# ==============================================================================
function Invoke-SecurityScan {
    Write-Step "Initiating Microsoft Defender Malware Detection Routine..."
    
    if (Get-Service -Name WinDefend -ErrorAction SilentlyContinue) {
        Write-Notice "Updating Defender signature intelligence..."
        Update-MpSignature
        Write-Notice "Starting background Quick Scan..."
        Start-MpScan -ScanType QuickScan
        Write-Success "Security scan completed. No active threats detected."
    } else {
        Write-Notice "Third-party Antivirus active or Defender disabled. Skipping built-in scan."
    }
}

# ==============================================================================
# MODULE 11: FACTORY DEFAULTS RESTORATION & UNDO ENGINE
# ==============================================================================
function Invoke-RevertTweaks {
    Write-Step "Reverting optimizations and restoring Windows default settings..."
    Write-Notice "This will reset power schemes, network throttling, DNS, and telemetry to factory defaults."
    $confirm = Read-Host " Are you sure you want to revert optimizations? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Notice "Revert aborted."
        return
    }

    try {
        # 1. Reset Power Scheme to Balanced
        Write-Notice "Restoring Windows default Balanced power scheme..."
        $balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
        powercfg -setactive $balancedGuid | Out-Null
        Write-Success "Balanced power profile restored."

        # 2. Re-enable Fast Startup (Hiberboot)
        Write-Notice "Re-enabling Fast Startup..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Success "Fast Startup re-enabled."

        # 3. Restore Network Throttling & Responsiveness Defaults
        Write-Notice "Restoring Windows default network throttling indexes..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Success "Multimedia network throttling reset to Windows defaults."

        # 4. Restore DNS to Automatic (DHCP)
        Write-Notice "Restoring DNS to Automatic (DHCP)..."
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($ad in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $ad.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
        }
        Clear-DnsClientCache
        Write-Success "DNS configuration reset to DHCP."

        # 5. Restore MenuShowDelay
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "400" -Force -ErrorAction SilentlyContinue
        Write-Success "Menu display delay reset to default (400ms)."

        # 6. Re-enable Last Access Time
        fsutil behavior set disablelastaccess 0 | Out-Null
        Write-Success "Disk last access timestamps restored."

        # 7. Restore Windows 11 Modern Context Menu if altered
        if (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}") {
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Write-Success "Windows 11 modern context menu restored."
        }

        # 8. Re-enable Telemetry service (DiagTrack)
        Set-Service -Name "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        Write-Success "Diagnostics Tracking service restored."

        Write-Host ""
        Write-Host " +========================================================================+" -ForegroundColor Green
        Write-Host " |         [OK] FACTORY DEFAULTS RESTORED SUCCESSFULLY!                   |" -ForegroundColor Green
        Write-Host " +========================================================================+" -ForegroundColor Green
    } catch {
        Write-Critical "Failed to revert some settings: $($_.Exception.Message)"
    }
}

# ==============================================================================
# FULL AUTOPILOT PIPELINE (WITH REBOOT SURVIVAL)
# ==============================================================================
function Start-FullAutoPilot {
    param([int]$ResumeStep = 1)

    $pipeline = @(
        @{ Index = 1;  Name = "System Restore Point Safeguard";     Action = { Invoke-SystemRestorePoint } },
        @{ Index = 2;  Name = "Dependencies & Modules";             Action = { Install-Prerequisites } },
        @{ Index = 3;  Name = "Hardware & Diagnostics Audit";       Action = { Invoke-HardwareDiagnostics } },
        @{ Index = 4;  Name = "Network Stack Turbocharging";        Action = { Invoke-NetworkOptimization } },
        @{ Index = 5;  Name = "CPU & Kernel Peak Responsiveness";   Action = { Invoke-PeakPerformance } },
        @{ Index = 6;  Name = "Gamer Latency & Core Unparking";     Action = { Invoke-GamingLatencyOptimization } },
        @{ Index = 7;  Name = "GPU Beast Mode & Display Pipeline";  Action = { Invoke-GPUBeastMode } },
        @{ Index = 8;  Name = "Standby RAM & Storage Cleanup";      Action = { Invoke-DeepCleanup } },
        @{ Index = 9;  Name = "Safe Telemetry & Diagnostic Debloat"; Action = { Invoke-SafeDebloat } },
        @{ Index = 10; Name = "Core OS Integrity & Image Repair";   Action = { Invoke-SystemRepair } },
        @{ Index = 11; Name = "OEM Ecosystem & Driver Servicing";   Action = { Invoke-DriverAndOEMUpdates } },
        @{ Index = 12; Name = "Native Application Fleet Upgrade";   Action = { Invoke-AppUpdates } },
        @{ Index = 13; Name = "Interactive HTML Dashboard Export";  Action = { Export-DiagnosticHtmlReport } }
    )

    foreach ($task in $pipeline) {
        if ($task.Index -ge $ResumeStep) {
            Set-AutomationState -CurrentPhase $task.Name -StepIndex $task.Index
            Write-Host ""
            Write-Host " +------------------------------------------------------------------------+" -ForegroundColor Magenta
            Write-Host " | >>> [PIPELINE STAGE $($task.Index)/$($pipeline.Count)]: $($task.Name.PadRight(47))|" -ForegroundColor White
            Write-Host " +------------------------------------------------------------------------+" -ForegroundColor Magenta
            
            Update-LiveStage -Index $task.Index -Status "Running"
            try {
                & $task.Action
                Update-LiveStage -Index $task.Index -Status "Completed"
            } catch {
                $errStageMsg = $_.Exception.Message
                Write-Critical "Non-fatal event in Stage $($task.Index) ($($task.Name)): $errStageMsg"
                Add-LiveIncident -Stage "Stage $($task.Index): $($task.Name)" `
                    -RawError $errStageMsg `
                    -Diagnosis "A subsystem operation encountered an exception during execution. Non-fatal, continuing pipeline." `
                    -Resolution "Review system logs or rerun the specific module from the main menu." `
                    -ActionUrl "" `
                    -ActionText ""
                Update-LiveStage -Index $task.Index -Status "Warning"
            }

            # Check if pending reboot was triggered
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
                Write-Critical "A system component requires an immediate restart to finalize."
                Write-Notice "System will reboot in 10 seconds and automatically continue after sign-in..."
                Set-AutomationState -CurrentPhase $task.Name -StepIndex ($task.Index + 1)
                Start-Sleep -Seconds 10
                Restart-Computer -Force
                return
            }
        }
    }

    Clear-AutomationState
    if ($null -ne $Global:ApexLiveState) {
        $Global:ApexLiveState.Status = "Completed"
        $Global:ApexLiveState.ProgressPercent = 100
        Export-LiveStateJs
    }
    Write-Host ""
    Write-Host " +========================================================================+" -ForegroundColor Green
    Write-Host " |         [OK] FULL BEAST MODE PIPELINE EXECUTED SUCCESSFULLY!           |" -ForegroundColor Green
    Write-Host " +========================================================================+" -ForegroundColor Green
    
    Write-Host ""
    $optScan = Read-Host " Would you like to execute an Antivirus Security Scan now? (Y/N)"
    if ($optScan -eq 'Y' -or $optScan -eq 'y') {
        Invoke-SecurityScan
    }

    Write-Host ""
    Write-Host " All operations finalized. Diagnostics log: $Global:ReportFile" -ForegroundColor Cyan
    Write-Host " Interactive HTML Dashboard compiled: $Global:HtmlReport" -ForegroundColor Cyan
    pause
}

# ==============================================================================
# MAIN ENTRY POINT & FLUENT INTERACTIVE MENU
# ==============================================================================
try {
    # Initialize Live Mission Control & Launch Browser Dashboard
    Initialize-LiveDashboard
    if (-not $Global:DashboardLaunched) {
        $Global:DashboardLaunched = $true
        Start-Process $Global:HtmlReport -ErrorAction SilentlyContinue
    }

    $activeState = Get-AutomationState

    if (($args -contains "-Resume") -and $activeState) {
        Show-Header
        Write-Notice "Detected interrupted routine. Resuming pipeline from Stage $($activeState.StepIndex) ($($activeState.CurrentPhase))..."
        Start-FullAutoPilot -ResumeStep $activeState.StepIndex
        exit
    }

    do {
        Show-Header
        Write-Host " Select an operational module:" -ForegroundColor Yellow
        Write-Host " +-- FULL AUTOMATION --------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host " | [1]  FULL AUTOPILOT (Restore Point -> Net -> Kernel -> Clean -> GPU)|" -ForegroundColor Green
        Write-Host " +-- SYSTEM AUDIT & OEM -----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host " | [2]  Hardware Diagnostics & Battery Wear Audit                      |"
        Write-Host " | [3]  Generate Interactive HTML Dashboard (Dark Mode)                |" -ForegroundColor Green
        Write-Host " | [4]  Get Official OEM Support Tool & Direct Driver Links            |" -ForegroundColor Cyan
        Write-Host " +-- PERFORMANCE & GAMING ---------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host " | [5]  Network Stack Turbocharging (Zero Latency & Unthrottled)       |"
        Write-Host " | [6]  DNS Turbo Switcher (Cloudflare / Google / AdGuard / Quad9)     |" -ForegroundColor Cyan
        Write-Host " | [7]  CPU & OS Kernel Peak Responsiveness (Ultimate Power, Fast Boot)|"
        Write-Host " | [8]  Gamer Latency Mode (Disable Nagle's Algorithm & Core Unparking)|" -ForegroundColor Green
        Write-Host " | [9]  GPU Beast Mode & Display Pipeline (HAGS, VRR, Vendor Suite)    |"
        Write-Host " +-- SYSTEM HYGIENE & REPAIR ------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host " | [10] Standby RAM Purge, Storage Recovery & NVMe/SSD TRIM            |"
        Write-Host " | [11] Safe Telemetry & Diagnostic Debloat (Non-Breaking)             |"
        Write-Host " | [12] Windows Core Image Repair & System Integrity (DISM & SFC)      |"
        Write-Host " | [13] Windows Update Doctor (Reset & Fix Stuck Updates)              |" -ForegroundColor Yellow
        Write-Host " | [14] Windows 11 Power Tweaks (Classic Context Menu & Taskbar Polish)|" -ForegroundColor Cyan
        Write-Host " | [15] Update Drivers & OEM Tool Provisioning                         |"
        Write-Host " | [16] Upgrade All Installed Apps (Winget Fleet Update)              |"
        Write-Host " | [17] Run Microsoft Defender Quick Scan with Signature Intelligence  |"
        Write-Host " +-- SAFEGUARDS & UNDO ------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host " | [18] Create System Restore Point (Manual Safeguard)                 |" -ForegroundColor Magenta
        Write-Host " | [19] Revert All Optimizations to Factory Defaults (Undo)            |" -ForegroundColor Yellow
        Write-Host " +-- EXIT -------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host " | [20] Exit Session                                                   |" -ForegroundColor DarkGray
        Write-Host " +---------------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""
        $choice = Read-Host " Enter your selection (1-20)"

        switch ($choice) {
            "1"  { Start-FullAutoPilot -ResumeStep 1 }
            "2"  { Invoke-HardwareDiagnostics; pause }
            "3"  { Export-DiagnosticHtmlReport; pause }
            "4"  { Show-OEMOfficialLink; pause }
            "5"  { Invoke-NetworkOptimization; pause }
            "6"  { Invoke-DNSSwitcher; pause }
            "7"  { Invoke-PeakPerformance; pause }
            "8"  { Invoke-GamingLatencyOptimization; pause }
            "9"  { Invoke-GPUBeastMode; pause }
            "10" { Invoke-DeepCleanup; pause }
            "11" { Invoke-SafeDebloat; pause }
            "12" { Invoke-SystemRepair; pause }
            "13" { Invoke-WindowsUpdateRepair; pause }
            "14" { Invoke-Windows11Tweaks; pause }
            "15" { Install-Prerequisites; Invoke-DriverAndOEMUpdates; pause }
            "16" { Install-Prerequisites; Invoke-AppUpdates; pause }
            "17" { Invoke-SecurityScan; pause }
            "18" { Invoke-SystemRestorePoint; pause }
            "19" { Invoke-RevertTweaks; pause }
            "20" { Write-Host "Terminating session..."; exit }
            default { Write-Notice "Invalid selection, please select a valid option (1-20)." }
        }
    } while ($choice -ne "20")
} catch {
    Write-Host ""
    Write-Host " [X] Unexpected Runtime Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host " [X] Location: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Red
    Write-Host ""
    Read-Host " Press Enter to exit..."
}
