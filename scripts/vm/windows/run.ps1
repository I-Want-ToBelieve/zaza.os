<#
.SYNOPSIS
    zaza-vm-windows 的 QEMU/WHPX 启动器。

.EXAMPLE
    .\scripts\vm\windows\run.ps1 status
    .\scripts\vm\windows\run.ps1 fetch-iso
    .\scripts\vm\windows\run.ps1 create-disk
    .\scripts\vm\windows\run.ps1 install
    .\scripts\vm\windows\run.ps1 run
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('status', 'fetch-iso', 'create-disk', 'install', 'run')]
    [string]$Command,

    # Headless 只使用串口；Native/Angle 显式启用 SDL + VirGL。
    [ValidateSet('Headless', 'Native', 'Angle')]
    [string]$Graphics = 'Headless',

    [ValidateRange(1, 8)]
    [int]$Cpus = 4,

    [ValidateRange(1024, 65536)]
    [int]$MemoryMiB = 8192,

    [ValidateRange(8, 1024)]
    [int]$DiskGiB = 80,

    [string]$State = $(Join-Path $env:LOCALAPPDATA 'zaza-vm-windows'),

    # 可直接指向已经下载并校验过的 ISO；省略时使用 State 下的固定文件名。
    [string]$IsoPath,

    [ValidateRange(1024, 65535)]
    [int]$SshPort = 2222,

    # 0 表示关闭。QMP 权限很高，只在本机自动化确实需要时显式打开。
    [ValidateRange(0, 65535)]
    [int]$QmpPort = 0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$metadataPath = Join-Path $PSScriptRoot 'nixos-image.json'
if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    throw "ISO metadata is missing: $metadataPath"
}
$image = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json

if ([IO.Path]::IsPathRooted($State)) {
    $stateDirectory = [IO.Path]::GetFullPath($State)
} else {
    $stateDirectory = [IO.Path]::GetFullPath((Join-Path (Get-Location) $State))
}

$diskPath = Join-Path $stateDirectory 'zaza-vm-windows.qcow2'
$firmwareVarsPath = Join-Path $stateDirectory 'edk2-vars.fd'
$defaultIsoPath = Join-Path $stateDirectory ([string]$image.fileName)
if ([string]::IsNullOrWhiteSpace($IsoPath)) {
    $effectiveIsoPath = $defaultIsoPath
} elseif ([IO.Path]::IsPathRooted($IsoPath)) {
    $effectiveIsoPath = [IO.Path]::GetFullPath($IsoPath)
} else {
    $effectiveIsoPath = [IO.Path]::GetFullPath((Join-Path (Get-Location) $IsoPath))
}

function Get-QemuInstallation {
    $prefix = $null
    # 这台 VM 的 runner 与固件以 Scoop QEMU 为契约，优先于 PATH 中可能存在的
    # 旧版或其它发行版。
    $scoopCommand = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoopCommand) {
        try {
            $prefix = (& scoop prefix qemu 2>$null | Select-Object -First 1)
            if ($prefix) { $prefix = ([string]$prefix).Trim() }
        } catch {
            $prefix = $null
        }
    }

    if (-not $prefix) {
        $qemuCommand = Get-Command qemu-system-x86_64.exe -ErrorAction SilentlyContinue
        if ($qemuCommand) {
            $prefix = Split-Path -Parent $qemuCommand.Source
        }
    }

    if (-not $prefix) {
        $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE 'scoop' }
        $prefix = Join-Path $scoopRoot 'apps\qemu\current'
    }

    $qemu = Join-Path $prefix 'qemu-system-x86_64.exe'
    $qemuImg = Join-Path $prefix 'qemu-img.exe'
    $firmwareCode = Join-Path $prefix 'share\edk2-x86_64-code.fd'
    $firmwareTemplate = Join-Path $prefix 'share\edk2-i386-vars.fd'

    foreach ($required in @($qemu, $qemuImg, $firmwareCode, $firmwareTemplate)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "QEMU installation is incomplete; missing $required. Run: scoop install main/qemu"
        }
    }

    [PSCustomObject]@{
        Prefix = $prefix
        Qemu = $qemu
        QemuImg = $qemuImg
        FirmwareCode = $firmwareCode
        FirmwareTemplate = $firmwareTemplate
    }
}

