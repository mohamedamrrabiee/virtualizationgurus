---
title: "Creating the Workload Domain from VCF Operations"
date: 2026-10-31
draft: true
tags: ["VCF", "VMware", "Lab", "Workload Domain", "VCF Operations", "NSX"]
categories: ["VCF 9", "Lab Series"]
labPart: 11
cover:
  image: "/images/covers/lab-creating-workload-domain.jpg"
  alt: "Creating the Workload Domain from VCF Operations"
  relative: false
description: "Creating a VCF 9.1.1 workload domain from VCF Operations in a nested lab: every wizard step with the values used, what the wizard does not let you set, and how long the deployment took."
---

## Overview

With three commissioned hosts waiting as unassigned, the workload domain (`w01`) is created from VCF Operations: Inventory, then the VCF instance, then Add Workload Domain, then Create New. This post lists every step with the values used in this lab and the wizard limits that matter, because three of them are not obvious until you hit them.

The deployment took about one hour 12 minutes, from 15:24 to 16:36, with no failures.

## The wizard, step by step

| Step | Setting used |
|---|---|
| General information | Name `w01`, full deployment with a cluster, vSphere Supervisor not enabled in the wizard, passwords entered manually |
| vCenter | `vg1-w01-vc01` (10.20.10.33), new isolated SSO domain `vsphere.local` |
| Cluster | `vg1-w01-cl01` |
| Image | The management domain ESX image (9.1.1), shared with m01 |
| NSX Manager | New three-node cluster, size Medium, VIP `vg1-w01-nsx01` (10.20.10.38), nodes 10.20.10.39 to .41 |
| VPC | Full Stack VPC with centralized connectivity, configured after deployment |
| Storage | vSAN ESA, vSAN HCI, auto-claim of HCL-incompatible disks |
| Hosts | `vg1-w01-esx01` to `esx03` |
| Distributed switch | Default profile `vg1-w01-cl01-vds-01`, two uplinks, TEP VLAN 3328 |

<!-- TODO screenshots after masking: S133 (general information), S135 (NSX Manager), S138 (VPC), S139 (storage), S140 (hosts), S145 (distributed switch), S148 (review) -->

## What the wizard does not let you set

-> **No datacenter name**: the datacenter is created as `<domain>-DC`, here `w01-DC`. It can be renamed afterwards, which the next post covers.

-> **Medium is the smallest NSX Manager size**: for a new workload domain the wizard offered Medium as the minimum. Three Medium appliances run on the management cluster, which is what the capacity check in the verification post was about.

-> **TEPs are DHCP only**: in the default distributed switch profile, the host TEP assignment is DHCP and the VLAN has to be typed. This lab's router has no DHCP on the TEP VLAN, so the hosts came up without usable TEP addresses. The fix is a static pool applied after deployment.

-> **Centralized connectivity comes later**: the VPC step only chooses the type. The transit gateway is configured after deployment from vSphere under Networking.

-> **An isolated SSO domain**: a new workload domain gets its own SSO domain, even if you type `vsphere.local` again. It is not joined to the management domain's SSO.

## Validate and deploy

The review step summarizes everything, then validation runs. All checks succeeded in this lab, and the deployment was started.

<!-- TODO screenshot after masking: S154 (validation, all checks succeeded) -->

The task appears in VCF Operations under Tasks as "Creating Workload Domain: w01", with the commissioning and bundle tasks listed earlier in the same view. SDDC Manager shows the subtasks underneath, and all of them completed successfully at 16:36.

<!-- TODO screenshots after masking: S156 (task running), S157 (SDDC Manager subtasks completed), S188 (VCF Operations task successful) -->

## What to take from it

-> **Decide the TEP addressing before the wizard**: if your TEP VLAN has no DHCP, plan the static pool now. It is a second job after deployment.

-> **Plan NSX Manager capacity on the management cluster**: three Medium appliances, plus the new vCenter, are added to the management domain.

-> **The datacenter name is a naming-convention decision**: the wizard will not take it, so the rename is part of the runbook.

-> **A clean run is possible on nested hardware**: once the hosts are commissioned, the workload domain deployment itself raised no critical issue here.

## What's Next

Next in this series: after the wizard, the static host TEP pool, the NSX agents that stayed down, and the datacenter rename.

## Further Reading (Official Broadcom Documentation)

- [Broadcom KB 316012: Renaming VCF SDDC manager objects](https://knowledge.broadcom.com/external/article/316012)
- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
