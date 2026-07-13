---
title: "VCF 9 Lifecycle Management with VCF Operations: Unified Upgrades and Fleet Management"
date: 2026-07-15
draft: false
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

Managing the lifecycle of a VMware Cloud Foundation environment has historically required coordinated upgrades across multiple products — ESX, vCenter, NSX, and vSAN — with complex compatibility matrices and manual orchestration. VCF 9 changes this experience by moving lifecycle management into VCF Operations: the SDDC Manager UI is deprecated, and its LCM workflows now live in VCF Operations Fleet Management, giving you a single place to plan and orchestrate upgrades across every domain.

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
  |  |  (Upgrade Mgmt,  |  |  (All Domains,   |  |  (Primary + vSAN         |   |
  |  |   Desired State) |  |   Health Checks) |  |   licenses, 180-day)     |   |
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

Starting with VCF 9.0, the SDDC Manager UI is deprecated and its workflows move into VCF Operations and the vSphere Client. SDDC Manager itself is still installed as a component of every VCF 9 instance during this transition, but its lifecycle management capabilities — and the LCM API that used to live on SDDC Manager — now belong to VCF Operations Fleet Management. In practice, VCF Operations is where you go to manage one or more VCF instances. Key responsibilities include:

- **Fleet Management**: Centralized inventory and health visibility across all management and workload domains, including multi-site VCF deployments, with SDDC Manager's former LCM workflows absorbed into this capability
- **Lifecycle Management (LCM)**: Orchestrated upgrades for all VCF components (ESX, vCenter, NSX, vSAN) with pre-upgrade validation, staged rollout, and post-upgrade health checks
- **License Management**: Tracking and submission of VCF usage data under the per-core primary license model
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
- NSX update image — NSX virtual networking kernel modules (VIBs) ship bundled with ESX by default in VCF 9, and NSX VIB lifecycle is now tied to ESX lifecycle rather than managed separately
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
3. **NSX**: NSX Manager and transport nodes are upgraded. Because NSX VIBs ship with ESX, NSX VIB updates land as part of the ESX host upgrade rather than a separate maintenance cycle, and NSX VIBs on ESX hosts support ESX Live Patch — allowing certain updates to apply without maintenance mode or impact to vMotion and DRS.
4. **vSAN**: vSAN upgrades are typically part of the ESX upgrade in ESA deployments. VCF Operations monitors vSAN health throughout the upgrade.

### Step 4: Post-Upgrade Validation

After upgrade completion, VCF Operations automatically runs post-upgrade health checks:

- All components show expected version numbers
- NSX control plane is healthy and all transport nodes show as Up
- vSAN cluster health is green with no rebuild operations in progress
- vCenter inventory is consistent and all hosts show as Connected

## VCF 9 Licensing Model

VCF 9 replaces the many separate per-product license keys of earlier VCF versions with subscription-based license files assigned at the vCenter level. A few mechanics are worth understanding before you plan a deployment:

- **Primary licenses are per-core.** VCF and vSphere Foundation licenses are consumed by ESX hosts, calculated from total physical CPU cores across your environment. Most products enforce a **16-core-per-CPU minimum** — a CPU with fewer physical cores (say, 8) still consumes 16 cores of license capacity.
- **You license vCenter instances, not hosts directly.** You assign a primary license to a vCenter instance, and the other components connected to that vCenter (ESX, and by extension NSX) are licensed automatically.
- **vSAN capacity is a separate, pooled license measured in TiB.** A VCF subscription delivers both a default VMware Cloud Foundation (per-core) license and a default vSAN Enterprise (per-TiB) license. If your storage needs exceed the vSAN capacity included with your core purchase, you buy additional vSAN Capacity Add-on licenses in per-TiB increments.
- **Capacity pools automatically.** Multiple subscriptions for the same product, same unit of measure, and same Site ID combine into one default license rather than staying as separate license entries — useful when you add capacity incrementally over time.
- **New installs get a 90-day evaluation period** before licensing is required (stateless ESX hosts provisioned via Auto Deploy have no evaluation period in 9.0).

### License Submission

VCF 9 uses a **usage-based license submission model**:

- License usage data must be submitted to Broadcom at least once every **180 days** — miss the window and licenses are treated as expired, disconnecting hosts from vCenter and blocking workload operations
- In **connected mode**, VCF Operations generates and submits usage files automatically (daily)
- In **disconnected mode**, you export a signed usage file from VCF Operations and upload it to Broadcom Customer Connect manually on a regular interval

### Licensing in Disconnected/Air-gapped Environments

VCF Operations supports fully disconnected (air-gapped) operation:

- No internet connectivity required for LCM operations when using a local depot
- License usage data can be exported from VCF Operations as a signed file and manually uploaded to Broadcom Customer Connect
- VCF Operations continues to operate normally in disconnected mode; license submission is the only operation requiring external connectivity (and can still be done offline via manual file upload)

## Fleet-Level Health Monitoring

VCF Operations provides fleet-level health monitoring across all VCF domains:

### Dashboard and Alerts

- **Fleet Overview**: Single pane showing all management and workload domains with health status (green/yellow/red)
- **Component Health**: Per-component health (ESX, vCenter, NSX, vSAN) with drill-down from domain to individual host
- **Proactive Alerts**: Integration with Broadcom Skyline Health proactively identifies issues, including predictive hardware alerts from Proactive Hardware Management (PHM), NSX transport node issues, and certificate expiry warnings

### Certificate Lifecycle Management

VCF Operations manages certificate lifecycle for all VCF components:

- Tracks certificate expiry dates across all domains and components
- Automates certificate rotation for management domain components (vCenter, NSX Manager, VCF Operations itself)
- Sends proactive alerts when certificates approach expiry

## VCF SDK and Automation

VCF 9 provides comprehensive automation capabilities through a unified VCF SDK that consolidates what used to be separate per-component SDKs:

- **REST API**: Roughly 90% of VCF APIs now follow the OpenAPI 3.0 specification, improving consistency across lifecycle management, domain management, and license operations
- **Python and Java SDK**: A single unified VCF SDK for both languages, installable online via PyPI (Python) and Maven (Java), or offline through the Broadcom Developer Portal for regulated/air-gapped environments
- **VCF PowerCLI**: Auto-generated PowerShell modules providing 1:1 bindings with the VCF REST APIs, part of the broader PowerCLI suite

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

## Further Reading (Official Broadcom Documentation)

- [VCF Operations — What's New](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new/whats-new-vcf-ops.html)
- [Licensing Model](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/licensing/licensing-overview/licensing-model.html)
- [Updating Licenses and Viewing the License Usage File](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/licensing/update-licenses.html)
- [VCF SDKs, APIs, and CLIs — What's New](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/release-notes/vmware-cloud-foundation-90-release-notes/platform-whats-new/whats-new-vcf-cli-api-sdk.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
