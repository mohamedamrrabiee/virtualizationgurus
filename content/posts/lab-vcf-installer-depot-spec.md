---
title: "VCF Installer in a Lab: Appliance Placement, Offline Depot and a Spec from the Planning Workbook"
date: 2026-10-23
draft: true
tags: ["VCF", "VMware", "Lab", "VCF Installer", "Offline Depot", "Deployment"]
categories: ["VCF 9", "Lab Series"]
labPart: 3
cover:
  image: "/images/covers/lab-vcf-installer-depot-spec.jpg"
  alt: "VCF Installer in a Lab: Appliance Placement, Offline Depot and a Spec from the Planning Workbook"
  relative: false
description: "Where to run the VCF Installer when the management hosts have no datastore yet, how to connect an offline depot and pick the right 9.1.1 binaries, and how to generate a deployment JSON from the planning workbook with PowerShell on Linux."
---

## Overview

Before the VCF Installer can build anything, three practical questions need answers. Where does the installer appliance run when no datastore exists yet? How does it get the 9.1.1 binaries? And how do you produce a deployment spec that passes validation? This post walks through each, with the small mistakes that cost time in this lab.

## Where the installer runs

With vSAN ESA, the management hosts have no datastore before bring-up, and their NVMe disks must stay blank so vSAN can claim them. The installer cannot live on a management host, so it runs outside the management domain.

-> **Temporary datastore**: on `vg1-w01-esx01`, create a VMFS datastore on one 512 GiB NVMe disk.

-> **Port group**: a VM port group on VLAN 3321 on the standard switch. The installer VM only needs a VM port group, not a VMkernel adapter.

-> **Appliance**: deploy the SDDC Manager appliance OVA (thin provisioned) from the jump host as `installer.vgurus.lab` on `10.20.10.30/24`, with the lab router as gateway, DNS and NTP.

-> **Deployment choice**: in the installer, choose a VCF Installer deployed outside the management domain, so a new SDDC Manager (`vg1-m01-sddc01`) is deployed on vSAN.

-> **Clean-up**: after bring-up, power off and delete the installer, delete the temporary datastore and clear the partition table on that NVMe disk, so vSAN ESA can claim it when the workload domain hosts are commissioned.

Two small mistakes worth avoiding:

-> **A VMkernel adapter by mistake**: a new vmk showed up with an invalid address and no VLAN. Removing it and setting VLAN 3321 on the port group fixed it.

-> **The wrong appliance build**: a different build was picked from the depot. Deploy the build that matches the target release, here `VCF-SDDC-Manager-Appliance-9.1.1.0.25713928.ova`.

## The offline depot

The lab pulls binaries from an offline depot running on the jump host. Two things behaved differently from what the UI suggested.

-> **Depot by IP**: the installer rejected the depot host name with an "Invalid URL" error. Connecting the depot by IP address worked.

-> **Version selection**: the installer listed 9.1.0.0 binaries by default. Select 9.1.1.0 explicitly and download those bundles.

Keep the depot address in one place. In this lab the address changed once, and every file that referenced it had to be updated.

## Generating the deployment spec

The VCF 9 installer takes a JSON deployment spec. The planning workbook feeds a PowerShell generator, `VCF.JSONGenerator`, that produces it. Running it on an Ubuntu jump host needs a few extra steps.

```powershell
# Jump host (Ubuntu), inside pwsh
Import-Module VCF.JSONGenerator -SkipEditionCheck
Install-Module ImportExcel -Scope CurrentUser
Install-Module VCF.PowerCLI -Scope CurrentUser
Start-VCFJsonGeneration                     # menu driven; reads the saved planning workbook
```

Four things went wrong on the way, all small:

-> **Wrong shell**: `Set-PSRepository: command not found` meant the command was run in bash. Start `pwsh` first.

-> **Module not autoloading**: the module (version 9.1.0.1007) is tagged for the Desktop edition and does not load by default in PowerShell on Linux. `-SkipEditionCheck` fixes it. Install ImportExcel and VCF.PowerCLI manually.

-> **A "Value Missing" error**: `Invalid input 'Value Missing' for flt_net_nodea_gateway_cidr`. The gateway cell was empty, and the generator reads the values Excel last saved. Fill the gateway, recalculate and save in Excel, then rerun.

-> **Sizing and block differences**: the exported spec sized the appliances from the deployment model (High Availability plus Small), which differed from the plan, and it carried a default private transit gateway block of `172.31.0.0/16`. Align the plan to the model and set `privateTgwIpBlockCidr` to your own range.

A few fields from the finished spec show how the naming plan from post 1 lands in it:

```json
{
  "sddcId": "m01",
  "vcfInstanceName": "vg1",
  "workflowType": "VCF",
  "version": "9.1.1.0",
  "dnsSpec": { "subdomain": "vgurus.lab", "nameservers": ["10.20.10.1"] },
  "ntpServers": ["10.20.10.1"],
  "sddcManagerSpec": { "hostname": "vg1-m01-sddc01.vgurus.lab" }
}
```

## Two things that reset on every import

Nested virtual NVMe disks are not on the vSAN ESA HCL. The spec carries `skipHclAutoDiskClaim` for that case, and the installer's Storage step has two switches ("Allow auto claim of HCL incompatible disks" and "Skip HCL compatibility disk pre-check"). Both switches reset on every spec import and on every new installer appliance, so set them again each time. The next post walks through that wizard step.

Also, validate once. Repeated validations with a placeholder password lock the root account on the hosts (see the previous post).

## Before you move on

-> **Installer**: running on a temporary datastore outside m01, on the correct build.

-> **Depot**: connected by IP, 9.1.1.0 bundles selected.

-> **Spec**: generated from a saved and recalculated workbook, with real passwords and current thumbprints.

-> **Switches**: HCL options set after every import.

<!-- TODO screenshots after masking: S034, S035 (installer deployment and depot) -->

## What's Next

Next in this series: Walking the VCF Installer wizard for a new fleet.

## Further Reading (Official Broadcom Documentation)

- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)
- [VCF 9.1 Planning and Preparation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/planning-and-preparation.html)
- [Broadcom KB 442952: Disk eligibility and HCL warnings](https://knowledge.broadcom.com/external/article/442952)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
