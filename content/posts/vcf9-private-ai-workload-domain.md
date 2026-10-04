---
title: "Private AI Workload Domain: GPU Nodes, AI Kubernetes, and NVIDIA NIM"
date: 2026-10-10
draft: true
tags: ["Private AI", "GPU", "NVIDIA", "VKS", "NIM", "vSphere Supervisor"]
categories: ["VCF 9", "Private AI"]
description: "A GPU workload domain sounds like one build. VMware Private AI Foundation with NVIDIA actually gives you three distinct consumption paths, each with a different host bill of materials, and the licensing model spans two vendors who don't sell you the same piece."
seriesPart: 20
cover:
  image: "/virtualizationgurus/images/covers/vcf9-private-ai-workload-domain.jpg"
  alt: "Private AI Workload Domain: GPU Nodes, AI Kubernetes, and NVIDIA NIM"
  relative: false
---

## Introduction

"Stand up a GPU workload domain" reads like a single task. It isn't. VMware Private AI Foundation with NVIDIA (PAIF) on VCF 9.1 gives you three genuinely different ways to consume that GPU capacity, Deep Learning VMs, Private AI Services, and GPU-accelerated VKS clusters, and the one you pick changes your host bill of materials before you've deployed a single workload. Layer on a licensing model that spans two vendors who each sell you a different piece, and this is a domain where the planning decisions matter more than the deployment steps.

## The Architecture Pattern: Keep the Management Domain GPU-Free

Broadcom's deployment flow builds the GPU capacity into a dedicated VI workload domain, made up of GPU-accelerated ESX hosts, an NSX Edge cluster with a Tier-0 gateway, and a Supervisor instance on the domain's default cluster. The management domain stays outside that build, so keep it GPU-free. Resist the temptation to collapse everything into a single cluster to save hosts, especially heading toward production, because the Supervisor and the NSX Edge nodes have their own placement and availability needs and shouldn't compete with an AI workload for a GPU host during a failover. The documented starting point is a minimum of three GPU-enabled ESX hosts for the initial cluster.

Supervisor is the Kubernetes control plane for the domain, built into vSphere, so there is no separate Kubernetes distribution to install. Worker nodes are ordinary vSphere VMs, and GPUs attach to them through NVIDIA vGPU or DirectPath I/O. One operational detail to plan for: vGPU vMotion is not on by default, Broadcom's workload domain steps have you set the `vgpu.hotmigrate.enabled` advanced setting to true, and VMs using DirectPath I/O keep exclusive device access, so don't design failover around moving them live.

## Three Consumption Paths, Three Different Host Bills of Materials

PAIF doesn't give you one way to run AI workloads, it gives you three, and the choice isn't cosmetic:

-> **Deep Learning VMs (DLVMs)**: pre-configured VMs optimized and validated by NVIDIA and VMware, with popular ML libraries, frameworks, and the NVIDIA DCGM Exporter for GPU monitoring already in place. Data scientists request one from VCF Automation through the AI workstation catalog item, VI administrators can deploy one straight onto a cluster in the vSphere Client, and the kubectl route through the Supervisor VM service is available too. It is the fastest way to prove your GPU stack is healthy end to end.

-> **Private AI Services**: the LLM-centric path, installed as a Supervisor Service by VI administrators. It bundles a Model Gallery in Harbor, a Model Runtime that serves model endpoints, a PostgreSQL vector database for knowledge bases and RAG, an Agent Builder, and MCP server integration, all managed as one integrated service rather than something you assemble yourself.

-> **GPU-accelerated VKS clusters**: through VCF Automation, the AI Kubernetes Cluster catalog item deploys VKS clusters with the NVIDIA GPU Operator, which sets up the right NVIDIA driver on the worker nodes, and it asks for an NVIDIA NGC API key at request time. The kubectl route is documented for both vGPU and GPU passthrough, in connected and disconnected environments, so reach for it when you need a topology or automation the catalog item doesn't give you. VCF 9.1 also adds DirectPath enablement for GPUs, giving VMs and Kubernetes nodes exclusive GPU access without needing an NVAIE license.

## The Gotcha Nobody Reads Until It's Already a Problem: MIG Cannot Back NIM

Multi-Instance GPU (MIG) partitions a physical GPU into hardware-isolated slices, which is useful when you need strict isolation between users. Broadcom's requirements page is explicit about the limitation: MIG sharing is incompatible with NVIDIA NIM. If your inference workload needs NIM, plan for time-slicing vGPU or a dedicated GPU rather than MIG. Match the mode to the workload before you provision anything, because changing GPU assignment after the fact means reworking the hosts and the workloads on them.

## Licensing Spans Two Vendors, and They Don't Sell You the Same Thing

