---
title: "VCF 9 Deployment Flow: From Planning to a Running Management Domain"
date: 2026-06-22
draft: false
tags: ["VCF", "VMware", "Deployment", "VCF Installer", "Cloud Foundation"]
categories: ["VCF 9", "Deployment"]
description: "Step-by-step walkthrough of the VCF 9 deployment process, covering prerequisites, the VCF Installer virtual appliance workflow, and initial management domain bringup."
---

## Introduction

Deploying VMware Cloud Foundation 9 is a structured process that, when followed correctly, results in a fully configured SDDC in a matter of hours. This guide walks through the complete deployment flow from planning through a functional management domain.

> **Note:** VCF 9 replaces the Cloud Builder appliance used in VCF 5.x with the new **VCF Installer** — a new virtual appliance downloaded from the Broadcom Support portal that provides automated deployment and configuration workflows for the VCF environment. Unlike Cloud Builder which was a single-purpose OVA, the VCF Installer also supports VCF Converge (bringing existing vSphere infrastructure into VCF) and downloading/staging all required VCF component binaries.

## Deployment Flow Overview

The following diagram illustrates the end-to-end VCF 9 deployment flow, from initial planning through a running management domain:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         VCF 9 Deployment Flow                           │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  1. Planning &   │
│  Prerequisites   │
│  - Hardware      │
│  - Network/DNS   │
│  - NTP           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  2. Prepare      │
│  Deployment JSON │
│  (replaces Excel │
│   workbook)      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  3. Deploy VCF   │
│  Installer OVA   │◄─── New in VCF 9
│  (virtual appl.) │     (replaces Cloud Builder OVA)
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│              4. Pre-deployment Validation                     │
│   DNS ✓ | Network ✓ | NTP ✓ | Hardware HCL ✓                │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────────────┐
│    5. Management Domain Bringup    │
└────────────────────────────────────┘
                │
    ┌──────────┬───────────┼────────────┬───────────┐
    ▼          ▼           ▼            ▼           ▼
┌──────────┐ ┌────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐
│ Phase 1  │ │Phase 2 │ │Phase 3 │ │ Phase 4  │ │ Phase 5  │
│ ESX      │ │ vSAN   │ │vCenter │ │  NSX 9.0 │ │VCF Ops / │
│ Config   │ │Cluster │ │Deploy  │ │  Deploy  │ │VCF Mgmt  │
│ 15-20min │ │20-30min│ │30-45min│ │ 45-60min │ │ 20-30min │
└──────────┘ └────────┘ └────────┘ └──────────┘ └──────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│              6. Post-Deployment Validation                    │
│  VCF Operations UI | NSX 9.0 Status | vSAN Health            │
└──────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before starting the deployment, ensure you have the following in place:

### Hardware Requirements

- **Minimum hosts:** 3 physical ESX hosts for management domain (production deployments should plan according to workload requirements; see the VCF Planning and Preparation Workbook for sizing guidance)
- **CPU:** Intel or AMD processors with VT-x and VT-d support; VCF 9 requires a minimum of 16 cores per CPU for ESX 9.0 licensing
- **RAM:** Size according to management workload requirements; management VMs (vCenter, NSX Manager, VCF Operations) require dedicated resources
- **Storage:** NVMe SSDs required for vSAN ESA (check the Broadcom Compatibility Guide for ESA-certified NVMe drives)
- **Networking:** 10 GbE minimum, 25 GbE recommended; 2 uplinks per host

