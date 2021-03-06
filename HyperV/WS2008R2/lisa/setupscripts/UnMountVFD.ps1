#######################################################################
#
# UnMountVFD
#
# Description:
#   Unmount a .vfd file from a VMs floppy drive.
#
#######################################################################
param([string] $vmName, [string] $hvServer, [string] $testParams)

"UMountVFD.ps1 -vmName $vmName -hvServer $hvServer -testParams $testParams"

$sts = get-module | select-string -pattern HyperV -quiet
if (! $sts)
{
    Import-module .\HyperVLibV2Sp1\Hyperv.psd1
}

#
# If a .vfd is mounted, unmount it.
#
$vfd = Get-VMFloppyDisk -vm $vmName -server $hvServer
if ($vfd -ne $null)
{
    Remove-VMFloppyDisk -vm $vmName -server $hvServer -Force
    ".vfd file successfully unmounted"
}
else
{
    "No .vfd file was mounted"
}

return $true