---
title: "VCF 9 NSX VPC Deep Dive: Cloud-Native Networking for Your Private Cloud"
date: 2026-07-13
draft: true
tags: ["VCF", "VMware", "NSX", "VPC", "Networking", "Cloud Foundation"]
categories: ["VCF 9", "Networking"]
description: "An in-depth exploration of the VCF 9 Virtual Private Cloud (VPC) networking model in NSX 9.0, covering Transit Gateways, VPC design, EDP Standard, and practical workload networking patterns."
---

## Introduction

One of the most impactful networking changes in VCF 9 is the introduction of **Virtual Private Cloud (VPC)** networking as the primary multi-tenancy model in NSX 9.0. VPCs replace the manual overlay segment and Tier-1 gateway model of previous VCF releases with a cloud-native, self-service networking abstraction that aligns with industry standards.

In this post, we dive deep into the VCF 9 VPC architecture, Transit Gateway design patterns, and how application teams can consume VPC-based networking from vCenter, VCF Automation, and vSphere Supervisor.

## Architectural Overview

The diagram below illustrates the complete NSX 9.0 VPC networking architecture in VCF 9, from the physical network underlay through the VPC overlay consumed by workloads:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                    VCF 9 NSX 9.0 - VPC Networking Architecture                       │
└──────────────────────────────────────────────────────────────────────────────────────┘

  Consumption Layer (Application Teams)
  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
  │  vCenter Client   │  │  VCF Automation  │  │ vSphere          │
  │  (VPC creation,  │  │  (Self-service   │  │ Supervisor (VKS/ │
  │   subnet mgmt)   │  │   VMs + K8s)     │  │  vSphere Pods)   │
  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
           │                     │                     │
           └─────────────────────┴─────────────────────┘
                                 │
                         NSX Policy API
                                 │
  ┌──────────────────────────────▼─────────────────────────────────────────────────┐
  │                         NSX Manager (Policy Layer)                              │
  │                                                                                 │
  │  ┌──────────────────────────────────────────────────────────────────────────┐   │
  │  │                  VPC Constructs                                          │   │
  │  │                                                                          │   │
  │  │  ┌─────────────────────┐  ┌─────────────────────┐                       │   │
  │  │  │        VPC-1        │  │        VPC-2        │                       │   │
  │  │  │  (Tenant: App Team A)│  │  (Tenant: App Team B)│                      │   │
  │  │  │                     │  │                     │                       │   │
  │  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │                       │   │
  │  │  │  │  Subnet-1     │  │  │  │  Subnet-1     │  │                       │   │
  │  │  │  │  10.0.1.0/24  │  │  │  │  10.0.3.0/24  │  │                       │   │
  │  │  │  │  (Private)    │  │  │  │  (Private)    │  │                       │   │
  │  │  │  └───────────────┘  │  │  └───────────────┘  │                       │   │
  │  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │                       │   │
  │  │  │  │  Subnet-2     │  │  │  │  Subnet-2     │  │                       │   │
  │  │  │  │  10.0.2.0/24  │  │  │  │  10.0.4.0/24  │  │                       │   │
  │  │  │  │  (Public/NAT) │  │  │  │  (Public/NAT) │  │                       │   │
  │  │  │  └───────────────┘  │  │  └───────────────┘  │                       │   │
  │  │  └──────────┬──────────┘  └──────────┬──────────┘                       │   │
  │  │             │                        │                                   │   │
  │  │             └────────────┬───────────┘                                   │   │
  │  │                          │                                               │   │
  │  │              ┌───────────▼───────────┐                                   │   │
  │  │              │  Transit Gateway (TGW) │                                   │   │
  │  │              │  (Centralized or      │                                   │   │
  │  │              │   Distributed)        │                                   │   │
  │  │              └───────────┬───────────┘                                   │   │
  │  └──────────────────────────┼────────────────────────────────────────────── ┘   │
  │                             │                                                   │
  └─────────────────────────────┼───────────────────────────────────────────────────┘
                                │
  ┌─────────────────────────────▼───────────────────────────────────────────────────┐
  │             Data Plane (ESX Hosts - EDP Standard Mode)                          │
  │                                                                                 │
  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                       │
  │  │  ESX Host 1  │   │  ESX Host 2  │   │  ESX Host 3  │                       │
  │  │  NSX EDP Std │   │  NSX EDP Std │   │  NSX EDP Std │                       │
  │  │  ┌────────┐  │   │  ┌────────┐  │   │  ┌────────┐  │                       │
  │  │  │ VM-A1  │  │   │  │ VM-A2  │  │   │  │ VM-B1  │  │                       │
  │  │  │(VPC-1) │  │   │  │(VPC-1) │  │   │  │(VPC-2) │  │                       │
  │  │  └────────┘  │   │  └────────┘  │   │  └────────┘  │                       │
  │  │  [ TEP Pool ]│   │  [ TEP Pool ]│   │  [ TEP Pool ]│                       │
  │  └──────────────┘   └──────────────┘   └──────────────┘                       │
  │                  Geneve Overlay (NSX Transport Zone)                            │
  └─────────────────────────────────────────────────────────────────────────────────┘
                                │
  ┌─────────────────────────────▼───────────────────────────────────────────────────┐
  │             North-South Layer (NSX Edge Nodes)                                  │
  │                                                                                 │
  │  ┌─────────────────────────────────────────────────────────────────────────┐   │
  │  │  NSX Edge Cluster (Active/Active or Active/Standby)                     │   │
  │  │  Tier-0 Gateway ← BGP ← ToR Switch ← Physical Network                  │   │
  │  │  [ NAT ] [ Load Balancer ] [ VPN ] [ External IPs for Public Subnets ]  │   │
  │  └─────────────────────────────────────────────────────────────────────────┘   │
  └─────────────────────────────────────────────────────────────────────────────────┘
