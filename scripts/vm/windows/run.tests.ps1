<#
.SYNOPSIS
    Windows runner 的参数测试。使用临时 QEMU 占位文件；不需要 QEMU/WHPX，不启动 VM。
#>
[CmdletBinding()]
param()

# Keep the Scoop test double local even when this test file is dot-sourced.
& {
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$runner = Join-Path $PSScriptRoot 'run.ps1'
$tokens = $null
$parseErrors = $null
$null = [Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) {
    throw "run.ps1 has parser errors: $($parseErrors -join '; ')"
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) {
        throw "${Message}: expected '$Expected', got '$Actual'."
    }
}

function Get-Argument {
    param($Plan, [string]$Name)
    $index = [Array]::IndexOf($Plan.Arguments, $Name)
    if ($index -lt 0) { throw "Missing QEMU argument: $Name" }
    $Plan.Arguments[$index + 1]
}

function Assert-Rejected {
    param([scriptblock]$Action, [string]$Message)
    $rejected = $false
    try { $null = & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Expected rejection: $Message" }
}

$temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$qemuFixtureDirectory = Join-Path $temporaryRoot ("stellar-qemu-fixture-" + [Guid]::NewGuid().ToString('N'))
$testState = Join-Path $qemuFixtureDirectory 'absent VM state,with spaces'
$hadEsDriver = Test-Path Env:SDL_OPENGL_ES_DRIVER
$previousEsDriver = $env:SDL_OPENGL_ES_DRIVER

try {
    $null = New-Item -ItemType Directory -Path (Join-Path $qemuFixtureDirectory 'share')
    foreach ($fixtureFile in @('qemu-system-x86_64.exe', 'qemu-img.exe', 'share\edk2-x86_64-code.fd', 'share\edk2-i386-vars.fd')) {
        $null = New-Item -ItemType File -Path (Join-Path $qemuFixtureDirectory $fixtureFile)
    }
    # run.ps1 discovers this function before any installed Scoop command. These
    # files satisfy discovery only; DryRun must never execute either empty .exe.
    function scoop {
        param([string]$Operation, [string]$Package)
        if ($Operation -ne 'prefix' -or $Package -ne 'qemu') {
            throw "Unexpected Scoop operation in launch-plan tests: $Operation $Package"
        }
        $qemuFixtureDirectory
    }

$tty = & $runner run -DryRun
Assert-Equal $tty.Qemu (Join-Path $qemuFixtureDirectory 'qemu-system-x86_64.exe') 'QEMU discovery uses only the fixture'
Assert-Equal $tty.VmName 'zaza-vm-windows' 'Default VM'
Assert-Equal $tty.State (Join-Path $env:LOCALAPPDATA 'zaza-vm-windows') 'TTY state'
Assert-Equal (Split-Path -Leaf $tty.Disk) 'zaza-vm-windows.qcow2' 'TTY disk'
Assert-Equal (Split-Path -Leaf $tty.FirmwareVars) 'edk2-vars.fd' 'Existing TTY firmware compatibility'
Assert-Equal $tty.SshPort 2222 'TTY SSH port'
Assert-Equal (Get-Argument $tty '-display') 'none' 'Default display'
Assert-Equal ($tty.Arguments -contains 'virtio-vga') $true 'Headless video'
Assert-Equal ($tty.Arguments -contains 'virtio-vga-gl') $false 'No GL in Headless'
Assert-Equal ($tty.Arguments -contains '-qmp') $false 'QMP opt-in'
Assert-Equal ($tty.Arguments -contains '-vnc') $false 'VNC opt-in'
Assert-Equal $tty.VncEndpoint $null 'No inactive VNC endpoint'
Assert-Equal (Get-Argument $tty '-accel') 'whpx' 'Hardware acceleration'
Assert-Equal $tty.Acceleration 'whpx' 'Default acceleration metadata'
Assert-Equal ($tty.Arguments -contains '-cpu') $false 'Default WHPX CPU behavior unchanged'

$stellar = & $runner run -VmName zaza-vm-windows-stellar -Graphics Software -DryRun
Assert-Equal $stellar.State (Join-Path $env:LOCALAPPDATA 'zaza-vm-windows-stellar') 'Stellar state'
Assert-Equal (Split-Path -Leaf $stellar.Disk) 'zaza-vm-windows-stellar.qcow2' 'Stellar disk'
Assert-Equal $stellar.SshPort 2223 'Stellar SSH port'
Assert-Equal (Get-Argument $stellar '-name') 'zaza-vm-windows-stellar' 'QEMU name'
Assert-Equal (Get-Argument $stellar '-display') 'sdl,gl=off' 'Software display'
Assert-Equal ($stellar.Arguments -contains 'virtio-vga') $true 'Software video'
Assert-Equal ($stellar.Arguments -contains 'virtio-vga-gl') $false 'No VirGL in Software'
Assert-Equal ($stellar.Arguments -contains 'usb-tablet') $false 'SDL software input avoids Windows tablet freeze'
Assert-Equal $stellar.Environment.Count 0 'Software environment overrides'
Assert-Equal (Get-Argument $stellar '-netdev') 'user,id=net0,hostfwd=tcp:127.0.0.1:2223-:22' 'Loopback SSH'

$ttyVnc = & $runner run -Graphics Vnc -State $testState -DryRun
Assert-Equal (Get-Argument $ttyVnc '-vnc') '127.0.0.1:10' 'TTY default VNC display'
Assert-Equal $ttyVnc.VncEndpoint '127.0.0.1:5910' 'TTY default VNC endpoint'
$stellarVnc = & $runner run -VmName zaza-vm-windows-stellar -Graphics Vnc -State $testState -DryRun
Assert-Equal (Get-Argument $stellarVnc '-vnc') '127.0.0.1:11' 'Stellar default VNC display'
Assert-Equal $stellarVnc.VncEndpoint '127.0.0.1:5911' 'Stellar default VNC endpoint'
Assert-Equal (Get-Argument $stellarVnc '-display') 'none' 'VNC does not initialize SDL'
Assert-Equal ($stellarVnc.Arguments -contains 'virtio-vga') $true 'VNC software video'
Assert-Equal ($stellarVnc.Arguments -contains 'virtio-vga-gl') $false 'No VirGL in VNC'
Assert-Equal $stellarVnc.Environment.Count 0 'VNC environment overrides'
$lvlv = & $runner run -VmName lvlv-vm -Graphics Vnc -DryRun
Assert-Equal $lvlv.State (Join-Path $env:LOCALAPPDATA 'lvlv-vm') 'lvlv state'
Assert-Equal (Split-Path -Leaf $lvlv.Disk) 'lvlv-vm.qcow2' 'lvlv disk'
Assert-Equal (Split-Path -Leaf $lvlv.FirmwareVars) 'lvlv-vm-edk2-vars.fd' 'lvlv firmware'
Assert-Equal (Get-Argument $lvlv '-name') 'lvlv-vm' 'lvlv QEMU name'
Assert-Equal $lvlv.SshPort 2224 'lvlv SSH port'
Assert-Equal (Get-Argument $lvlv '-netdev') 'user,id=net0,hostfwd=tcp:127.0.0.1:2224-:22' 'lvlv loopback SSH'
Assert-Equal (Get-Argument $lvlv '-vnc') '127.0.0.1:12' 'lvlv default VNC display'
Assert-Equal $lvlv.VncEndpoint '127.0.0.1:5912' 'lvlv default VNC endpoint'
Assert-Equal (Get-Argument $lvlv '-display') 'none' 'lvlv VNC avoids SDL'
Assert-Equal (Get-Argument $lvlv '-accel') 'whpx' 'lvlv hardware acceleration'
Assert-Equal $lvlv.Acceleration 'whpx' 'lvlv defaults to WHPX'
Assert-Equal ($lvlv.Arguments -contains 'virtio-vga') $true 'lvlv VNC software video'
Assert-Equal ($lvlv.Arguments -contains 'usb-tablet') $true 'VNC keeps absolute pointer input'
Assert-Equal (@($tty.State, $stellar.State, $lvlv.State | Select-Object -Unique).Count) 3 'Default state isolation across all VMs'
$lvlvTcg = & $runner run -VmName lvlv-vm -Graphics Vnc -SoftwareEmulation -MemoryMiB 2048 -Cpus 2 -DryRun
Assert-Equal $lvlvTcg.Acceleration 'tcg' 'Explicit software emulation metadata'
Assert-Equal (Get-Argument $lvlvTcg '-accel') 'tcg,thread=multi' 'Explicit multithreaded TCG'
Assert-Equal (Get-Argument $lvlvTcg '-cpu') 'max' 'TCG CPU features'
Assert-Equal (Get-Argument $lvlvTcg '-m') '2048' 'TCG memory request'
Assert-Equal (Get-Argument $lvlvTcg '-smp') 'sockets=1,cores=2,threads=1' 'TCG CPU count'
Assert-Equal $lvlvTcg.Disk $lvlv.Disk 'Acceleration selection preserves guest disk'
Assert-Equal $lvlvTcg.FirmwareVars $lvlv.FirmwareVars 'Acceleration selection preserves guest firmware'
Assert-Equal $lvlvTcg.VncEndpoint '127.0.0.1:5912' 'CPU emulation preserves VNC selection'
Assert-Equal ($lvlvTcg.Arguments -contains 'whpx') $false 'TCG plan has no WHPX fallback'
$explicitWhpx = & $runner run -VmName lvlv-vm -SoftwareEmulation:$false -DryRun
Assert-Equal (Get-Argument $explicitWhpx '-accel') 'whpx' 'False software switch retains WHPX'
Assert-Equal ($explicitWhpx.Arguments -contains '-cpu') $false 'False software switch retains default CPU'
foreach ($vncPort in @(5900, 5999, 65535)) {
    $plan = & $runner run -Graphics Vnc -VncPort $vncPort -State $testState -DryRun
    Assert-Equal (Get-Argument $plan '-vnc') "127.0.0.1:$($vncPort - 5900)" 'Explicit VNC port conversion'
    Assert-Equal $plan.VncEndpoint "127.0.0.1:$vncPort" 'Explicit VNC endpoint'
}

$sharedTty = & $runner run -State $testState -DryRun
$sharedStellar = & $runner run -State $testState -VmName zaza-vm-windows-stellar -DryRun
$sharedLvlv = & $runner run -State $testState -VmName lvlv-vm -DryRun
Assert-Equal ($sharedTty.Disk -eq $sharedStellar.Disk) $false 'Disk isolation with explicit State'
Assert-Equal ($sharedTty.FirmwareVars -eq $sharedStellar.FirmwareVars) $false 'Firmware isolation with explicit State'
Assert-Equal (@($sharedTty.Disk, $sharedStellar.Disk, $sharedLvlv.Disk | Select-Object -Unique).Count) 3 'Disk isolation across all VMs with explicit State'
Assert-Equal (@($sharedTty.FirmwareVars, $sharedStellar.FirmwareVars, $sharedLvlv.FirmwareVars | Select-Object -Unique).Count) 3 'Firmware isolation across all VMs with explicit State'
$escapedDisk = $sharedStellar.Disk.Replace('\', '/').Replace(',', ',,')
Assert-Equal ($sharedStellar.Arguments -contains "file=$escapedDisk,format=qcow2,if=virtio,discard=unmap,detect-zeroes=unmap") $true 'QEMU path escaping'

foreach ($mode in @('Native', 'Angle')) {
    $plan = & $runner run -Graphics $mode -State $testState -DryRun
    Assert-Equal ($plan.Arguments -contains 'virtio-vga-gl') $true "$mode VirGL video"
    Assert-Equal ($plan.Arguments -contains 'usb-tablet') $false "$mode input avoids Windows tablet freeze"
    Assert-Equal (Get-Argument $plan '-accel') 'whpx' "$mode preserves WHPX"
    if ($mode -eq 'Native') {
        Assert-Equal (Get-Argument $plan '-display') 'sdl,gl=on' 'Native display'
        Assert-Equal $plan.Environment.SDL_OPENGL_ES_DRIVER '0' 'Native SDL setting'
    } else {
        Assert-Equal (Get-Argument $plan '-display') 'sdl,gl=es' 'ANGLE display'
        Assert-Equal $plan.Environment.SDL_OPENGL_ES_DRIVER '1' 'ANGLE SDL setting'
    }
}

$isoPath = Join-Path $testState 'installer image.iso'
$installer = & $runner install -VmName zaza-vm-windows-stellar -State $testState -IsoPath $isoPath -SshPort 2200 -QmpPort 4444 -DryRun
Assert-Equal $installer.Installer $true 'Installer mode'
Assert-Equal (Get-Argument $installer '-cdrom') $isoPath 'ISO path is one argument'
Assert-Equal (Get-Argument $installer '-boot') 'once=d,menu=on' 'Installer boot order'
Assert-Equal (Get-Argument $installer '-qmp') 'tcp:127.0.0.1:4444,server=on,wait=off' 'Loopback-only QMP'
Assert-Equal $installer.SshPort 2200 'Explicit SSH override'
$lvlvInstaller = & $runner install -VmName lvlv-vm -Graphics Vnc -State $testState -IsoPath $isoPath -SshPort 2201 -VncPort 5998 -DryRun
Assert-Equal $lvlvInstaller.Installer $true 'lvlv installer mode'
Assert-Equal $lvlvInstaller.Disk $sharedLvlv.Disk 'lvlv install and run share only their own disk'
Assert-Equal $lvlvInstaller.FirmwareVars $sharedLvlv.FirmwareVars 'lvlv install and run share only their own firmware'
Assert-Equal (Get-Argument $lvlvInstaller '-cdrom') $isoPath 'lvlv explicit ISO reuse'
Assert-Equal $lvlvInstaller.SshPort 2201 'lvlv explicit SSH override'
Assert-Equal $lvlvInstaller.VncEndpoint '127.0.0.1:5998' 'lvlv explicit VNC override'
$tcgInstaller = & $runner install -VmName lvlv-vm -State $testState -IsoPath $isoPath -SoftwareEmulation -DryRun
Assert-Equal (Get-Argument $tcgInstaller '-accel') 'tcg,thread=multi' 'Installer supports explicit TCG'
Assert-Equal (Get-Argument $tcgInstaller '-cpu') 'max' 'Installer TCG CPU features'
Assert-Equal (Get-Argument $tcgInstaller '-cdrom') $isoPath 'TCG installer ISO path'
Assert-Equal (Get-Argument $stellar '-boot') 'order=c,menu=on' 'Normal disk boot'
Assert-Rejected { & $runner run -QmpPort 2222 -DryRun } 'TTY SSH/QMP collision'
Assert-Rejected { & $runner run -VmName zaza-vm-windows-stellar -QmpPort 2223 -DryRun } 'Stellar SSH/QMP collision'
Assert-Rejected { & $runner run -VmName lvlv-vm -QmpPort 2224 -DryRun } 'lvlv SSH/QMP collision'
Assert-Rejected { & $runner run -Graphics Vnc -SshPort 5910 -DryRun } 'TTY VNC/SSH collision'
Assert-Rejected { & $runner run -Graphics Vnc -QmpPort 5910 -DryRun } 'TTY VNC/QMP collision'
Assert-Rejected { & $runner run -VmName zaza-vm-windows-stellar -Graphics Vnc -SshPort 5911 -DryRun } 'Stellar VNC/SSH collision'
Assert-Rejected { & $runner run -VmName zaza-vm-windows-stellar -Graphics Vnc -QmpPort 5911 -DryRun } 'Stellar VNC/QMP collision'
Assert-Rejected { & $runner run -VmName lvlv-vm -Graphics Vnc -SshPort 5912 -DryRun } 'lvlv VNC/SSH collision'
Assert-Rejected { & $runner run -VmName lvlv-vm -Graphics Vnc -QmpPort 5912 -DryRun } 'lvlv VNC/QMP collision'
Assert-Rejected { & $runner run -Graphics Vnc -VncPort 5999 -SshPort 5999 -DryRun } 'Explicit VNC/SSH collision'
Assert-Rejected { & $runner run -Graphics Vnc -VncPort 5899 -DryRun } 'Invalid low VNC port'
Assert-Rejected { & $runner run -Graphics Vnc -VncPort 65536 -DryRun } 'Invalid high VNC port'
# A VNC port is unused outside Vnc mode, so it must not reject a real SSH listener.
$noVnc = & $runner run -State $testState -SshPort 5910 -VncPort 5910 -DryRun
Assert-Equal ($noVnc.Arguments -contains '-vnc') $false 'Inactive VNC port does not bind'
Assert-Rejected { & $runner create-disk -State $testState -DryRun } 'DryRun cannot create a disk'
Assert-Rejected { & $runner run -VmName another-vm -DryRun } 'Unknown VM name'
Assert-Rejected { & $runner run -Graphics Invalid -DryRun } 'Unknown display mode'
Assert-Equal (Test-Path -LiteralPath $testState) $false 'DryRun did not create state'
Assert-Equal (Test-Path Env:SDL_OPENGL_ES_DRIVER) $hadEsDriver 'SDL environment presence unchanged'
Assert-Equal $env:SDL_OPENGL_ES_DRIVER $previousEsDriver 'SDL environment value unchanged'
} finally {
    if (Test-Path -LiteralPath $qemuFixtureDirectory) {
        $resolvedFixture = (Resolve-Path -LiteralPath $qemuFixtureDirectory).ProviderPath
        if (-not $resolvedFixture.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean a fixture outside the temporary directory: $resolvedFixture"
        }
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}

Write-Host 'Windows runner parser and launch-plan tests passed; no VM was started.'
}
