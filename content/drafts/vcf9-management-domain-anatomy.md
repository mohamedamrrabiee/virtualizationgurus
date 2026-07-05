---
title: "VCF 9 Management Domain Anatomy: What Actually Runs Inside"
date: 2026-07-27
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

-> Deployed first, always -- the management domain is created during initial deployment or convergence by VCF Installer, before any workload domain exists.

-> Houses the fleet's control plane -- in the first VCF Instance of a fleet, the management domain is where the License server, VCF Operations, VCF management services, and VCF Automation actually run. Additional management domains (for additional Instances in the same fleet) carry instance-level components only, not the fleet-level ones.

-> Runs SDDC Manager workflows -- the management domain includes the SDDC Manager appliance, which adds infrastructure-management automation workflows on top of VCF Operations for the fleet.

-> Can still run business workloads -- the management domain isn't purely infrastructure; it's permitted to host general workloads and NSX Edge nodes alongside its management role, though most designs keep it dedicated to management functions for lifecycle and resource isolation reasons.

## Shared vs. Dedicated NSX: A Real Tradeoff

Workload domains -- and by extension, the NSX relationship they have with the management domain -- can either get a dedicated NSX Manager cluster or share one. Broadcom's documentation lays out the tradeoff plainly:

| Attribute | Dedicated NSX per Domain | Shared NSX Across Domains |
|---|---|---|
| Footprint | Higher -- one NSX Manager cluster per domain | Lower -- one cluster serves multiple domains |
| Availability | Independent control plane per domain | Larger blast radius if the shared cluster fails |
| Scalability | Each domain scales independently | Constrained by the shared instance's limits |
| Lifecycle | Upgrades/patches applied independently | Upgrades/patches affect every domain sharing it |

A VCF Instance can scale up to 40 workload domains, and each one individually chooses dedicated or shared NSX -- it isn't a fleet-wide, all-or-nothing setting.


## Architecture at a Glance

```
MANAGEMENT DOMAIN (first in the fleet)
  vCenter + clusters | SDDC Manager (Day-2 automation) | NSX Manager (dedicated or shared)
  VCF Operations + VCF Automation (fleet-level, first Instance only)
        |
        | deploys / manages
   -----+-----+-----
   |         |        |
WORKLOAD DOMAIN 1  WORKLOAD DOMAIN 2  WORKLOAD DOMAIN N
```

## A Practical Tip

Size the management domain with room to grow -- Broadcom's own guidance notes that you may need to expand its resources over time to accommodate additional workload domains and management components, so treat initial sizing as a floor, not a ceiling.

## Sources

This post was validated against Broadcom's official VCF 9.1 documentation, specifically the VCF Taxonomy and VCF Domain Models pages under [VMware Cloud Foundation 9.1 documentation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts/design-guide-vmware-cloud-foundation-architecture-models.html).

## Up Next

Next in this series: NSX Edge Cluster Deep Dive -- T-0/T-1 gateways, VPN, and north-south firewall design.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