function Assert-WhpxReady {
    try {
        $feature = Get-CimInstance Win32_OptionalFeature -Filter "Name='HypervisorPlatform'"
        $computer = Get-CimInstance Win32_ComputerSystem
        $processors = @(Get-CimInstance Win32_Processor)
    } catch {
        throw "Unable to inspect WHPX status: $($_.Exception.Message)"
    }

    if (-not $feature -or $feature.InstallState -ne 1) {
        throw 'Windows Hypervisor Platform is disabled. Run scripts\vm\windows\enable-whpx.ps1 from an administrator PowerShell, then restart Windows.'
    }

    if (-not $computer.HypervisorPresent) {
        $firmwareEnabled = $processors.Count -gt 0 -and -not ($processors | Where-Object { -not $_.VirtualizationFirmwareEnabled })
        if ($firmwareEnabled) {
            throw 'The Windows hypervisor is not running. Restart Windows after enabling WHPX; no TCG fallback will be used.'
        }
        throw 'The Windows hypervisor is not running. Enable Intel VT-x in UEFI/BIOS, enable WHPX, and restart; no TCG fallback will be used.'
    }
}

function ConvertTo-QemuPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$Keyval
    )

    $result = [IO.Path]::GetFullPath($Path).Replace('\', '/')
    if ($Keyval) {
        # QEMU keyval syntax escapes a comma by doubling it.
        $result = $result.Replace(',', ',,')
    }
    $result
}

function Assert-Iso {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Installer ISO is missing: $Path"
    }

    $actualSize = (Get-Item -LiteralPath $Path).Length
    if ($actualSize -ne [int64]$image.sizeBytes) {
        throw "Installer size mismatch at $Path (expected $($image.sizeBytes), got $actualSize). Refusing to use it."
    }

    Write-Host '校验 NixOS ISO SHA-256…'
    $actualHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $expectedHash = ([string]$image.sha256).ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "Installer SHA-256 mismatch at $Path. Refusing to use it."
    }
}

function Initialize-FirmwareVars {
    param([Parameter(Mandatory = $true)]$QemuInstallation)

    if (-not (Test-Path -LiteralPath $firmwareVarsPath -PathType Leaf)) {
        Copy-Item -LiteralPath $QemuInstallation.FirmwareTemplate -Destination $firmwareVarsPath
        Write-Host "已创建持久化 UEFI 变量：$firmwareVarsPath"
    }
}

function Show-Status {
    try {
        $qemuInstallation = Get-QemuInstallation
        $qemuStatus = $qemuInstallation.Qemu
    } catch {
        $qemuStatus = "不可用：$($_.Exception.Message)"
    }

    try {
        $feature = Get-CimInstance Win32_OptionalFeature -Filter "Name='HypervisorPlatform'"
        if ($feature -and $feature.InstallState -eq 1) { $featureStatus = 'enabled' } else { $featureStatus = 'disabled' }
    } catch {
        $featureStatus = "unknown ($($_.Exception.Message))"
    }

    try {
        $computer = Get-CimInstance Win32_ComputerSystem
        $hypervisorStatus = [bool]$computer.HypervisorPresent
    } catch {
        $hypervisorStatus = "unknown ($($_.Exception.Message))"
    }

    try {
        $processors = @(Get-CimInstance Win32_Processor)
        $firmwareVirtualization = $processors.Count -gt 0 -and -not ($processors | Where-Object { -not $_.VirtualizationFirmwareEnabled })
    } catch {
        $firmwareVirtualization = "unknown ($($_.Exception.Message))"
    }

    [PSCustomObject]@{
        Qemu = $qemuStatus
        WhpxFeature = $featureStatus
        HypervisorPresent = $hypervisorStatus
        FirmwareVirtualization = $firmwareVirtualization
        State = $stateDirectory
        DiskExists = Test-Path -LiteralPath $diskPath -PathType Leaf
        UefiVarsExist = Test-Path -LiteralPath $firmwareVarsPath -PathType Leaf
        Iso = $effectiveIsoPath
        IsoExists = Test-Path -LiteralPath $effectiveIsoPath -PathType Leaf
    } | Format-List
}

