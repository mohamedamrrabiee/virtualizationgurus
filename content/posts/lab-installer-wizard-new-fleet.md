---
title: "Walking the VCF Installer Wizard for a New Fleet"
date: 2026-10-24
draft: true
tags: ["VCF", "VMware", "Lab", "VCF Installer", "Deployment", "vSAN ESA"]
categories: ["VCF 9", "Lab Series"]
labPart: 4
cover:
  image: "/images/covers/lab-installer-wizard-new-fleet.jpg"
  alt: "Walking the VCF Installer Wizard for a New Fleet"
  relative: false
description: "A step-by-step walk through the VCF Installer wizard for a new VCF 9.1.1 fleet: every setting used for the management domain, the vSAN ESA HCL warnings on nested hardware, and what the final validation looked like."
---

## Overview

With the hosts prepared and the installer running, the wizard is where the design from the first post turns into settings. This post walks through the management domain deployment in the order the wizard asks for it, with the exact choices used in this lab and the one step that needs extra attention on nested hardware.

The wizard was run three times in this lab. The first two runs stopped on a thumbprint problem and a vSAN disk problem (covered in the troubleshooting post). The settings below are from the final run, which passed every validation.

## The settings at a glance

| Wizard step | Setting used |
|---|---|
| Deployment path | New VCF fleet, VCF Operations deployed by the installer, VCF Automation not deployed |
| Size options | High availability, Small |
| Network options | Full Stack VPC with distributed connectivity |
| Storage | vSAN ESA, auto-claim of HCL-incompatible disks enabled |
| VCF Management Services | Fleet, instance, identity broker and services runtime FQDNs, internal cluster CIDR `250.0.0.0/15` |
| NSX Manager | Three-node cluster, VPC gateway connectivity VLAN 3332, gateway `10.20.98.1/24` |
| SDDC Manager | New appliance `vg1-m01-sddc01` (the installer is not part of the domain) |

## Step by step

### 1. General information

Pick the version (9.1.1.0 here), the instance name (`vg1`), the domain name (`m01`), and the DNS and NTP servers (the lab router). The instance and domain names are the tokens in every host name that follows, so this is the step where the naming plan from the first post gets locked in.

<!-- TODO screenshot after masking: S008 (general information) -->

### 2. Networks

Enter the ESX management, VM management and VCF management networks with their VLAN IDs, subnets and gateways, plus the IP pool used by VCF Management Services.

<!-- TODO screenshot after masking: S011 (networks) -->

### 3. VCF Management

This step defines the VCF Operations deployment: a primary node and a replica node, a cloud proxy and the license server, each with an FQDN from the naming plan.

<!-- TODO screenshot after masking: S013 (VCF Operations nodes) -->

### 4. vCenter

Set the vCenter name (`vg1-m01-vc01`), datacenter (`vg1-m01-dc01`), cluster (`vg1-m01-cl01`) and the SSO domain (`vsphere.local`).

<!-- TODO screenshot after masking: S015 (vCenter) -->

### 5. Storage

Choose vSAN ESA and enable the option to auto-claim HCL-incompatible disks. This is the step that matters most on nested hardware, and it gets its own section below.

<!-- TODO screenshot after masking: S016 (storage) -->

### 6. Distributed switch

Name the switch (`vg1-m01-cl01-vds01`), assign two uplinks, and map the traffic types (management, vMotion, vSAN) to port groups.

<!-- TODO screenshot after masking: S017 (distributed switch) -->

### 7. NSX Manager

Enter the cluster VIP and the three appliance FQDNs, then the VLAN and gateway for VPC gateway connectivity. This lab uses distributed connectivity on VLAN 3332 with gateway `10.20.98.1/24`.

<!-- TODO screenshot after masking: S020 (NSX Manager) -->

### 8. Validate and deploy

The installer runs its pre-checks against the hosts, network, DNS and NTP. Anything that cannot be fixed shows up here as an error, and anything it considers a risk shows up as a warning you must acknowledge before deploying.

<!-- TODO screenshot after masking: S024 (validation with HCL warnings), S079 (final run, all validations passed) -->

## The HCL warning on nested hardware

The nested hosts use virtual NVMe disks, which are not on the vSAN ESA HCL. The first validation failed on all four hosts with "ESX Host vSAN HCL Compatibility" and the message "Host is not HCL compatible; no vSAN ESA certified disks".

-> **Spec setting**: `skipHclAutoDiskClaim` must be `true` in the vSAN ESA configuration of the spec. The imported spec had it set to `false`.

-> **Two switches in the Storage step**: "Allow auto claim of HCL incompatible disks" and "Skip HCL compatibility disk pre-check". Both need to be on.

-> **Warnings that remain**: after that, the validation still lists HCL warnings. Acknowledge them, and the deployment can proceed.

-> **Both switches reset**: on every spec import and on every new installer appliance. If you re-import a spec, check the Storage step again.

This is a lab-only workaround for unsupported hardware. On certified hardware, the HCL check should pass and none of this applies.

## Before you deploy

-> **Names**: every FQDN in the wizard matches the naming plan and has forward and reverse DNS.

-> **Thumbprints**: SHA-256 values captured after the certificate restart, as described in the certificates post.

-> **Storage**: both HCL switches set, and the warnings acknowledged.

-> **Passwords**: real values in the spec before the first validation, so the hosts do not lock the root account.

## What's Next

Next in this series: Bring-up milestones, what each stage builds and how long it took.

## Further Reading (Official Broadcom Documentation)

- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)
- [Components in VCF](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/vcf-management-appliances.html)
- [Broadcom KB 408300: vSAN ESA HCL override](https://knowledge.broadcom.com/external/article/408300)
- [Broadcom KB 442952: Disk eligibility and HCL warnings](https://knowledge.broadcom.com/external/article/442952)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
