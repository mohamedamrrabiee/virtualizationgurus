---
title: "Guided Edge Deployment from vCenter: Port Group, TEP Pool and the Edge Cluster"
date: 2026-11-04
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "Edge", "Networking"]
categories: ["VCF 9", "Lab Series"]
labPart: 15
cover:
  image: "/images/covers/lab-guided-edge-deployment-vcenter.jpg"
  alt: "Guided Edge Deployment from vCenter: Port Group, TEP Pool and the Edge Cluster"
  relative: false
description: "Deploying a two-node NSX Edge cluster from the vSphere Client with the centralized connectivity wizard: the two prerequisites to create first, every value used, and the details that save time."
---

## Overview

A VPC with centralized connectivity needs NSX Edge nodes. In VCF 9.1.1 the vSphere Client can deploy them for you through a guided wizard, so the Edge cluster itself is built without leaving the vSphere Client. Two things have to exist before you start, and the wizard expects both to exist already.

In this lab the prerequisites took about 10 minutes and the wizard run about 20 minutes, ending with both Edge nodes Up.

## Architecture at a glance

What the guided deployment attaches to: two Edge nodes, four VLANs and the uplink mapping on the workload domain hosts.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-guided-edge-deployment-vcenter-glance.svg"></object>
</div>

## Prerequisites to create first

-> **A VM management port group on the w01 VDS**: the default switch profile created during the workload domain deployment has no port group for Edge management. I created `vg1-w01-cl01-vds-01-pg-vmmgmt` on VLAN 3321 before opening the wizard.

-> **NSX activated on the distributed port groups**: the documentation lists Activate NSX on DVPG on the VDS as a prerequisite for the workflow. In this lab the cluster was prepared during the workload domain deployment.

-> **A static IP pool for the Edge TEPs**: the TEP VLAN has no DHCP, so the Edge TEPs need a pool. In NSX Manager I created `vg1-w01-ippool-edgetep`, 10.20.25.11 to 10.20.25.20 on 10.20.25.0/24 with gateway .1.

![New Distributed Port Group wizard with VLAN ID 3321](/images/lab/lab-S225.jpg)
*The Edge management port group on VLAN 3321.*

![NSX Set Subnets dialog for the Edge TEP pool](/images/lab/lab-S219.jpg)
*The Edge TEP pool range, CIDR and gateway in NSX Manager.*

![NSX IP address pools list with both pools Success](/images/lab/lab-S220.jpg)
*Host TEP pool and Edge TEP pool, both Success.*

The VLANs involved, so the numbers do not get mixed up:

| VLAN | Purpose |
|---|---|
| 3321 | Edge management (VM management port group) |
| 3328 | Host TEPs |
| 3329 | Edge TEPs |

The Edge uplink VLANs are covered in the BGP post that follows this one.

## The wizard

The wizard opens from the workload domain vCenter in the vSphere Client: Networks, Transit Gateways, Setup Network Connectivity, with Centralized Connection as the connectivity type. The Edge cluster part of it asks for a node at a time. The documentation allows a minimum of 2 and a maximum of 10 Edge nodes per cluster, and the Edge VMs get a 100 percent CPU and memory reservation.

| Setting | Value used |
|---|---|
| Connectivity type | Centralized Connection |
| Edge cluster | `vg1-w01-ec01`, two nodes, size Medium |
| Tunnel endpoint MTU | 9000, read from the Global Fabric Settings |
| Node 1 | `vg1-w01-en01`, management 10.20.10.51 |
| Node 2 | `vg1-w01-en02`, management 10.20.10.52 |
| Management network | The VM management port group, VLAN 3321 |
| Edge TEP | VLAN 3329, addresses from the static pool |
| Uplink mapping | uplink-1 to fp-eth0 (vmnic0 active, vmnic1 standby), uplink-2 to fp-eth1 (vmnic1 active, vmnic0 standby) |

Edge sizes, as the documentation lists them: Small (2 vCPU, 4 GB) for labs and proofs of concept, Medium (4 vCPU, 8 GB) for production, Large (8 vCPU, 32 GB) and XLarge (16 vCPU, 64 GB). With Supervisor or VCF Automation the documentation recommends Large or XLarge, so Medium is a lab choice here.

The resulting Edge TEP addresses were 10.20.25.11 and .12 on the first node, and .13 and .14 on the second.

![Configure Network Connectivity with Centralized Connection selected](/images/lab/lab-S169.jpg)
*Step 1: Centralized Connection.*

![Edge Cluster step with MTU 9000 and size Medium](/images/lab/lab-S172.jpg)
*Step 2: cluster vg1-w01-ec01, tunnel endpoint MTU 9000, form factor Medium.*

![Add Node management settings with a successful gateway ping](/images/lab/lab-S170.jpg)
*Node 1 management settings, with the management gateway ping succeeded.*

![Add Node uplink mapping and TEP VLAN](/images/lab/lab-S171.jpg)
*Node 1 uplink mapping, TEP VLAN and TEP IP pool.*

Four details are worth knowing:

-> **Ping the management gateway in the wizard**: the management step tests the gateway and reports success. A failure there points to the port group, the VLAN or the gateway, so fix it before going further.

-> **Clone the second node**: the Add Node form has a Clone action that copies the first node's settings. The documentation says to change only the FQDN. In the lab I also set the management IP to .52 for the second Edge, since the clone carries the first node's address.

-> **Two TEP addresses per Edge**: each node took two (10.20.25.11 and .12 on the first), so the pool needs at least four addresses for two Edges. The range of ten leaves room for more.

-> **Let the MTU check pass**: the wizard validates the VLAN MTU against the tunnel endpoint MTU, which comes from the Global Fabric Settings. With the Edge TEP VLAN at 9000 end to end, the check passed.

![Empty Add Node form](/images/lab/lab-S230.jpg)
*The empty Add Node form, before the first node is filled in.*

![Edit Node form for the second Edge node](/images/lab/lab-S231.jpg)
*The second node after Clone: same port group, uplink mapping and TEP VLAN.*

![VLAN MTU check passed for supported hosts](/images/lab/lab-S233.jpg)
*The VLAN MTU check passed.*

## Deployment

After the last page the wizard deploys the Edge VMs from OVF, which shows up under Recent Tasks in vCenter. The whole workflow, including the Tier-0 and BGP steps that the next post covers, took from 22:23 to 22:43, and both Edge nodes showed Up at the end.

![vCenter tasks showing both Edge OVF deployments running](/images/lab/lab-S239.jpg)
*Both Edge OVF deployments running under vCenter tasks.*

## What to take from it

-> **Create the port group and the pool first**: the wizard assumes both already exist.

-> **Use a static pool when the TEP VLAN has no DHCP**: the same lesson as the host TEPs, one layer up.

-> **Size the pool for growth**: four addresses for two nodes is the minimum, and a pool of ten leaves room for another Edge pair.

-> **Keep a VLAN table**: with host TEPs, Edge TEPs, management and two uplinks, a one-line table per VLAN prevents mix-ups.

## What's Next

Next in this series: the Tier-0 active/standby gateway and eBGP to the lab router, verified from both sides.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [VPC centralized network connectivity with guided Edge deployment (VMware Cloud Foundation blog)](https://blogs.vmware.com/cloud-foundation/2025/06/25/vpc-centralized-network-connectivity-with-guided-edge-deployment/)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
