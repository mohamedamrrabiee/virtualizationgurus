---
title: "Activating a Supervisor on VPC Networking: Design Choices, the Wizard and the First 50 Minutes"
slug: "lab-supervisor-vpc-networking"
date: 2027-03-11
draft: true
tags: ["VCF", "VMware", "Lab", "Supervisor", "vSphere Kubernetes", "NSX", "VPC"]
categories: ["VCF 9", "Lab Series"]
labPart: 21
cover:
  image: "/images/covers/lab-supervisor-vpc-networking.jpg"
  alt: "Activating a Supervisor on VPC Networking"
  relative: false
description: "Enabling a vSphere Supervisor with VCF Networking and VPC on a nested VCF 9.1.1 workload domain: the design choices, the activation wizard step by step, and what happens in the first 50 minutes."
---

## Overview

With the workload domain, the Edge cluster, the Tier-0 gateway, the transit gateway and the VPC objects in place, the lab was ready for the Supervisor. This post covers the decisions made before the wizard, each step of the wizard with the values used, and what the activation looked like from the first click to a running Supervisor.

The result was a Supervisor `vg1-w01-sup01` with three control plane VMs, running about 52 minutes after Finish was pressed.

## Architecture at a glance

The management addressing, the Supervisor and the workload network that the wizard ties together.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-supervisor-vpc-networking-glance.svg"></object>
</div>

## Design choices

| Decision | Choice | Reason |
|---|---|---|
| Networking stack | VCF Networking with VPC | Consistent with the VPC design built in the previous posts |
| Deployment type | Cluster deployment on `vg1-w01-cl01` | One cluster, one management zone, host level HA |
| Control plane | 3 VMs, size Small | Highly available, and enough for a lab |
| Control plane storage | vSAN ESA RAID-5 policy | RAID-6 needs more hosts than the 3 in this lab |
| Load balancing | NSX Edge load balancer | Used by default when no Avi load balancer is detected |
| Management IPs | 5 consecutive addresses | Three nodes, a floating IP and one spare |

## Prerequisites to settle first

The Supervisor wizard asks for objects that must already exist. Settle these before starting:

-> **A vSphere cluster** with vSphere HA and DRS, and enough capacity for the control plane VMs.

-> **An NSX project with a VPC connectivity profile**, backed by the Edge cluster and the Tier-0 and transit gateway from the earlier posts.

-> **A storage policy** that the cluster can satisfy for the control plane VMs, ephemeral disks and the image cache.

-> **Management network addresses**: five IPs, as covered below.

-> **IP ranges that do not overlap**: external IP blocks, private transit gateway IP blocks, private VPC CIDRs and the Service CIDR must not collide with each other or with the management network.

The storage policy deserves an early check. Both vCenter Servers had RAID-5 and RAID-6 vSAN ESA policies. On a 3-host cluster only RAID-5 can be satisfied, so that is the one to select.

![VM Storage Policies in vCenter showing the RAID5 and RAID6 policies](/images/lab/lab-S303.jpg)
*VM Storage Policies: RAID-5 and RAID-6 policies exist on both vCenter Servers. The 3-host cluster can only satisfy RAID-5.*

![Cluster capacity before the Supervisor](/images/lab/lab-S304.jpg)
*Capacity before activation: 6.5 of 59.9 GHz CPU used, 128.4 GB of 240 GB memory free, 315 of 3072 GB storage used.*

## The management network: five addresses

The control plane needs five IPs on the management network: three for the control plane VMs, one floating IP that sits on the etcd leader and serves the API, and one spare used when a failed VM is replaced or during an upgrade. After deployment, the control plane VM addresses and the floating IP cannot be changed, so the range needs to be right the first time.

| Address | Role |
|---|---|
| 10.20.10.61 | Floating IP (API and SSH) |
| 10.20.10.62 to .64 | Control plane nodes |
| 10.20.10.65 | Kept free for upgrades and VM replacement |

Before running the wizard, a loop on the jump host confirms the range is really free:

```bash
watch -n 10 'for i in 61 62 63 64 65; do ping -c1 -W1 10.20.10.$i >/dev/null && echo ".$i IN USE" || echo ".$i free"; done'
```

The same loop is useful during the deployment. It shows the addresses being taken one by one, with `.65` staying free as intended.

![Free IP loop on the jump host during deployment](/images/lab/lab-S319.jpg)
*Mid-deployment: .61 to .64 in use, .65 free.*

## The activation wizard

### Step 2: location

The wizard asks for a deployment type. Cluster deployment with a single management zone was used, with the zone `vg1-w01-az01` created automatically from the cluster. The zone name cannot be changed once set.

![Wizard Step 2, Supervisor location](/images/lab/lab-S306.jpg)
*Step 2: the Supervisor name, the vCenter, the cluster deployment type and the zone.*

### Step 3: storage

The policies for the control plane, the ephemeral disks and the image cache were all set to the vSAN ESA RAID-5 policy.

![Wizard Step 3, storage](/images/lab/lab-S307.jpg)
*Step 3: storage policies for the control plane, ephemeral disks and image cache, before the selection.*

### Step 4: management network

The management network uses the port group `vg1-w01-cl01-vds-01-pg-vmmgmt` on VLAN 3321. Static addressing with the starting IP `10.20.10.61` reserves the range of five addresses. The gateway, DNS and NTP server are all `10.20.10.1`, and the search domain is `vgurus.lab`.

![Wizard Step 4, management network](/images/lab/lab-S308.jpg)
*Step 4: management network with a static starting address and the lab router for DNS and NTP.*

### Step 5: workload network

This is where the VPC design pays off. The wizard takes the NSX project and the VPC connectivity profile, then the address ranges:

