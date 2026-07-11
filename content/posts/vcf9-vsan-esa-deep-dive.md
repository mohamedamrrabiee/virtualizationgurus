---
title: "VCF 9 vSAN ESA Deep Dive: Architecture, Performance, and New Features"
date: 2026-07-12
draft: false
tags:
  - VCF
  - VMware
  - vSAN
  - ESA
  - Storage
  - Cloud Foundation
categories:
  - VCF 9
  - Storage
description: "A comprehensive deep dive into vSAN Express Storage Architecture (ESA) in VCF 9, covering architecture design decisions, performance characteristics, VCF 9.1's Auto-RAID capability, and best practices for storage policy design."
---

## Introduction

vSAN Express Storage Architecture (ESA) is the recommended storage architecture for all new VMware Cloud Foundation 9 deployments. ESA represents a ground-up redesign of the vSAN storage stack, purpose-built to exploit the performance characteristics of modern NVMe flash media. In this post, we explore the vSAN ESA architecture, design decisions, VCF 9.1's new Auto-RAID capability, and best practices for storage policy design.

## Architectural Overview

The diagram below illustrates the vSAN ESA architecture in a VCF 9 environment, from the NVMe hardware layer through the vSAN data path and management plane:

```
+-----------------------------------------------------------------------------------+
|           VCF 9 - vSAN Express Storage Architecture (ESA)                         |
+-----------------------------------------------------------------------------------+

  +-----------------------------------------------------------------------------+
  |                        vSAN Management Plane                                 |
  |                                                                              |
  |  +------------------+  +------------------+  +--------------------------+   |
  |  |  vCenter Server  |  |  vSAN Health Svc |  |  VCF Operations          |   |
  |  |  (Policy Mgmt,   |  |  (Proactive HW,  |  |  (LCM, Capacity Mgmt,   |   |
  |  |   Cluster Ops)   |  |   Skyline Health)|  |   vSAN File Services)    |   |
  |  +------------------+  +------------------+  +--------------------------+   |
  +-----------------------------------------------------------------------------+
                                      |
  +-------------------------------------v----------------------------------------+
  |                         ESX Host Data Path (per host)                         |
  |                                                                               |
  |  +-------------------------------------------------------------------------+  |
  |  |                      vSAN ESA Storage Stack                             |  |
  |  |                                                                         |  |
  |  |   VM I/O Request                                                        |  |
  |  |        |                                                                |  |
  |  |        v                                                                |  |
  |  |  +-------------+   Log-Structured File System (LFS)                    |  |
  |  |  | vSAN Object |<-- Single-tier NVMe pool (no cache/capacity split)    |  |
  |  |  |   Layer     |   Always-on compression (cluster service, VCF 9.1)   |  |
  |  |  +------+------+   Metadata/B-tree based snapshots (near-zero impact) |  |
  |  |         |                                                              |  |
  |  |         v                                                              |  |
  |  |  +-------------+                                                       |  |
  |  |  |  NVMe/RDMA  |<-- NVMe-oF support for direct fabric I/O             |  |
  |  |  |   Driver    |                                                       |  |
  |  |  +------+------+                                                       |  |
  |  +---------|-----------------------------------------------------------------+  |
  |            |                                                              |
  |  +---------v---------------------------------------------------------+   |
  |  |                       NVMe SSD Pool (ESA)                         |   |
  |  |                                                                   |   |
  |  |   +------------+  +------------+  +------------+                 |   |
  |  |   | NVMe SSD 1 |  | NVMe SSD 2 |  | NVMe SSD 3 |  [+more]      |   |
  |  |   | (PHM mon.) |  | (PHM mon.) |  | (PHM mon.) |                |   |
  |  |   +------------+  +------------+  +------------+                 |   |
  |  |                                                                   |   |
  |  |   All drives contribute to a single performance+capacity pool     |   |
  |  |   No cache/capacity tier separation (unlike OSA)                  |   |
  |  +-------------------------------------------------------------------+   |
  +---------------------------------------------------------------------------+

  vSAN ESA Cluster (3 hosts minimum)
  +-----------------+   +-----------------+   +-----------------+
  |    ESX Host 1   |   |    ESX Host 2   |   |    ESX Host 3   |
  |  NVMe x3 (min)  |   |  NVMe x3 (min)  |   |  NVMe x3 (min)  |
  |  Auto-RAID      |   |  Auto-RAID      |   |  Auto-RAID      |
  +-----------------+   +-----------------+   +-----------------+
            |                    |                    |
            +--------------------+--------------------+
                        vSAN Network (dedicated VLAN)
```

## ESA vs OSA: Architecture Comparison

vSAN ESA fundamentally differs from the original vSAN Original Storage Architecture (OSA):

