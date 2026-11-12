---
title: "VPCs and Subnets from vCenter: Private, Public, DHCP, DNS and NTP"
slug: "lab-vpcs-subnets-vcenter"
date: 2027-02-18
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "VPC", "DHCP", "Networking"]
categories: ["VCF 9", "Lab Series"]
labPart: 18
cover:
  image: "/images/covers/lab-vpcs-subnets-vcenter.jpg"
  alt: "VPCs and Subnets from vCenter: Private, Public, DHCP, DNS and NTP"
  relative: false
description: "Building two VPCs and three subnets in the vSphere Client: private and public access modes, the subnet size choices, DHCP, and why DNS and NTP live in the VPC service profile and not in the connectivity profile."
---

## Overview

With the transit gateway in place, VPCs are quick to create. The vSphere Client builds a VPC, then its subnets, and the choices that matter are the access mode, the subnet CIDR and where DHCP, DNS and NTP are configured.

In this lab I built two VPCs and three subnets in about 25 minutes, from 22:49 to 23:14 local, then spent a few more minutes finding where DNS and NTP belong. That search is the most useful part of this post.

## Architecture at a glance

The two VPCs, their three subnets and the SNAT addresses, with the shared service profile underneath.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-vpcs-subnets-vcenter-glance.svg"></object>
</div>

## The VPCs

| VPC | Private CIDR | Profile |
|---|---|---|
| `vpc-app01` | 172.20.0.0/20 | Default VPC Connectivity Profile, Connectivity Policy None |
| `vpc-dev01` | 172.20.16.0/20 | Default VPC Connectivity Profile, Connectivity Policy None |

The private VPC CIDR is local to the VPC and is not part of either block from the previous post. I carved one /20 per VPC out of 172.20.0.0/16, so they cannot overlap. The dialog accepts up to five CIDRs per VPC.

![New Virtual Private Cloud dialog for vpc-app01](/images/lab/lab-S182.jpg)
*Creating `vpc-app01`: private CIDR 172.20.0.0/20 and the Default VPC Connectivity Profile.*

![New Virtual Private Cloud dialog for vpc-dev01](/images/lab/lab-S185.jpg)
*Creating `vpc-dev01`: private CIDR 172.20.16.0/20, same profile.*

## The subnets

The subnet wizard has three steps: basic information, DHCP configuration and a ready-to-complete page. The documentation lists three access modes: Private (the default), Public and Private to the transit gateway. I used the first two.

| Subnet | VPC | Access mode | Address source | DHCP |
|---|---|---|---|---|
| `app-private` | `vpc-app01` | Private - VPC | Manual CIDR 172.20.1.0/24 | DHCP server |
| `app-public` | `vpc-app01` | Public | Auto-allocated /28 from the external block, which gave 10.80.0.16/28 | DHCP server |
| `dev-private` | `vpc-dev01` | Private - VPC | Manual CIDR 172.20.17.0/24 | DHCP server |

What changes between the modes:

-> **Private - VPC**: the subnet uses VPC address space. Traffic leaving the VPC is source NATed with the VPC SNAT address. The IP block field offered `default--vpc-app01 (172.20.0.0/20)`, which is the block created for the VPC itself.

-> **Public**: the subnet draws from the external block, so its addresses are routable and advertised over BGP with no NAT. With Auto allocate on, you choose a size instead of a CIDR. The default offered was 64 IPs (/26) and I chose 16 IPs (/28).

-> **Subnet size is final**: the documentation says the size cannot be changed after creation, and gives a range of 8 to 65536 addresses with a default of 64. Pick it with growth in mind.

![Add Subnet app-private first view](/images/lab/lab-S241.jpg)
*`app-private`, first view: access mode Private - VPC, IP block of the VPC, VPC Gateway Connectivity Yes.*

![Add Subnet app-private with DHCP server selected](/images/lab/lab-S183.jpg)
*`app-private`: 172.20.1.0/24 entered as the IP CIDR, DHCP server chosen.*

![Add Subnet app-public first view](/images/lab/lab-S243.jpg)
*`app-public`, first view: access mode Public, the external block as the IP block, auto allocate with the default /26.*

![Add Subnet app-public with a /28 and DHCP server](/images/lab/lab-S184.jpg)
*`app-public`: a /28 (16 IPs) from the external block, DHCP server.*

![Add Subnet dev-private](/images/lab/lab-S244.jpg)
*`dev-private` in `vpc-dev01`: 172.20.17.0/24, Private - VPC.*

## DHCP, DNS and NTP

The documentation lists three DHCP modes for a subnet: NSX-managed DHCP server (the default), DHCP relay to an external server, and none. DNS server settings only apply when DHCP is NSX-managed.

The DHCP step of the subnet wizard then showed this for `app-private`:

![Subnet DHCP Configuration showing DNS Server IPs and NTP Server IPs as Not Set](/images/lab/lab-S242.jpg)
*DHCP Configuration for `app-private`: DNS and NTP Not Set, lease time 86400 seconds, and a note that the DHCP server configuration comes from the service profile.*

The note on that page says it all: the DHCP server configuration is defined in the VPC Service Profile and applied to every VPC that uses the default profile. So the subnet has no DNS or NTP fields to fill.

I first looked in the VPC Connectivity Profile, because it was the profile attached to the VPC. It has Edge cluster, default outbound NAT and N-S services settings, and no DHCP, DNS or NTP fields at all. The NSX API reference agrees: the DHCP server settings, including DNS, NTP and lease time, belong to the VPC service profile (`VpcServiceProfile`, `dhcp_config.dhcp_server_config`).

The values saved in the service profile:

| Setting | Value |
|---|---|
| DHCP server | Enabled |
| DNS server IPs | 10.20.10.1 |
| NTP server IPs | 10.20.10.1 |
| Lease time | 86400 seconds |
| DHCP relay | Off |

Both DNS and NTP point at the lab router, which serves both in this lab. You can enter more than one DNS server, up to two.

![VPC Service Profile with DHCP, DNS and NTP](/images/lab/lab-S186.jpg)
*VPC, Profiles, VPC Service Profile: DHCP server enabled, DNS and NTP 10.20.10.1, lease time 86400 seconds.*

I saved the service profile at about 23:20, after the subnets existed. The test VMs then received the DNS server through DHCP and resolved names correctly.

## What to take from it

-> **Choose the access mode first**: it decides where the addresses come from and whether the subnet is NATed or advertised.

-> **Public subnets spend external block addresses**: size the external block for them, and for NAT addresses and VIPs.

-> **Size subnets once**: they cannot be resized after creation.

-> **DNS, NTP and lease time live in the VPC Service Profile**: set them there, once, before you create subnets, and every VPC using the profile inherits them.

-> **The connectivity profile is not the place**: it holds the Edge cluster, NAT and N-S services settings only.

-> **A DHCP-server subnet with no DNS set hands out nothing useful**: check the DHCP step before you click Next.

## What's Next

Next in this series: proving VPC isolation with PowerCLI test VMs and a ping matrix.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [Subnets in an NSX VPC (NSX 4.2 documentation)](https://docs.vmware.com/en/VMware-NSX/4.2/administration/GUID-CC2A7BC0-3021-4312-AF8C-941A995EE8E5.html)
- [VPC centralized network connectivity with guided Edge deployment (VMware Cloud Foundation blog)](https://blogs.vmware.com/cloud-foundation/2025/06/25/vpc-centralized-network-connectivity-with-guided-edge-deployment/)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
