---
title: "Workload Domain Creation: Greenfield vs Import Existing vCenter"
date: 2026-07-27
draft: true
tags: ["Workload Domains", "vCenter", "Migration", "NSX"]
categories: ["VCF 9", "Deployment"]
description: "Two ways to add a workload domain to a VCF instance -- build it fresh through the wizard, or import an existing vCenter as-is. What each path requires, what it changes on day one, and how to choose."
---

## Introduction

Every VI workload domain in a VCF instance got there one of two ways: it was built from scratch through the workload domain wizard, or it was an existing vCenter environment that VCF Operations absorbed as-is. These aren't just two UI paths to the same result -- they carry different prerequisites, different day-one side effects, and different long-term upgrade constraints. Picking the wrong one for your situation doesn't just cost time in the wizard; it can lock a workload domain out of upgrade paths for its entire lifecycle.

## Two Paths, One Fleet

**Greenfield** creates a new workload domain from hosts that have never run a production vCenter -- commissioned ESX hosts, a chosen principal storage type, and a new or shared NSX Manager instance. VCF Operations builds the vCenter, configures the cluster, and enrolls the domain into fleet management from the moment it exists.

**Import** takes a vCenter instance you already run -- with or without NSX -- and brings its entire inventory into the VCF instance as a workload domain. VCF Operations calls this "Import"; the same mechanism invoked through the VCF Installer with a JSON specification file is called "Converge." Same outcome, different entry point depending on whether you're driving it through the UI or automating it.

## Greenfield: Build It Fresh

The wizard-driven path assumes a clean slate. Hosts must already be commissioned with the target principal storage type, and if the management domain hosts were imaged with an express patch, the new workload domain's hosts need that same patch applied before they'll pass validation. For NSX, you choose per domain: deploy a new NSX Manager instance, or join an existing shared instance from another workload domain -- though a shared instance deployed in an IPv4-only domain forces the new workload domain onto IPv4 as well, even if it was otherwise planned for dual-stack.

vVols as a principal storage type still works in VCF 9, but it ships deprecated -- if you're standing up new infrastructure today, that's a call worth making deliberately rather than by default.

## Import: Bring What You Already Have

Import has real teeth around version alignment and configuration shape, because it's absorbing infrastructure VCF didn't build:

- **Minimum versions**: vCenter 8.0 Update 1+, ESX 8.0 Update 1+, and if NSX Manager is present, a three-node cluster on 4.1.0.2 or later. No NSX Manager present? VCF deploys one during the import, at the latest version compatible with that vCenter.
- **All-or-nothing at the vCenter level**: every cluster managed by the imported vCenter comes in together. There's no picking a subset -- if even one cluster in that vCenter doesn't meet the requirements, the whole import blocks.
- **Storage priority is fixed**: when a cluster has multiple datastore types, VCF picks the primary automatically -- vSAN first, then NFS v3, then VMFS, then NFS 4.1, then iSCSI, with vVols last and not recommended. A JSON convergence spec can override this with `existingDatastoreName`, but the UI-driven import can't.
- **What's explicitly unsupported**: Dell VxRail-managed clusters, vSphere Configuration Profiles, vCenter instances still running Enhanced Linked Mode (ELM must be broken first), clusters on baseline-based lifecycle management, and clusters with DRS set to manual or partially automated rather than fully automated.

Two prerequisites are easy to miss because they sit outside the wizard entirely: SSH has to be enabled on the existing vCenter appliance before you start, and every ESX host in scope needs to be using FQDNs in vSphere inventory rather than short names -- both are precheck failures if skipped.

## What Import Changes on Day One

The import workflow doesn't just register the vCenter -- it actively reconfigures the network layer underneath it. NSX gets activated on every Distributed Virtual Port Group in the imported cluster, which in turn activates the Distributed Firewall on those same DVPGs. The default DFW ruleset allows all Layer 2 and Layer 3 traffic, so nothing breaks immediately -- but existing workloads are now sitting behind a firewall layer that wasn't there an hour before, and someone now owns writing real rules for it. You can deactivate NSX on DVPGs afterward through the NSX UI or the Transport Node Collection API if that's not what you wanted on day one.

## The Forward-Only Upgrade Trap

This is the constraint that makes "just import it and sort out versions later" a bad plan. VCF enforces forward-only upgrade validation: you can only upgrade to a target version released after your current version's release date. When you import components, your workload domain's effective baseline becomes the *earliest* release date among everything you brought in. If the NSX instance you imported was released after a given VCF minor or maintenance version, that workload domain is permanently blocked from upgrading to that specific version -- not delayed, blocked. Checking the VMware Interoperability Matrix before importing, not after, is the difference between a clean path forward and a workload domain stuck a step behind the rest of the fleet.

## Choosing Between Them: A Checklist

- **No existing vSphere estate to bring in?** Greenfield -- there's nothing to import, and the wizard is simpler than staging a migration.
- **Existing production vCenter with workloads you can't re-platform?** Import -- greenfield would mean rebuilding and migrating, and import exists specifically to skip that.
- **Existing vCenter using ELM, VxRail, baselines, or manual DRS?** Remediate those first; none of them pass import prechecks as-is.
- **Mixed NSX versions across what you're importing?** Check the Interoperability Matrix against your target VCF version before you start -- not after the import completes.
- **Either way**: confirm SSH is enabled and every host is on FQDN before you open the wizard. Both are the most common precheck failures, and both take five minutes to fix in advance.

## What's Next

Next in this series: VI Workload Domains -- Shared vs Dedicated NSX.

## Further Reading (Official Broadcom Documentation)

- [Import an Existing vCenter to Create a Workload Domain](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/building-your-private-cloud-infrastructure/working-with-workload-domains/import-an-existing-vcenter-to-create-a-workload-domain.html)
- [Create a New Workload Domain](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/building-your-private-cloud-infrastructure/working-with-workload-domains/deploy-a-vi-workload-domain-using-the-sddc-manager-ui.html)
- [Create a Workload Domain by Using the VCF Operations API](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/building-your-private-cloud-infrastructure/working-with-workload-domains/create-a-workload-domain-by-using-the-vcf-operations-api.html)
- [VMware Interoperability Matrix](https://interopmatrix.broadcom.com/Upgrade?productId=912&isHidePatch=false&isHideLegacyReleases=false)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
