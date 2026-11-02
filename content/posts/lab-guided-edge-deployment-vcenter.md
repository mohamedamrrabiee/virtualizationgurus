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

## Prerequisites to create first

-> **A VM management port group on the w01 VDS**: the default switch profile created during the workload domain deployment has no port group for Edge management. I created `vg1-w01-cl01-vds-01-pg-vmmgmt` on VLAN 3321 before opening the wizard.

-> **A static IP pool for the Edge TEPs**: the TEP VLAN has no DHCP, so the Edge TEPs need a pool. In NSX Manager I created `vg1-w01-ippool-edgetep`, 10.20.25.11 to 10.20.25.20 on 10.20.25.0/24 with gateway .1.

<!-- TODO screenshots after masking: S225 (new port group, VLAN 3321), S219 (Edge TEP pool range), S220 (host TEP pool and Edge TEP pool, both Success) -->

The VLANs involved, so the numbers do not get mixed up:

| VLAN | Purpose |
|---|---|
| 3321 | Edge management (VM management port group) |
| 3328 | Host TEPs |
| 3329 | Edge TEPs |

The Edge uplink VLANs are covered in the BGP post that follows this one.

## The wizard

The wizard opens from the vSphere Client under Networking, on the Transit Gateway tab, with Centralized Connection as the connectivity type. The Edge cluster part of it asks for a node at a time.

| Setting | Value used |
|---|---|
| Connectivity type | Centralized Connection |
| Edge cluster | `vg1-w01-ec01`, two nodes, size Medium |
| Tunnel endpoint MTU | 9000 |
| Node 1 | `vg1-w01-en01`, management 10.20.10.51 |
| Node 2 | `vg1-w01-en02`, management 10.20.10.52 |
| Management network | The VM management port group, VLAN 3321 |
| Edge TEP | VLAN 3329, addresses from the static pool |
| Uplink mapping | uplink-1 to fp-eth0 (vmnic0 active, vmnic1 standby), uplink-2 to fp-eth1 (vmnic1 active, vmnic0 standby) |

The resulting Edge TEP addresses were 10.20.25.11 and .12 on the first node, and .13 and .14 on the second.

<!-- TODO screenshots after masking: S169 (Centralized Connection), S170 (node 1 management settings, gateway ping succeeded), S171 (uplink mapping and TEP VLAN 3329), S172 (Edge cluster, MTU 9000, Medium) -->

Four details are worth knowing:

-> **Ping the management gateway in the wizard**: the management step tests the gateway and reports success. A failure there points to the port group, the VLAN or the gateway, so fix it before going further.

-> **Clone the second node**: the Add Node form has a Clone action that copies the first node's settings. For the second Edge I cloned the first, then changed only the management IP and the TEP addresses.

-> **Two TEP addresses per Edge**: each node took two (10.20.25.11 and .12 on the first), so the pool needs at least four addresses for two Edges. The range of ten leaves room for more.

-> **Let the MTU check pass**: the wizard validates the VLAN MTU against the tunnel endpoint MTU. With the Edge TEP VLAN at 9000 end to end, the check passed.

<!-- TODO screenshots after masking: S230 (empty Add Node form), S231 (second node cloned, management IP .52), S232 (second node uplink mapping and TEP), S233 (VLAN MTU check passed) -->

## Deployment

After the last page the wizard deploys the Edge VMs from OVF, which shows up under Recent Tasks in vCenter. The whole workflow, including the Tier-0 and BGP steps that the next post covers, took from 22:23 to 22:43, and both Edge nodes showed Up at the end.

<!-- TODO screenshot after masking: S239 (vCenter tasks, Edge OVF deployments running) -->

## What to take from it

-> **Create the port group and the pool first**: the wizard assumes both already exist.

-> **Use a static pool when the TEP VLAN has no DHCP**: the same lesson as the host TEPs, one layer up.

-> **Size the pool for growth**: four addresses for two nodes is the minimum, and a pool of ten leaves room for another Edge pair.

-> **Keep a VLAN table**: with host TEPs, Edge TEPs, management and two uplinks, a one-line table per VLAN prevents mix-ups.

## What's Next

Next in this series: the Tier-0 active/standby gateway and eBGP to the lab router, verified from both sides.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
