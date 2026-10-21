---
title: "Designing a Nested VCF 9.1.1 Lab: Names, VLANs and Decisions"
date: 2026-10-21
draft: true
tags: ["VCF", "VMware", "Lab", "Design", "Nested"]
categories: ["VCF 9", "Lab Series"]
labPart: 1
cover:
  image: "/images/covers/lab-designing-nested-vcf-lab.jpg"
  alt: "Designing a Nested VCF 9.1.1 Lab: Names, VLANs and Decisions"
  relative: false
description: "The design behind a hands-on VCF 9.1.1 lab built end to end: naming convention, VLAN and subnet plan, host sizing, and the decisions that shaped the management and workload domains before a single appliance was deployed."
---

## Overview

This is the first post in a hands-on series that builds a VCF 9.1.1 environment from empty hosts to a working Supervisor, with the real issues and fixes along the way. Before any appliance gets deployed, the lab needs a design. Names, VLANs, subnets and sizing are the decisions that are cheapest to make on paper and most expensive to change once the VCF Installer has certificates, thumbprints and DNS records baked into a deployment spec.

The lab is a nested environment: seven nested ESX 9.1.1 hosts, a lab router and a jump host, and nothing else configured. Everything else in this series is built on top of that starting point.

## What the lab builds

The target is a VCF 9.1.1 fleet with two domains:

-> **Management domain (m01)**: four hosts on vSAN ESA, vCenter, SDDC Manager, a three-node NSX cluster (Medium), a two-node VCF Operations deployment with a cloud proxy, and VCF Management Services in `small_ha` mode.

-> **Workload domain (w01)**: three hosts on vSAN ESA with their own vCenter, an isolated SSO domain and their own three-node NSX cluster, using a centralized connectivity VPC design.

-> **Services around it**: a lab router (gateway, DNS, NTP, BGP) and an Ubuntu jump host that carries PowerShell, the offline depot and, later, the identity provider.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-designing-nested-vcf-lab.svg"></object>
</div>

## Naming convention

A VCF deployment spec asks for a host name for nearly every component, and the installer builds certificates and DNS expectations from them. A predictable pattern pays off every time you read a log line or a validation error.

The pattern used throughout the series is `<instance>-<domain>-<component><nn>.vgurus.lab`:

| Component | Management (m01) | Workload (w01) |
|---|---|---|
| ESX hosts | `vg1-m01-esx01` to `esx04` | `vg1-w01-esx01` to `esx03` |
| vCenter | `vg1-m01-vc01` | `vg1-w01-vc01` |
| NSX VIP and managers | `vg1-m01-nsx01`, `nsx01a` to `c` | `vg1-w01-nsx01`, `nsx01a` to `c` |
| SDDC Manager | `vg1-m01-sddc01` | n/a |
| VCF Operations | `vg1-m01-ops01`, `ops01a`, `ops01b`, cloud proxy `opscp01` | n/a |
| Cluster, datacenter | `vg1-m01-cl01`, `vg1-m01-dc01` | `vg1-w01-cl01`, `vg1-w01-dc01` |
| Network pool | `vg1-m01-np01` | `vg1-w01-np01` |

-> **Instance (`vg1`)**: matches the VCF instance name, so the first token in any name tells you which fleet member you are looking at.

-> **Domain (`m01`, `w01`)**: matches the domain name in SDDC Manager, which keeps host names, cluster names and network pools aligned with what the UI shows.

-> **Short name plus domain, never the full FQDN as the host name**: this one is easy to get wrong on the ESX side and it breaks certificates later. The next post covers it.

## VLAN and subnet plan

Every VLAN has its own /24 inside `10.20.0.0/16`, with the third octet grouping the purpose. Keeping the VLAN ID and the subnet in one table makes the planning workbook and the NSX uplink profiles easy to cross-check.

| VLAN | Network | Subnet | MTU |
|---|---|---|---|
| 3321 | VM Management | 10.20.10.0/24 | 1500 |
| 3322 | ESX Management | 10.20.11.0/24 | 1500 |
| 3323 | m01 vMotion | 10.20.12.0/24 | 9000 |
| 3324 | m01 vSAN | 10.20.13.0/24 | 9000 |
| 3325 | m01 host TEP | 10.20.14.0/24 | 9000 |
| 3333 | VCF Management (VCF Management Services, VCF Operations) | 10.20.99.0/24 | 1500 |
| 3332 | m01 VPC gateway connectivity | 10.20.98.0/24 | 1500 |
| 3326 | w01 vMotion | 10.20.22.0/24 | 9000 |
| 3327 | w01 vSAN | 10.20.23.0/24 | 9000 |
| 3328 | w01 host TEP | 10.20.24.0/24 | 9000 |

Edge TEPs and the BGP uplinks get their own VLANs later in the series, once the Edge cluster is built. Overlay and VPC address space (`10.80.0.0/22`, `172.16.0.0/16`, `172.20.0.0/16`) is kept completely outside the `10.20.0.0/16` underlay, so a route on the lab router can never be confused with a lab VLAN.

## Host sizing

The two domains are sized differently on purpose.

-> **m01 hosts**: 16 vCPU, 160 GiB memory and two 1 TiB virtual NVMe disks each. The management domain carries vCenter, SDDC Manager, a three-node NSX cluster, VCF Operations and VCF Management Services, and the later w01 NSX nodes also run here.

-> **w01 hosts**: 8 vCPU, 80 GiB memory and two 512 GiB virtual NVMe disks each. Enough for a Supervisor, a VKS cluster and a handful of test VMs.

Nested virtual NVMe disks are not on the vSAN ESA HCL. The lab handles that with explicit spec settings and installer switches, covered in the bring-up posts.

## Decisions that shaped the build

-> **Four hosts in m01, three in w01**: the management domain carries the whole VCF management stack plus the w01 NSX nodes, so it gets the larger cluster. The workload domain only needs to host the Supervisor, VKS and test workloads.

-> **VCF Installer outside the management domain**: with vSAN ESA, the m01 hosts have no datastore before bring-up and their NVMe disks must stay blank. The installer therefore runs on a temporary datastore on a w01 host and is removed afterwards. Post 3 covers this.

-> **Isolated SSO for w01**: the workload domain gets its own vCenter and its own `vsphere.local` domain. VCF SSO with an external identity provider and vCenter linking come later, so one vSphere Client can see both domains.

-> **Centralized connectivity for w01 VPCs**: Edge nodes and a Tier-0 gateway peer with the lab router over eBGP, which makes north-south traffic and VPC reachability something you can verify from both sides.

-> **Static host TEP pool for w01**: the workload domain wizard defaults to DHCP for host TEPs. That did not work in this lab and a static pool replaced it, which is why the plan above reserves a pool range for it.

## Pre-flight checklist

-> **DNS**: forward and reverse records for every name in the table above, before the installer runs.

-> **NTP**: all seven hosts pointed at the lab router, service running and set to start with the host.

-> **Routing and MTU**: every gateway (`.1`) answers, and jumbo frames pass between hosts once the vSAN and TEP interfaces exist (`vmkping -d -s 8972`).

-> **Certificates**: regenerated on every host after the host name and domain are set correctly, before thumbprints are captured.

## What's Next

Next in this series: Preparing nested ESX hosts, certificates and thumbprints done right.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 Planning and Preparation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/planning-and-preparation.html)
- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