function Invoke-FetchIso {
    if (Test-Path -LiteralPath $effectiveIsoPath -PathType Leaf) {
        Assert-Iso -Path $effectiveIsoPath
        Write-Host "ISO 已存在且校验通过：$effectiveIsoPath"
        return
    }

    $destinationDirectory = Split-Path -Parent $effectiveIsoPath
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    $partialPath = "$effectiveIsoPath.part"

    if (Test-Path -LiteralPath $partialPath -PathType Leaf) {
        $partialSize = (Get-Item -LiteralPath $partialPath).Length
        if ($partialSize -gt [int64]$image.sizeBytes) {
            throw "Partial ISO is larger than expected: $partialPath. Remove that .part file manually before retrying."
        }
        if ($partialSize -eq [int64]$image.sizeBytes) {
            try {
                Assert-Iso -Path $partialPath
            } catch {
                throw "$($_.Exception.Message) Remove the invalid .part file manually before retrying."
            }
            Move-Item -LiteralPath $partialPath -Destination $effectiveIsoPath
            Write-Host "ISO 下载完成：$effectiveIsoPath"
            return
        }
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        Write-Host "下载 NixOS $($image.release) minimal ISO（支持断点续传）…"
        & $curl.Source `
            --fail `
            --location `
            --retry 5 `
            --retry-delay 2 `
            --continue-at - `
            --output $partialPath `
            ([string]$image.url)
        if ($LASTEXITCODE -ne 0) {
            throw "ISO download failed (curl exit $LASTEXITCODE). The partial file was kept for resume."
        }
    } else {
        if (Test-Path -LiteralPath $partialPath) {
            throw "curl.exe is unavailable, so the existing partial download cannot be resumed: $partialPath"
        }
        Write-Host "下载 NixOS $($image.release) minimal ISO（BITS）…"
        Import-Module BitsTransfer
        Start-BitsTransfer -Source ([string]$image.url) -Destination $partialPath
    }

    Assert-Iso -Path $partialPath
    Move-Item -LiteralPath $partialPath -Destination $effectiveIsoPath
    Write-Host "ISO 下载完成：$effectiveIsoPath"
}

function Invoke-CreateDisk {
    $qemuInstallation = Get-QemuInstallation
    if (Test-Path -LiteralPath $diskPath) {
        throw "Disk already exists: $diskPath. It will not be overwritten."
    }

    New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
    & $qemuInstallation.QemuImg create -f qcow2 $diskPath "${DiskGiB}G"
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to create the virtual disk (qemu-img exit $LASTEXITCODE)."
    }
    Write-Host "已创建 ${DiskGiB} GiB 稀疏磁盘：$diskPath"
}

function Start-ZazaVm {
    param([Parameter(Mandatory = $true)][bool]$Installer)

    Assert-WhpxReady
    if ($QmpPort -ne 0 -and $QmpPort -eq $SshPort) {
        throw 'QMP and SSH cannot listen on the same host port.'
    }
    $qemuInstallation = Get-QemuInstallation
    if (-not (Test-Path -LiteralPath $diskPath -PathType Leaf)) {
        throw "Disk is missing: $diskPath. Run create-disk first."
    }

    if ($Installer) {
        Assert-Iso -Path $effectiveIsoPath
    }

    New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
    Initialize-FirmwareVars -QemuInstallation $qemuInstallation

    $firmwareCode = ConvertTo-QemuPath -Path $qemuInstallation.FirmwareCode -Keyval
    $firmwareVars = ConvertTo-QemuPath -Path $firmwareVarsPath -Keyval
    $disk = ConvertTo-QemuPath -Path $diskPath -Keyval
    $videoDevice = if ($Graphics -eq 'Headless') {
        'virtio-vga'
    } else {
        'virtio-vga-gl'
    }

    $qemuArguments = @(
        '-name', 'zaza-vm-windows',
        '-machine', 'q35',
        '-accel', 'whpx',
        '-smp', "sockets=1,cores=$Cpus,threads=1",
        '-m', ([string]$MemoryMiB),
        '-drive', "if=pflash,format=raw,readonly=on,file=$firmwareCode",
        '-drive', "if=pflash,format=raw,file=$firmwareVars",
        '-device', 'virtio-rng-pci',
        '-device', $videoDevice,
        '-device', 'qemu-xhci',
        '-device', 'usb-tablet',
        '-drive', "file=$disk,format=qcow2,if=virtio,discard=unmap,detect-zeroes=unmap",
        '-netdev', "user,id=net0,hostfwd=tcp:127.0.0.1:$SshPort-:22",
        '-device', 'virtio-net-pci,netdev=net0',
        '-serial', 'mon:stdio'
    )

    if ($QmpPort -ne 0) {
        $qemuArguments += @('-qmp', "tcp:127.0.0.1:$QmpPort,server=on,wait=off")
    }

    if ($Installer) {
        $qemuArguments += @('-cdrom', $effectiveIsoPath, '-boot', 'once=d,menu=on')
    } else {
        $qemuArguments += @('-boot', 'order=c,menu=on')
    }

    $hadEsDriver = Test-Path Env:SDL_OPENGL_ES_DRIVER
    $previousEsDriver = $env:SDL_OPENGL_ES_DRIVER
    try {
        if ($Graphics -eq 'Headless') {
            $qemuArguments += @('-display', 'none')
        } elseif ($Graphics -eq 'Angle') {
            $env:SDL_OPENGL_ES_DRIVER = '1'
            $qemuArguments += @('-display', 'sdl,gl=es')
        } else {
            $env:SDL_OPENGL_ES_DRIVER = '0'
            $qemuArguments += @('-display', 'sdl,gl=on')
        }

        $displaySummary = if ($Graphics -eq 'Headless') {
            '串口 headless'
        } else {
            "VirtIO GL ($Graphics)"
        }
        $connectionSummary = "启动 zaza-vm-windows：WHPX，$displaySummary，SSH 127.0.0.1:$SshPort"
        if ($QmpPort -ne 0) {
            $connectionSummary += "，QMP 127.0.0.1:$QmpPort"
        }
        Write-Host "$connectionSummary。"
        Write-Host '串口切换到 QEMU monitor：Ctrl-a c；退出：Ctrl-a x。不会自动回退到 TCG。'
        if ($Installer) {
            if ($Graphics -eq 'Headless') {
                Write-Host 'Headless 安装时，ISO 的 UEFI GRUB 不读取 ttyS0 键盘；按 Ctrl-a c 进入 QEMU monitor，用 sendkey 选择 Serial console，再按 Ctrl-a c 返回串口。'
            } else {
                Write-Host '在 SDL 的 ISO 引导菜单选择 Serial console (ttyS0, 115200n8)。'
            }
            Write-Host '启动器本身不会自动分区或覆盖磁盘。'
        }

        & $qemuInstallation.Qemu @qemuArguments
        $qemuExitCode = $LASTEXITCODE
    } finally {
        if ($hadEsDriver) {
            $env:SDL_OPENGL_ES_DRIVER = $previousEsDriver
        } else {
            Remove-Item Env:SDL_OPENGL_ES_DRIVER -ErrorAction SilentlyContinue
        }
    }

    if ($qemuExitCode -ne 0) {
        throw "QEMU failed (exit $qemuExitCode). Hardware acceleration was not replaced by TCG."
    }
}

switch ($Command) {
    'status' { Show-Status }
    'fetch-iso' { Invoke-FetchIso }
    'create-disk' { Invoke-CreateDisk }
    'install' { Start-ZazaVm -Installer $true }
    'run' { Start-ZazaVm -Installer $false }
}
