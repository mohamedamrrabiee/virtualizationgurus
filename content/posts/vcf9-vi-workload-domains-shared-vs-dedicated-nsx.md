---
title: "VI Workload Domains: Shared vs Dedicated NSX"
date: 2026-08-2
draft: false
tags: ["NSX", "Workload Domains", "vCenter", "Design Decisions"]
categories: ["VCF 9", "NSX"]
description: "How to choose between a shared and a dedicated NSX Manager instance for each VI workload domain in VCF 9.1, and what that decision costs you in footprint, availability, and lifecycle."
---

## Introduction

Every VI workload domain you stand up in VCF asks the same networking question: does it join an existing NSX Manager, or get its own? The Networking page of the workload domain creation wizard boils this down to two buttons -- "Join Existing NSX Manager Instance" and "Create New NSX Manager Instance" -- but the operational consequences run much deeper than a single click. This is a per-domain decision, not a fleet-wide one, and a VCF instance scaling toward its 25-domain ceiling will likely end up with a mix of both.

## Architectural Overview

```
VCF Instance (up to 25 total domains: 1 management + 24 VI workload domains)
+-------------------------------------------------+
| |
| Domain A --+ |
| Domain B --+---> Shared NSX Manager Instance |
| Domain C --+ (lower footprint, shared |
| lifecycle & blast radius) |
| |
| Domain D ---------> Dedicated NSX Manager |
| (own cluster, independent |
| scaling & lifecycle) |
+-------------------------------------------------+
```

## Shared NSX: Join an Existing Instance

Choosing "Join Existing NSX Manager Instance" surfaces only version-compatible NSX Managers already in the fleet, and the new workload domain's vCenter is automatically registered as a compute manager against it. VCF 9.1 adds a notable option here: a workload domain can now select the management domain's own NSX Manager as its shared instance, rather than requiring a separate dedicated NSX deployment elsewhere. Shared NSX means a smaller overall footprint and one fewer NSX Manager cluster to patch and monitor, at the cost of a larger blast radius -- an NSX-side incident or maintenance window now touches every domain attached to that instance, and scaling is constrained by whatever headroom the shared instance has left. That headroom has a hard ceiling: an NSX Manager deployed at Large or Extra Large appliance size supports up to 16 attached vCenters (compute managers), while a Medium-sized NSX Manager supports only 2.

## Dedicated NSX: Create a New Instance

Choosing "Create New NSX Manager Instance" hands you a full deployment wizard: a Deployment Size of Simple (single-node) or High-Availability (three-node, recommended for anything beyond a lab), an Appliance Size of Medium, Large, or Extra Large, and FQDN requirements for each node plus a cluster-level FQDN. A dedicated NSX Manager gives the domain independent availability, independent scaling, and a lifecycle that moves on its own schedule -- nothing else. The tradeoff is a materially higher footprint: another HA cluster to size, deploy, and keep patched.

## Version Compatibility Matters More With Shared NSX

Because a shared NSX Manager serves multiple domains, its version has to stay compatible with every attached vCenter -- and that compatibility isn't binary. Broadcom's workload domain creation documentation lays it out as a state table:

| Shared NSX Version | Workload Domain vCenter Version | Resulting State |
|---|---|---|
| NSX 9.1 | vCenter 9.1 | Full features |
| NSX 9.1 | vCenter 9.0.x | Pinned state (limited to vCenter 9.0 capabilities) |
| NSX 9.1 | vCenter 8.0.x | Pinned state (limited to vCenter 8.0 capabilities) |
| NSX 9.0.x | vCenter 9.0.x | Full features |
| NSX 4.2.x | vCenter 8.0.x | Legacy mode |

Even after NSX Manager itself is upgraded, new NSX 9.1 features stay inactive until every ESXi host transport node across every attached workload domain is running the matching version. A dedicated NSX Manager sidesteps this entirely -- its version story only has to make sense for one domain.

## The Tradeoff, Side by Side

| Dimension | Dedicated NSX | Shared NSX |
|---|---|---|
| Footprint | Higher -- own HA cluster | Lower -- reuse existing cluster |
| Availability | Independent of other domains | Shared blast radius |
| Scalability | Scales independently | Constrained by shared instance headroom (16 vCenters max on Large/XL, 2 on Medium) |
| Lifecycle | Upgrades on its own schedule | Version compatibility can pin features |

## A Decision That's Independent of VPC Connectivity

Whichever NSX topology you pick, it's a separate decision from how the domain reaches the outside world -- VCF 9's networking consumption model is built on Virtual Private Clouds (VPCs) sitting behind Transit Gateways, and each workload domain chooses how that Transit Gateway connects out. Centralized Connectivity keeps north-south traffic funneled through a dedicated Edge cluster, and only becomes VPC-ready once you configure that Edge cluster with an active-standby Tier-0 gateway after domain creation. Distributed Connectivity is VPC-ready as soon as the domain is created, but needs a Virtual Network Appliance cluster deployed afterward if you want the Distributed Transit Gateway to provide stateful NAT or load balancing. Shared-vs-dedicated NSX and centralized-vs-distributed connectivity are two independent switches you flip for every domain -- not one combined choice.

## What's Next

Next in this series: NSX Edge Cluster Deep Dive: Tier-0/Tier-1 Gateways, VPN, and North-South Firewall Design.

## Further Reading (Official Broadcom Documentation)

- [Create a New Workload Domain](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/working-with-workload-domains/deploy-a-vi-workload-domain-using-the-sddc-manager-ui.html)
- [VMware Cloud Foundation Architecture Models](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts/design-guide-vmware-cloud-foundation-architecture-models.html)
- [Managing Virtual Private Clouds in vCenter](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/managing-virtual-private-clouds-in-vcenter.html)
- [VMware Configuration Maximums for VCF 9](https://configmax.broadcom.com/guest?vmwareproduct=SDDC%20Manager&release=9.0.0&categories=17-0,73-0,165-0)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
