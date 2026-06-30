---
title: "VCF 9 Deployment Flow: From Planning to a Running Management Domain"
date: 2026-06-22
draft: false
tags: ["VCF", "VMware", "Deployment", "SDDC Manager", "Cloud Foundation"]
categories: ["VCF 9", "Deployment"]
description: "Step-by-step walkthrough of the VCF 9 deployment process, covering prerequisites, the Cloud Builder workflow, and initial management domain bringup."
---

## Introduction

Deploying VMware Cloud Foundation 9 is a structured process that, when followed correctly, results in a fully configured SDDC in a matter of hours. This guide walks through the complete deployment flow from planning through a functional management domain.

## Prerequisites

Before starting the deployment, ensure you have the following in place:

### Hardware Requirements

- **Minimum hosts**: 3 physical hosts for management domain (4 recommended for production)
- **CPU**: Intel or AMD processors with VT-x and VT-d support
- **RAM**: Minimum 512 GB per host for production workloads
- **Storage**: NVMe SSDs required for vSAN ESA (minimum 2x cache + 2x capacity per host)
- **Networking**: 10 GbE minimum, 25 GbE recommended; 2 uplinks per host

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

## Step 1: Prepare the Deployment Parameter Workbook

VMware provides an Excel-based deployment parameter workbook (available from the Broadcom Support Portal). Fill in all required fields:

1. **Management network parameters**: IP addresses, subnet masks, gateway, DNS servers
2. **Host credentials**: Root password for all ESXi hosts
3. **License keys**: vSphere, vSAN, NSX, and SDDC Manager licenses
4. **DNS entries**: Pre-populate all required DNS records before running the workbook validation

## Step 2: Deploy Cloud Builder

Cloud Builder is the deployment appliance that orchestrates the initial bringup. Deploy the Cloud Builder OVA from the Broadcom Support Portal:

```bash
# Cloud Builder minimum requirements:
# - 4 vCPUs
# - 8 GB RAM  
# - 200 GB storage
# Deploy to any existing ESXi host or vCenter environment
```

Once deployed, access the Cloud Builder UI at `https://<cloud-builder-ip>/` and log in with admin credentials.

## Step 3: Import and Validate the Deployment Workbook

In Cloud Builder:

1. Navigate to **Workflow** → **Deploy VMware Cloud Foundation**
2. Upload your completed deployment parameter workbook
3. Click **Validate** — Cloud Builder will perform over 200 pre-deployment checks including:
   - DNS resolution for all FQDNs
   - Network connectivity between hosts
   - NTP synchronization
   - Host hardware compatibility
   - License key validity

> **Tip**: Address all validation failures before proceeding. Common issues include DNS TTL problems and NTP drift. Cloud Builder will clearly indicate which checks failed and why.

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

After Cloud Builder reports successful completion:

1. **Log in to SDDC Manager** at `https://<sddc-manager-fqdn>/`
2. **Verify inventory**: All hosts should show as ACTIVE under the management domain
3. **Check NSX status**: Navigate to NSX Manager and confirm all transport nodes show as Up
4. **Validate vSAN health**: In vCenter, check vSAN health under the cluster — all checks should be green
5. **Run SDDC Manager health check**: Under **Developer Center** → **API Explorer**, run the health API to get a comprehensive system status report

## Common Deployment Issues and Fixes

### vSAN Disk Claim Failures
If vSAN fails to claim disks during Phase 2, verify:
- Disks are not presenting existing partition tables (wipe with `esxcli storage core device partition delete`)
- NVMe disks meet the ESA compatibility requirements (check HCL)

### NSX Manager Deployment Timeout
If NSX Manager deployment times out:
- Check vSAN health — insufficient capacity is the most common cause
- Verify the NSX Manager FQDN resolves correctly from Cloud Builder

## Up Next

Now that your management domain is running, the next logical step is creating your first workload domain. In the next post, we will cover workload domain planning, network design for NSX segments, and automated workload domain deployment using the SDDC Manager API.
