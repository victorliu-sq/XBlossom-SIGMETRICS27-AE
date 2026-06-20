# Azure VM Setup

## Resource Request

Before creating the VM, request sufficient quota for the target VM family.

Some Azure VM types are only available in specific regions or availability zones. If a VM size does not appear during creation, check:

```text
Region
Availability zone
Quota for the VM family
GPU quota, if using GPU instances
```

For GPU VMs, quota availability is often the blocking issue.

## Security Type

For `bm-nvads-v710`, disable Secure Boot in Azure.

Procedure:

```text
Azure Portal -> bm-nvads-v710 -> Settings -> Configuration -> Security type / Trusted launch -> uncheck Enable secure boot -> Save
```

This matters for AMD GPU/ROCm setup. On this VM, the default Azure kernel can load the `amdgpu` DRM module, but it does not provide ROCm compute access through `/dev/kfd`.

The observed failure was:

```text
ROCm KFD device: /dev/kfd missing
amd-smi: Driver not loaded (amdgpu not found in modules)
```

Installing `amdgpu-dkms` can provide the needed ROCm compute support, but with Secure Boot enabled the DKMS install triggers interactive MOK enrollment:

```text
Enter a password for Secure Boot.
The Secure Boot key you've entered is not valid.
```

That prompt breaks non-interactive bootstrap runs over SSH. Disable Secure Boot before running the AMD GPU bootstrap target so the driver installation can proceed automatically.

## Username

Use `ubuntu` as the VM username.

This keeps the SSH config aligned with AWS hosts:

```sshconfig
Host azure-nv24ads-v710
    HostName 172.171.241.43
    User ubuntu
    IdentityFile ~/Downloads/jiaxin-azure.pem
```

Using the same username across AWS and Azure makes host entries easier to copy, compare, and automate.

## SSH Key

Generate a new SSH key if needed during Azure VM creation.

In the Azure portal, the private key is created after clicking:

```text
Review + create
```

Download the generated `.pem` file and store it locally, for example:

```text
~/Downloads/jiaxin-azure.pem
```

After downloading, restrict the private key permissions:

```shell
chmod 600 ~/Downloads/jiaxin-azure.pem
```

SSH will reject the key if it is readable or writable by group/others.

## Connect

Add an SSH config entry:

```sshconfig
Host azure-nv24ads-v710
    HostName <public-ip>
    User ubuntu
    IdentityFile ~/Downloads/jiaxin-azure.pem
```

Then connect with:

```shell
ssh azure-nv24ads-v710
```
