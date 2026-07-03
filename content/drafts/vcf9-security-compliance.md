---
title: "VCF 9 Security and Compliance: DFW, VPC Isolation, and Hardened Operations"
date: 2026-08-03
draft: true
tags:
  - VCF
  - VMware
  - Security
  - NSX
  - DFW
  - Compliance
  - Cloud Foundation
categories:
  - VCF 9
  - Security
description: "A comprehensive guide to VCF 9 security architecture, covering NSX Distributed Firewall design, VPC-level isolation, Gateway Firewall best practices, and VCF Operations security compliance capabilities."
---

## Introduction

Security is a foundational concern in any private cloud deployment. VMware Cloud Foundation 9 delivers a layered security architecture that spans from the physical network underlay through the workload networking and compute layers, with VCF Operations providing centralized visibility into the security posture of all domains.

In this post, we explore the VCF 9 security architecture, focusing on NSX Distributed Firewall design, VPC-level isolation, the Gateway Firewall default behavior change, and how VCF Operations integrates security compliance monitoring.

## Architectural Overview

The diagram below illustrates the VCF 9 security architecture, showing the defense-in-depth layers from the physical network through workload micro-segmentation:

```
+-----------------------------------------------------------------------------------+
|             VCF 9 - Security Architecture (Defense in Depth)                       |
+-----------------------------------------------------------------------------------+

  Layer 1: Physical Network Security
  +---------------------------------------------------------------------+
  | Physical Switches + Firewall                                         |
  | [ ACLs / Port Security ] [ BGP route filtering ] [ MACsec (opt.) ]  |
  +---------------------------------------------------------------------+
                                  |
  Layer 2: NSX Edge / North-South Security
  +---------------------------------------------------------------------+
  | NSX Edge Cluster (Tier-0 Gateway)                                    |
  |                                                                      |
  | [ Gateway Firewall (DISABLED by default in NSX 9.0) ]               |
  | [ Enable only for perimeter stateful inspection use cases ]          |
  | [ NAT / Load Balancer / VPN (IPsec, L2VPN) ]                        |
  | [ BGP to physical network with route filters ]                       |
  +---------------------------------------------------------------------+
                                  |
  Layer 3: VPC Isolation (NSX 9.0 Multi-Tenancy)
  +---------------------------+   +---------------------------+
  | VPC-1 (Tenant A)          |   | VPC-2 (Tenant B)          |
  |                           |   |                           |
  | [ Private Subnets ]       |   | [ Private Subnets ]       |
  | [ Public Subnets + NAT ]  |   | [ Public Subnets + NAT ]  |
  | [ No cross-VPC traffic    |   | [ No cross-VPC traffic    |
  |   without TGW attachment] |   |   without TGW attachment] |
  +---------------------------+   +---------------------------+
            |     inter-VPC via Transit Gateway (explicit attachment only)
            +-------------------------------+
                                            |
  Layer 4: NSX Distributed Firewall (East-West Micro-Segmentation)
  +---------------------------------------------------------------------+
  | DFW (runs in EDP Standard mode on every ESX host kernel)            |
  |                                                                      |
  | [ VM-to-VM traffic filtered at vNIC level ]                         |
  | [ Context-aware policies: VM tags + Security Groups ]               |
  | [ Application-layer filtering with IDPS (optional add-on) ]        |
  | [ Zero-trust: default deny between security groups ]                |
  +---------------------------------------------------------------------+
                    |              |              |
              +----------+  +----------+  +----------+
              | VM (App) |  | VM (Web) |  | VM (DB)  |
              | Tag: App |  | Tag: Web |  | Tag: DB  |
              +----------+  +----------+  +----------+

  Layer 5: VCF Operations Security Compliance
  +---------------------------------------------------------------------+
  | VCF Operations                                                       |
  | [ Security compliance scanning (ESX, vCenter, NSX configurations) ] |
  | [ Certificate lifecycle management ]                                 |
  | [ Skyline Health integration ]                                       |
  | [ Audit logging for all VCF Operations actions ]                    |
  +---------------------------------------------------------------------+
```