| Feature | OSA | ESA |
|---|---|---|
| Drive Tiers | Cache + Capacity (2-tier) | Single NVMe pool (1-tier) |
| NVMe Support | Limited (cache tier only) | Full NVMe-native throughout |
| Compression | Software only (post-process) | Always-on cluster service (VCF 9.1), hardware-assisted |
| Snapshot Performance | Degrades under load | Metadata-based, near-zero impact |
| RAID-5/6 Efficiency | Requires 6 hosts (RAID-6) | Available with 4 hosts (RAID-5), auto-selected via Auto-RAID in VCF 9.1 |
| Drive Health Monitoring | Basic health alerts | Proactive Hardware Management (PHM) for predictive NVMe failure detection |
| File System | VMFS-based (COW) | Log-Structured File System (LFS) |
| Minimum Hosts | 3 | 3 |
| Minimum Drives/Host | 1 cache + 1 capacity | 3 NVMe (all-flash single tier) |

## ESA Key Design Decisions

### Single-Tier NVMe Pool

ESA eliminates the two-tier cache/capacity split used in OSA. All NVMe drives contribute to a single unified storage pool, delivering:

- **Consistent low-latency I/O** across all stored objects regardless of working set size
- **Simplified capacity planning** with no cache-to-capacity ratio calculations required
- **Minimum 3 NVMe drives per host** for ESA (the Broadcom Compatibility Guide lists ESA-certified NVMe drives)
- All drives must be certified for ESA — not all NVMe drives qualify; refer to the Broadcom Compatibility Guide (BCG) for the ESA Compatibility category

### Log-Structured File System (LFS)

ESA uses a purpose-built Log-Structured File System optimized for NVMe characteristics:

- Sequential write patterns to all NVMe devices, maximizing write throughput
- In VCF 9.1, compression is now an **always-on cluster service** rather than a per-policy toggle, reducing write amplification and extending drive life with no configuration required
- Efficient space reclamation through background compaction without impacting foreground I/O

### Near-Zero Impact Snapshots

ESA's log-structured architecture enables a metadata-based snapshot engine that is fundamentally different from OSA's copy-on-write approach:

- Snapshots are tracked through metadata pointers rather than copying data blocks, so creation is crash-consistent without stunning the VM
- Snapshot deletion is largely a metadata operation — acknowledged immediately, with underlying data reclaimed asynchronously — and is dramatically faster than OSA's redo-log-based mechanism
- Snapshot trees do not degrade read/write performance, enabling efficient use of snapshots for backup integration (VMware Live Recovery)
- Supports VMware Live Recovery with RPO as low as 1 minute for vSAN-to-vSAN replication in supported configurations

## New in VCF 9.1: Auto-RAID

VCF 9.1 introduces **Auto-RAID**, a fully system-managed approach to data resilience that replaces manual RAID/FTT policy selection as the recommended default for vSAN ESA clusters:

- A single **"vSAN ESA Auto RAID Policy"** governs all vSAN 9.1 clusters cluster-wide — no explicit resilience settings are stored in the policy itself; vSAN senses cluster characteristics (host count, topology) and applies the optimal RAID level automatically
- **Standard clusters with 6+ hosts**: FTT=2 using RAID-6 (1.5x capacity overhead)
- **Standard clusters with 3–5 hosts**: FTT=1 using RAID-5, always using the 2+1 erasure code (1.5x capacity overhead)
- **Fewer than 3 hosts**: FTT=0 (1.0x capacity overhead) until the cluster scales up
- Stretched clusters and 2-node clusters have their own Auto-RAID resilience tables, layering a mirror-based site/host disaster tolerance on top of the same erasure-coding logic
- Cluster changes (adding/removing hosts) are re-evaluated dynamically, so resilience adjusts automatically as the cluster grows
- **All new VCF 9.1 clusters use Auto-RAID by default.** Existing clusters upgraded to 9.1 keep their prior storage policy or Auto-Policy Management configuration until migrated, though vSAN surfaces a health alert recommending the switch

This is a meaningful shift from earlier vSAN ESA guidance (including VCF 9.0), where administrators manually selected RAID-1/5/6 per policy based on host count and workload criticality.

## Proactive Hardware Management (PHM) for NVMe Drives

vSAN's **Proactive Hardware Management (PHM)** capability applies to ESA NVMe drives in VCF 9:

- **Predictive detection**: PHM surfaces disk predictive-failure events generated by the OEM vendor through a registered Hardware Support Manager (HSM), rather than waiting for a hard failure
- **Continuous polling**: PHM checks for HSM-generated hardware failure events every 10 minutes
- **Administrator-driven remediation**: Based on the predictive failure signal, PHM lets you take the appropriate remediation action (such as proactively evacuating data from the affected drive) before an unplanned failure occurs
- **Alert integration**: PHM events surface through the vSAN management service on vCenter and integrate with vSAN Health and Skyline Health for fleet-wide visibility in VCF Operations

Requires a supported Hardware Support Manager registered to vCenter — without an HSM, vSAN cannot receive OEM predictive-failure signals for PHM.

