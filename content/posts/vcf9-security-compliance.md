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

In this post, we explore the VCF 9 security architecture, focusing on the Distributed Firewall design, VPC-level isolation, the Gateway Firewall default behavior change, and how VCF Operations handles security compliance monitoring.

A quick terminology note: starting with VCF/NSX 9.0, Broadcom rebranded this firewall and threat-prevention stack as **VMware vDefend**. What was "NSX Distributed Firewall," "NSX Gateway Firewall," and "NSX Intelligence / NSX ATP" are now formally the **vDefend Distributed Firewall**, **vDefend Gateway Firewall**, and **vDefend Advanced Threat Prevention (ATP)**. We'll use the familiar DFW / Gateway Firewall shorthand throughout for readability, calling out the vDefend branding where it matters (worth knowing for interviews and documentation searches, since Broadcom TechDocs now files this content under vDefend, not NSX).

## Architectural Overview

The diagram below illustrates the VCF 9 security architecture, showing the defense-in-depth layers from the physical network through workload micro-segmentation:

```
+-----------------------------------------------------------------------------------+
| VCF 9 - Security Architecture (Defense in Depth) |
+-----------------------------------------------------------------------------------+

Layer 1: Physical Network Security
+---------------------------------------------------------------------+
| Physical Switches + Firewall |
| [ ACLs / Port Security ] [ BGP route filtering ] [ MACsec (opt.) ] |
+---------------------------------------------------------------------+
|
Layer 2: NSX Edge / North-South Security
+---------------------------------------------------------------------+
| NSX Edge Cluster (Tier-0 Gateway) |
| |
| [ vDefend Gateway Firewall (off by default for NEW gateways on ] |
| [ greenfield VCF 9.0; ON by default for new gateways when ] |
| [ upgrading an existing VCF instance to 9.0) ] |
| [ NAT / Load Balancer / VPN (IPsec, L2VPN) ] |
| [ BGP to physical network with route filters ] |
+---------------------------------------------------------------------+
|
Layer 3: VPC Isolation (NSX 9.0 Multi-Tenancy)
+---------------------------+ +---------------------------+
| VPC-1 (Tenant A) | | VPC-2 (Tenant B) |
| | | |
| [ Private Subnets ] | | [ Private Subnets ] |
| [ Public Subnets + NAT ] | | [ Public Subnets + NAT ] |
| [ No cross-VPC traffic | | [ No cross-VPC traffic |
| without TGW attachment] | | without TGW attachment] |
+---------------------------+ +---------------------------+
| inter-VPC via Transit Gateway (explicit attachment only)
+-------------------------------+
|
Layer 4: vDefend Distributed Firewall (East-West Micro-Segmentation)
+---------------------------------------------------------------------+
| vDefend DFW (enforced in the ESX kernel datapath at the vNIC) |
| VCF 9.0 defaults new workload domains to EDP Standard mode |
| |
| [ VM-to-VM traffic filtered at vNIC level ] |
| [ Context-aware policies: VM tags + Security Groups ] |
| [ Application-layer filtering with vDefend ATP (optional add-on) ]|
| [ Zero-trust: default deny between security groups ] |
+---------------------------------------------------------------------+
| | |
+----------+ +----------+ +----------+
| VM (App) | | VM (Web) | | VM (DB) |
| Tag: App | | Tag: Web | | Tag: DB |
+----------+ +----------+ +----------+

Layer 5: VCF Operations Security Compliance
+---------------------------------------------------------------------+
| VCF Operations |
| [ Security compliance scanning (ESX, vCenter, NSX configurations) ] |
| [ Certificate lifecycle management + auto-renewal ] |
| [ VCF Health / Diagnostics (Skyline Advisor + Diagnostics parity) ] |
| [ Audit logging for all VCF Operations actions ] |
+---------------------------------------------------------------------+
```

## vDefend Distributed Firewall (DFW) in VCF 9

The vDefend Distributed Firewall (formerly "NSX Distributed Firewall") is the primary security control for east-west (lateral) traffic between workloads in a VCF 9 environment.

### DFW Architecture in VCF 9

VCF 9.0 sets **Enhanced Data Path (EDP) Standard** as the default host switch mode for new VCF workload domains and new NSX installations, and the vDefend DFW is enforced within that same kernel datapath. In practice:

- DFW policy enforcement runs in the ESX kernel at the vNIC level, not in a user-space proxy
- EDP Standard delivers superior throughput, packet rate, and lower latency compared to the legacy Standard host switch stack, and supports NSX SPAN and Live Traffic Analysis in the fast path
- DFW intercepts and filters all VM-to-VM traffic at the source vNIC before it traverses the physical network fabric
- Workload domains that are upgraded or imported from earlier VCF releases keep running the legacy host switch stack until an administrator explicitly migrates them to EDP Standard

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
- Between VPCs connected via a Transit Gateway (centralized CTGW or distributed DTGW), DFW policies at the attachment point control inter-VPC traffic
- VPC-level isolation provides the first layer; DFW provides the workload-level layer within each VPC

### Context-Aware DFW and Threat Prevention (vDefend ATP)

As of VCF/NSX 9.0, Broadcom's advanced security add-on is branded **VMware vDefend Advanced Threat Prevention (ATP)** — this replaces the older "NSX Intelligence" / "NSX ATP" naming you may still see referenced in older material. vDefend ATP combines several detection technologies with aggregation, correlation, and context from Network Detection and Response (NDR):

