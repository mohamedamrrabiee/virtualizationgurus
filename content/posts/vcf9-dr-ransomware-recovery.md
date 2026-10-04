---
title: "DR & Ransomware Recovery: Isolated Recovery, SRM, and VPC Isolation"
date: 2026-10-03
draft: false
tags: ["Disaster Recovery", "Ransomware", "IRE", "SRM", "vSAN ESA", "NSX"]
categories: ["VCF 9", "Security"]
description: "Cyber recovery and operational DR get planned as one discipline in most VCF conversations. Broadcom builds them as two, with different assumptions, different tooling, and a dedicated Isolated Recovery Environment that exists for exactly one purpose."
seriesPart: 19
cover:
  image: "/virtualizationgurus/images/covers/vcf9-dr-ransomware-recovery.jpg"
  alt: "DR & Ransomware Recovery: Isolated Recovery, SRM, and VPC Isolation"
  relative: false
---

## Introduction

Disaster recovery and ransomware recovery get planned in the same conversation more often than not, same team, same budget line, sometimes the same runbook with a different label on it. Broadcom's own architecture disagrees with that framing. Operational DR assumes your primary environment is healthy but unreachable or impaired, the priority is RTO, automation, and minimal data loss. Cyber recovery assumes your primary environment is compromised, every action requires forensic isolation, immutability, and an air-gap mentality. Same team can run both. Structurally, they're not the same discipline, and VCF 9.1's tooling treats them as genuinely separate.

## The Isolated Recovery Environment Exists for One Purpose Only

Central to any cyber recovery strategy is the Isolated Recovery Environment, IRE, a cyber recovery "clean room" disconnected from the production data center, used to safely power on, inspect, and recover ransomware-infected workloads. Broadcom's validated design is explicit about scope: the IRE is not used for test/development, burst capacity, or anything else. One purpose, full stop.

The reference design specifies exactly what that isolation looks like:

-> **A dedicated vSAN storage cluster using Express Storage Architecture (ESA)** stores the replicated virtual machines, plus a separate compute cluster with its own NSX edge clusters and a remote datastore mounted from that storage cluster.

-> **A Tier-1 gateway and dedicated network segment**, configured in the isolated workload domain's NSX, is what the recovered test virtual machines actually connect to, with DHCP serving IP addresses and DNS settings on that segment.

-> **A Python isolation script creates graduated levels of network isolation** on the IRE, letting you control how contained a given recovery session is depending on what phase of investigation you're in. This does require its own Distributed Firewall license on NSX, worth budgeting for separately rather than discovering mid-incident.

-> **Outbound access to your EDR platform is deliberately allowed** from inside the otherwise-isolated environment, specifically so recovered VMs can have security sensors installed and get analyzed before anything is trusted.

-> **DNS and NTP in the IRE are both intentionally separate** from what the protected production instance uses, on the reasoning that the IRE's path to the internet shouldn't retrace anything the compromised environment touches.

## The Recovery Workflow Itself

VCF 9.1's Protection and Recovery capability, paired with VMware Advanced Cyber Compliance, extends the familiar site-recovery pattern into something built specifically for cyber incidents rather than just outages. In Broadcom's recovery states, a snapshot sits In backup until you validate it, then runs In validation, powered on inside the IRE (Protection and Recovery calls it the clean room), where it gets inspected with EDR tooling. That includes built-in AI/ML-powered detection and integrated analysis through Carbon Black (managed by Broadcom) or CrowdStrike (customer-managed). Once it's Validated it moves to Staged, gets Recovered at the secondary site, and is then reprotected.

Cyber recovery is supported with vSAN snapshots and replication, and only vSAN-protected VMs are supported, so scope your protection groups with that in mind. VCF 9.1 ships two purpose-built presets rather than making you hand-configure retention every time: a Ransomware Recovery preset (1-hour RPO, last snapshot kept, hourly retained for a day, daily for a week, weekly for a month, monthly for six months) and a lighter Short-Term Retention preset for less critical workloads (same 1-hour RPO, but retention tapers off after the weekly tier). Protection groups can now be assigned by vSphere tag as well as by static or wildcard name, which matters once you're managing this at real fleet scale rather than a handful of VMs.