> **Important:** Always cross-reference hardware against the [Broadcom Compatibility Guide](https://compatibilityguide.broadcom.com/) for ESX 9.0 HCL compliance before purchasing.

### Network Prerequisites

| Network | Purpose | Recommended VLAN |
|---------|---------|-----------------|
| Management | ESX management, vCenter, VCF Ops | Dedicated VLAN |
| vMotion | Live migration traffic | Dedicated VLAN |
| vSAN | Storage traffic | Dedicated VLAN |
| NSX Overlay | Geneve-encapsulated workload traffic | Trunk |
| NSX Edge Uplink | North-south routing | Dedicated VLANs |

### DNS and NTP

All FQDNs must be resolvable (forward and reverse DNS) before starting deployment:

- VCF Installer FQDN
- vCenter Server FQDN
- NSX Manager FQDN (and optional 3x NSX Manager cluster FQDNs for HA)
- ESX host FQDNs for all management domain hosts
- NTP server reachable from all hosts and management VMs

## Step 1: Download and Deploy the VCF Installer

VCF 9 introduces the **VCF Installer** as the successor to Cloud Builder. The VCF Installer is:

- A **virtual appliance (OVA)** downloaded from the Broadcom Support portal
- Deployed to an existing ESX host or vCenter instance that is separate from your VCF management domain target hosts
- Part of the VCF SDK (with Python and Java bindings), integrated with PowerCLI, and provides a comprehensive OpenAPI 3.0 specification
- Capable of deploying new VCF environments, converging existing vSphere infrastructure to VCF, and downloading all necessary install binaries

```bash
# VCF Installer deployment workflow:
# 1. Download VCF Installer OVA from Broadcom Support portal
# 2. Deploy OVA to an existing ESX/vCenter host (NOT the target management domain hosts)
# 3. Power on the VCF Installer appliance
# 4. Access the VCF Installer UI at:
#    https://<vcf-installer-appliance-fqdn>/

# Key differences from VCF 5.x Cloud Builder:
# - Both are OVA virtual appliances, but VCF Installer supports Converge workflows
# - VCF Installer integrates with VCF SDK for automation
# - Deployment JSON replaces the Excel-based deployment parameter workbook
```

Once deployed, access the VCF Installer UI and log in with your admin credentials.

## Step 2: Prepare the Deployment JSON

In VCF 9, the Excel-based deployment parameter workbook used in VCF 5.x has been replaced by a **JSON-based deployment specification**. Use the **VCF Planning and Preparation Workbook** (available from the VCF documentation portal) to gather all required parameters, then use the VCF Installer UI or CLI to generate and validate the deployment JSON.

Fill in all required fields:

- Management network parameters: IP addresses, subnet masks, gateway, DNS servers
- Host credentials: Root password for all ESX hosts
- License keys: VCF and vSAN licenses (VCF 9 uses 2 license types instead of 11 in older releases)
- DNS entries: Pre-populate all required DNS records (forward and reverse) before running the validation

## Step 3: Import and Validate the Deployment JSON

In the VCF Installer:

1. Navigate to **Workflow → Deploy VMware Cloud Foundation**
2. Upload your completed deployment JSON specification
3. Click **Validate** — the VCF Installer will perform over 200 pre-deployment checks including:
   - DNS resolution (forward and reverse) for all FQDNs
   - Network connectivity between hosts
   - NTP synchronization
   - Host hardware compatibility (HCL check)
   - License key validity

> **Tip:** Address all validation failures before proceeding. Common issues include missing reverse DNS entries and NTP drift between hosts. The VCF Installer clearly indicates which checks failed and why.

## Step 4: Initiate Management Domain Bringup

Once validation passes (all green), click **Deploy** to begin the management domain bringup. The process includes:

### Phase 1: ESX Configuration (15-20 min)
- Configures vSwitches and port groups on all hosts
- Sets NTP and DNS configuration
- Prepares hosts for vSAN cluster formation

### Phase 2: vSAN Cluster Formation (20-30 min)
- Creates vSAN ESA cluster
- Formats and initializes NVMe disks for ESA
- Configures vSAN storage policies
- ESA initialization includes hardware-level format steps specific to NVMe-native operation

### Phase 3: vCenter Deployment (30-45 min)
- Deploys vCenter Server 9.0 appliance to vSAN datastore
- Configures vCenter inventory (datacenter, cluster, hosts)
- Applies DRS and HA settings

### Phase 4: NSX 9.0 Deployment (45-60 min)
- Deploys NSX Manager (3-node cluster for production HA, or single node for resource-constrained/lab environments)
- Configures transport zones and host switch profiles
- NSX VIBs are already bundled with ESX 9.0 — no separate VIB installation is required
- Configures VTEP pool and host transport nodes
- Enhanced Data Path (EDP) Standard is configured as the default host switch mode for new VCF installations

### Phase 5: VCF Operations and Management Domain Registration (20-30 min)
- Deploys VCF Operations (formerly SDDC Manager) appliance
- Imports and registers management domain inventory
- Configures initial license assignments (VCF 9 uses 2 license types: "VMware Cloud Foundation (cores)" and "VMware vSAN (TiBs)")
- Enables fleet management, lifecycle management, and cost/capacity visibility

## Step 5: Post-Deployment Validation

After the VCF Installer reports successful completion:

1. Log in to **VCF Operations** at `https://<vcf-operations-fqdn>/`
2. **Verify inventory:** All ESX hosts should show as ACTIVE under the management domain
3. **Check NSX 9.0 status:** Navigate to NSX Manager and confirm all transport nodes show as Up; verify EDP Standard mode is active
4. **Validate vSAN health:** In vCenter, check vSAN health under the cluster — all checks should be green; verify ESA disk groups are formed correctly
5. **Run VCF Operations health check:** From VCF Operations, review system health across all management domain components
6. **Verify licensing:** Confirm VCF and vSAN licenses are applied and usage is being tracked; note that license usage must be submitted from VCF Operations every 180 days

## Common Deployment Issues and Fixes

### vSAN Disk Claim Failures

If vSAN ESA fails to claim disks during Phase 2, verify:

- Disks are not presenting existing partition tables (wipe with `esxcli storage core device partition delete`)
- NVMe disks are certified for vSAN ESA (check the Broadcom Compatibility Guide — ESA requires specific NVMe certification)
- All ESA-required NVMe disks are visible and healthy in ESX

### NSX Manager Deployment Timeout

If NSX Manager deployment times out:

- Check vSAN health — insufficient capacity is the most common cause
- Verify the NSX Manager FQDN resolves correctly (including reverse DNS) from the VCF Installer appliance
- Ensure the management network has connectivity to all target hosts

### License Validation Failures

VCF 9 uses a new licensing model. If license validation fails:

- Confirm you are using VCF 9-compatible licenses (2 license types: VCF cores and vSAN TiB)
- Pre-version 9 licenses are supported during upgrades but new deployments require VCF 9 licenses
- VCF Operations can operate in disconnected mode if the environment has no internet access

## Up Next

Now that your management domain is running, the next logical step is creating your first workload domain. In the next post, we will cover workload domain planning, VPC-based network design, and automated workload domain deployment using the VCF Operations API.


<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