- **IDS/IPS**: Signature-based intrusion detection and prevention, supported on both the Distributed Firewall and the Gateway Firewall; NSX Manager checks for new intrusion-detection signatures on the cloud every 4 hours by default
- **Network Sandboxing (Malware Prevention)**: File-based threat analysis for traffic traversing the DFW or Gateway Firewall
- **Network Traffic Analysis (NTA)**: Behavioral and anomaly detection to catch lateral movement and unusual traffic patterns within the VCF environment
- **Licensing**: the IDS/IPS capability requires a Threat Prevention license; Malware Prevention requires the separate Advanced Threat Prevention license — worth confirming which license tier a customer has before promising ATP capabilities in a design

## vDefend Gateway Firewall: Off by Default for New Gateways

One of the significant security posture changes in VCF 9 / NSX 9.0 is that the **vDefend Gateway Firewall is disabled by default for new gateways — but only on greenfield VCF 9.0 deployments.** This is controlled by the *Auto-Activate Gateway Firewall on New Gateways* setting (Security → Gateway Firewall → Settings) and can be toggled globally; changing it never affects gateways that are already deployed.

The behavior is different for brownfield environments: **for an installation upgraded from a previous VCF release to VCF 9.0, Gateway Firewall remains enabled by default for new gateways.** If you want the new off-by-default posture on an upgraded environment, you have to explicitly switch the auto-activate setting to Off.

### Why Was This Changed?

In NSX 9.0's VPC-centric design, the primary traffic model has shifted:

- VPC isolation provides tenant separation by default — cross-VPC communication requires explicit Transit Gateway attachment
- DFW provides micro-segmentation within VPCs
- The Gateway Firewall was historically used for perimeter-style controls, which are better implemented at the physical edge in the VPC model

Disabling the Gateway Firewall by default (for greenfield deployments) improves performance and resource utilization on NSX Edge nodes, which no longer need to maintain stateful connection tracking for all workload traffic by default.

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

VCF Operations centralizes certificate lifecycle management for both the VCF management components and the components inside every VCF instance/domain:

- Tracks certificates and surfaces expiry alerts for ESX SSL, vCenter machine SSL, NSX Manager (LM and VIP), SDDC Manager SSL, VCF Identity Broker, VCF Operations, VCF Automation, and VCF Operations for Logs/Networks
- Flags certificates that have expired, are nearing expiration, or have been revoked by the issuing CA, with replace guidance built into the console
- Supports automatic (non-disruptive) renewal for eligible certificates, avoiding a manual replace-and-restart cycle
- Can generate certificate signing requests (CSRs) and configure an internal or external Certificate Authority directly from the console

Note that SDDC Manager still appears in this certificate inventory in VCF 9.0 — its management UI is deprecated and lifecycle workflows have moved to VCF Operations Fleet Management, but the SDDC Manager component itself, and its certificate, are still part of the deployed stack during this transition.

### Audit Logging

All VCF Operations actions (domain creation, upgrades, license submissions, user access) are recorded in the VCF Operations audit log:

- Provides a tamper-evident record of all administrative actions
- Supports SIEM integration for centralized security monitoring
- Audit log retention is configurable based on compliance requirements

### VCF Health and Diagnostics (Skyline Parity)

Rather than "integrating with" a separate Skyline Health product, **VCF Operations 9.0 natively absorbs Skyline Advisor and Skyline Health Diagnostics functionality** as built-in Health and Diagnostics findings:

- VCF Health continuously checks the environment against roughly 62 findings equivalent to former Skyline Advisor signatures, plus around 52 log-based findings equivalent to Skyline Health Diagnostics, re-evaluated automatically on a 4-hour cycle
- Findings cover known product issues, VMSA-based security exposures, expired/expiring certificates, NTP drift, DNS misconfiguration, and other best-practice deviations, each with root-cause detail and remediation steps
- Findings and affected objects can be exported to CSV for offline tracking or reporting
- Remediation for version-related findings typically routes through VCF Operations Fleet Management (applying the relevant update bundle)

## Security Hardening Checklist for VCF 9

Following the Broadcom VCF 9.0 Design documentation, here is a high-level security hardening checklist:

**NSX / vDefend:**
- Confirm the Gateway Firewall auto-activate status for new gateways — off by default only applies to greenfield VCF 9.0 deployments; verify explicitly if this environment was upgraded from a prior VCF release
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

In the next post, we cover the NSX Edge Cluster Deep Dive: Tier-0/Tier-1 Gateways, VPN, and North-South Firewall Design — the perimeter layer that sits just outside the DFW and VPC isolation boundaries covered here. We'll look at Edge cluster sizing and HA, Tier-0/Tier-1 gateway placement, VPN configurations (IPsec and L2VPN), and how the Gateway Firewall default-off posture from this post plays into North-South firewall design decisions.

## Further Reading (Official Broadcom Documentation)

- [vDefend Distributed Firewall](https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/vdefend/vdefend-firewall/9-0/vdefend-distributed-firewall.html)
- [Gateway Firewall Settings](https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/vdefend/vdefend-firewall/9-0/vdefend-gateway-firewall/gateway-firewall-settings.html)
- [Virtual Private Cloud in NSX](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/advanced-network-management/administration-guide/virtual-private-cloud-in-nsx.html)
- [Managing Certificates in VMware Cloud Foundation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/fleet-management/certificate-management-9-0.html)
- [Overview of NSX IDS/IPS and NSX Malware Prevention (vDefend ATP)](https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/vdefend/vdefend-atp/9-0/nsx-ids-ips-and-nsx-malware-prevention/overview-of-nsx-ids-ips-and-nsx-malware-prevention.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