## NSX Distributed Firewall (DFW) in VCF 9

The NSX Distributed Firewall is the primary security control for east-west (lateral) traffic between workloads in a VCF 9 environment.

### DFW Architecture in VCF 9

In VCF 9 with NSX 9.0, DFW runs in **Enhanced Data Path (EDP) Standard mode** for all new workload domains. This means:

- DFW policy enforcement runs in the ESX kernel at the vNIC level, not in a user-space proxy
- EDP Standard delivers superior throughput and lower latency for DFW-inspected traffic compared to the legacy Standard stack
- DFW intercepts and filters all VM-to-VM traffic at the source vNIC before it traverses the physical network fabric

### Security Groups and Tags

VCF 9's DFW uses **security groups** and **VM tags** as the primary policy constructs:

- **VM Tags**: Labels applied to VMs in vCenter or NSX (e.g., "Tier=Web", "Tier=App", "Tier=DB", "Env=Production")
- **Security Groups**: Dynamic groups that include VMs based on tag membership criteria
- **DFW Rules**: Policies that define allowed or denied traffic between security groups, without requiring IP address management

Example DFW policy structure for a 3-tier application:

| Rule Name | Source | Destination | Service | Action |
|---|---|---|---|---|
| Allow-Web-to-App | SG-Web | SG-App | TCP/8080 | Allow |
| Allow-App-to-DB | SG-App | SG-DB | TCP/3306 | Allow |
| Allow-Web-Inbound | SG-External | SG-Web | TCP/443 | Allow |
| Default-Deny | Any | Any | Any | Drop |

### DFW and VPC Integration

In VCF 9's VPC model, DFW policies apply within and between VPCs:

- Within a VPC, DFW provides micro-segmentation between VMs on different subnets
- Between VPCs connected via Transit Gateway, DFW policies at the Transit Gateway attachment point control inter-VPC traffic
- VPC-level isolation provides the first layer; DFW provides the workload-level layer within each VPC

### Context-Aware DFW (IDPS Add-on)

NSX 9.0 supports context-aware DFW policies with the optional NSX Intelligence or NSX Advanced Threat Prevention add-on:

- **Application-layer filtering**: Inspect traffic at Layer 7 (application protocol awareness) for HTTP, DNS, and other protocols
- **Intrusion Detection and Prevention (IDPS)**: NSX ATP provides inline threat detection with signature-based and AI/ML-based detection capabilities
- **Anomaly detection**: Behavioral analysis to detect lateral movement and unusual traffic patterns within the VCF environment

## Gateway Firewall: Disabled by Default in NSX 9.0

One of the significant security posture changes in VCF 9 / NSX 9.0 is that the **Gateway Firewall is disabled by default** for all new Tier-0 and Tier-1 gateway deployments.

### Why Was This Changed?

In NSX 9.0's VPC-centric design, the primary traffic model has shifted:

- VPC isolation provides tenant separation by default — cross-VPC communication requires explicit Transit Gateway attachment
- DFW provides micro-segmentation within VPCs
- The Gateway Firewall was historically used for perimeter-style controls, which are better implemented at the physical edge in the VPC model

Disabling the Gateway Firewall by default improves performance and resource utilization on NSX Edge nodes, which no longer need to maintain stateful connection tracking for all workload traffic.

### When to Enable Gateway Firewall

Enable the Gateway Firewall (on Tier-0 or Tier-1) only for specific use cases requiring stateful inspection at the gateway layer:

- **Perimeter security**: Stateful firewall enforcement for north-south traffic entering/exiting the VCF environment from external networks
- **Compliance requirements**: Specific regulatory frameworks requiring perimeter inspection (not covered by DFW alone)
- **East-west isolation at the VPC boundary**: Stateful inspection for inter-VPC traffic traversing the Transit Gateway (supplement to DFW)