## Where SRM Fits

VMware Live Recovery has been renamed and integrated into VCF as VCF Protection and Recovery, and Broadcom's 9.1 documentation frames it as three capabilities: operational recovery on vSAN local snapshots, disaster recovery that orchestrates array-based and host-based replication, and cyber recovery in a clean room. Site Recovery Manager hasn't disappeared, Broadcom's validated on-premises ransomware recovery design still documents a recovery plan built on SRM and vSphere Replication for business-critical workloads. What changed is that SRM is no longer the only recovery path, since vSAN snapshots now cover operational recovery and the cyber recovery workflow is built on vSAN-protected VMs. The 9.1 Protection and Recovery documentation doesn't name SRM at all, so confirm which orchestrator your design actually relies on against the validated design before you commit to it.

## Architectural Overview

<div class="diagram-embed">
  <object type="image/svg+xml" data="/virtualizationgurus/images/diagrams/vcf9-dr-ransomware-recovery.svg"></object>
</div>

## What Can Actually Go Wrong

Broadcom's own 9.1 release notes for Protection and Recovery list a real failure mode worth knowing before you're mid-incident: the Ransomware Recovery End workflow can fail with "Operation interrupted: running," caused by the srm service crashing and auto-restarting immediately after, which leaves the Recovery Plan stuck in active Ransomware Recovery Mode with no End action visible in the UI. The documented workaround is calling the `rwrEnd` API directly against the Protection and Recovery server's Managed Object Browser, RecoveryManager object, rather than waiting for the UI option to reappear on its own.

## VPC Isolation Is the Same Mechanism, Different Context

The network isolation techniques underpinning the IRE, Tier-1 gateways, DFW-based segmentation, scriptable isolation levels, aren't a special-purpose invention for cyber recovery. They're the same VPC isolation model this series has already covered for centralized vs. distributed connectivity in normal workload domains. What changes in the IRE context isn't the mechanism, it's the intent: isolation here exists to contain a suspected-compromised workload during forensic inspection, not to segment tenants or manage north-south traffic flow.

## A Quick Checklist

- **Planning DR and cyber recovery as the same runbook?** Split them, the assumptions about what state your primary environment is in are opposite, and a runbook that's right for one is actively dangerous for the other.
- **Building an IRE?** Budget for the separate DFW license the isolation script depends on, and plan DNS/NTP infrastructure that's genuinely separate from production, not just logically separate.
- **Configuring retention?** Start from the Ransomware Recovery or Short-Term Retention presets rather than hand-building a schedule, they're tuned defaults, not just examples.
- **Stuck in Ransomware Recovery Mode with no End option showing?** Check for a crashed and auto-restarted srm service before assuming the UI is simply broken, the `rwrEnd` API workaround is the documented fix.

## What's Next

Next in this series: Private AI Workload Domain, GPU Nodes, AI Kubernetes, and NVIDIA NIM.

## Further Reading (Official Broadcom Documentation)

- [Isolated Recovery Environment Design for On-Premises Ransomware Recovery](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vvs/9-X/on-prem-ransomware-recovery-for-vmware-cloud-foundation/detailed-design-for-site-protection-and-disaster-recovery/ire-design(1).html)
- [Cyber Recovery in Protection and Recovery 9.1](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/protection-and-recovery/9-1/using-on-premises-ransomware-recovery/welcome-to-cyber-recovery.html)
- [Ransomware Recovery States](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/protection-and-recovery/9-1/using-on-premises-ransomware-recovery/using-on-premises-ransomware-recovery/ransomware-recovery-states.html)
- [Protection and Recovery 9.1 Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/protection-and-recovery/9-1/release-notes/protection-and-recovery-91-release-notes.html)
- [VMware vSAN Protection and Recovery Enhancements for VCF 9.1](https://blogs.vmware.com/cloud-foundation/2026/05/14/vmware-vsan-protection-and-recovery-enhancements-for-vcf-9-1/)
- [Continuous Compliance, Integrated Cyber Recovery and Enhanced Platform Security for VCF 9.1](https://blogs.vmware.com/cloud-foundation/2026/05/05/continuous-compliance-integrated-cyber-recovery-and-enhanced-platform-security-for-vcf-9-1/)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
