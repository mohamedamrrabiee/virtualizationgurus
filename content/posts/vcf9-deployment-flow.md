---
title: "VCF 9 Deployment Flow: From Planning to a Running Management Domain"
date: 2026-06-22
draft: false
tags: ["VCF", "VMware", "Deployment", "SDDC Manager", "Cloud Foundation"]
categories: ["VCF 9", "Deployment"]
description: "Step-by-step walkthrough of the VCF 9 deployment process, covering prerequisites, the VCF Installer workflow, and initial management domain bringup."
---

## Introduction

Deploying VMware Cloud Foundation 9 is a structured process that, when followed correctly, results in a fully configured SDDC in a matter of hours. This guide walks through the complete deployment flow from planning through a functional management domain.

> **Note:** VCF 9 replaces the Cloud Builder appliance used in VCF 5.x with the new **VCF Installer** — a streamlined, web-based deployment tool that handles management domain bringup without the need for a separate appliance OVA.

## Deployment Flow Overview

The following diagram illustrates the end-to-end VCF 9 deployment flow, from initial planning through a running management domain:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VCF 9 Deployment Flow                                │
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
  │  3. Launch       │
  │  VCF Installer   │◄─── New in VCF 9
  │  (Web UI / CLI)  │     (replaces Cloud Builder)
  └────────┬─────────┘
           │
           ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                 4. Pre-deployment Validation                  │
  │  DNS ✓  |  Network ✓  |  NTP ✓  |  Hardware HCL ✓           │
  └────────────────────────────┬─────────────────────────────────┘
                               │
           ┌────────────────────────────────────┐
           │    5. Management Domain Bringup     │
           └────────────────────────────────────┘
                               │
        ┌──────────┬───────────┼────────────┬───────────┐
        ▼          ▼           ▼            ▼           ▼
  ┌──────────┐ ┌────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐
  │  Phase 1 │ │Phase 2 │ │Phase 3 │ │ Phase 4  │ │ Phase 5  │
  │  ESXi    │ │ vSAN   │ │vCenter │ │   NSX    │ │  SDDC    │
  │  Config  │ │Cluster │ │Deploy  │ │  Deploy  │ │ Manager  │
  │ 15-20min │ │20-30min│ │30-45min│ │ 45-60min │ │ 20-30min │
  └──────────┘ └────────┘ └────────┘ └──────────┘ └──────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │              6. Post-Deployment Validation                    │
  │   SDDC Manager UI  |  NSX Status  |  vSAN Health             │
  └──────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before starting the deployment, ensure you have the following in place:

### Hardware Requirements

- **Minimum hosts:** 3 physical hosts for management domain (4 recommended for production)
- **CPU:** Intel or AMD processors with VT-x and VT-d support
- **RAM:** Minimum 512 GB per host for production workloads
- **Storage:** NVMe SSDs required for vSAN ESA (minimum 2x cache + 2x capacity per host)
- **Networking:** 10 GbE minimum, 25 GbE recommended; 2 uplinks per host

### Network Prerequisites

| Network | Purpose | Recommended VLAN |
|---------|---------|-----------------|
| Management | ESXi management, vCenter | Dedicated VLAN |
| vMotion | Live migration traffic | Dedicated VLAN |
| vSAN | Storage traffic | Dedicated VLAN |
| NSX Overlay | Geneve-encapsulated workload traffic | Trunk |
| NSX Edge Uplink | North-south routing | Dedicated VLANs |

### DNS and NTP

All FQDNs must be resolvable before starting deployment:

- SDDC Manager FQDN
- vCenter Server FQDN
- NSX Manager FQDN (and 3x NSX Manager cluster FQDNs)
- ESXi host FQDNs for all management domain hosts
- NTP server reachable from all hosts

## Step 1: Prepare the Deployment JSON

In VCF 9, the Excel-based deployment parameter workbook used in VCF 5.x has been replaced by a **JSON-based deployment specification**. You can generate and validate this file using the VCF Installer UI or CLI tooling.

Fill in all required fields:

- Management network parameters: IP addresses, subnet masks, gateway, DNS servers
- Host credentials: Root password for all ESXi hosts
- License keys: vSphere, vSAN, NSX, and SDDC Manager licenses
- DNS entries: Pre-populate all required DNS records before running the validation

## Step 2: Launch the VCF Installer

VCF 9 introduces the **VCF Installer** as the successor to Cloud Builder. Unlike Cloud Builder, which was a separate OVA appliance, the VCF Installer is:

- A lightweight, web-based deployment tool
- Available as part of the VCF 9 download bundle
- Runnable directly on a jump host or management workstation (no separate OVA deployment required)

```bash
# VCF Installer is launched directly - no OVA deployment needed.
# Access the VCF Installer UI at:
# https://<vcf-installer-host>:9090/

# Key difference from VCF 5.x Cloud Builder:
# - No separate appliance VM to deploy
# - Installer runs as a containerized service on your jump host
# - Same pre-deployment checks, streamlined UX
```

Once launched, access the VCF Installer UI and log in with your admin credentials.

## Step 3: Import and Validate the Deployment JSON

In the VCF Installer:

1. Navigate to **Workflow -> Deploy VMware Cloud Foundation**
2. Upload your completed deployment JSON specification
3. Click **Validate** -- the VCF Installer will perform over 200 pre-deployment checks including:
   - DNS resolution for all FQDNs
   - Network connectivity between hosts
   - NTP synchronization
   - Host hardware compatibility
   - License key validity

> **Tip:** Address all validation failures before proceeding. Common issues include DNS TTL problems and NTP drift. The VCF Installer will clearly indicate which checks failed and why.

## Step 4: Initiate Management Domain Bringup

Once validation passes (all green), click **Deploy** to begin the management domain bringup. The process includes:

### Phase 1: ESXi Configuration (15-20 min)
- Configures vSwitches and port groups on all hosts
- Sets NTP and DNS configuration
- Enables vSAN on all management hosts

### Phase 2: vSAN Cluster Formation (20-30 min)
- Creates vSAN cluster
- Formats and initializes disks
- Configures vSAN storage policies
- ESA initialization takes slightly longer than OSA due to additional format steps

### Phase 3: vCenter Deployment (30-45 min)
- Deploys vCenter Server appliance to vSAN datastore
- Configures vCenter inventory (datacenter, cluster, hosts)
- Applies DRS and HA settings

### Phase 4: NSX Deployment (45-60 min)
- Deploys 3-node NSX Manager cluster (for production) or single node (for lab)
- Configures transport zones
- Deploys NSX agents on all hosts
- Configures VTEP pool and host transport nodes

### Phase 5: SDDC Manager Deployment (20-30 min)
- Deploys SDDC Manager appliance
- Imports management domain inventory
- Configures initial license assignments
- Enables Lifecycle Manager

## Step 5: Post-Deployment Validation

After the VCF Installer reports successful completion:

1. Log in to **SDDC Manager** at `https://<sddc-manager-fqdn>/`
2. **Verify inventory:** All hosts should show as ACTIVE under the management domain
3. **Check NSX status:** Navigate to NSX Manager and confirm all transport nodes show as Up
4. **Validate vSAN health:** In vCenter, check vSAN health under the cluster -- all checks should be green
5. **Run SDDC Manager health check:** Under Developer Center -> API Explorer, run the health API to get a comprehensive system status report

## Common Deployment Issues and Fixes

### vSAN Disk Claim Failures

If vSAN fails to claim disks during Phase 2, verify:

- Disks are not presenting existing partition tables (wipe with `esxcli storage core device partition delete`)
- NVMe disks meet the ESA compatibility requirements (check HCL)

### NSX Manager Deployment Timeout

If NSX Manager deployment times out:

- Check vSAN health -- insufficient capacity is the most common cause
- Verify the NSX Manager FQDN resolves correctly from the VCF Installer host

## Up Next

Now that your management domain is running, the next logical step is creating your first workload domain. In the next post, we will cover workload domain planning, network design for NSX segments, and automated workload domain deployment using the SDDC Manager API.
