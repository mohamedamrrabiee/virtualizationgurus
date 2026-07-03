---
title: "VCF 9 vSAN ESA Deep Dive: Architecture, Performance, and New Features"
date: 2026-07-20
draft: true
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
description: "A comprehensive deep dive into vSAN Express Storage Architecture (ESA) in VCF 9, covering architecture design decisions, performance characteristics, new features like Dying Disk Handling, and best practices for storage policy design."
---

## Introduction

vSAN Express Storage Architecture (ESA) is the recommended storage architecture for all new VMware Cloud Foundation 9 deployments. ESA represents a ground-up redesign of the vSAN storage stack, purpose-built to exploit the performance characteristics of modern NVMe flash media. In this post, we explore the vSAN ESA architecture, design decisions, new VCF 9 capabilities, and best practices for storage policy design.

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
  |  |  (Policy Mgmt,   |  |  (Proactive DDH, |  |  (LCM, Capacity Mgmt,   |   |
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
  |  |  +-------------+   Log-Structured FS (LSFS)                            |  |
  |  |  | vSAN Object |<-- Single-tier NVMe pool (no cache/capacity split)    |  |
  |  |  |   Layer     |   Hardware-assisted compression (inline)              |  |
  |  |  +------+------+   Near-zero impact snapshots (CLAD algorithm)        |  |
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
  |  |   | (DDH mon.) |  | (DDH mon.) |  | (DDH mon.) |                |   |
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
  |  RAID-5/6 ready |   |  RAID-5/6 ready |   |  RAID-5/6 ready |
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
| Compression | Software only (post-process) | Hardware-assisted (inline) |
| Snapshot Performance | Degrades under load | Near-zero impact (CLAD algorithm) |
| RAID-5/6 Efficiency | Requires 6 hosts (RAID-6) | Available with 4 hosts (RAID-5) |
| Cache Drive Monitoring | Basic health alerts | Dying Disk Handling (DDH) for NVMe |
| File System | VMFS-based (COW) | Log-Structured File System (LSFS) |
| Minimum Hosts | 3 | 3 |
| Minimum Drives/Host | 1 cache + 1 capacity | 3 NVMe (all-flash single tier) |

## ESA Key Design Decisions

### Single-Tier NVMe Pool

ESA eliminates the two-tier cache/capacity split used in OSA. All NVMe drives contribute to a single unified storage pool, delivering:

- **Consistent low-latency I/O** across all stored objects regardless of working set size
- **Simplified capacity planning** with no cache-to-capacity ratio calculations required
- **Minimum 3 NVMe drives per host** for ESA (the Broadcom Compatibility Guide lists ESA-certified NVMe drives)
- All drives must be certified for ESA — not all NVMe drives qualify; refer to the Broadcom Compatibility Guide (BCG) for the ESA Compatibility category

### Log-Structured File System (LSFS)

ESA uses a purpose-built Log-Structured File System optimized for NVMe characteristics:

- Sequential write patterns to all NVMe devices, maximizing write throughput
- Inline hardware-assisted compression reduces write amplification and extends drive life
- Efficient space reclamation through background compaction without impacting foreground I/O

### Near-Zero Impact Snapshots

ESA introduces the Consistent Log-Aligned Data (CLAD) algorithm for snapshot operations:

- Snapshots are created and deleted without copying data blocks (unlike OSA's copy-on-write approach)
- Snapshot trees do not degrade read/write performance, enabling efficient use of snapshots for backup integration (VMware Live Recovery)
- Supports VMware Live Recovery with RPO >= 1 minute for supported configurations

## New in VCF 9: Dying Disk Handling (DDH) for NVMe Drives

VCF 9 introduces **Dying Disk Handling (DDH)** for ESA NVMe drives. DDH provides:

- **Proactive detection**: vSAN health monitoring tracks drive latency trends and NVMe SMART attributes to identify drives showing early signs of failure
- **Automated remediation**: When DDH detects a drive latency threshold breach, vSAN automatically triggers an evacuation of data from the at-risk drive before a complete failure occurs
- **Reduced data loss risk**: By evacuating data proactively, DDH prevents the unplanned loss of a drive from triggering a resync storm or reducing cluster redundancy without administrator awareness
- **Alert integration**: DDH events surface in vSAN Health Service, Skyline Health, and VCF Operations dashboards

DDH complements vSAN's existing proactive rebalance and resync capabilities, providing a complete automated response workflow from detection through remediation.

## vSAN ESA Storage Policies in VCF 9

Storage policies in vSAN ESA are defined through VM Storage Policies applied at the VM or VMDK level.

### Key Policy Parameters

**Failures to Tolerate (FTT)** — the number of host failures the cluster can sustain:

- FTT=1 with RAID-1 (mirroring): minimum 3 hosts required
- FTT=1 with RAID-5 (erasure coding): minimum 4 hosts, more space-efficient than RAID-1
- FTT=2 with RAID-6 (erasure coding): minimum 6 hosts, recommended for production workloads

**Storage Policy Best Practices for VCF 9:**

1. Use **RAID-5/FTT=1** for general workloads with 4+ hosts — provides 1.33x space overhead vs 2x for RAID-1
2. Use **RAID-6/FTT=2** for business-critical VMs requiring tolerance of 2 simultaneous host failures
3. Define **separate storage policies** for management VMs (RAID-1/FTT=1) and workload VMs (RAID-5/FTT=1 or RAID-6/FTT=2)
4. Enable **storage-based policy management (SPBM)** integration with VCF Automation for self-service policy assignment

### vSAN File Services

VCF 9 supports vSAN File Services on ESA clusters:

- Supports up to **500 file shares per cluster**
- Provides NFS v3/v4.1 protocol support for workloads requiring shared file storage
- File services VMs are deployed automatically within the vSAN cluster
- Useful for Kubernetes persistent volumes (NFS-backed) and legacy application shared storage requirements

## vSAN ESA and VMware Live Recovery Integration

VCF 9's vSAN ESA integrates with **VMware Live Recovery** for disaster recovery:

- RPO >= 1 minute for protected VMs (replication interval configurable)
- Near-zero impact snapshots (via CLAD) enable efficient replication without degrading production I/O
- Failover orchestration is managed through VCF Operations or dedicated Live Recovery management interface
- Supports both on-premises-to-on-premises and on-premises-to-VMware Cloud replication topologies

## Operational Best Practices

**Host maintenance and replacement:**

- Before removing a host from the cluster, use vSphere maintenance mode with "Ensure Accessibility" or "Full Data Migration" to safely migrate vSAN objects
- For ESA, a minimum of 3 fully operational hosts (not including the host in maintenance) is required to maintain FTT=1 protection

**Capacity management:**

- Monitor vSAN capacity from VCF Operations > Cost and Capacity Management
- Plan for vSAN resync capacity: maintain 10-15% slack capacity for background resync after a host failure or replacement
- VCF 9 provides capacity forecasting in VCF Operations to predict when cluster expansion will be required

**Monitoring and health:**

- Enable Skyline Health integration in VCF Operations for proactive hardware health alerts
- Review DDH alerts regularly — a DDH-triggered evacuation indicates a drive is near end of life and should be scheduled for replacement
- vSAN performance diagnostics are available from vCenter > Monitor > vSAN > Performance

## What's Next

In the next post, we will explore VCF 9 lifecycle management using VCF Operations, covering the unified upgrade process for ESX, vCenter, NSX, and vSAN components, as well as the new VCF 9 licensing model and fleet-level health monitoring.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
