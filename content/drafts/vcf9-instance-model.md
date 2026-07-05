---
title: "VCF 9 Instance Model: Designing HQ, DR, and Edge/Sovereign Topologies"
date: 2026-07-24
draft: false
tags: ["VCF", "VMware", "VCF Instance", "Fleet", "Disaster Recovery", "Cloud Foundation"]
categories: ["VCF 9", "Architecture"]
description: "A technical breakdown of the VCF 9 Instance and Fleet constructs, validated against official Broadcom documentation: how single-site, multi-site, and disaster-recovery topologies map onto the four VCF Fleet deployment designs."
---

## Introduction

Once you've internalized "one Fleet across every site," the next question is practical: how do you actually design that fleet across a headquarters site, a DR site, and edge or sovereign-cloud locations? This post breaks down the core VCF Instance/Fleet constructs and the four fleet deployment designs Broadcom documents for VCF 9.1, and maps them to the multi-site patterns operators actually build.

## The Three Constructs, Revisited

Broadcom's VCF Taxonomy defines three nested constructs worth keeping straight:

-> VCF Instance -- the compute, storage, and networking infrastructure that runs actual workloads: a management domain plus, optionally, workload domains.

-> VCF fleet -- the environment managed by a single set of fleet-level components (VCF Operations and VCF Automation), which can span one or more VCF Instances and even standalone vCenter deployments not otherwise part of an Instance.

-> VCF private cloud -- the highest-level construct, containing one or more VCF fleets.

A single Instance can be headquarters-sized on its own. Multiple Instances under one fleet are what let a HQ, a DR site, and edge locations share centralized operations and automation instead of running as isolated silos.

## Four Fleet Deployment Designs

Broadcom's VCF Fleet Deployment Models documentation lays out four designs, each building on the previous one, that map naturally onto common multi-site topologies:

-> Basic Design -- a single VCF fleet in one availability zone or region. This is the starting point: one management domain instance centrally controlling one or more workload domain instances, without cross-site protection. A natural fit for a standalone HQ deployment.

-> Site High Availability (Across Zones) Design -- adds fault domains that spread resources across two availability zones with vSphere HA, vSAN stretched clustering, and NSX stretched segments, giving active-active protection against a single zone outage.

-> Disaster Recovery (Across Regions) Design -- builds on the Basic Design and adds a second Instance in a separate region, using VMware Live Recovery for failover and failback -- the closest match to a dedicated HQ + DR pairing.

-> Fault Domains and Disaster Recovery Design -- combines both: fault-domain high availability within a site plus cross-region disaster recovery, for organizations that need protection from both localized hardware failures and full site-level disasters.

Edge and sovereign-cloud locations aren't called out as a fixed named category in the core taxonomy -- in practice, they're additional VCF Instances joined to the same fleet, sized and secured according to whichever of the four designs above fits their role and connectivity constraints.

## Architecture at a Glance

```
VCF FLEET (VCF Operations + VCF Automation) -- single control plane, one or more Instances
        |
   -----+-----+-----
   |         |        |
HQ INSTANCE   DR INSTANCE   EDGE/SOVEREIGN INSTANCE
Basic/Site-HA  Cross-region   sized to role
```

## Comparing the Four Designs

| Design | Protects Against | Typical Role |
|---|---|---|
| Basic | Host/storage failure only | Single-site HQ |
| Site HA (Across Zones) | Zone-level outage | HQ with local resilience |
| Disaster Recovery (Across Regions) | Site-wide disaster | HQ + DR pairing |
| Fault Domains + DR | Both zone and region failures | HQ with local HA, plus DR |

## A Practical Tip

Before committing to a topology, check the network latency and bandwidth requirements between sites -- stretched-cluster and cross-region designs both depend on meeting specific latency thresholds, and Broadcom's Ports and Protocols documentation is the place to verify them before finalizing a design.

## Sources

This post was validated against Broadcom's official VCF 9.1 documentation, specifically the VCF Taxonomy and VCF Fleet Deployment Models pages under [VMware Cloud Foundation 9.1 documentation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts/vcf-operations-deployment-models.html).

## Up Next

Next in this series: Management Domain Anatomy -- what actually lives inside a management domain, and how the first one differs from the rest.

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
