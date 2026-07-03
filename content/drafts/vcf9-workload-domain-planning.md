---
title: "VCF 9 Workload Domain Planning and Deployment"
date: 2026-07-06
draft: true
tags: ["VCF", "VMware", "Workload Domain", "NSX", "vSAN", "Cloud Foundation"]
categories: ["VCF 9", "Deployment"]
description: "A practical guide to planning, designing, and deploying VCF 9 workload domains using VCF Operations, validated against official Broadcom documentation, including deployment options, storage choices, and VPC-ready networking."
---

## Introduction

With the VCF 9 management domain up and running, the next step in your private cloud journey is creating workload domains. A workload domain groups ESX hosts under a dedicated vCenter instance, along with NSX networking and storage, so it can host tenant or departmental workloads. Depending on how you configure NSX connectivity during creation, a workload domain can become VPC-ready either immediately or after a short follow-up step — more on that below.

## Three Ways to Create a Workload Domain

Per VCF Operations' Workload Domain wizard, there are three supported paths:

- **Full deployment with cluster** — deploys a fully provisioned workload domain with an initial vSphere cluster. Requires ESX hosts already commissioned with the target principal storage type.
- **Domain infrastructure only** — deploys and configures a new vCenter instance and a new-or-shared NSX Manager instance, without requiring any unassigned ESX hosts. You add a vSphere cluster to it later.
- **Import an existing vCenter** — brings an already-running vCenter and its managed ESX hosts under VCF as a workload domain, so it's included in centralized identity, certificate, and lifecycle management.

## Architectural Overview

The diagram below illustrates the relationship between the VCF 9 management domain, VCF Operations, and multiple workload domains, including VPC-based networking topology:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│ VCF 9 - Workload Domain Architecture │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────────────┐
│ VCF Operations (Management Plane) │
│ │
│ ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ │
│ │ Fleet Mgmt │ │ Lifecycle Mgmt │ │ Cost & Capacity │ │
│ │ (All Domains) │ │ (All Components)│ │ Management │ │
│ └──────────────────┘ └──────────────────┘ └──────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
│
┌──────────────────────────────┼──────────────────────────────┐
│ │ │
▼ ▼ ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
│ Management Domain │ │ Workload Domain A │ │ Workload Domain B │
│ │ │ │ │ │
│ vCenter (Mgmt) │ │ vCenter (WLD-A) │ │ vCenter (WLD-B) │
│ NSX 9.x (Mgmt) │ │ NSX 9.x (shared or │ │ NSX 9.x (shared or │
│ vSAN (Mgmt) │ │ dedicated) │ │ dedicated) │
│ │ │ vSAN / NFS / FC │ │ vSAN / NFS / FC │
│ ┌───────────────┐ │ │ ┌───────────────┐ │ │ ┌───────────────┐ │
│ │ Management │ │ │ │ VPC / Tenant│ │ │ │ VPC / Tenant│ │
│ │ VMs only │ │ │ │ Workloads │ │ │ │ Workloads │ │
│ └───────────────┘ │ │ └───────────────┘ │ │ └───────────────┘ │
└─────────────────────┘ └─────────────────────┘ └─────────────────────┘

NSX VPC Networking (Per Workload Domain)
┌───────────────────────────────────────┐
│ │
│ Transit Gateway (Centralized or │
│ Distributed connectivity) │
│ ┌────────────┐ ┌────────────┐ │
│ │ VPC-1 │ │ VPC-2 │ │
│ │ (Tenant A) │ │ (Tenant B) │ │
│ │ Subnet 1 │ │ Subnet 1 │ │
│ │ Subnet 2 │ │ Subnet 2 │ │
│ └────────────┘ └────────────┘ │
│ │ │ │
│ └───────┬───────┘ │
│ │ │
│ External Uplink │
│ (via NSX Edge North-South) │
└───────────────────────────────────────┘

