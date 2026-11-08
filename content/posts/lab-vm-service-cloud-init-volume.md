---
title: "VMs Next to Containers: VM Service with cloud-init, and a Volume from the Local Consumption Interface"
date: 2026-11-25
draft: true
tags: ["VCF", "VMware", "Lab", "VM Service", "Supervisor", "cloud-init", "vSAN", "Local Consumption Interface"]
categories: ["VCF 9", "Lab Series"]
labPart: 24
cover:
  image: "/images/covers/lab-vm-service-cloud-init-volume.jpg"
  alt: "VMs Next to Containers: VM Service with cloud-init and a Volume from the Local Consumption Interface"
  relative: false
description: "Deploying an Ubuntu VM in a Supervisor namespace with VM Service and cloud-init on VCF 9.1.1, reaching it through a load balancer address, and attaching a 2 GiB volume created in the Local Consumption Interface, including the patch that made the attach work."
---

## Overview

A Supervisor namespace is not only for containers. The same namespace that holds the VKS cluster from the previous post can run ordinary virtual machines, declared the same way as everything else on the Supervisor: as Kubernetes objects. That is VM Service.

This post deploys an Ubuntu 24.04 VM in `ns-app-dev` from the vSphere Client, configures it with cloud-init, publishes SSH on an address from the external block, and then gives it a second disk from the Volume Service. The last step needed a patch that is not obvious, and it is covered at the end.

## Architecture at a glance

The VM, its image, its volume and its address, in the same namespace as the VKS nodes.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-vm-service-cloud-init-volume-glance.svg"></object>
</div>

## Why a VM in a Kubernetes namespace

VMs and containers share a namespace, a network, a storage policy and a quota. The VKS nodes from the previous post are VMs in this namespace too, created by the same VM service. A VM next to them gets the same workload network, the same storage classes and a load balancer service of its own, without a separate VLAN, a datastore choice or a ticket.

-> **For application teams**: a VM that is a manifest in the same repository as the containers it talks to.

-> **For the platform team**: one namespace to size, one network to secure and one policy model for both kinds of workload.

## An image library for VMs

VM Service deploys from VM images in a content library that is associated with the namespace. The Kubernetes Service Content Library from the earlier posts is managed by VKS and holds node images. VM images go into a separate library.

The lab uses a local library, `vg1-w01-cl-vmsvc`, stored on the vSAN datastore. The image is the Ubuntu 24.04 cloud image in OVA format, imported by URL straight from the Ubuntu cloud image site. It is about 1.06 GB and was named `ubuntu-2404-cloud`.

![Import Library Item from URL: the Ubuntu 24.04 cloud OVA imported as ubuntu-2404-cloud](/images/lab/lab-S406.jpg)
*Import Library Item: the source is a URL, the item name is `ubuntu-2404-cloud` and the destination is `vg1-w01-cl-vmsvc`.*

The library then has to be added to the namespace. On the namespace summary, Add Content Library lists the libraries in the inventory. The Kubernetes Service library is shown too, but it is managed from the Kubernetes Service card, so the lab library is the one to select.

![Add Content Library: vg1-w01-cl-vmsvc selected for ns-app-dev](/images/lab/lab-S410.jpg)
*Add Content Library: the local library `vg1-w01-cl-vmsvc` is added to `ns-app-dev`.*

Once the library is associated, its items show up as VM images, each with a generated image name. The `ubuntu-2404-cloud` item became `vmi-f8ad32b62a9cd4de1`, and that name is what the VM object refers to.

## Create the VM

The wizard is under Resources, Virtual Machine Service, Create Virtual Machine. Like the cluster wizard, it keeps a YAML panel on the right with the Kubernetes objects it will apply.

The first steps choose the image and size the VM.

![New Virtual Machine: image ubuntu-2404-cloud and the YAML panel](/images/lab/lab-S415.jpg)
*The image `ubuntu-2404-cloud` selected, with the generated `VirtualMachine` object on the right.*

| Setting | Value |
|---|---|
| VM name | `vm-ubuntu01` |
| Zone | `vg1-w01-az01` |
| VM image | `ubuntu-2404-cloud` |
| VM class | `best-effort-small` (2 vCPU, 4 GiB) |
| Storage class | `sp-vks-gold` |
| Power state | Powered On |

