---
title: "VCF 9 Architecture Deep Dive: What Changed and Why It Matters"
date: 2026-06-15
draft: false
tags: ["VCF", "VMware", "Architecture", "Cloud Foundation"]
categories: ["VCF 9", "Architecture"]
description: "A comprehensive look at the architectural changes in VMware Cloud Foundation 9, including the new management domain design, NSX 9.0 updates, vSAN ESA improvements, and the new VCF Operations management plane."
---

## Overview

VMware Cloud Foundation 9 (VCF 9) represents a significant evolution in how Broadcom delivers its software-defined data center stack. Released on June 17, 2025, VCF 9 unifies ESX 9.0, vCenter 9.0, NSX 9.0, and vSAN under a single platform version. In this post, we explore the core architectural changes that differentiate VCF 9 from its predecessors and understand why these changes matter for enterprise deployments.

## VCF 9 Architecture Overview

The diagram below shows the high-level architecture of a VCF 9 environment, spanning the management domain and workload domains with all core components:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                        VMware Cloud Foundation 9 - Architecture                      │
└──────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                               MANAGEMENT PLANE                                      │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐    │
│  │                            VCF Operations                                   │    │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐  │    │
│  │  │  Fleet & Domain  │  │  Lifecycle Mgmt  │  │   API / Automation       │  │    │
│  │  │    Management    │  │    & Upgrades    │  │   (REST / PowerCLI)      │  │    │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                     │
│  ┌───────────────────────────┐    ┌──────────────────────────────────────────────┐  │
│  │  NSX Manager              │    │  vCenter Server                              │  │
│  │  ┌────┐ ┌────┐ ┌────┐    │    │  ┌──────────────┐  ┌────────────────────┐   │  │
│  │  │NSX1│ │NSX2│ │NSX3│    │    │  │   DRS / HA   │  │  Lifecycle Mgmt    │   │  │
│  │  └────┘ └────┘ └────┘    │    │  └──────────────┘  └────────────────────┘   │  │
│  │  (3-node HA cluster or    │    └──────────────────────────────────────────────┘  │
│  │   single node for lab)    │                                                     │
│  └───────────────────────────┘                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     MANAGEMENT DOMAIN (min. 3 ESX hosts)                            │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                            vSAN ESA Cluster                                    │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             │ │
│  │  │   ESX Host 1     │  │   ESX Host 2     │  │   ESX Host 3     │  [+more]    │ │
│  │  │ NVMe  NVMe  NVMe │  │ NVMe  NVMe  NVMe │  │ NVMe  NVMe  NVMe │             │ │
│  │  │ [ NSX DFW (EDP)] │  │ [ NSX DFW (EDP)] │  │ [ NSX DFW (EDP)] │             │ │
│  │  │  VTEP | TEP Pool │  │  VTEP | TEP Pool │  │  VTEP | TEP Pool │             │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘             │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  NETWORKS: [ Management VLAN ] [ vMotion VLAN ] [ vSAN VLAN ] [ NSX Overlay Trunk] │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                  WORKLOAD DOMAIN(S) (optional, expandable)                          │
│                                                                                     │
│  ┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐ │
│  │         Workload Domain A            │  │         Workload Domain B            │ │
│  │  vCenter + NSX + vSAN ESA cluster   │  │  vCenter + NSX + vSAN ESA cluster   │ │
│  │  [ VPC-based workload isolation ]   │  │  [ VPC-based workload isolation ]   │ │
│  └──────────────────────────────────────┘  └──────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           PHYSICAL NETWORK UNDERLAY                                 │
│       ToR Switches (BGP/ECMP) → Spine Layer → Core/WAN                             │
│       NSX Edge Nodes: North-South routing, Load Balancing, NAT, VPN                │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Management Domain Redesign

One of the most impactful changes in VCF 9 is the redesigned management domain. Unlike previous versions, VCF 9 introduces a more flexible and unified approach:

- **Reduced minimum footprint:** VCF 9 supports a 3-host management domain, lowering the barrier to entry for smaller deployments and edge/ROBO scenarios
- **VCF Operations as the single management plane:** VCF Operations replaces the SDDC Manager-centric model, providing a unified interface for fleet management, lifecycle operations, licensing, and cost management across all VCF instances
- **Single NSX Manager support:** VCF 9 introduces the option to deploy a single NSX Manager (instead of the traditional 3-node cluster) for resource-constrained environments. A 3-node NSX Manager cluster remains the recommended configuration for production high availability.
- **Unified versioning:** VCF 9.0 ships ESX 9.0, vCenter 9.0, and NSX 9.0 as a single, co-versioned platform — simplifying compatibility and lifecycle management