```

## Key VPC Concepts in NSX 9.0

### Virtual Private Cloud (VPC)

A VPC in NSX 9.0 is a self-contained networking environment with:

- **Complete isolation** from other VPCs by default (no inter-VPC communication without explicit Transit Gateway attachment)
- **Private subnets** for internal workload-to-workload communication
- **Public subnets** for workloads requiring external IP exposure (NAT or direct external IP assignment)
- **DHCP enhancements** supporting advanced configurations beyond basic use cases
- **Multiple namespaces** support — multiple Kubernetes namespaces can be assigned to a single VPC

### Transit Gateway (TGW)

The NSX Transit Gateway is a central routing hub for inter-VPC and VPC-to-external-network communication:

| TGW Type | Use Case | Key Benefit |
|---------|---------|------------|
| Centralized TGW (CTGW) | Shared external routing across multiple VPCs | Simplified routing, single point of control |
| Distributed TGW (DTGW) | Direct host-to-fabric connectivity | Lower latency, reduced Edge node dependency, non-blocking performance |

VCF 9 also supports **Transit Gateways with Distributed VLAN Connectivity (DTGW)**, which provides a direct, high-performance datapath from ESX hosts to the network fabric without requiring additional Edge node infrastructure.

### Connectivity and Service Profiles

VPC 9 introduces **Connectivity and Service Profiles** that allow cloud administrators to define:

- External connectivity patterns (which TGW a VPC connects to)
- Services available to VPCs (NAT, DHCP, Load Balancing)
- Centralized policy that multiple VPCs can reference

This simplification means application teams can create VPCs by selecting a profile, without needing to understand the underlying NSX infrastructure topology.

### Enhanced Data Path (EDP) Standard

NSX 9.0 introduces **EDP Standard as the default host switch mode** for all new VCF installations and workload domains. EDP Standard:

- Delivers superior throughput, packet rate, and reduced latency compared to the legacy Standard stack
- Supports NSX Switch Port Analyzer (SPAN) and Live Traffic Analysis in the fast path
- Is available for new deployments — upgraded/imported workload domains continue using the legacy stack until explicitly migrated

## VPC Consumption Patterns

### From vCenter (Infrastructure Team)

Infrastructure administrators can create and manage VPCs directly from the vCenter networking pane:

1. Navigate to **vCenter → Networking → VPCs**
2. Create a VPC with name, CIDR range, and Connectivity Profile
3. Create subnets (private or public) within the VPC
4. Attach VMs to subnets via standard vCenter port group assignment

### From VCF Automation (Application Teams - Self-Service)

VCF Automation provides a cloud-like self-service experience for VPC consumption:

- Application teams request VPCs and subnets from a catalog
- VMs and Kubernetes clusters are automatically placed in the appropriate VPC
- Network isolation and security policies are automatically applied

### From vSphere Supervisor (Platform Engineering)

vSphere Supervisor integrates VPCs as the fundamental networking building block for Kubernetes workloads:

- VKS clusters and vSphere Pods are placed inside VPCs
- K8s NetworkPolicy and NSX SecurityPolicy work together for workload-level micro-segmentation
- StaticRoutes within VPCs enable specific routing requirements for multi-tier applications

## Security Considerations

### Gateway Firewall - Disabled by Default

In NSX 9.0, Gateway Firewall is **disabled by default** for all new Tier-0 and Tier-1 gateway deployments. This improves performance and resource utilization. Enable Gateway Firewall only for perimeter security requirements where stateful inspection at the gateway level is needed.

### Distributed Firewall (DFW)

NSX Distributed Firewall remains active and is the primary security mechanism for east-west traffic within and between VPCs. DFW in VCF 9:

- Runs in EDP Standard mode for improved performance
- Supports context-aware policies using VM tags and security groups
- Operates at the hypervisor level for zero-trust micro-segmentation

### VPC-Level Isolation

VPCs provide built-in isolation — by default, VMs in different VPCs cannot communicate. Inter-VPC communication requires explicit Transit Gateway attachment and routing configuration, providing an isolation-by-default security posture.

## What's Next

In the next post, we will explore VCF 9 lifecycle management using VCF Operations, covering the unified upgrade process for ESX, vCenter, NSX, and vSAN, as well as license management, fleet-level health monitoring, and the VCF SDK for automation.


<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
