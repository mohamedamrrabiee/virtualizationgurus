---
title: "VCF 9 Workload Domain Planning and Deployment"
date: 2026-07-06
draft: true
tags: ["VCF", "VMware", "Workload Domain", "NSX", "vSAN", "Cloud Foundation"]
categories: ["VCF 9", "Deployment"]
description: "A practical guide to planning, designing, and deploying VCF 9 workload domains using VCF Operations, including VPC-ready networking configuration and automated domain deployment."
---

## Introduction

With the VCF 9 management domain up and running, the next step in your private cloud journey is creating workload domains. In VCF 9, workload domains are the fundamental building blocks for hosting tenant or departmental workloads, each with their own dedicated vCenter Server, NSX instance, and vSAN cluster. Every workload domain in VCF 9 is automatically provisioned **VPC-ready**, meaning Virtual Private Cloud networking isolation is available immediately.

## Architectural Overview

The diagram below illustrates the relationship between the VCF 9 management domain, VCF Operations, and multiple workload domains, including VPC-based networking topology:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                        VCF 9 - Workload Domain Architecture                             │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                              VCF Operations (Management Plane)                       │
│                                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐                   │
│  │   Fleet Mgmt     │  │  Lifecycle Mgmt  │  │  Cost & Capacity │                   │
│  │  (All Domains)   │  │  (All Components)│  │   Management     │                   │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘                   │
└──────────────────────────────────────────────────────────────────────────────────────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         │                              │                              │
         ▼                              ▼                              ▼
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Management Domain  │    │  Workload Domain A   │    │  Workload Domain B   │
│                     │    │                     │    │                     │
│  vCenter (Mgmt)     │    │  vCenter (WLD-A)     │    │  vCenter (WLD-B)     │
│  NSX 9.0 (Mgmt)     │    │  NSX 9.0 (WLD-A)     │    │  NSX 9.0 (WLD-B)     │
│  vSAN ESA (Mgmt)    │    │  vSAN ESA (WLD-A)    │    │  vSAN ESA (WLD-B)    │
│                     │    │                     │    │                     │
│  ┌───────────────┐  │    │  ┌───────────────┐  │    │  ┌───────────────┐  │
│  │  Management   │  │    │  │   VPC / Tenant│  │    │  │   VPC / Tenant│  │
│  │  VMs only     │  │    │  │   Workloads   │  │    │  │   Workloads   │  │
│  └───────────────┘  │    │  └───────────────┘  │    │  └───────────────┘  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘

                    NSX VPC Networking (Per Workload Domain)
                    ┌───────────────────────────────────────┐
                    │                                       │
                    │  Transit Gateway (TGW)                │
                    │  ┌────────────┐  ┌────────────┐       │
                    │  │  VPC-1     │  │  VPC-2     │       │
                    │  │ (Tenant A) │  │ (Tenant B) │       │
                    │  │ Subnet 1   │  │ Subnet 1   │       │
                    │  │ Subnet 2   │  │ Subnet 2   │       │
                    │  └────────────┘  └────────────┘       │
                    │         │               │             │
                    │         └───────┬───────┘             │
                    │                 │                     │
                    │         External Uplink               │
                    │    (via NSX Edge North-South)         │
                    └───────────────────────────────────────┘

                    Physical Infrastructure (Per Workload Domain)
                    ┌───────────────────────────────────────────────────┐
                    │  ESX Hosts (min. 3 for vSAN ESA)                  │
                    │  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
                    │  │ ESX-1   │  │ ESX-2   │  │ ESX-3   │  [+more]  │
                    │  │NVMe x3  │  │NVMe x3  │  │NVMe x3  │           │
                    │  │NSX(EDP) │  │NSX(EDP) │  │NSX(EDP) │           │
                    │  └─────────┘  └─────────┘  └─────────┘           │
                    │                                                   │
                    │  Networks: Mgmt | vMotion | vSAN | NSX Overlay    │
                    └───────────────────────────────────────────────────┘
