#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# 只启用 QEMU/WHPX 所需的 Windows 组件；不关闭 VBS、Credential Guard 或其它
# 安全功能，也不擅自重启正在使用的工作站。
$result = Enable-WindowsOptionalFeature `
    -Online `
    -FeatureName HypervisorPlatform `
    -All `
    -NoRestart

& "$env:SystemRoot\System32\bcdedit.exe" /set hypervisorlaunchtype auto
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set hypervisorlaunchtype (exit $LASTEXITCODE)."
}

$result | Select-Object FeatureName, State, RestartNeeded
Write-Host 'WHPX 已启用；请重启 Windows。'
Write-Host '如果重启后仍不可用，请在 UEFI/BIOS 中启用 Intel Virtualization Technology (VT-x)。'