| Setting | Value |
|---|---|
| Project | Default |
| VPC connectivity profile | Default VPC Connectivity Profile |
| External IP block (advertised) | `vg1-w01-vpc-ext-ip-block`, 10.80.0.0/22 |
| Private transit gateway IP block (not advertised) | 172.31.0.0/16 |
| Private VPC CIDR | 172.21.0.0/16 |
| Service CIDR | 10.96.0.0/23 |
| DNS and NTP | 10.20.10.1 |

Two defaults were changed on purpose. The default private VPC CIDR 172.30.0.0/16 became 172.21.0.0/16, and the default Service CIDR 172.29.0.0/16 became 10.96.0.0/23, so that nothing overlaps with the transit gateway block or other lab ranges.

![Wizard Step 5, workload network](/images/lab/lab-S311.jpg)
*Step 5: the NSX project, the connectivity profile and the address ranges.*

### Step 6: advanced settings

The control plane size was set to Small. The documentation lists Tiny, Small, Medium and Large, and a size can only be increased later, never reduced. The wizard in this lab showed Small as 4 CPUs, 16 GB memory and 48 GB storage. API server DNS names are optional and were left empty.

![Wizard Step 6, advanced settings](/images/lab/lab-S312.jpg)
*Step 6: control plane size Small.*

### Step 7: review

The review page lists every choice. Export configuration saves the wizard values as JSON, which is worth doing so the Supervisor can be recreated from the same inputs.

![Wizard Step 7, ready to complete](/images/lab/lab-S313.jpg)
*Step 7: Ready to complete.*

## The first 50 minutes

The timeline, in local time:

| Time | Event |
|---|---|
| 12:41 to 13:03 | Pre-checks: IPs, storage policy, NSX objects |
| 13:53 | Finish pressed in the wizard |
| about 14:19 | Configuration conditions reach 17 of 17 |
| 14:45 | Supervisor reports Running, about 52 minutes after Finish |

The vCenter shows the progress as a list of conditions on the Supervisor and on each control plane VM. Then the hosts are configured as Kubernetes nodes.

![Configuring vg1-w01-sup01 with 17 of 17 conditions](/images/lab/lab-S323.jpg)
*Configuring the Supervisor: 17 of 17 conditions.*

![Control plane VM conditions](/images/lab/lab-S325.jpg)
*Conditions on the first control plane VM.*

![Configuring host nodes at 0 of 12](/images/lab/lab-S327.jpg)
*Configuring the host nodes, starting at 0 of 12.*

The control plane VMs show up in the vSAN virtual objects view on the RAID-5 policy as expected.

![vSAN virtual objects showing the control plane VMs on RAID5](/images/lab/lab-S331.jpg)
*vSAN virtual objects: the three control plane VMs on the RAID-5 policy.*

When the activation finishes, the Supervisor reports Running with its API endpoint on `10.80.0.6` and three namespaces already present for the system.

![Supervisor Running with API endpoint and namespaces](/images/lab/lab-S333.jpg)
*The Supervisor is Running. API endpoint 10.80.0.6, 3 namespaces.*

## Verifying the result

From the vCenter shell, the Supervisor control plane password is retrieved with `/usr/lib/vmware-wcp/decryptK8Pwd.py`. SSH to the floating IP then gives a root shell on the active control plane VM:

```bash
kubectl get nodes -o wide
kubectl get pods -A | grep -vE "Running|Completed"
kubectl get svc -A | grep LoadBalancer
kubectl get vpcnetworkconfigurations
curl -k https://10.80.0.6
```

The results:

| Check | Result |
|---|---|
| Nodes | 6 Ready: 3 control plane and 3 ESX hosts as agents |
| Unhealthy pods | None |
| Load balancer VIPs | 10.80.0.4 kube-dns, .5 registry, .6 Kubernetes API (443 and 6443), .7 image proxy |
| System VPCs | `kube-system` and `vmware-system-supervisor-services-vpc` |
| API VIP | HTTP 200 from the jump host through the lab router over BGP |
| Version | v1.34.9+vmware.1-vsc9.1.1.0 |
| Services | `svc-tkg` (VKS), `svc-velero`, `svc-cci-ns` |

The HTTP 200 from the jump host matters. It shows that the external IP block is advertised through the Tier-0 gateway and the BGP session to the lab router, the path built in the earlier posts.

One side effect to expect: the floating IP moves between control plane nodes, so SSH may warn about a changed host key. `ssh-keygen -R 10.20.10.61` clears it.

## The Supervisor and VKS as built



<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-asbuilt-supervisor-vks.svg"></object>
</div>

*The final Supervisor, namespace VPC, VKS cluster and DFW layout on the centralized connectivity design.*

## What to take from it

-> **Count the management IPs first**: five consecutive addresses, with one left free on purpose.

-> **Pick a storage policy the cluster can satisfy**: RAID-5 on 3 hosts. A policy the cluster cannot meet stalls the deployment.

-> **Change the default ranges that can collide**: the VPC CIDR and Service CIDR defaults overlap easily with an existing design.

-> **Export the configuration** before pressing Finish.

-> **Allow close to an hour**: in this nested lab it took about 52 minutes from Finish to Running.

-> **Verify from outside**: a 200 from the API VIP on the jump host proves the whole network path, not only the Supervisor.

## What's Next

Next in this series: Namespaces, Storage Policies and Kubernetes Releases, getting VKS ready for a team.

## Further Reading (Official Broadcom Documentation)

- [Deploy a Supervisor with VPC Networking (VCF 9.1)](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsphere-supervisor-installation-and-configuration/supervisor-networking-with-virtual-private-clouds/deploy-a-supervisor-with-nsx-vpc.html)
- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
