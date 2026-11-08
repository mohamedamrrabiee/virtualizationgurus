---
title: "Tier-0 Active/Standby and eBGP to the Lab Router, Verified from Both Sides"
date: 2026-11-17
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "BGP", "Tier-0", "Networking"]
categories: ["VCF 9", "Lab Series"]
labPart: 16
cover:
  image: "/images/covers/lab-tier0-bgp-lab-router.jpg"
  alt: "Tier-0 Active/Standby and eBGP to the Lab Router, Verified from Both Sides"
  relative: false
description: "The Tier-0 gateway and eBGP part of the centralized connectivity wizard: every uplink and BGP value used, what the lab router and NSX each show, and one brief session flap while the workflow was still running."
---

## Overview

The guided Edge deployment from the previous post ends with the wizard asking for the Tier-0 gateway uplinks and BGP. This post covers that second half: Active/Standby high availability, two eBGP sessions per Edge, and how to prove it works from the router side and from the NSX side.

In this lab the Tier-0 `vg1-w01-t0-01` came up with four eBGP sessions Established to the lab router, and both Edge nodes showed Up and Success about 20 minutes after the wizard started. One thing worth knowing up front: for a short time while the workflow was still running, the Edge 1 sessions dropped back to Connect and then recovered on their own.

## Architecture at a glance

The four eBGP sessions between the two Edge nodes and the lab router, each over its own VLAN.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-tier0-bgp-lab-router-glance.svg"></object>
</div>

## What the documentation says

Before the lab values, the parts of the VCF 9.1 documentation that shaped them:

-> **Tier-0 HA mode**: Active/Standby uses two Edge nodes, one forwarding and one standing by, and supports stateful services such as NAT. Active/Active uses up to eight Edge nodes with ECMP and does not support stateful services. The VPC default outbound NAT is a stateful service, so Active/Standby is the fit for VPCs that need it, and it is what the wizard configured here.

-> **Two BGP peers per Edge**: the documentation asks for each Edge to peer with two top-of-rack switches. This lab has one router, so I gave it two VLAN interfaces and peered each Edge uplink with a different one. That keeps the session count realistic but is a lab simplification, not a substitute for two physical switches.

-> **BFD**: recommended for faster failure detection. It was off in this lab, with no BGP password either.

-> **Private ASN and subnet size**: use a unique private ASN for the Tier-0 and a peering subnet of /28 or larger. The lab used 65100 on the Tier-0, 65001 on the router, and /24 peering subnets.

-> **MTU**: the uplink MTU accepts 1500 to 9000. The uplinks here stayed at 1500.

-> **Tier-0 HA is independent of the transit gateway HA setting**: two separate things, even though both read Active Standby in the UI.

## The values used

| Setting | Value |
|---|---|
| Tier-0 gateway | `vg1-w01-t0-01`, Active Standby |
| BGP | On, local ASN 65100, router ASN 65001 |
| Edge 1 uplinks | 10.20.26.2/24 on VLAN 3330 and 10.20.27.2/24 on VLAN 3331 |
| Edge 2 uplinks | 10.20.26.3/24 on VLAN 3330 and 10.20.27.3/24 on VLAN 3331 |
| BGP peers | Router addresses 10.20.26.1 and 10.20.27.1 |
| Uplink MTU | 1500 |
| BFD and BGP password | Off and empty |
| Total sessions | Four, two per Edge, each over its own VLAN |

The first form, for Edge 1, takes the VLAN, the interface CIDR, the peer address, the MTU and the BGP peer settings. For Edge 2 the BGP peer ASN, BFD and password fields are locked, with a note that the peer address is the same one already entered for the first Edge. You only fill the interface VLAN, CIDR and MTU again.

![Workload Domain Connectivity with BGP On and local ASN 65100](/images/lab/lab-S173.jpg)
*Workload Domain Connectivity: BGP on, local ASN 65100, and two uplinks to set per Edge node.*

![Second uplink form for Edge 2 with VLAN 3331 and locked BGP fields](/images/lab/lab-S175.jpg)
*The second uplink of Edge 2: VLAN 3331, 10.20.27.3/24, peer 10.20.27.1. The BGP peer fields are locked because the peer address was already used.*

![Review and Deploy with Tier-0 details](/images/lab/lab-S178.jpg)
*Review and Deploy: Edge cluster `vg1-w01-ec01`, Medium, gateway `vg1-w01-t0-01`, Active Standby, BGP On.*