The storage class is the policy from the earlier post. The VM's boot disk lands on the same RAID-5 tier that the persistent volumes use.

### A load balancer for SSH

The advanced step can create a VM load balancer. It is a Kubernetes Service of type LoadBalancer with a selector that matches a label on the VM, which makes the VM reachable on an address from the external block just like the web app from the previous post.

![Create VM Load Balancer: name vm-ubuntu01-ssh, port 22, TCP, target 22](/images/lab/lab-S420.jpg)
*The VM load balancer `vm-ubuntu01-ssh`: port 22, protocol TCP, target port 22.*

### Guest customization with cloud-init

The same step asks how the guest should be customized. The options are None, Cloud-Init, Sysprep, LinuxPrep and vAppConfig. A cloud image such as this one is built for cloud-init, which reads a user-data document on first boot and configures the guest.

The wizard offers an SSH public keys field and a raw configuration editor. The lab uses the raw editor, so the whole user-data document is visible and stays in the namespace as a secret.

```yaml
#cloud-config
hostname: vm-ubuntu01
users:
- name: labuser
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  ssh_authorized_keys:
  - ssh-ed25519 <jump-host-public-key>
```

Only the public key of the jump host goes into this document. The private key stays on the jump host, which is the one place SSH will come from.

![Guest customization: Cloud-Init, raw configuration with the user, sudo rule and the SSH key](/images/lab/lab-S422.jpg)
*Guest customization: Cloud-Init with the raw configuration. The right side shows the `Secret` that carries it.*

### Review and deploy

The review page lists what will be created: the `VirtualMachine`, the bootstrap `Secret` and the `VirtualMachineService` for SSH. A note at the bottom says that the VM will have one network interface, connected to the default workload network of the namespace.

![Review: VM, secret and load balancer; one NIC on the namespace workload network](/images/lab/lab-S424.jpg)
*Review and confirm: three objects, and one NIC on the namespace workload network.*

```yaml
apiVersion: vmoperator.vmware.com/v1alpha5
kind: VirtualMachine
metadata:
  name: vm-ubuntu01
  namespace: ns-app-dev
  labels:
    vm-ubuntu01-ssh: vm-lb-selector
spec:
  className: best-effort-small
  imageName: vmi-f8ad32b62a9cd4de1
  storageClass: sp-vks-gold
  powerState: PoweredOn
  bootstrap:
    cloudInit:
      rawCloudConfig:
        name: vm-ubuntu01-bootstrap-secret
        key: user-data
---
apiVersion: vmoperator.vmware.com/v1alpha5
kind: VirtualMachineService
metadata:
  name: vm-ubuntu01-ssh
  namespace: ns-app-dev
spec:
  type: LoadBalancer
  selector:
    vm-ubuntu01-ssh: vm-lb-selector
  ports:
  - name: ssh
    port: 22
    targetPort: 22
    protocol: TCP
```

After Deploy, the VM appears in the Virtual Machine Service list next to the three VKS node VMs, which is the clearest picture of what this feature is: one list, one API, two kinds of workload.

![Virtual Machine Service: vm-ubuntu01 next to the three VKS node VMs](/images/lab/lab-S425.jpg)
*`vm-ubuntu01` deploying, listed with the three node VMs of `vks-app-dev01`.*

## Reaching the VM

The VM took the address 172.21.0.34 in the namespace VPC, and the service took the address 10.80.0.11 from the external block, which the lab router learns over BGP.

```bash
kubectl get vm,virtualmachineservice -n ns-app-dev -o wide
ssh labuser@10.80.0.11 'cloud-init status; hostname; ip -br addr'
```

From the VM, a short set of checks proves the network from the workload side.

| Check | Result |
|---|---|
| DNS | Resolves |
| VPC gateway | Reachable |
| Management network | Reachable |
| Supervisor API at 10.80.0.6 | HTTP 200 |
| Web app at 10.80.0.10 | HTTP 200 |
| Internet | Reachable through the VPC SNAT |
| NTP | Synchronized |

The web app answering from a VM shows that VMs and VKS workloads share the same VPC and reach each other's published addresses.

## A volume from the Local Consumption Interface

