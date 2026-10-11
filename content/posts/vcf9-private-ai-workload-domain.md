---
title: "Private AI Workload Domain: GPU Nodes, AI Kubernetes, and Private AI Services"
date: 2026-10-12
draft: false
tags: ["Private AI", "GPU", "NVIDIA", "VKS", "Private AI Services", "vSphere Supervisor"]
categories: ["VCF 9", "Private AI"]
description: "Running AI on your own infrastructure sounds like one project. With VMware Private AI Foundation with NVIDIA it is really three different ways to use your GPUs, plus a licensing model that spans two vendors, and the choices you make early shape everything you build and buy."
seriesPart: 20
cover:
  image: "/virtualizationgurus/images/covers/vcf9-private-ai-workload-domain.jpg"
  alt: "Private AI Workload Domain: GPU Nodes, AI Kubernetes, and Private AI Services"
  relative: false
---

## Introduction

"Run AI on our own infrastructure" sounds like a single project. With VMware Private AI Foundation with NVIDIA (PAIF) on VCF 9.1.x it isn't, there are three different ways to use your GPUs, and the one you pick changes what you build before the first workload runs. Add a licensing model where two vendors each sell you a different piece, and the planning decisions matter more than the deployment steps. This post covers the fundamentals, what the domain is made of, the three ways to consume it, and what you need to license.

## What a Private AI Workload Domain Is

PAIF builds its GPU capacity into a dedicated VI workload domain, made up of GPU-enabled ESX hosts, an NSX Edge cluster, and a Supervisor on the domain's default cluster. The management domain stays outside that build, so keep it GPU-free. Broadcom's documented starting point is at least three GPU-enabled ESX hosts in the initial cluster.

Supervisor is the Kubernetes control plane built into vSphere, so there is no separate Kubernetes product to install. GPUs reach virtual machines in one of two ways, NVIDIA vGPU, which shares a physical GPU between workloads, or DirectPath I/O, which gives a VM or Kubernetes node exclusive access to a GPU.

## Three Ways to Use the GPUs

PAIF doesn't give you one way to run AI workloads, it gives you three, and the right one depends on who is consuming the GPUs:

-> **Deep Learning VMs (DLVMs)**: ready-made virtual machines validated by NVIDIA and VMware, with the NVIDIA drivers and common machine learning tooling already installed. Data scientists request one through a VCF Automation catalog item or kubectl, and VI administrators can deploy one from the vSphere Client. It is the quickest way to prove your GPU stack works end to end.

-> **Private AI Services**: the path for building applications on large language models (LLMs), installed by a VI administrator as a Supervisor Service. It bundles a Model Gallery in Harbor for storing models, a Model Runtime that serves them, knowledge bases for retrieval-augmented generation (RAG), and an Agent Builder, all managed as one integrated service.

-> **GPU-accelerated VKS clusters**: Kubernetes clusters whose worker nodes have GPUs, for teams that want to run their own AI containers. The AI Kubernetes Cluster catalog item in VCF Automation deploys them with the NVIDIA GPU Operator, which sets up the NVIDIA driver on the workers, and it asks for an NVIDIA NGC API key when you request one.

## Licensing Spans Two Vendors

PAIF involves up to three entitlements. A VCF subscription and the Private AI Foundation license both come from Broadcom, which offers Private AI Foundation with NVIDIA as a solution license for VCF. The NVIDIA AI Enterprise (NVAIE) license comes directly from NVIDIA, and Broadcom's requirements state it is needed for vGPU workloads, for the host driver and the guest drivers. With VCF 9.1, DirectPath workloads don't need it, so the way you attach GPUs affects what you buy from NVIDIA.

One placement detail is worth knowing up front. The Private AI Foundation license is allocated to the GPU-enabled workload domains, but the guided deployment UI in the vSphere Client only appears if the license is also assigned to the management domain.

## Architectural Overview

<div class="diagram-embed">
  <object type="image/svg+xml" data="/virtualizationgurus/images/diagrams/vcf9-private-ai-workload-domain.svg"></object>
</div>

## What 9.1.1 Changed

VCF 9.1.1 keeps the same three paths. Its Private AI Foundation release notes list two additions, a new version of Private AI Services, 3.0, and a new Deep Learning VM image. Check the release notes for your version before you upgrade an existing deployment, because AI Kubernetes blueprints and NVIDIA GPU Operator versions have had compatibility notes in earlier releases.

## A Quick Checklist

- **Choosing a path?** Deep Learning VMs to validate the GPU stack, Private AI Services to build LLM applications, GPU-accelerated VKS clusters for teams that want Kubernetes-native AI.
- **Planning the hosts?** A dedicated GPU workload domain with at least three GPU hosts, and a GPU-free management domain.
- **Budgeting licenses?** The Private AI Foundation license from Broadcom, plus NVAIE from NVIDIA if you use vGPU. Check whether DirectPath covers your workload before buying NVAIE.
- **Upgrading an existing deployment?** Read the release notes for your target version first.

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
- [VMware Cloud Foundation 9.1.1.0 Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/release-notes/vmware-cloud-foundation-9-1-1-0-release-notes.html)
- [VMware Private AI Foundation with NVIDIA 9.1.x Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/private-ai/foundation-with-nvidia/9-1/private-ai-release-notes/vmware-private-ai-foundation-with-nvidia-91-release-notes.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
