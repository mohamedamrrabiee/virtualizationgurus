---
title: "Physical Network Design: VDS Separation, ToR Switches, and BGP Uplinks"
date: 2026-07-24
draft: true
tags: ["Networking", "Physical Network", "VDS", "BGP", "ToR"]
categories: ["VCF 9", "Networking"]
description: "How VCF 9.1 expects the physical fabric to look before you ever build a workload domain -- rack-level fault tolerance, ToR trunk and MTU requirements, vSphere Distributed Switch traffic separation profiles, and BGP uplinks from NSX Edge to the physical network."
---

## Introduction

Every workload domain you'll ever stand up in VCF inherits whatever the physical network underneath it can actually deliver. By the time you're in the workload domain creation wizard picking a VDS profile, the rack layout, the ToR trunk configuration, and the MTU on every switch port in between have already decided how much of that wizard's promise you can keep. This post works bottom-up: what the physical fabric needs to provide, how vSphere Distributed Switches carve that fabric into traffic types, and how NSX Edge nodes hand off to it over BGP.

## Architectural Overview

```
Spine / Core Routers
| eBGP |
+--------v--------+ +--------v--------+
| ToR Switch A | <== 802.1Q trunk ==> | ToR Switch B |
+--------+--------+ +--------+--------+
| 2x 25GbE+ per host | 2x 25GbE+ per host
+---------------+---------------+
|
+------------v------------+
| ESX Host |
| vSphere Distributed |
| Switch (traffic-type |
| separated portgroups) |
| Mgmt | vMotion | vSAN |
| NSX Host TEP overlay |
+------------+------------+
|
+------------v------------+
| NSX Edge Node |
| Tier-0 uplinks --eBGP--> ToR/Spine |
+--------------------------+
```

## Rack-Level Fabric: Where Bottlenecks Actually Come From

Broadcom's data center network design guidance frames physical fault tolerance in layers -- sites, availability zones, witness sites, and racks -- and racks are where most day-to-day network design decisions actually live. Two hosts on the same ToR switch typically see no fabric-induced bottleneck; hosts on different switches, whether in the same rack or across racks, can be constrained by over-subscription on the links between switches or through the spine. That's not a theoretical concern -- it's the reason "which rack is this host in" is a real design input, not just a facilities detail.

## ToR Switch Requirements: Trunks, Uplinks, and MTU

Each ToR switch pair is configured to carry every VLAN a host needs over an 802.1Q trunk, and each ESX host connects to that ToR pair with two or more redundant ports, recommended at 25GbE or higher. MTU is the detail that's easy to under-provision: NSX Geneve encapsulation sets the don't-fragment bit on overlay traffic between host and Edge TEPs, so the whole path -- host physical NICs, ToR ports, spine, and every hop in between -- has to carry it without fragmenting. The minimum required MTU is 1600, but 1700 is the recommended figure, sized to leave headroom for future Geneve header growth rather than the bare minimum.

## VDS Separation: Five Profiles for Splitting Traffic

The workload domain creation wizard doesn't make you hand-design a VDS from nothing -- it offers preconfigured profiles, each mapping traffic types onto one or more distributed switches with dedicated physical NICs:

| Profile | What it separates |
|---|---|
| Default | Single VDS, unified fabric for every traffic type |
| Storage Traffic Separation | Two VDS: one dedicated to storage, one for everything else |
| NSX Traffic Separation | Two VDS: one dedicated to NSX (overlay) traffic, one for everything else |
| Storage and NSX Traffic Separation | Three VDS: storage, NSX, and everything else, each isolated |
| Custom Switch Configuration | Build your own VDS layout, copying from a profile or starting fresh |

Whichever profile you pick, some traffic types -- Management, vMotion, vSAN, and NSX -- can only be configured once per cluster, while NSX and Public traffic types can span multiple VDS if your custom configuration calls for it. Uplinks per switch are either individual VDS Uplinks (software load-balanced via LBT or virtual-port-ID hashing, no special physical switch configuration required) or a VDS LAG bundling multiple physical NICs under LACP -- which does require matching LACP configuration on the ToR side, active or passive.

## BGP Uplinks: Getting NSX Edge Talking to the Physical Fabric

Once traffic reaches an NSX Edge node, the Tier-0 gateway's uplinks are where the overlay world hands off to the physical one, and that handoff is BGP in the overwhelming majority of VCF designs. eBGP neighbors must sit directly connected in the same subnet as the Tier-0 uplink -- multi-hop eBGP is supported but requires explicit configuration -- and both a local AS number and the physical router's remote AS number are required before the session comes up. Active-active Tier-0 gateways default to ASN 65000 and enable BGP automatically; active-standby gateways have no default ASN and start with BGP disabled.

For load distribution across multiple uplinks, ECMP hashes on the standard 5-tuple (protocol, source/destination address, source/destination port). If your physical topology advertises routes with the same AS-path length but different AS-path content -- common with certain multi-uplink or multi-router designs -- ECMP alone won't use all of them; Multipath Relax has to be enabled on top of ECMP to allow load-sharing across paths that only differ in AS-path values. On the resiliency side, BFD intervals as low as 500ms are supported for Edge nodes running as VMs, and MD5 authentication is available on the BGP session itself if your network team requires it.

## Putting It Together: A Design Checklist

None of these layers are independent decisions. A VDS profile that isolates NSX traffic onto its own switch is only as good as the ToR trunk and MTU underneath it; a beautifully tuned BGP uplink is only as resilient as the rack fault-tolerance model it's peering out of. Before a workload domain goes live, it's worth walking the stack top to bottom: confirm the VDS profile matches the isolation the workload actually needs, confirm every switch in the Geneve path carries at least 1700 MTU, confirm ToR uplinks are redundant at 25GbE or better, and confirm the Tier-0 BGP configuration -- AS numbers, ECMP, Multipath Relax if needed -- matches what the physical network team actually configured on their side.

## What's Next

Next in this series: Workload Domain Creation: Greenfield vs Import Existing vCenter.

## Further Reading (Official Broadcom Documentation)

- [Data Center Network Requirements](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/design-library/datacenter-network-requirements.html)
- [Create a New Workload Domain](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/working-with-workload-domains/deploy-a-vi-workload-domain-using-the-sddc-manager-ui.html)
- [Configure BGP](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/advanced-network-management/administration-guide/tier-0-gateways/configure-bgp-in-nsx.html)
- [Tier-0 Gateways](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/tier-0-gateways.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
