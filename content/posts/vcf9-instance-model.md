---
title: "VCF 9 Instance Model: Designing HQ, DR, and Edge/Sovereign Topologies"
date: 2026-07-17
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

One placement detail matters when you're actually drawing this topology: per Broadcom's taxonomy, the fleet-level components (VCF Operations and VCF Automation) live in the management domain of whichever VCF Instance is *first* in the fleet. So when you're designing an HQ + DR + Edge fleet, the choice of which Instance goes first effectively decides where your single control plane physically sits.

## Four Fleet Deployment Designs

Broadcom's VCF Fleet Deployment Models documentation lays out four designs, each building on the previous one, that map naturally onto common multi-site topologies:

-> Basic Design -- a single VCF fleet in one availability zone or region. This is the starting point: one management domain instance centrally controlling one or more workload domain instances, without cross-site protection. A natural fit for a standalone HQ deployment.

-> Site High Availability (Across Zones) Design -- adds fault domains that spread resources across two availability zones with vSphere HA, vSAN stretched clustering, and NSX stretched segments, giving active-active protection against a single zone outage.

-> Disaster Recovery (Across Regions) Design -- builds on the Basic Design and adds a second Instance in a separate region, using VMware Live Recovery for failover and failback -- the closest match to a dedicated HQ + DR pairing.

-> Fault Domains and Disaster Recovery Design -- combines both: fault-domain high availability within a site plus cross-region disaster recovery, for organizations that need protection from both localized hardware failures and full site-level disasters.

Edge locations, unlike the general HQ/DR patterns above, do get their own named model: **VCF Edge** (formerly called Remote Clusters), a purpose-built configuration for edge deployments with its own sizing rules -- a minimum of 10 sites, at least 8 CPU cores per host, a cap of 256 CPU cores per site, and a requirement that Edge hosts sit in a physically distinct location (a separate rack or switch) from your data center workloads unless you have strict segregation controls in place. VCF Operations is a mandatory licensing requirement for any VCF Edge deployment. Sovereign-cloud requirements, by contrast, aren't tied to a single named topology -- they're typically met by combining one of the four fleet designs above with in-country data residency and recovery controls (for example, vSAN-based ransomware and data recovery) rather than a distinct named architecture.

## Architecture at a Glance
**Architecture of HQ Instance Basic / Site-HA**

```
+-----------------------------------------------------------+
|           HQ INSTANCE -- Basic / Site-HA Design           |
+-----------------------------------------------------------+

                              |
                              v
+-----------------------------------------------------------+
|   VCF Fleet Control Plane (first Instance in the fleet)   |
|              VCF Operations + VCF Automation              |
+-----------------------------------------------------------+
                              |
                              v
+-----------------------------------------------------------+
|                     Management Domain                     |
+-----------------------------------------------------------+
                              |
                              v
+------------------------+        +------------------------+ 
|   Workload Domain A    |        |   Workload Domain B    | 
+------------------------+        +------------------------+ 

Site-HA option -- hosts split across two availability zones:
+------------------------+        +------------------------+ 
|   Zone A (Preferred)   |        |   Zone B (Secondary)   | 
|       ESX Hosts        |        |       ESX Hosts        | 
+------------------------+        +------------------------+ 
             |                                 |             
             +----------------+----------------+             
vSAN Stretched Cluster | NSX Stretched Segments | vSphere HA

Basic Design = same picture without the Zone A / Zone B split

```

**Architecture of DR Instance (cross-region recovery)**

```
--------------------------------------------------------------------+
|                  VCF FLEET (spans both Instances)                  |
|    VCF Operations + VCF Automation -- lives in the HQ Instance     |
+--------------------------------------------------------------------+
                                   |                                  
               +-------------------+-------------------+              
               v                                       v              
+----------------------------+          +----------------------------+
|        HQ INSTANCE         |          |        DR INSTANCE         |
|      Region: Primary       |          |     Region: Secondary      |
|                            |          |                            |
|     Management Domain      |          |     Management Domain      |
|     Workload Domain(s)     |          |     Workload Domain(s)     |
+----------------------------+          +----------------------------+
                                                                      
           -------- Failover: HQ -> DR -------->                      
           <------- Failback: DR -> HQ ---------                      
           VMware Live Recovery -- cross-region replication

```
**Architecture of Edge / Sovereign Instance (VCF Edge model)**

```
+------------------------------------------------------------------------------+
|                              CORE / HQ INSTANCE                              |
|                           VCF Fleet Control Plane                            |
|                     VCF Operations (mandatory for Edge)                      |
+------------------------------------------------------------------------------+
                                                  |                             
        +--------------------+--------------------+--------------------+        
        v                    v                    v                    v        
+---------------+    +---------------+    +---------------+    +---------------+
|  Edge Site 1  |    |  Edge Site 2  |    |  Edge Site 3  |    |      ...      |
|>= 8 cores/host|    |>= 8 cores/host|    |>= 8 cores/host|    |    min. 10    |
|  <= 256 cores |    |  <= 256 cores |    |  <= 256 cores |    |  sites total  |
+---------------+    +---------------+    +---------------+    +---------------+

          VCF Edge model (formerly Remote Clusters): minimum 10 sites
     Each Edge site: physically distinct rack/switch from core DC workloads

            Sovereign Cloud overlay (not a separate named topology):
                        any of the 4 Fleet Designs above
                    + in-country data residency requirements
                + vSAN-based ransomware / data recovery controls

```

## Comparing the Four Designs

| Design | Protects Against | Typical Role |
|---|---|---|
| Basic | Host/storage failure only | Single-site HQ |
| Site HA (Across Zones) | Zone-level outage | HQ with local resilience |
| Disaster Recovery (Across Regions) | Site-wide disaster | HQ + DR pairing |
| Fault Domains + DR | Both zone and region failures | HQ with local HA, plus DR |

Each design also maps to a named infrastructure blueprint in Broadcom's Design Library -- what you actually select from when building the design in practice:

| Design | Infrastructure Blueprint |
|---|---|
| Basic | VCF Fleet in a Single Site (or ...with Minimal Footprint) |
| Site HA (Across Zones) | VCF Fleet with Multiple Sites in a Single Region |
| Disaster Recovery (Across Regions) | VCF Fleet with Multiple Sites Across Multiple Regions |
| Fault Domains + DR | VCF Fleet with Multiple Sites in a Single Region plus Additional Region(s) |

## A Practical Tip

Before committing to a topology, check the network latency and bandwidth requirements between sites -- stretched-cluster and cross-region designs both depend on meeting specific latency thresholds, and Broadcom's Ports and Protocols documentation is the place to verify them before finalizing a design.

## What's Next

Next in this series: VCF 9 Management Domain Anatomy -- what actually lives inside a management domain, and how the first one differs from the rest.

## Further Reading (Official Broadcom Documentation)

- [VCF Taxonomy](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/overview-of-vmware-cloud-foundation-9/workload-domains-in-vmware-cloud-foundation.html)
- [VCF Fleet Deployment Models](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts/vcf-operations-deployment-models.html)
- [VCF Edge Models](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/design/vmware-cloud-foundation-concepts/vcf-edge.html)
- [Architectural Options in VMware Cloud Foundation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
