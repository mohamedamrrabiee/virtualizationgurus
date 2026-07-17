---
title: "vSAN ESA vs OSA: Storage Architecture Decisions"
date: 2026-08-19
draft: true
tags: ["vSAN", "ESA", "OSA", "Storage", "Hardware"]
categories: ["VCF 9", "vSAN"]
description: "Comparing vSAN Express Storage Architecture (ESA) and Original Storage Architecture (OSA) in VCF 9.1 -- hardware requirements, cluster types, and how to choose."
---

## Introduction

vSAN's storage architecture choice gets made before a single VM is ever placed -- it's a hardware and cluster-topology decision baked in at workload domain creation. VCF 9.1 supports two architectures side by side, Express Storage Architecture (ESA) and the Original Storage Architecture (OSA), and they claim disks in fundamentally different ways. Picking the wrong one for your hardware, or your operational model, is expensive to unwind later.

## Architectural Overview

```
vSAN OSA vSAN ESA
+----------------------+ +----------------------+
| Disk Group 1 | | Storage Pool |
| +--------++--------+ | | +----++----++----+ |
| | Cache ||Capacity| | | |NVMe||NVMe||NVMe| |
| | (SSD) ||(SSD/HDD)|| | |TLC ||TLC ||TLC | |
| +--------++--------+ | | +----++----++----+ |
| Disk Group 2 ... | | every device = cache |
+----------------------+ | + capacity, one pool |
+----------------------+
Storage controller required No disk groups, no
(HBA / RAID passthrough) separate cache tier
```

## OSA: Cache and Capacity, Organized in Disk Groups

Under the Original Storage Architecture, every host contributing storage needs at least one cache device and at least one capacity device, organized into one or more disk groups. Cache devices are SAS/SATA SSD or PCIe flash, and for hybrid configurations the cache tier needs to be sized at roughly 10% of anticipated capacity storage. Capacity devices differ by configuration: hybrid clusters use SAS/NL-SAS magnetic disks, all-flash clusters use SAS/SATA SSD or PCIe flash. OSA also requires a storage controller -- a SAS/SATA HBA or RAID controller running in passthrough or RAID-0 mode -- and host memory is sized based on how many disk groups and devices each host carries, typically worked out with the vSAN Sizer tool.

## ESA: One Pool, Every Device Contributes

With ESA, the cache/capacity split disappears. Every storage device claimed by vSAN contributes to both capacity and performance in a single, unified storage pool per host -- no disk groups to plan around. The hardware requirement is narrower but stricter: each storage pool needs at least one NVMe TLC device, and that device category is separately certified in the Broadcom Compatibility Guide from OSA's cache/capacity certifications. Host memory requirements are also simpler to state -- ESA requires a flat minimum of 128GB per host, rather than the sizing-tool exercise OSA demands.

ESA also brings architectural extras that OSA doesn't have: a Log-Structured File System (LSFS) with inline hardware-assisted compression and a Consistent Log-Aligned Data (CLAD) algorithm that keeps snapshot performance impact near zero. On the operational side, vSAN Proactive Hardware Management (PHM) rounds this out for ESA NVMe drives specifically -- once a supported Hardware Support Manager is registered to vCenter, PHM surfaces OEM predictive-failure signals for a dying device so you can remediate before it takes the storage pool down with it.

## Cluster Types: HCI, Compute-Only, and Storage-Only

The workload domain creation wizard exposes different cluster shapes depending on which architecture you pick. OSA supports a "vSAN HCI" cluster (compute and storage combined) or a "vSAN Compute Cluster" (compute only, which also supports a 2-node configuration without a witness host). ESA supports "vSAN HCI" as well, plus a disaggregated option -- a storage-only "vSAN Storage Cluster" that other vSAN ESA or compute clusters can mount as a datastore. This disaggregated model was previously branded vSAN Max in earlier VCF releases before being folded into vSAN ESA as the vSAN Storage Cluster. Data-in-transit encryption, with a configurable rekey interval defaulting to 1440 minutes, is available for both architectures.

## Policy Mechanics That Apply to Both

Whichever architecture you land on, vSAN's fault-tolerance policies still drive host-count minimums: RAID-1 (FTT=1) needs at least 3 hosts, RAID-5 (FTT=1) needs at least 4 hosts and is more space-efficient than RAID-1, and RAID-6 (FTT=2) needs at least 6 hosts. These minimums shape whether ESA's disaggregated storage-only cluster or a more traditional HCI shape is the better fit for a given domain's host count.

## Choosing Between Them

OSA remains the right call where you're working with existing hybrid or mixed-media hardware, or where a full NVMe refresh isn't in the current budget cycle. ESA is the better fit for new NVMe-based deployments where the simplified single-pool model, inline compression, and near-zero-impact snapshots outweigh the flat 128GB memory tax and stricter device certification requirements.

## What's Next

Next in this series: VCF 9 Security and Compliance: DFW, VPC Isolation, and Hardened Operations.

## Further Reading (Official Broadcom Documentation)

- [vSAN Deployment, Administration, and Monitoring](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsan-deployment-administration-and-monitoring.html)
- [vSAN Concepts](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsan-deployment-administration-and-monitoring/vsan-planning-and-deployment/what-is-vsan/vsan-concepts.html)
- [Hardware Requirements for vSAN](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsan-deployment-administration-and-monitoring/vsan-planning-and-deployment/requirements-for-creating-a-virtual-san-cluster/hardware-requirements-for-virtual-san.html)
- [Managing Proactive Hardware](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/vsan-deployment-administration-and-monitoring/vsan-monitoring-and-troubleshooting/managing-proactive-hardware.html)
- [Create a New Workload Domain](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/working-with-workload-domains/deploy-a-vi-workload-domain-using-the-sddc-manager-ui.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