The VM has only its boot disk. A second disk comes from the Volume Service, a card in the namespace UI that creates persistent volume claims without writing YAML. In 9.1.1 this Local Consumption Interface is part of the vSphere Client, so nothing had to be installed.

New Volume asks for a name, a storage type, a storage class and a capacity. The lab volume is `vm-ubuntu01-data`, a Block volume on `sp-vks-gold` with 2 GiB and the access mode Single VM or Pod, which is ReadWriteOnce.

![New Volume: vm-ubuntu01-data, Block, sp-vks-gold, 2 GiB](/images/lab/lab-S431.jpg)
*New Volume: `vm-ubuntu01-data`, Block, `sp-vks-gold`, 2 GiB.*

The Volume Service list shows the new claim next to everything else that uses storage in the namespace: the VM's boot disk, the claims of the VKS cluster and the node disks.

![Volume Service: the new volume plus the boot disk, the guest-cluster PVCs and the node disks](/images/lab/lab-S432.jpg)
*The Volume Service list. `vm-ubuntu01-data` is Bound, with 2 GiB on `sp-vks-gold`.*

### Attaching it: JSON patch, not merge patch

Creating the volume does not attach it. The VM object has to reference the claim. The obvious command is a merge patch with the new volume.

```bash
kubectl patch vm vm-ubuntu01 -n ns-app-dev --type merge -p '{"spec":{"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"vm-ubuntu01-data"}}]}}'
```

It is rejected by the admission webhook:

```text
admission webhook ... denied the request: spec.volumes[0]: Forbidden: cannot remove volume with removable=false
```

In the VM Operator API used here, `spec.volumes` already holds the boot disk, marked as not removable. A merge patch replaces the whole list, so it tries to remove the boot disk. A JSON patch that appends one entry leaves the list as it is.

```bash
kubectl patch vm vm-ubuntu01 -n ns-app-dev --type json -p \
  '[{"op":"add","path":"/spec/volumes/-","value":{"name":"data","persistentVolumeClaim":{"claimName":"vm-ubuntu01-data"}}}]'
kubectl get vm vm-ubuntu01 -n ns-app-dev -o jsonpath='{range .status.volumes[*]}{.name}{"  attached="}{.attached}{"\n"}{end}'
```

The status shows the new volume as attached, and the disk is hot-added to the running VM.

### Inside the VM

The guest sees a new 2 GB disk, `sdb`, next to the 10 GB boot disk. It is empty, so it needs a filesystem and a mount point.

```bash
ssh labuser@10.80.0.11 'lsblk'
ssh labuser@10.80.0.11 'sudo mkfs.ext4 -q /dev/sdb'
ssh labuser@10.80.0.11 'sudo mkdir -p /data && sudo mount /dev/sdb /data'
ssh labuser@10.80.0.11 'echo ok | sudo tee /data/proof.txt; df -h /data'
```

![Inside vm-ubuntu01: sdb of 2 GB hot-added, formatted and mounted on /data](/images/lab/lab-S433.jpg)
*`lsblk` shows `sdb` of 2 GB, then the filesystem is created, mounted on `/data` and written to.*

The mount is not in `/etc/fstab`, so it would not survive a reboot. For anything beyond a lab, add a UUID entry.

## What to take from this

-> **VM images are a separate library**: the Kubernetes Service library holds node images, and a local library holds VM images for the namespace.

-> **cloud-init through a secret**: the raw editor keeps the full user-data visible, and only a public key ever goes into it.

-> **A VM is a VirtualMachine object**: it shows up in the same list as the VKS nodes, and the same address pool publishes its services.

-> **Attach with a JSON patch append**: a merge patch on `spec.volumes` fails, because the list already contains the boot disk.

-> **Add the mount to fstab**: a manual mount is enough for a proof, not for a VM that reboots.

## What's Next

Next in this series: micro-segmentation between VPCs with the Distributed Firewall, proven with Traceflow.

## Further Reading (Official Broadcom Documentation)

- [Deploy a Supervisor with VPC Networking (VCF 9.1)](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsphere-supervisor-installation-and-configuration/supervisor-networking-with-virtual-private-clouds/deploy-a-supervisor-with-nsx-vpc.html)
- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
