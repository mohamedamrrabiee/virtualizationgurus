---
title: "VCF 9 Management Domain Anatomy: What Actually Runs Inside"
date: 2026-07-20
draft: false
tags: ["VCF", "VMware", "Management Domain", "vCenter", "NSX", "Cloud Foundation"]
categories: ["VCF 9", "Architecture"]
description: "A technical breakdown of the VCF 9 management domain, validated against official Broadcom documentation: its required components, how the first management domain differs from additional ones, and the shared-vs-dedicated NSX decision."
---

## Introduction

Every VCF Instance starts with a management domain -- it's the first workload domain deployed, and it never stops being special. This post breaks down exactly what components live inside a management domain per Broadcom's official documentation, why the very first one in a fleet carries extra weight, and the shared-vs-dedicated NSX tradeoff that shows up in almost every design conversation.

## What Every VCF Domain Contains

Per the VCF Taxonomy documentation, any VCF domain -- management or workload -- is built from the same base components: one vCenter instance, one or more vSphere clusters with vSphere HA and DRS enabled, at least one vSphere Distributed Switch per cluster plus NSX segments for workload traffic, a dedicated or shared NSX Manager instance, optional NSX Edge or Virtual Network Appliance clusters added after domain creation, and one or more shared storage allocations.

## The Management Domain's Extra Responsibilities

What makes the management domain different is what else it carries on top of that baseline, according to the VCF Domain Models documentation:

-> Deployed first, always -- the management domain is the first workload domain deployed in a VCF Instance, created during initial deployment or convergence by VCF Installer, before any workload domain exists.

-> Houses the fleet's control plane -- in the first VCF Instance of a fleet, the management domain contains the VCF fleet management components in addition to its own instance-level components. Additional management domains (for additional Instances in the same fleet) carry instance-level components only, not the fleet-level ones.

-> Runs SDDC Manager *and* a separate fleet management appliance -- the management domain includes the SDDC Manager appliance alongside a distinct fleet management appliance. It's worth keeping these two straight: SDDC Manager is still installed and still listed as a management-domain component, but its UI and lifecycle-management workflows are deprecated as of VCF 9.0 and have moved into VCF Operations Fleet Management. The fleet management appliance is the component that actually extends the VCF Operations instance with the infrastructure-automation workflows for the fleet -- not SDDC Manager itself.

-> Hosts a dedicated License Server -- as of VCF 9.1, licensing runs in its own VCF License Server appliance (auto-deployed alongside VCF Operations during install or upgrade) rather than inside VCF Operations, as it did previously.

-> Can still run business workloads -- the management domain isn't purely infrastructure; per Broadcom's Domain Models documentation, it's explicitly permitted to host general workloads and NSX Edge nodes alongside its management role, though most designs keep it dedicated to management functions for lifecycle and resource isolation reasons.

## Shared vs. Dedicated NSX: A Real Tradeoff

Workload domains -- and by extension, the NSX relationship they have with the management domain -- can either get a dedicated NSX Manager cluster or share one. Broadcom's documentation lays out the tradeoff plainly:

| Attribute | Dedicated NSX per Domain | Shared NSX Across Domains |
|---|---|---|
| Footprint | Higher -- one NSX Manager cluster per domain | Lower -- one cluster serves multiple domains |
| Availability | Independent control plane per domain | Larger blast radius if the shared cluster fails |
| Scalability | Each domain scales independently | Constrained by the shared instance's limits |
| Lifecycle | Upgrades/patches applied independently | Upgrades/patches affect every domain sharing it |

A VCF Instance can scale up to 25 total domains -- one management domain plus as many as 24 VI workload domains -- and each workload domain individually chooses dedicated or shared NSX; it isn't a fleet-wide, all-or-nothing setting. A single shared NSX Manager has its own ceiling too: an Extra Large or Large form factor supports up to 16 attached vCenters/Compute Managers, while a Medium form factor supports only 2.

## Architecture at a Glance

```
MANAGEMENT DOMAIN (first in the fleet)
vCenter + clusters | SDDC Manager (deprecated UI) | Fleet Mgmt Appliance | NSX Manager (dedicated or shared)
VCF Operations + VCF Automation + License Server (fleet-level, first Instance only)
|
| deploys / manages
-----+-----+-----
| | |
WORKLOAD DOMAIN 1 WORKLOAD DOMAIN 2 WORKLOAD DOMAIN N
```

## A Practical Tip

Size the management domain with room to grow -- Broadcom's own guidance notes that you may need to expand its resources over time to accommodate additional workload domains and management components, so treat initial sizing as a floor, not a ceiling.

## What's Next

Next in this series: Physical Network Design: VDS Separation, ToR, and BGP Uplinks.

## Further Reading (Official Broadcom Documentation)

- [VCF Taxonomy](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/overview-of-vmware-cloud-foundation-9/workload-domains-in-vmware-cloud-foundation.html)
- [VCF Domain Models](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts/design-guide-vmware-cloud-foundation-architecture-models.html)
- [Deploy VCF Management Services and License Server as Part of VCF Upgrade to 9.1](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/upgrading-cloud-foundation/deploy-vcf-management-services.html)
- [Licensing Overview](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/licensing/licensing-overview.html)
- [VMware Configuration Maximums for VCF 9](https://configmax.broadcom.com/guest?vmwareproduct=SDDC%20Manager&release=9.0.0&categories=17-0,73-0,165-0)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
