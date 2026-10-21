---
title: "Advanced Services for VCF: VPC, Load Balancing, and Network Observability"
date: 2026-10-19
draft: false
tags: ["VCF", "VMware", "NSX", "VPC", "Load Balancing", "Avi", "Network Observability", "Cloud Foundation"]
categories: ["VCF 9", "Networking"]
description: "The services that sit on top of a VCF 9 VPC: service profiles, NAT and DHCP, the load balancing options and their entitlement, and how VCF Operations for Networks gives you flow visibility across the fleet."
seriesPart: 21
cover:
  image: "/images/covers/vcf9-advanced-services.jpg"
  alt: "Advanced Services for VCF: VPC, Load Balancing, and Network Observability"
  relative: false
---

## Overview

Over the previous 20 posts, the series built the platform: instances, domains, NSX, vSAN, lifecycle and security. This last post covers what sits on top of it once workloads arrive: the services a VPC provides, the load balancing options and who is entitled to what, and the tooling that shows you what the network is actually doing.

None of these is a new component. Together they decide whether a VCF 9 environment is something application teams can consume without a ticket, and something operations teams can troubleshoot without guessing.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/vcf9-advanced-services.svg"></object>
</div>

## VPC Services: Set Once, Reuse Everywhere

Post 5 covered VPC architecture, subnet types and Transit Gateways. The service layer on top is smaller than most people expect, and it is mostly configured in one place.

-> **VPC service profile**: a collection of services (DHCP, DNS forwarder and subnet profiles). Broadcom describes it as simplifying the configuration of common services across multiple VPCs, so you define the behavior once and reference it from every VPC that needs it.

-> **DHCP, static routes and groups**: regardless of the external connection type (centralized or distributed), you can configure static routes, groups and a DHCP server in a VPC.

-> **NAT**: centralized connectivity supports full NAT configuration. Private VPC subnets need NAT to reach the outside, and external IPs give a workload on a private network outside connectivity through 1:1 IP translation.

For platform teams, the practical takeaway is to standardize on a small number of service profiles per environment (for example, one per tenant class) instead of editing DHCP and DNS settings VPC by VPC.

## Load Balancing: Know Your Entitlement Before You Design

Load balancing is where designs most often go wrong, and the reason is licensing as much as technology. Broadcom changed the entitlement of the built-in NSX load balancer starting with VCF 9.0: general-purpose load balancing features are no longer part of the VCF entitlement, and Broadcom recommends VMware Avi Load Balancer instead.

-> **NSX load balancer, still included for two use cases**: load balancing for VCF infrastructure components such as VCF appliances, and Layer 4 load balancing for vSphere Supervisor, including VM Service, vSphere Pods, VKS clusters and Supervisor Services.

-> **Avi Load Balancer, for everything else**: Broadcom describes Avi as a superset of NSX load balancing, adding capabilities such as global server load balancing (GSLB), advanced analytics, container ingress, security and WAF.

-> **Existing NSX 4.x and NSX-T 3.x entitlements are not affected**: those customers can keep using the load balancer for all traffic types until the end of life of each release.

For Supervisor specifically, Broadcom states that both Avi and NSX VPC networking are fully supported in VCF 9.x, and that the choice should rest on functional requirements. NSX VPC is the default recommended framework for VCF 9.1 Automation, while Avi fits environments that need advanced application delivery features, and customers moving to VCF 9.1 do not need to abandon existing Avi licenses.

| If you need | Start with |
|---|---|
| Supervisor, VKS and VM Service load balancing with the simplest automation story | NSX with VPC networking |
| Load balancing for VCF infrastructure components | NSX load balancer |
| GSLB, deep traffic analytics, container ingress or WAF | Avi Load Balancer |
| General application load balancing on a new VCF 9 platform | Avi Load Balancer |
| An existing NSX 4.x or NSX-T 3.x deployment | Keep it, and plan the move before end of life |

