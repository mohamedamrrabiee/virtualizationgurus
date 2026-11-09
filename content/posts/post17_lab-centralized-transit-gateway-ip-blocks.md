---
title: "Centralized Transit Gateway and IP Blocks: What Gets Advertised and What Does Not"
slug: "lab-centralized-transit-gateway-ip-blocks"
date: 2026-11-18
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "Transit Gateway", "VPC", "BGP"]
categories: ["VCF 9", "Lab Series"]
labPart: 17
cover:
  image: "/images/covers/lab-centralized-transit-gateway-ip-blocks.jpg"
  alt: "Centralized Transit Gateway and IP Blocks: What Gets Advertised and What Does Not"
  relative: false
description: "The VPC network configuration step of the centralized connectivity wizard: the external IP block, the private transit gateway block, which one is advertised over BGP, and what the lab router actually learned."
---

## Overview

The last page of the centralized connectivity wizard asks for two IP blocks, and they behave very differently. One is routable and advertised to the physical network. The other stays inside the transit gateway and is never advertised. Mixing them up is the easiest mistake on this page.

In this lab the external block was 10.80.0.0/22, created inside the wizard, and the private block was the one VCF had already created during bring-up. After the VPCs existed, the lab router learned only addresses from the external block, which is exactly the point.

## Architecture at a glance

How the Tier-0, the transit gateway and the two IP blocks fit together, and which block is advertised.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-centralized-transit-gateway-ip-blocks-glance.svg"></object>
</div>

## The two blocks

| Block | Purpose | Advertised over BGP |
|---|---|---|
| External IP block | Public subnets, NAT addresses and load balancer VIPs. Its addresses are routable outside | Yes |
| Private transit gateway IP block | Addressing between the VPCs and the transit gateway. Internal plumbing | No |

The documentation sets the sizes. The external block must be a /24 or larger, with up to five CIDRs. The private transit gateway block must be a /23 or larger, also up to five. Private VPC address ranges are a third thing: they are local to each VPC and are not part of either block.

-> **External block, lab value**: 10.80.0.0/22, a name of `vg1-w01-vpc-ext-ip-block`, visibility External.

-> **Private block, lab value**: the `Day0 Private Tgw Ip Block` that VCF created during bring-up. Its CIDR was not shown on this page. I later saw it as 172.31.0.0/16 in the Supervisor wizard, so I kept it rather than create a new one.

-> **Keep the external block unique**: it has to be an address range your physical network can route to the Edges and nowhere else.

![VPC external IP block field before the block exists](/images/lab/lab-S237.jpg)
*The external block field with no block yet: the wizard lets you create it right here.*

![External and private transit gateway blocks selected](/images/lab/lab-S177.jpg)
*Both blocks selected: `vg1-w01-vpc-ext-ip-block` as the external block and the Day0 private block.*

## What gets advertised

For the physical network to reach a VPC resource, the transit gateway routes must reach the Tier-0 and then BGP. The documentation says the Transit Gateway Static route source has to be redistributed into BGP so that public subnets, NAT addresses and VIPs are advertised. What the router received is the evidence in this lab.

From the router, after the VPCs were created:

| Learned route | Where it comes from |
|---|---|
| 10.80.0.0/32 | The SNAT address of `vpc-app01` |
| 10.80.0.1/32 | The SNAT address of `vpc-dev01` |
| 10.80.0.16/28 | The `app-public` subnet, allocated from the external block |

The router received all three over BGP from the active Edge, which was `en02`. The router did not receive 172.20.0.0/20, 172.20.16.0/20, or the private transit gateway block. That is the design working: private VPC ranges and the private block stay inside.

I checked the routes with `show ip route bgp` on the router at about 23:05, after the three subnets existed. The 10.80.0.0/22 prefix filter on the router would also have blocked anything else, so this result alone does not prove nothing else was advertised. The absence of the private ranges is consistent with the documentation, which says the private block is not advertised.

## Default outbound NAT and the SNAT addresses

Each VPC with a private subnet that reaches the outside gets a source NAT address from the external block. In this lab those were 10.80.0.0 for `vpc-app01` and 10.80.0.1 for `vpc-dev01`. The documentation describes this as the default outbound NAT, with one auto-created SNAT per VPC.

![VPC Connectivity Profile with Default Outbound NAT on](/images/lab/lab-S245.jpg)
*The Default VPC Connectivity Profile: Edge cluster `vg1-w01-ec01`, Default Outbound NAT On, N-S Services On. The external block field for default outbound NAT shows empty in this view.*

I opened this profile by mistake while looking for DNS and NTP, which turned out to belong somewhere else (the next post). The external block selector for the default outbound NAT reads empty in the screenshot, and the SNAT addresses still came from 10.80.0.0/22. Treat that as an observation from this lab, not a rule.

The SNAT mapping, 10.80.0.0 for app and 10.80.0.1 for dev, follows from the routes the router learned. The source address was not packet-captured on the router. The Distributed Firewall test later in the lab did confirm it indirectly: a rule matching source 10.80.0.1 dropped traffic from `vpc-dev01`.

## The transit gateway in vCenter

Once the workflow finishes, the transit gateway shows in vCenter, Networks, Transit Gateways, as `Default Transit Gateway`, connection Centralized, HA mode Active Standby, and no VPCs connected yet.

![vSphere Client Transit Gateways list showing Default Transit Gateway](/images/lab/lab-S181.jpg)
*vSphere Client, Networks, Transit Gateways: Default Transit Gateway, Centralized, Active Standby, 0 connected VPCs.*

## What to take from it

-> **Two blocks, two roles**: the external block is advertised and routable. The private transit gateway block is internal and never advertised.

-> **Size them to the documented minimums**: /24 or larger external, /23 or larger private.

-> **Filter on the router**: accepting only the external block, as this lab router does, is a clean way to keep the physical network tidy.

-> **Check what the router learned, not only what you configured**: `show ip route bgp` is the proof of what actually left the Tier-0.

-> **Check the redistribution setting**: the documentation says it matters for public subnets, NAT addresses and VIPs.

## What's Next

Next in this series: creating VPCs and subnets from vCenter, with private and public subnets, DHCP, DNS and NTP.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [VPC centralized network connectivity with guided Edge deployment (VMware Cloud Foundation blog)](https://blogs.vmware.com/cloud-foundation/2025/06/25/vpc-centralized-network-connectivity-with-guided-edge-deployment/)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