Physical Infrastructure (Per Workload Domain)
┌───────────────────────────────────────────────────┐
│ ESX Hosts (min. 3 for vSAN ESA) │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │ ESX-1 │ │ ESX-2 │ │ ESX-3 │ [+more] │
│ │NVMe/SSD │ │NVMe/SSD │ │NVMe/SSD │ │
│ │NSX(EDP) │ │NSX(EDP) │ │NSX(EDP) │ │
│ └─────────┘ └─────────┘ └─────────┘ │
│ │
│ Networks: Mgmt | vMotion | vSAN | NSX Overlay │
└───────────────────────────────────────────────────┘
```

## Workload Domain Planning Considerations

Before creating a workload domain in VCF 9, use the **VCF Planning and Preparation Workbook** to document all design decisions. Key areas to plan:

### Compute Sizing

- Minimum of 3 ESX hosts for a vSAN ESA workload domain
- Size CPU and RAM based on the expected VM density and workload type (compute-intensive, memory-intensive, or mixed)
- Account for ESX host management overhead and vSAN overhead when calculating usable capacity
- For high availability, plan for N+1 host capacity so one host can fail without a performance hit

### Storage Design

A workload domain can be built on one of four principal storage types, selected during the wizard's Storage step:

- **vSAN** — either ESA (the current recommended architecture) or OSA; requires SSD or NVMe disks free of pre-existing partitions
- **NFS** — an external NFS datastore, identified by server IP and export path
- **VMFS on FC** — Fibre Channel-backed VMFS datastore
- **vVols** — supported for compatibility, but Broadcom has marked vVols as deprecated as of VCF/vSphere Foundation 9.0, with removal planned in a future release; new designs should avoid it

### Networking Design

| Network Segment | Purpose | Configuration Notes |
|----------------|---------|-------------------|
| Management VLAN | ESX management, vCenter | Must be reachable from VCF Operations |
| vMotion VLAN | Live VM migration | Dedicated VLAN for performance isolation |
| vSAN VLAN | Storage traffic | Dedicated VLAN, jumbo frames recommended |
| NSX Overlay (Host TEP) | Tenant Geneve-encapsulated traffic | Needs a static IP pool or DHCP scope |
| NSX Edge Uplink | North-south routing to physical network | Dedicated VLANs for T0 connectivity |

### NSX and VPC Planning

Every workload domain needs an NSX Manager, which can either be a new dedicated instance or a shared instance already used by another domain (subject to version-compatibility rules between the shared NSX Manager and each domain's vCenter version). When configuring VPC Gateway Connectivity during creation, you choose between:

- **Centralized Connectivity** — simpler to set up, but the domain becomes VPC-ready only after you separately deploy an NSX Edge cluster with a Tier-0 gateway afterward
- **Distributed Connectivity** — requires a dedicated VLAN, gateway CIDR, and external/private IP blocks up front, but the workload domain is VPC-ready immediately after creation

## Deploying a Workload Domain via VCF Operations

### Step 1: Commission ESX Hosts

Before creating a full-deployment workload domain, commission the target ESX hosts (skip this if you're using the "domain infrastructure only" or "import existing vCenter" paths):

1. In VCF Operations, commission hosts with the correct target principal storage type
2. VCF Operations validates host connectivity, DNS, NTP, and hardware compliance
3. Hosts move to an unassigned state once commissioned, ready to be selected during workload domain creation

### Step 2: Create the Workload Domain

1. In VCF Operations, click **Operate** in the top navigation bar, then in the left pane select **Overview → Inventory**
2. Expand **VCF Instances** and select the instance where you're creating the domain
3. From the **Add workload domain** drop-down, choose **Create new**, review prerequisites, and proceed
4. Work through the wizard: General Information → vCenter → Cluster → Image → Networking (NSX) → Storage → Hosts → vSphere Distributed Switch → vSphere Supervisor (optional) → Finish
5. VCF Operations performs pre-deployment validation, then orchestrates the full domain bringup
6. Track progress under **Fleet Management → Tasks**

### Step 3: Post-Creation VPC Setup

If you chose Centralized Connectivity, complete VPC-readiness by deploying an NSX Edge cluster with an active-standby Tier-0 gateway. If you chose Distributed Connectivity, the domain is already VPC-ready — proceed straight to creating VPCs, subnets, and Transit Gateway connectivity for each tenant or application team.

## Day-2 Workload Domain Operations

VCF Operations provides built-in automation for common Day-2 operations, and VCF 9.1 adds guardrails so that certain out-of-band changes (made outside the VCF Operations UI, such as expanding a cluster or changing primary storage directly in vCenter) no longer create unresolvable configuration drift:

- **Cluster expansion/contraction:** Add or remove ESX hosts from an existing cluster via VCF Operations
- **Host remediation:** Apply ESX updates, patches, or desired-state images across the cluster using vSphere Lifecycle Manager images
- **Certificate rotation:** Automate certificate lifecycle for all workload domain components from VCF Operations
- **License management:** Track and submit VCF and vSAN license usage periodically directly from VCF Operations

## Sources

Validated against Broadcom's official VCF 9.1 documentation: [Building Cloud Infrastructure](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure.html), [Managing VCF Domains](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/working-with-workload-domains.html), and [Create a New Workload Domain](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/working-with-workload-domains/deploy-a-vi-workload-domain-using-the-sddc-manager-ui.html).

## What's Next

In the next post, we will do a deep dive into VCF 9 NSX VPC networking, covering Transit Gateway design, VPC consumption from vCenter, and practical examples of deploying application workloads using VPC-based isolation.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