One caution: the entitlement wording is Broadcom's to interpret, not ours. Before committing a design that relies on the NSX load balancer for application traffic, confirm the use case with your Broadcom representative.

## Network Observability: VCF Operations for Networks

A VPC makes the network self-service, which also means the people running it no longer see every change as it happens. VCF Operations for Networks is the tool that closes that gap. Broadcom positions it as network operations for VCF private clouds, helping network teams and VCF administrators plan, deploy and operate the network.

-> **Flow visibility and application discovery**: it uses network flow data to discover existing applications and understand the current network state, with granular visibility across VMs and containers through IPFIX support on VDS and the Antrea CNI.

-> **VPC planning**: it analyzes VLANs, traffic patterns and reachability to plan a move from VDS networking to VPC-based networking, maps applications to VPC subnets and helps connect workloads to the VPC Transit Gateway. This makes it a useful assessment tool before a migration, not only a monitoring tool afterwards.

-> **Troubleshooting**: dashboards for network inventory and capacity, real-time metrics for NSX Edge and ESX host networking in a troubleshooting workbench, and end-to-end visibility across virtual and physical networks, including alerts, metrics, logs and flows. It also helps troubleshoot connectivity between containerized workloads on VKS.

### Where flow data goes missing

Flow visibility depends on correct IPFIX configuration end to end, and Broadcom's knowledge base documents several situations where flows go missing. Check these before opening a case:

-> **NSX flows not visible despite IPFIX being enabled**: [KB 440684](https://knowledge.broadcom.com/external/article/440684/flows-and-telemetry-metrics-not-visible.html).

-> **IPFIX flow data dropped because of SNAT**: [KB 432629](https://knowledge.broadcom.com/external/article/432629/ipfix-flow-data-dropped-in-vcf-operation.html).

-> **VDS flow collection settings not persisting after an upgrade to VCF Operations for Networks 9.1.0**: [KB 446159](https://knowledge.broadcom.com/external/article/446159/vds-flow-collection-settings-do-not-pers.html).

-> **Incomplete flow visibility after migrating VMs from distributed port groups to NSX segments**: [KB 448198](https://knowledge.broadcom.com/external/article/448198/incomplete-flow-visibility-in-vcf-operat.html).

-> **Missing NSX DFW flows for load balancer virtual IPs**: [KB 450436](https://knowledge.broadcom.com/external/article/450436/missing-nsx-dfw-flows-in-vcf-operations.html).

## Design Checklist

-> **Service profiles**: define a small set and reuse them across VPCs.

-> **NAT model**: decide per VPC which subnets are private, which are public and where external IPs are needed.

-> **Load balancing**: map every use case to the entitlement it falls under before choosing a product.

-> **Observability**: enable IPFIX on VDS and NSX from day one, and plan the VCF Operations for Networks deployment alongside the VPC design, not after it.

## What's Next

This was the last post in the VCF 9 series. The next series is hands-on: the [Lab Series](/lab-series/) builds a VCF 9.1.1 lab end to end, from nested hosts to a Supervisor and VKS cluster, with the real issues along the way.

## Further Reading (Official Broadcom Documentation)

- [Virtual Private Clouds Overview](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/advanced-network-management/virtual-private-cloud-in-nsx/virtual-private-clouds-overview.html)
- [Avi Load Balancer vs. NSX VPC for Supervisor Clusters in VCF 9.x (KB 441725)](https://knowledge.broadcom.com/external/article/441725/avi-load-balancer-vs-nsx-vpc-for-supervi.html)
- [VMware NSX Load Balancer Entitlement Changes (KB 401492)](https://knowledge.broadcom.com/external/article/401492/)
- [NSX Load Balancer to VMware Avi Load Balancer Migration (KB 439411)](https://knowledge.broadcom.com/external/article/439411/nsx-load-balancer-to-vmware-avi-load-bal.html)
- [VCF Network Operations Product Overview](https://www.vmware.com/docs/vmw-vcf-network-operations-product-overview)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