## The lab router side

The router is a Linux host running FRR with the local AS 65001. Two VLAN interfaces sit in the Edge uplink subnets, so the router owns 10.20.26.1 and 10.20.27.1. Its policy is simple:

-> **It sends a default route** to the Tier-0.

-> **It accepts only prefixes inside 10.80.0.0/22**, which is the external block you will meet in the next post.

The documentation recommends the same shape for a real ToR: advertise the default route into the Tier-0 and accept only the prefixes you expect from it.

The commands used to check it:

```bash
ip -br addr | grep -E 'vlan33(29|30|31)'
sudo vtysh -c 'show bgp summary'
sudo vtysh -c 'show bgp neighbors'
sudo vtysh -c 'show ip route bgp'
watch -n 10 "sudo vtysh -c 'show bgp summary'"
```

The `watch` form refreshes every 10 seconds, which is what you want while the workflow is still running.

## The session flap

Two captures from the router, 30 seconds apart. The router clock shows UTC, which is three hours behind my local time in the lab notes.

![Router show bgp summary with all four sessions up](/images/lab/lab-S240.jpg)
*19:36:08 on the router: all four sessions up for about one minute, one prefix sent (the default route), none received yet.*

![Router show bgp summary with the Edge 1 sessions in Connect](/images/lab/lab-S179.jpg)
*30 seconds later: the Edge 2 sessions are still up, and the two Edge 1 sessions are back in Connect.*

The FRR neighbor detail for the Edge 1 sessions showed a reset reason of a notification sent for an unexpected message in the OpenSent state. My reading is that the Edge 1 side was still being configured by the connectivity workflow when the session tried to open, so the two ends collided. That is an inference from the symptom and the timing, not something I proved. Nothing needed fixing: all four sessions were Established again by 22:39 local and stayed up.

-> **Judge BGP only after the workflow finishes**: a Connect state in the middle of the run is not a failure.

-> **Use `watch`, not a single command**: one snapshot can show either the good or the bad moment.

## The NSX side

The router side proves the sessions. The NSX side proves the Edges. In NSX Manager, System, Fabric, Edges, the cluster `vg1-w01-ec01` shows two nodes, Connectivity Up and Status Success, with Gateway `vg1-w01-t0-01`.

![NSX Edges list showing both nodes Up and Success](/images/lab/lab-S180.jpg)
*NSX Manager, Edges: cluster Success, `vg1-w01-en01` and `vg1-w01-en02` Up, with their TEP addresses.*

To complete the picture from the Edge itself, run these on an Edge node as admin:

```bash
get logical-routers
vrf <tier0-sr-vrf-id>
get bgp neighbor summary
get route 0.0.0.0/0
```

The first lists the logical routers and their VRF IDs, the next enters the Tier-0 service router, then the BGP neighbor summary and the default route learned from the router.

## The topology as built



<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-asbuilt-edge-bgp-vpc.svg"></object>
</div>

*Both Edges peer with the lab router over two uplink VLANs. Only 10.80.0.0/22 is advertised.*

## What to take from it

-> **Pick Active/Standby when you need NAT**: the VPC default outbound NAT is stateful, and stateful services need Active/Standby.

-> **Plan the session count**: two Edges with two uplinks each means four sessions, and four peering addresses on the router side.

-> **Filter in and out**: the router sends only a default and accepts only the expected block.

-> **Check both sides**: the router shows sessions, NSX shows Edge health, and neither alone is the whole answer.

-> **Wait for the workflow**: a brief Connect state while the wizard is still deploying is normal in this lab.

-> **Know the lab shortcuts**: one router standing in for two ToR switches, BFD off, no BGP password and MTU 1500 are fine here and are not a production design.

A note on sizing: the lab runs Medium Edges, which suits this lab. For Supervisor or VCF Automation workloads the documentation recommends Large or XLarge, so size up before you copy this build.

## What's Next

Next in this series: the centralized transit gateway and IP blocks, and what gets advertised to the router and what does not.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [VPC centralized network connectivity with guided Edge deployment (VMware Cloud Foundation blog)](https://blogs.vmware.com/cloud-foundation/2025/06/25/vpc-centralized-network-connectivity-with-guided-edge-deployment/)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
