---
title: "VCF 9 Fleet Management Layer: One Control Plane for Every Instance"
date: 2026-07-03
draft: false
tags: ["VCF", "VMware", "Fleet Management", "VCF Operations", "VCF Automation", "VCF Installer", "Cloud Foundation"]
categories: ["VCF 9", "Architecture"]
description: "A technical breakdown of the VCF 9 Fleet management layer, validated against official Broadcom documentation: how VCF Installer, VCF Operations, and VCF Automation combine into a single control plane across VCF Instances."
---

## Introduction

VMware Cloud Foundation 9 collapses what used to be three separate consoles into one control plane. If you're coming from a 5.x background, this is arguably the single biggest mental model shift in the release: you stop thinking "one SDDC Manager per site" and start thinking "one Fleet across every site." This post breaks down what Fleet actually is, which components feed into it, and how the pieces map to Broadcom's official architecture documentation.

## From Per-Site Consoles to a Single Fleet

In VCF 5.x, operators juggled Cloud Builder for initial bring-up, SDDC Manager for ongoing lifecycle work, and a separate automation tool layered on top for self-service provisioning. Each of those tools generally spoke to a single site. Running HQ, a DR site, and an edge location meant stitching together multiple, mostly disconnected management planes.

VCF 9 restructures this around two core constructs, defined in Broadcom's official VCF Taxonomy documentation: the **VCF Instance** (the compute, storage, and networking infrastructure running actual workloads — a management domain plus optional workload domains) and the **VCF fleet** (the environment managed by a single set of fleet-level components, which can span one or more Instances and even standalone vCenter deployments).

## The Components That Make Up Fleet

According to the official documentation, three components are involved, though they play distinct roles rather than being three equal peers sitting "inside" Fleet:

**VCF Installer** is a dedicated virtual appliance used for Day-0 work: planning, validating, and deploying a new VCF or vSphere Foundation platform, converging existing infrastructure into VCF, or extending an existing fleet with an additional Instance. It ships as part of the SDDC Manager appliance OVA and can operate in two modes — a standalone "installer mode" for deploying multiple platforms, or it transitions into the SDDC Manager role for the Instance it just deployed. This is the direct functional replacement for the old Cloud Builder appliance.

**VCF Operations** (formerly Aria Operations) is the persistent, fleet-level operations plane. Per Broadcom's overview, it helps build, manage, operate, and secure the private cloud across four functional areas — build, manage, operate, and protect — covering monitoring, alerting, capacity, and compliance across the whole fleet, not just a single site. This is what absorbs SDDC Manager's Day-2 operational role in the new model.

**VCF Automation** (formerly Aria Automation) provides the self-service layer: a multi-tenant Infrastructure-as-a-Service catalog with policy-based governance, spanning cloud services, provider management, organization management, and vSphere Supervisor for Kubernetes workloads.

Strictly speaking, the persistent "VCF fleet" is composed of VCF Operations and VCF Automation running together in the management domain of the first Instance — that pairing is what the taxonomy defines as the fleet-level component set. VCF Installer is the tool you use *to create and extend* that fleet, rather than a service that runs continuously inside it. It's a subtle distinction, but one worth knowing if you're mapping this to the official architecture rather than a simplified mental model.

## Architecture at a Glance

```
                     ┌────────────────────┐
                     │   VCF Installer    │   Day-0: bootstrap,
                     │  (bootstraps &      │   validate, deploy,
                     │   extends Fleet)    │   converge, extend
                     └──────────┬─────────┘
                                │ deploys / extends
                                ▼
        ┌───────────────────────────────────────────┐
        │      VCF FLEET (management domain of       │
        │            the first VCF Instance)         │
        │                                             │
        │   ┌─────────────────┐  ┌─────────────────┐ │
        │   │  VCF Operations  │  │  VCF Automation │ │
        │   │  Day-2 lifecycle,│  │  Self-service    │ │
        │   │  monitoring,     │  │  catalog,        │ │
        │   │  compliance      │  │  policy-driven   │ │
        │   └─────────────────┘  └─────────────────┘ │
        └───────────────────────┬─────────────────────┘
                                 │ manages
             ┌───────────────────┼───────────────────┐
             ▼                   ▼                   ▼
      ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
      │ VCF Instance │     │ VCF Instance │     │ VCF Instance │
      │  (HQ site)   │     │  (DR site)   │     │ (Edge site)  │
      └─────────────┘     └─────────────┘     └─────────────┘
```

## The Mental Model Shift

| VCF 5.x | VCF 9 |
|---|---|
| Cloud Builder per deployment | VCF Installer bootstraps and extends the fleet |
| SDDC Manager per site | VCF Operations manages Day-2 across every Instance |
| Bolted-on automation tool | VCF Automation as a native, policy-driven catalog |
| Separate logins per site | One login, one inventory, one Fleet |

## A Note on Instance Topologies

Multi-site patterns like a primary/HQ Instance, a DR Instance, and edge or sovereign-cloud Instances are common real-world deployment topologies under the VCF Instance/Fleet model, rather than a fixed set of named categories in the core taxonomy documentation itself. Broadcom's Design guidance covers specific reference architectures for these patterns in more depth — worth a read if you're designing a multi-site fleet.

## Sources

This post was validated against Broadcom's official VCF 9.1 documentation, specifically the VCF Taxonomy, VCF Installer Overview, VCF Operations Overview, and VCF Automation Overview pages under [VMware Cloud Foundation 9.1 documentation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/fleet-management.html).

## Up Next

Next in this series: VCF 9 Workload Domain Planning and Deployment — putting the fleet management layer to work by planning, provisioning, and standing up your first workload domain.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