```

## Workload Domain Planning Considerations

Before creating a workload domain in VCF 9, use the **VCF Planning and Preparation Workbook** to document all design decisions. Key areas to plan:

### Compute Sizing

- Minimum of 3 ESX hosts for a vSAN ESA workload domain
- Size CPU and RAM based on the expected VM density and workload type (compute-intensive, memory-intensive, or mixed)
- Account for ESX host management overhead and vSAN ESA overhead when calculating usable capacity
- For high-availability, plan for N+1 host capacity (allows one host to fail while maintaining full performance)

### Storage Design

- vSAN ESA is the default and recommended storage architecture in VCF 9
- Minimum NVMe disk requirements for ESA: check the Broadcom Compatibility Guide for ESA-certified drives
- vSAN storage policies (Number of Failures to Tolerate, RAID level) are configured per workload domain
- VCF 9 supports stretched compute-only clusters with remote vSAN storage clusters for site-level resilience
- vSAN file services supports up to 500 file shares per cluster in VCF 9

### Networking Design

| Network Segment | Purpose | Configuration Notes |
|----------------|---------|-------------------|
| Management VLAN | ESX management, vCenter | Must be reachable from VCF Operations |
| vMotion VLAN | Live VM migration | Dedicated VLAN for performance isolation |
| vSAN VLAN | Storage traffic | Dedicated VLAN, jumbo frames recommended |
| NSX Overlay | Tenant Geneve-encapsulated traffic | Trunk port group |
| NSX Edge Uplink | North-south routing to physical network | Dedicated VLANs for T0 connectivity |

### NSX VPC Planning

VCF 9 introduces a VPC-ready workload domain model. Plan your VPC topology:

- **Transit Gateway (TGW) model:** Centralized (CTGW) for shared routing, or Distributed (DTGW) for host-level direct connectivity
- **VPC CIDR ranges:** Define non-overlapping CIDR blocks for each VPC
- **External connectivity:** Plan NSX Edge node placement and uplink VLANs for T0 north-south traffic
- **Service profiles:** Define Connectivity and Service Profiles for VPCs to centralize networking and service definitions

## Deploying a Workload Domain via VCF Operations

### Step 1: Commission ESX Hosts

Before creating a workload domain, commission the target ESX hosts in VCF Operations:

1. In VCF Operations, navigate to **Inventory → Hosts**
2. Click **Commission Hosts**
3. Enter ESX host FQDNs and root credentials
4. VCF Operations validates host connectivity, DNS, NTP, and hardware compliance
5. Hosts move to **UNASSIGNED** state once commissioned

### Step 2: Create the Workload Domain

1. In VCF Operations, navigate to **Inventory → Workload Domains**
2. Click **Create Workload Domain**
3. Provide the domain configuration:
   - Domain name and vCenter Server FQDN
   - Select commissioned hosts to assign
   - Configure vSAN ESA storage policy
   - Configure NSX networking (transport zone, TEP pool, edge uplink configuration)
4. VCF Operations performs pre-deployment validation
5. Click **Create** — VCF Operations orchestrates the full domain bringup

### Step 3: Post-Creation VPC Setup

After the workload domain is created, it is automatically VPC-ready:

1. Log in to the workload domain's NSX Manager
2. Navigate to **Networking → VPCs**
3. Create VPCs with appropriate CIDR ranges for each tenant or application team
4. Attach subnets (private or publicly advertised) to each VPC
5. Configure Transit Gateway connectivity for inter-VPC and external routing

## Day-2 Workload Domain Operations

VCF Operations provides built-in automation for common Day-2 operations:

- **Cluster expansion:** Add ESX hosts to an existing cluster via VCF Operations with automated validation and remediation
- **Host remediation:** Apply ESX updates, patches, or desired state images across the cluster using vSphere Lifecycle Manager integration
- **Certificate rotation:** Automate certificate lifecycle for all workload domain components from VCF Operations
- **License management:** Track and submit VCF and vSAN license usage every 180 days directly from VCF Operations

## What's Next

In the next post, we will do a deep dive into VCF 9 NSX VPC networking, covering Transit Gateway design, VPC consumption from vCenter, and practical examples of deploying application workloads using VPC-based isolation.
