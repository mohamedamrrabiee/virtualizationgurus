---
title: "VCF 9 Lifecycle Management with VCF Operations: Unified Upgrades and Fleet Management"
date: 2026-07-27
draft: true
tags:
  - VCF
  - VMware
  - Lifecycle Management
  - VCF Operations
  - LCM
  - Cloud Foundation
categories:
  - VCF 9
  - Operations
description: "A deep dive into VCF 9 lifecycle management using VCF Operations, covering the unified upgrade workflow for ESX, vCenter, NSX, and vSAN, the new licensing model, fleet-level health monitoring, and automation through the VCF SDK."
---

## Introduction

Managing the lifecycle of a VMware Cloud Foundation environment has historically required coordinated upgrades across multiple products — ESX, vCenter, NSX, and vSAN — with complex compatibility matrices and manual orchestration. VCF 9 fundamentally changes this experience by introducing a unified lifecycle management model through VCF Operations, the new single management plane that replaces SDDC Manager.

In this post, we explore the VCF 9 lifecycle management architecture, the unified upgrade workflow, the new licensing model, and fleet-level health monitoring capabilities.

## Architectural Overview

The diagram below shows the VCF Operations lifecycle management architecture, including the relationships between the management plane, fleet components, and the upgrade orchestration workflow:

```
+-----------------------------------------------------------------------------------+
|       VCF 9 - Lifecycle Management Architecture (VCF Operations)                   |
+-----------------------------------------------------------------------------------+

  +-----------------------------------------------------------------------------+
  |                          VCF Operations (LCM Plane)                          |
  |                                                                              |
  |  +------------------+  +------------------+  +--------------------------+   |
  |  |  Lifecycle Mgmt  |  |  Fleet Mgmt      |  |  License Management      |   |
  |  |  (Upgrade Mgmt,  |  |  (All Domains,   |  |  (VCF Cores + vSAN TiB, |   |
  |  |   Desired State) |  |   Health Checks) |  |   180-day submission)    |   |
  |  +------------------+  +------------------+  +--------------------------+   |
  |                                                                              |
  |  +------------------+  +------------------+  +--------------------------+   |
  |  |  Cost & Capacity |  |  Security        |  |  VCF SDK / REST API      |   |
  |  |  Management      |  |  Compliance      |  |  (Python, Java, PowerCLI)|   |
  |  +------------------+  +------------------+  +--------------------------+   |
  +-----------------------------------------------------------------------------+
                 |                    |                    |
          +------+------+      +------+------+      +------+------+
          |             |      |             |      |             |
          v             v      v             v      v             v
  +---------------+ +---------------+ +---------------+
  | Management    | | Workload      | | Workload      |
  | Domain        | | Domain A      | | Domain B      |
  |               | |               | |               |
  | ESX 9.0       | | ESX 9.0       | | ESX 9.0       |
  | vCenter 9.0   | | vCenter 9.0   | | vCenter 9.0   |
  | NSX 9.0       | | NSX 9.0       | | NSX 9.0       |
  | vSAN ESA      | | vSAN ESA      | | vSAN ESA      |
  +---------------+ +---------------+ +---------------+

  Upgrade Orchestration Flow:
  +--------+    +--------+    +--------+    +--------+    +--------+
  |  Plan  | -> |  Stage | -> | PreChk | -> |Upgrade | -> |PostChk |
  | Bundle |    | Images |    | (200+) |    | (Auto) |    | Health |
  +--------+    +--------+    +--------+    +--------+    +--------+

  Update Bundle Sources:
  +----------------------------+    +------------------------+
  | Broadcom Customer Connect  | -> | VCF Depot (Online)     |
  |                            |    | or Local Depot         |
  +----------------------------+    +------------------------+
```

## VCF Operations: The Unified Management Plane

VCF Operations replaces SDDC Manager from VCF 5.x as the single management plane for all VCF environments. Key responsibilities include:

- **Fleet Management**: Centralized inventory and health visibility across all management and workload domains, including multi-site VCF deployments
- **Lifecycle Management (LCM)**: Orchestrated upgrades for all VCF components (ESX, vCenter, NSX, vSAN) with pre-upgrade validation, staged rollout, and post-upgrade health checks
- **License Management**: Tracking and submission of VCF usage data under the new simplified 2-license model
- **Cost and Capacity Management**: Resource utilization visibility and capacity forecasting across all domains
- **Security Compliance**: Integration with Broadcom's security compliance frameworks for VCF component configuration validation

## VCF 9 Lifecycle Management: Upgrade Workflow

The VCF 9 upgrade workflow is orchestrated entirely through VCF Operations, providing a single workflow for upgrading all VCF components across one or multiple domains.

### Step 1: Bundle Management

VCF 9 uses upgrade bundles that contain all required component images:

- **Online Depot**: Connect VCF Operations to Broadcom Customer Connect (online) to download bundles automatically. VCF Operations checks for available updates and presents them in the Lifecycle Management dashboard.
- **Offline/Air-gapped**: Download bundles from Broadcom Customer Connect and import to a local depot. VCF Operations consumes bundles from the local depot without internet connectivity.

A VCF update bundle includes:
- ESX 9.0 update image (compatible with vSphere Lifecycle Manager)
- vCenter Server update or patch image
- NSX update image (note: NSX VIBs are bundled with ESX 9.0, so NSX kernel module upgrades may be included in ESX update bundles)
- vSAN update (typically part of the ESX image for ESA deployments)

### Step 2: Pre-Upgrade Validation

Before applying any upgrade, VCF Operations performs automated pre-upgrade checks:

- **Hardware compatibility**: Validates all ESX hosts against the Broadcom Compatibility Guide (BCG) for the target upgrade version
- **Component compatibility**: Verifies the upgrade bundle is compatible with the current VCF component versions (interoperability matrix check)
- **Health checks**: Validates vSAN cluster health, NSX control plane health, and vCenter inventory state
- **License validation**: Confirms VCF licenses are valid and usage has been submitted within the required 180-day window
- **DNS/NTP validation**: Verifies DNS resolution and NTP synchronization for all management domain components

Address all pre-upgrade failures before proceeding. VCF Operations clearly identifies which checks failed and provides remediation guidance.

### Step 3: Upgrade Orchestration

Once validation passes, VCF Operations orchestrates the upgrade in the correct sequence:

1. **ESX hosts**: ESX hosts are upgraded using vSphere Lifecycle Manager (vLCM) integration. Hosts are placed in maintenance mode sequentially (or using custom scheduling), updated, and returned to service. DRS ensures workload migration during maintenance.
2. **vCenter Server**: vCenter is upgraded after all ESX hosts in the domain are updated. The upgrade uses the vCenter appliance upgrade mechanism and is orchestrated by VCF Operations.
3. **NSX**: NSX Manager and transport nodes are upgraded. Because NSX VIBs are bundled with ESX 9.0, transport node upgrades may require only an NSX Manager upgrade (without separate ESX maintenance cycles for VIB updates). Live Patch for NSX transport nodes is available in supported configurations.
4. **vSAN**: vSAN upgrades are typically part of the ESX upgrade in ESA deployments. VCF Operations monitors vSAN health throughout the upgrade.

### Step 4: Post-Upgrade Validation

After upgrade completion, VCF Operations automatically runs post-upgrade health checks:

- All components show expected version numbers
- NSX control plane is healthy and all transport nodes show as Up
- vSAN cluster health is green with no rebuild operations in progress
- vCenter inventory is consistent and all hosts show as Connected

## VCF 9 Licensing Model

VCF 9 introduces a simplified **2-license model**, replacing the complex 11-license model of VCF 4.x and 5.x:

| License Type | Unit | Description |
|---|---|---|
| VMware Cloud Foundation | Per Core | Covers ESX, vCenter, NSX, and VCF Operations for all hosts in all domains |
| VMware vSAN | Per TiB | Covers vSAN ESA capacity consumed across all domains |

### License Submission

VCF 9 uses a **usage-based license submission model**:

- License usage data must be submitted to Broadcom from VCF Operations every **180 days**
- VCF Operations tracks core counts (ESX CPU cores) and vSAN consumed capacity (TiB) automatically
- Submission can be done online (via Broadcom Customer Connect) or offline (export usage file and upload manually)
- Pre-version 9 licenses are supported during upgrades from VCF 4.x/5.x, but new deployments require VCF 9 licenses

### Licensing in Disconnected/Air-gapped Environments

VCF Operations supports fully disconnected (air-gapped) operation:

- No internet connectivity required for LCM operations when using a local depot
- License usage data can be exported from VCF Operations as a signed file and manually uploaded to Broadcom Customer Connect
- VCF Operations continues to operate normally in disconnected mode; license submission is the only operation requiring external connectivity (and can be done offline)

## Fleet-Level Health Monitoring

VCF Operations provides fleet-level health monitoring across all VCF domains:

### Dashboard and Alerts

- **Fleet Overview**: Single pane showing all management and workload domains with health status (green/yellow/red)
- **Component Health**: Per-component health (ESX, vCenter, NSX, vSAN) with drill-down from domain to individual host
- **Proactive Alerts**: Integration with Broadcom Skyline Health proactively identifies issues (including hardware alerts from DDH, NSX transport node issues, and certificate expiry warnings)

### Certificate Lifecycle Management

VCF Operations manages certificate lifecycle for all VCF components:

- Tracks certificate expiry dates across all domains and components
- Automates certificate rotation for management domain components (vCenter, NSX Manager, VCF Operations itself)
- Sends proactive alerts when certificates approach expiry

## VCF SDK and Automation

VCF 9 provides comprehensive automation capabilities through the VCF SDK:

- **REST API** (OpenAPI 3.0 specification): All VCF Operations functions are accessible via REST API, including lifecycle management, domain management, and license operations
- **Python SDK**: High-level Python bindings for the VCF REST API
- **Java SDK**: High-level Java bindings for the VCF REST API
- **VCF PowerCLI**: PowerShell-based automation for VCF Operations functions, consistent with the broader vSphere PowerCLI ecosystem

### Example: Triggering an Upgrade via API

```python
# Example: Using VCF Python SDK to trigger an LCM upgrade
from vcf_sdk import VcfClient

client = VcfClient(host="vcf-operations.example.com", username="admin", password="...")

# Get available upgrade bundles
bundles = client.lifecycle.get_bundles(domain_id="management-domain-id")
print(f"Available bundles: {[b.version for b in bundles]}")

# Run pre-upgrade checks
validation = client.lifecycle.validate_upgrade(
    domain_id="management-domain-id",
    bundle_id=bundles[0].id
)
print(f"Validation status: {validation.status}")

# Initiate upgrade if validation passes
if validation.status == "SUCCEEDED":
    upgrade = client.lifecycle.start_upgrade(
        domain_id="management-domain-id",
        bundle_id=bundles[0].id
    )
    print(f"Upgrade started: {upgrade.id}")
```

## What's Next

In the next post, we will explore VCF 9 security and compliance, covering the NSX Distributed Firewall design, VPC-level isolation, and how VCF Operations integrates with Broadcom's security compliance frameworks to maintain a hardened VCF environment.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