When enabling Gateway Firewall, define an explicit default-deny rule and allow only required traffic (similar to DFW policy design).

## VPC-Level Isolation: The Foundation of Multi-Tenancy Security

VCF 9's VPC model provides **isolation-by-default** between tenants:

- VMs in VPC-1 cannot communicate with VMs in VPC-2 without explicit Transit Gateway attachment and routing configuration
- No routing leakage between VPCs: each VPC has its own routing table
- Public subnets within a VPC allow external connectivity (via NAT or direct external IP), but this does not expose other VPCs

### VPC Security Best Practices

1. **One VPC per tenant or application boundary**: Don't share VPCs across security boundaries
2. **Minimize public subnet exposure**: Place only VMs requiring external access in public subnets; all other VMs should be in private subnets
3. **Use Transit Gateway with explicit route filtering**: Attach only required VPCs to a Transit Gateway and configure route filters to limit inter-VPC reachability to specific prefixes
4. **Apply DFW within VPCs**: Never rely solely on VPC isolation; apply DFW policies for micro-segmentation within each VPC

## VCF Operations: Security Compliance and Monitoring

VCF Operations provides centralized security compliance capabilities for all VCF domains:

### Security Configuration Compliance

VCF Operations integrates with Broadcom's security compliance frameworks to:

- Scan ESX host, vCenter, NSX, and vSAN configurations against security baselines (VMware Security Configuration Guides)
- Report deviations from recommended security configurations
- Track remediation status for identified compliance findings

### Certificate Lifecycle Management

VCF Operations manages certificate lifecycle across all VCF components:

- Tracks certificate expiry dates for vCenter, NSX Manager, VCF Operations, and other VCF management components
- Sends proactive alerts 60-90 days before certificate expiry
- Automates certificate rotation for management domain components through VCF Operations workflows

### Audit Logging

All VCF Operations actions (domain creation, upgrades, license submissions, user access) are recorded in the VCF Operations audit log:

- Provides a tamper-evident record of all administrative actions
- Supports SIEM integration for centralized security monitoring
- Audit log retention is configurable based on compliance requirements

### Skyline Health Integration

VCF Operations integrates with Broadcom Skyline Health for proactive security and health monitoring:

- Skyline Health collects VCF environment telemetry and cross-references it against known issues and security advisories
- Proactive findings (security patches available, known vulnerabilities in deployed versions) are surfaced in the VCF Operations dashboard
- Skyline findings can be addressed through the VCF Operations Lifecycle Management workflow (applying the relevant update bundle)

## Security Hardening Checklist for VCF 9

Following the Broadcom VCF 9.0 Design documentation, here is a high-level security hardening checklist:

**NSX:**
- Confirm Gateway Firewall status (disabled by default; only enable if required)
- Define DFW default-deny policy for all workload domains
- Use security groups with VM tags for DFW policy management (avoid IP-based rules where possible)
- Enable NSX audit logging and forward logs to SIEM

**vSphere / ESX:**
- Apply the ESX Security Configuration Guide settings via vSphere Lifecycle Manager desired state
- Enable vSphere Authentication Proxy for ESX host authentication
- Restrict management network access to ESX hosts (dedicated management VLAN with firewall controls)

**vSAN:**
- Enable vSAN data-at-rest encryption (if required by compliance framework)
- Enable vSAN data-in-transit encryption for sensitive workload domains (adds performance overhead; evaluate for each domain)

**VCF Operations:**
- Enable multi-factor authentication (MFA) for VCF Operations admin accounts
- Integrate VCF Operations with enterprise identity provider (LDAP/AD integration)
- Review VCF Operations audit logs regularly and forward to SIEM

## What's Next

This concludes our foundational VCF 9 series. In upcoming posts, we will explore advanced topics including VCF Automation for self-service VM and Kubernetes provisioning, vSphere Supervisor Platform for Kubernetes workloads (VKS), and multi-site VCF fleet design with the Transit Gateway for inter-site connectivity.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
  <img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
