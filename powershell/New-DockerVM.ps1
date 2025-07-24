$role = [PSCustomObject]@{
    cluster    = "cluster.domain.com"
    node       = "hyperv.domain.com"
    vm         = "docker-3.domain.com"
    iso        = "C:\ClusterStorage\Volume1\Setup"
    dist       = "AlmaLinux-10.0-x86_64-minimal.iso"
    storage    = "C:\ClusterStorage\Volume3"
    vlan       = 310
}
$state = Get-VM -Name $role.vm `
    -CimSession $role.cluster -ErrorAction SilentlyContinue
if ($state) {
    Write-Host "VM $($role.vm) already exists on $($role.cluster)."
} else {
    Write-Host "Creating VM $($role.vm) on $($role.cluster)."
    Invoke-Command -ComputerName $role.node -ScriptBlock {
        param($role)
        $vm_path = "$($role.storage)\Hyper-V\$($role.vm)\Virtual Machines"
        $vhd_path = "$($role.storage)\Hyper-V\$($role.vm)\Virtual Hard Disks"
        if (-not (Test-Path $vm_path)) {
            New-Item -Path $vm_path -ItemType Directory `
                -Force | Out-Null
        }
        if (-not (Test-Path $vhd_path)) {
            New-Item -Path $vhd_path -ItemType Directory `
                -Force | Out-Null
        }
        New-VM -Name $role.vm `
            -MemoryStartupBytes 8Gb -Generation 2 `
            -Path $vm_path | Out-Null
        New-VHD -SizeBytes 128Gb -Dynamic -BlockSizeBytes 1MB `
            -Path "$vhd_path\$($role.vm)-sda.vhdx" | Out-Null
        New-VHD -SizeBytes 256Gb -Dynamic -BlockSizeBytes 1MB `
            -Path "$vhd_path\$($role.vm)-sdb.vhdx" | Out-Null
        Add-VMHardDiskDrive -VMName $role.vm `
            -Path "$vhd_path\$($role.vm)-sda.vhdx"
        Add-VMHardDiskDrive -VMName $role.vm `
            -Path "$vhd_path\$($role.vm)-sdb.vhdx"
    } -ArgumentList $role
    Add-ClusterVirtualMachineRole `
        -Cluster $role.cluster -VMName $role.vm | Out-Null
    Set-VM `
        -Name $role.vm -CimSession $role.cluster `
        -AutomaticStartAction Start -ProcessorCount 4
    Set-VMFirmware `
        -VMName $role.vm -CimSession $role.cluster `
        -EnableSecureBoot On `
        -SecureBootTemplate MicrosoftUEFICertificateAuthority
    Add-VMDvdDrive `
        -VMName $role.vm -CimSession $role.cluster `
        -Path "$($role.iso)\$($role.dist)"
    Set-VMNetworkAdapterVlan `
        -VMName $role.vm -CimSession $role.cluster `
        -Access -VlanId $role.vlan
    Connect-VMNetworkAdapter `
        -VMName $role.vm -CimSession $role.cluster`
        -SwitchName "vSwitch"
}