## vSAN ESA Storage Policies in VCF 9

Storage policies in vSAN ESA are defined through VM Storage Policies applied at the VM or VMDK level. As of VCF 9.1, **Auto-RAID is the recommended default** for resilience settings (see above); the guidance below reflects the underlying RAID mechanics and remains relevant for pre-9.1 clusters or environments not yet migrated to Auto-RAID.

### Key Policy Parameters

**Failures to Tolerate (FTT)** — the number of host failures the cluster can sustain:

- FTT=1 with RAID-1 (mirroring): minimum 3 hosts required
- FTT=1 with RAID-5 (erasure coding): minimum 4 hosts, more space-efficient than RAID-1
- FTT=2 with RAID-6 (erasure coding): minimum 6 hosts, recommended for production workloads

**Storage Policy Best Practices for VCF 9:**

1. On VCF 9.1, start with the **vSAN ESA Auto RAID Policy** as the datastore default — it removes the guesswork of matching RAID level to host count and adjusts automatically as the cluster scales
2. If manual policies are still required (pre-9.1 clusters, or specific IOPS limit / Object Space Reservation / stretched-cluster site-locality needs), use **RAID-5/FTT=1** for general workloads with 4+ hosts and **RAID-6/FTT=2** for business-critical VMs requiring tolerance of 2 simultaneous host failures
3. Define **separate storage policies** for management VMs and workload VMs only where Auto-RAID's cluster-wide policy doesn't fit the requirement (for example, custom IOPS limits)
4. Enable **storage-based policy management (SPBM)** integration with VCF Automation for self-service policy assignment

### vSAN File Services

VCF 9 supports vSAN File Services on ESA clusters:

- Supports up to **500 file shares per cluster**, of which up to 100 can be SMB
- Provides NFS v3/v4.1 and SMB protocol support for workloads requiring shared file storage
- VCF 9.1 delivers **up to 2x faster metadata operations** for SMB workloads
- File services VMs are deployed automatically within the vSAN cluster
- Useful for Kubernetes persistent volumes (NFS-backed) and legacy application shared storage requirements

## vSAN ESA and VMware Live Recovery Integration

VCF 9's vSAN ESA integrates with **VMware Live Recovery** for disaster recovery:

- Host-based vSAN-to-vSAN replication with RPO as low as 1 minute for protected VMs
- Metadata-based snapshots enable efficient replication without degrading production I/O
- VCF 9.1 adds seeding for vSAN replication, using existing replicas to avoid full re-synchronization when creating new replication pairs
- Failover orchestration is managed through VCF Operations or the dedicated Live Recovery management interface
- Supports both on-premises-to-on-premises and on-premises-to-VMware Cloud replication topologies

## Operational Best Practices

**Host maintenance and replacement:**

- Before removing a host from the cluster, use vSphere maintenance mode with "Ensure Accessibility" or "Full Data Migration" to safely migrate vSAN objects
- For ESA, a minimum of 3 fully operational hosts (not including the host in maintenance) is required to maintain FTT=1 protection

**Capacity management:**

- Monitor vSAN capacity from VCF Operations > Cost and Capacity Management
- VCF 9.1's Auto-RAID standardizes capacity overhead per cluster type (1.5x for standard clusters, 3x for stretched, 2x for 2-node), which simplifies capacity forecasting compared to mixed manual policies
- Plan for vSAN resync capacity: maintain 10-15% slack capacity for background resync after a host failure or replacement

**Monitoring and health:**

- Enable Skyline Health integration in VCF Operations for proactive hardware health alerts
- Review PHM alerts regularly — a predictive-failure signal indicates a drive is near end of life and should be scheduled for replacement
- vSAN performance diagnostics are available from vCenter > Monitor > vSAN > Performance

## What's Next

In the next post, we cover VCF 9 Lifecycle Management with VCF Operations — Unified Upgrades and Fleet Management, walking through the unified upgrade workflow for ESX, vCenter, NSX, and vSAN, the new simplified licensing model, and fleet-level health monitoring across every VCF domain.

## Further Reading (Official Broadcom Documentation)

- [vSAN 9.1 New Features — Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-0-0-release-notes/what-s-new/whats-new-vsan.html)
- [Selecting the Best RAID Configuration for a vSAN Storage Cluster](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsan-deployment-administration-and-monitoring/administering-vmware-vsan/increasing-space-efficiency-in-a-vsan-cluster/using-raid-5-6-erasure-coding-in-vsan-cluster.html)
- [Managing Proactive Hardware](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/vsan-deployment-administration-and-monitoring/vsan-monitoring-and-troubleshooting/managing-proactive-hardware.html)
- [vSAN File Service](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsan-deployment-administration-and-monitoring/administering-vmware-vsan/expanding-and-managing-a-vsan-cluster/vsan-file-service.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
