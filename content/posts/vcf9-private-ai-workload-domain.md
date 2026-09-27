---
title: "Private AI Workload Domain: GPU Nodes, AI Kubernetes, and NVIDIA NIM"
date: 2026-10-10
draft: true
tags: ["Private AI", "GPU", "NVIDIA", "VKS", "NIM", "vSphere Supervisor"]
categories: ["VCF 9", "Private AI"]
description: "A GPU workload domain sounds like one build. VMware Private AI Foundation with NVIDIA actually gives you three distinct consumption paths, each with a different host bill of materials, and the licensing model spans two vendors who don't sell you the same piece."
---

## Introduction

"Stand up a GPU workload domain" reads like a single task. It isn't. VMware Private AI Foundation with NVIDIA (PAIF) on VCF 9.1 gives you three genuinely different ways to consume that GPU capacity, Deep Learning VMs, Private AI Services, and GPU-accelerated VKS clusters, and the one you pick changes your host bill of materials before you've deployed a single workload. Layer on a licensing model that spans two vendors who each sell you a different piece, and this is a domain where the planning decisions matter more than the deployment steps.

## The Architecture Pattern: Keep the Management Domain GPU-Free

The validated shape is a GPU-free management domain feeding one or more GPU-enabled VI workload domains, each holding the GPU-accelerated ESX hosts, an NSX Edge cluster, and vSphere Supervisor. Resist the temptation to collapse this into a single cluster to save hosts, especially heading toward production. The Supervisor control plane and the NSX Edge nodes have their own placement and availability requirements, and you don't want them competing with an actual NIM pod for a GPU host during a failover event.

Supervisor itself is the Kubernetes control plane, and it runs directly on the ESX hypervisor layer, there's no separate Kubernetes distribution to install and no external control plane to operate. Worker nodes are ordinary vSphere VMs, and GPUs attach to them through NVIDIA vGPU or Dynamic DirectPath I/O, consumed via the same vSphere scheduler your team already understands, vMotion and DRS behave the way they always have.

## Three Consumption Paths, Three Different Host Bills of Materials

PAIF doesn't give you one way to run AI workloads, it gives you three, and the choice isn't cosmetic:

-> **Deep Learning VMs (DLVMs)**: pre-configured VMs that boot with the NVIDIA driver, CUDA libraries, and common frameworks already in place from the NGC catalog. Requested through the VCF Automation Service Catalog with a vGPU profile selection, this is the fastest way to validate that your GPU stack is actually healthy end to end, and the only NVIDIA component you supply yourself if you build a custom image is the vGPU guest driver.

-> **Private AI Services**: the LLM-centric path, a Model Store and Model Runtime serving model endpoints, with the vector database and RAG plumbing already managed for you rather than something you assemble yourself.

-> **GPU-accelerated VKS clusters**: the validated recommendation is deploying these through the VCF Automation catalog, which pre-installs the NVIDIA GPU Operator and a NIM template so an ML engineer never has to hand-touch a Helm chart from NGC. Drop to manual kubectl deployment only when you genuinely need infrastructure-as-code, a custom cluster topology, or the NVIDIA Network Operator for distributed inference and training across hosts. As of VCF 9.1, both the catalog path and the manual path support vGPU and DirectPath I/O, you no longer trade away self-service to get passthrough.

## The Gotcha Nobody Reads Until It's Already a Problem: MIG Cannot Back NIM

Multi-Instance GPU (MIG) partitions a physical GPU into isolated slices, and it's genuinely useful, for training workloads and notebook isolation specifically. It cannot back NVIDIA NIM microservices. If your inference workload needs NIM, the mode has to be a whole GPU assignment or time-slicing, not MIG. Match the mode to the workload before you provision anything, reconfiguring GPU assignment mode after the fact is a much bigger job than picking correctly up front.

## Licensing Spans Two Vendors, and They Don't Sell You the Same Thing

Standing up PAIF requires three separate entitlements: a VCF subscription, the Private AI Foundation add-on, both from Broadcom, and an NVIDIA AI Enterprise (NVAIE) vGPU license, bought directly from NVIDIA, not from Broadcom. There's also a placement subtlety worth knowing before you assign anything: the Private AI Foundation add-on license goes on the GPU-enabled workload domain where the AI workloads actually run, but if you also want the guided deployment UI to show up in the vSphere Client, you need to assign that same license to the management domain as well.

## Where Bring-Ups Actually Stall

Two prerequisites cause more failed first attempts than anything else in the deployment: SR-IOV needs to be enabled in the host BIOS, and the matching vGPU host driver VIB needs to already be in your vSphere Lifecycle Manager image before you start. Neither is hard to fix, but both are easy to discover only after a deployment has already failed partway through.

## A Real Version Compatibility Trap

Broadcom's own release notes for Private AI Foundation with NVIDIA document a specific breakage worth knowing if you're touching an existing deployment: AI Kubernetes blueprints in VCF Automation stop working once you move to VKr (vSphere Kubernetes release) 1.33 or later, because the `tanzukubernetescluster` class type the blueprints depend on is deprecated at that version. If you're planning a VKS upgrade alongside an existing PAIF deployment, check your blueprint compatibility before you upgrade, not after.

## Architectural Overview

<div class="diagram-embed">
  <object type="image/svg+xml" data="/virtualizationgurus/images/diagrams/vcf9-private-ai-workload-domain.svg"></object>
</div>

## A Quick Checklist

- **Choosing a consumption path?** Match it to the actual workload, DLVM to validate the stack, Private AI Services for LLM serving without assembling your own RAG plumbing, VKS for teams that want Kubernetes-native AI without touching Helm charts.
- **Planning inference with NIM?** Whole GPU or time-sliced vGPU, never MIG, decide before provisioning.
- **Assigning the Private AI Foundation add-on license?** GPU workload domain always, management domain too if you want the guided UI in vSphere Client.
- **Prepping hosts?** SR-IOV in BIOS and the matching vGPU driver VIB in your vLCM image, verify both before the deployment, not during it.
- **Upgrading VKS on an existing PAIF deployment?** Check AI Kubernetes blueprint compatibility against VKr 1.33+ before you touch the upgrade.

## What's Next

Next in this series: Advanced Services for VCF, VPC, Load Balancing, and Network Observability.

## Further Reading (Official Broadcom Documentation)

- [VMware Private AI Foundation with NVIDIA 9.1](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-1.html)
- [Deploy VCF on Supermicro HGX Servers with NVIDIA GPUs for AI Workloads](https://blogs.vmware.com/cloud-foundation/2026/08/31/deploy-vcf-on-supermicro-hgx-servers-with-nvidia-gpus-for-ai-workloads/)
- [VCF 9.1: The Secure, Cost-Effective Private Cloud Platform for Production AI](https://blogs.vmware.com/cloud-foundation/2026/05/05/vcf-9-1-secure-cost-effective-private-cloud-platform-for-production-ai/)
- [VMware Private AI Foundation with NVIDIA 9.0.x Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-0/private-ai-release-notes/vmware-private-ai-foundation-with-nvidia-90-release-notes.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