PAIF involves up to three entitlements. A VCF subscription and the Private AI Foundation add-on both come from Broadcom, and the add-on is what unlocks the guided deployment UI, VM classes with GPU reservation, and Private AI Services. The NVIDIA AI Enterprise (NVAIE) license comes directly from NVIDIA, and Broadcom's requirements state it is needed for the vGPU host driver VIB on the ESX hosts and the guest OS drivers. That makes it a vGPU-mode requirement: with the 9.1 DirectPath enablement, passthrough workloads don't need it, so your GPU mode now drives your NVIDIA licensing as well as your architecture.

There's also a placement subtlety worth knowing before you assign anything. The add-on license capacity is allocated only to the GPU-enabled workload domains, but the guided deployment UI in the vSphere Client and the quickstart wizard in VCF Automation only appear if the license is also assigned to the management domain.

## Where Bring-Ups Actually Stall

Prerequisites are where first attempts tend to stall. For vGPU, SR-IOV must be enabled in the host BIOS and on the graphics devices, and the matching vGPU host driver VIB has to be added to the cluster's vSphere Lifecycle Manager image before host remediation. When you deploy the workload domain, you select hosts whose NVIDIA vGPU state is Ready, so a host that missed either step simply won't qualify. None of it is hard to fix, but all of it is easier to verify up front than to discover mid-deployment.

## A Real Version Compatibility Trap

Broadcom's 9.0.1 release notes for Private AI Foundation with NVIDIA document a specific known issue worth knowing if you're touching an existing deployment: AI Kubernetes blueprints in VCF Automation no longer work with VKr (vSphere Kubernetes release) 1.33 or later, because the `tanzukubernetescluster` class type they depend on is deprecated. The 9.1 notes also flag that the NVIDIA GPU Operator version in the AI Kubernetes Cluster blueprint has reached end of life and can be updated in the blueprint. If you're planning a VKS upgrade alongside an existing PAIF deployment, check blueprint compatibility against the release notes for your version before you upgrade, not after.

## Architectural Overview

<div class="diagram-embed">
  <object type="image/svg+xml" data="/virtualizationgurus/images/diagrams/vcf9-private-ai-workload-domain.svg"></object>
</div>

## A Quick Checklist

- **Choosing a consumption path?** Match it to the actual workload: DLVM to validate the stack, Private AI Services for LLM serving without assembling your own RAG plumbing, VKS for teams that want Kubernetes-native AI.
- **Planning inference with NIM?** Time-sliced vGPU or a dedicated GPU, never MIG, decide before provisioning.
- **Budgeting licenses?** Add-on on the GPU workload domain, and on the management domain too for the guided UI. NVAIE for vGPU mode, and check whether DirectPath covers your workload before buying it.
- **Prepping hosts?** At least three GPU hosts, SR-IOV in BIOS, the vGPU driver VIB in your vLCM image, and the vGPU vMotion setting if you need live migration.
- **Upgrading VKS on an existing PAIF deployment?** Check AI Kubernetes blueprint compatibility against VKr 1.33+ and the GPU Operator version before you touch the upgrade.

## What's Next

Next in this series: Advanced Services for VCF, VPC, Load Balancing, and Network Observability.

## Further Reading (Official Broadcom Documentation)

- [VMware Private AI Foundation with NVIDIA 9.1](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-1.html)
- [Requirements for Deploying VMware Private AI Foundation with NVIDIA](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-0/private-ai-foundation-9-x/deploying-private-ai-foundation-with-nvidia/requirements-for-deploying-private-ai-foundation-with-nvidia.html)
- [Assign a Private AI Foundation License to the Management Domain](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-0/private-ai-foundation-9-x/deploying-private-ai-foundation-with-nvidia/assign-the-private-ai-foundation-license-to-the-management-domain.html)
- [Deploying AI Workloads on VKS Clusters](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-1/deploying-ai-workloads-on-tkg-clusters.html)
- [Delivering Generative AI Applications by Using Private AI Services](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-1/what-is-private-ai-services.html)
- [Deploy VCF on Supermicro HGX Servers with NVIDIA GPUs for AI Workloads](https://blogs.vmware.com/cloud-foundation/2026/08/31/deploy-vcf-on-supermicro-hgx-servers-with-nvidia-gpus-for-ai-workloads/)
- [VCF 9.1: The Secure, Cost-Effective Private Cloud Platform for Production AI](https://blogs.vmware.com/cloud-foundation/2026/05/05/vcf-9-1-secure-cost-effective-private-cloud-platform-for-production-ai/)
- [VMware Private AI Foundation with NVIDIA 9.0.x Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-0/private-ai-release-notes/vmware-private-ai-foundation-with-nvidia-90-release-notes.html)
- [VMware Private AI Foundation with NVIDIA 9.1.x Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-1/private-ai-release-notes/vmware-private-ai-foundation-with-nvidia-91-release-notes.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
