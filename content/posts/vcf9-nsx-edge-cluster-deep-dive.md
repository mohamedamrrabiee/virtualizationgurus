---
title: "NSX Edge Cluster Deep Dive: Tier-0/Tier-1 Gateways, VPN, and North-South Firewall Design"
date: 2026-08-05
draft: true
tags: ["NSX", "Edge Cluster", "Tier-0", "Tier-1", "VPN", "Firewall", "Networking"]
categories: ["VCF 9", "NSX"]
description: "A deep dive into NSX Edge cluster architecture in VCF 9.1 -- Tier-0 and Tier-1 gateway roles, HA modes, VPN connectivity, and north-south firewall design with vDefend."
---

## Introduction

Every workload domain eventually needs to talk to the outside world, and in NSX that conversation happens at the edge. The NSX Edge cluster is where policy meets physical: it hosts the Tier-0 gateway that peers with your physical network, terminates VPN tunnels, and enforces the firewall rules that decide what's allowed to cross the north-south boundary. Get the Edge cluster's HA design wrong and you inherit asymmetric routing, dropped stateful sessions, or a firewall that silently fails open on a node switchover. This post breaks down the Tier-0/Tier-1 split, the HA modes that govern them, and how VPN and firewall services layer on top.

## Architectural Overview

```
Physical / Upstream Network
| (BGP / static)
+---------v---------+
| Tier-0 Gateway | active-active or active-standby
| (NSX Edge Cluster)|
+---------+---------+
100.64.0.0/16 transit
+---------v---------+
| Tier-1 Gateway | downlinks only, no direct N-S uplink
+---+-----------+---+
| |
+------v---+ +-----v----+
| Segment A| | Segment B| (E-W via Distributed Firewall)
+----------+ +----------+

VPN (IPSec / L2) --+ +-- vDefend Gateway Firewall
active-standby only v v N-S stateful L2-7 inspection
+-------------------+
| Tier-0 Gateway |
+-------------------+
```

## Tier-0 Gateway: The Fleet's Front Door

The Tier-0 gateway is the top-tier gateway in the NSX topology -- it's the only place where NSX hands off to your physical network. Southbound, it connects to one or more Tier-1 gateways or directly to segments; northbound, it peers with physical routers. A given NSX Edge node supports a single Tier-0 gateway, which is why Edge cluster sizing is really a Tier-0 sizing exercise. The default T0-T1 transit subnet is 100.64.0.0/16, with an internal transit subnet of 169.254.0.0/24 used for intra-tier links -- worth knowing before you start allocating overlapping RFC 1918 ranges elsewhere in the fabric.

## Tier-1 Gateway: Segment-Level Routing

Tier-1 gateways sit below Tier-0 and own the downlinks to your segments. They have no direct physical uplink of their own -- everything they don't know how to route gets pushed up to Tier-0. Tier-1 supports route advertisement back to Tier-0, static routes, and even recursive static routes for more deliberate control over what gets learned where. In practice, Tier-1 is where you scope tenancy or application boundaries, while Tier-0 stays focused on the fleet-wide north-south path.

## High Availability: Active-Active vs Active-Standby

Both Tier-0 and Tier-1 gateways support two HA modes. Active-active is the default: both Edge nodes forward traffic simultaneously and load-balance across the pair, which is great for throughput but has a hard limitation -- stateful services (SNAT, DNAT, load balancing, stateful firewall, and VPN) are not supported in this mode, because there's no guarantee a return packet lands on the node that saw the original flow.

Active-standby elects a single active node and holds the second in reserve, with all stateful services allowed. Failover behavior itself is configurable: preemptive mode fails back to the original active node once it recovers, non-preemptive leaves the newly active node in place until the next failure. If your design needs NAT, a load balancer, or VPN anywhere on that gateway, active-standby isn't optional -- it's a prerequisite. An HA VIP is also available in active-standby mode, letting a single external interface failure be absorbed without a routing protocol re-convergence, though it's intended to work with static routing rather than BGP.

## VPN Connectivity: IPSec and L2 VPN

NSX Edge supports two VPN types for extending connectivity beyond the fleet. IPSec VPN builds site-to-site tunnels using ESP in tunnel mode (IP protocol 50) with IKE negotiation over UDP 500, or UDP 4500 when NAT-traversal is involved. You can run it policy-based or route-based, authenticating with a pre-shared key or certificates using SHA256/384/512 with RSA. L2 VPN, by contrast, extends a Layer 2 segment across data centers -- useful for migrations or stretched clusters rather than routed connectivity.

Both VPN types share the same HA constraint as other stateful services: IPSec VPN requires the Tier-0, Tier-0 VRF, or Tier-1 gateway to be running in active-standby mode, and on failover the VPN state is synchronized to the standby node so tunnels don't need to renegotiate from scratch. One notable gap: an IPSec VPN session isn't supported directly between a parent Tier-0 and an attached Tier-0 VRF.

## North-South Firewall with vDefend

Firewalling in NSX comes in two form factors. The Distributed Firewall runs per-vSphere-workload and handles east-west traffic between VMs regardless of which segment they sit on. The Gateway Firewall is the north-south counterpart, deployed on a vSphere host as either a VM or a bare-metal ISO appliance, to inspect traffic crossing the Tier-0/Tier-1 boundary.

Both are part of the broader vDefend Firewall with Advanced Threat Prevention, a software-defined L2-7 stateful firewall stack that layers IDS/IPS, network sandboxing, and network traffic analysis with NDR-style aggregation and correlation on top of basic packet filtering. For the Edge cluster specifically, the Gateway Firewall is your enforcement point for anything leaving or entering the fleet -- and like NAT and VPN, its statefulness depends on the gateway running in active-standby HA.

## Deploying the Edge Cluster

NSX Edge nodes can be installed through the NSX UI, the vSphere Client, or the CLI using the OVF tool, and are then grouped into an Edge cluster via the "Create an NSX Edge Cluster and Add Edge Nodes" workflow. This matters for workload domain connectivity models too: a domain using Centralized Connectivity only becomes VPC-ready after you've separately deployed an Edge cluster with a Tier-0 in active-standby mode, whereas Distributed Connectivity is VPC-ready immediately but still needs a Virtual Network Appliance cluster if you want stateful NAT or load balancing.

## What's Next

Next in this series: vSAN ESA vs OSA: Storage Architecture Decisions.

## Further Reading (Official Broadcom Documentation)

- [NSX Advanced Network Management](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management.html)
- [Tier-0 Gateways](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/tier-0-gateways.html)
- [Add an NSX Tier-0 Gateway](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/tier-0-gateways/add-an-nsx-tier-0-gateway.html)
- [Tier-1 Gateways](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/tier-1-gateways.html)
- [Installing NSX Edge](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/installing-nsx-edge.html)
- [Understanding IPSec VPN](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/virtual-private-network-vpn/understanding-ipsec-vpn.html)
- [vDefend Firewall with Advanced Threat Prevention](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/security.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