## NSX 9.0 Integration

VCF 9 ships with NSX 9.0 as the default networking layer. Key improvements include:

### Enhanced Data Path (EDP) Standard as Default

NSX 9.0 introduces **Enhanced Data Path (EDP) Standard** as the default host switch mode of operation for all new VCF Workload Domains. EDP Standard delivers superior performance in terms of throughput, packet rate, latency, and CPU utilization compared to the legacy Standard stack. Workload Domains upgraded or imported from VCF 5.x will continue using the legacy stack until the mode is explicitly changed.

### Virtual Private Cloud (VPC) Networking

VCF 9 introduces **Virtual Private Cloud (VPC)** as the multi-tenancy networking model, replacing the need for manual NSX segment configuration for tenant isolation. VPCs are consumable from vCenter, VCF Automation, and vSphere Supervisor (VKS). Key VPC capabilities include:

- **Transit Gateways (TGW):** Centralized or distributed gateway hubs for inter-VPC and VPC-to-external routing, eliminating the need for tenants to configure infrastructure components directly
- **VPC-Ready Workload Domains:** All prerequisites for VPC consumption are fulfilled automatically when a workload domain is created
- **Terraform support:** The NSX Terraform Provider supports Transit Gateway, VPCs, and related constructs

### NSX VIBs Bundled with ESX

A significant operational improvement in VCF 9: NSX kernel modules (VIBs) are now **bundled with ESX 9.0** by default, removing the separate NSX VIB installation/upgrade step. This enables Live Patch for NSX transport node upgrades without requiring ESX maintenance mode.

### Gateway Firewall Disabled by Default

Starting with NSX 9.0, Gateway Firewall is automatically disabled by default for all new Tier-0 and Tier-1 Gateway deployments, improving performance and resource utilization for modern VPC-based network designs.

## vSAN ESA (Express Storage Architecture)

VCF 9 continues with vSAN ESA (Express Storage Architecture) as the recommended storage architecture, with new capabilities:

| Feature | OSA | ESA |
|---------|-----|-----|
| NVMe Support | Limited | Full NVMe-native |
| Compression | Software only | Hardware-assisted |
| Snapshot Performance | Degraded under load | Near-zero impact |
| Cache Drive Monitoring | Basic | Dying Disk Handling (DDH) for cache drives |
| Disaster Recovery | Basic | VMware Live Recovery integration (RPO ≥ 1 min) |

**New in VCF 9:** vSAN ESA now supports **Dying Disk Handling (DDH)** for cache drives, enabling proactive detection and automated corrective actions when disk latency exceeds a predefined threshold.

## Workload Domain Orchestration

The workload domain creation and management process in VCF 9 has been significantly modernized:

- **VCF Installer for deployment:** The new VCF Installer virtual appliance (replacing Cloud Builder) orchestrates management domain bringup. It is downloaded from the Broadcom Support portal and deployed as a virtual appliance.
- **VCF Operations for Day-2:** VCF Operations provides a unified interface for fleet and domain management, lifecycle operations, license management, cost and capacity visibility, and security compliance — all from a single pane of glass
- **VPC-Ready domains:** Every new workload domain is provisioned VPC-ready, meaning networking isolation via NSX VPCs is available immediately upon domain creation
- **API-first design:** The VCF SDK (with Python and Java bindings) and PowerCLI provide comprehensive automation capabilities for all VCF operations

## What This Means for Your Deployment

If you are planning a new VCF deployment or evaluating an upgrade from VCF 4.x or 5.x, here are the key takeaways:

- **Smaller entry point:** 3-host management domains and single NSX Manager option make VCF 9 accessible for smaller environments and branch offices
- **Better storage performance with ESA:** vSAN ESA delivers dramatically better performance for mixed I/O workloads, with new DDH protection for cache drives
- **Modern networking with VPCs:** The VPC model provides cloud-native tenant isolation without complex manual NSX segment management
- **Operational efficiency:** VCF Operations consolidates all management, licensing, cost visibility, and lifecycle tasks into a single interface
- **EDP performance gains:** Enhanced Data Path Standard is now the default, delivering superior network performance for all new workload domains
- **Simplified NSX lifecycle:** NSX VIBs bundled with ESX and Live Patch support eliminate the operational complexity of separate NSX upgrade cycles

## Next Steps

In our next post, we will walk through the complete VCF 9 deployment flow, from initial planning through a working management domain using the new VCF Installer. Stay tuned!


<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
