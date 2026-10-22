---
title: "Day-N Starts in VCF Operations: Verifying the Management Domain"
date: 2026-10-29
draft: true
tags: ["VCF", "VMware", "Lab", "VCF Operations", "Day-N", "Verification"]
categories: ["VCF 9", "Lab Series"]
labPart: 9
cover:
  image: "/images/covers/lab-verifying-management-domain.jpg"
  alt: "Day-N Starts in VCF Operations: Verifying the Management Domain"
  relative: false
description: "What to check in VCF Operations once a VCF 9.1.1 management domain bring-up completes: fleet component versions, domain health, depot and cluster status, capacity before the workload domain, and removing the installer."
---

## Overview

A completed bring-up is not a verified platform. The installer says the deployment succeeded, and the next hour decides whether the rest of the build starts on solid ground. In VCF 9.1 the place to check is VCF Operations, because Day-N actions run from VCF Operations and the VCF view in vCenter. The SDDC Manager UI is deprecated, although its API and Developer Center remain available.

This post is the verification checklist used after the management domain finished in this lab, in the order it was run.

## The verification path

1. **Fleet components and versions**: in VCF Operations, open Build, then Lifecycle, then VCF Management, and confirm every component is listed with its 9.1.1 version.
2. **The management domain**: open the m01 domain under VCF Instances and confirm SDDC Manager, NSX, vCenter and the ESX cluster are on target.
3. **Depot and appliance health**: check that the offline depot is connected and that the VCF Operations cluster is healthy, with the primary and replica nodes online and the cloud proxy healthy.
4. **Capacity before the next domain**: review the cluster in vCenter before planning the workload domain.
5. **Networking**: confirm the default transit gateway and its distributed connectivity.
6. **Housekeeping**: remove the installer and its temporary datastore.

![VCF Operations lifecycle page listing the fleet components and versions](/images/lab/lab-S104.jpg)
*Build, Lifecycle, VCF Management: every fleet component with its 9.1.1 version.*

![VCF Operations m01 domain component versions all on target](/images/lab/lab-S105.jpg)
*The m01 domain: SDDC Manager, NSX, vCenter and the ESX cluster on target.*

![VCF Operations administration showing the cluster online with primary and replica running](/images/lab/lab-S107.jpg)
*VCF Operations administration: cluster online, primary and replica running.*

![vSphere capacity and usage for the management cluster](/images/lab/lab-S109.jpg)
*Management cluster capacity before the workload domain: about 255 GB of 640 GB memory free.*

![vSphere client showing the default transit gateway with distributed connectivity](/images/lab/lab-S115.jpg)
*Networking: the default transit gateway with distributed connectivity.*

## What the fleet list shows

The VCF Management page lists the fleet components under the instance name: VCF Operations, the VCF services runtime, fleet lifecycle, the identity broker, the Salt services, the software depot, SDDC lifecycle and telemetry. All carry a 9.1.1 version string.

-> **Build numbers differ between components**: that is normal, because each component ships on its own build inside the same release.

-> **A banner about registration is expected in a lab**: VCF Operations showed a license registration banner because no licenses were applied to this lab. Treat it differently on a real platform.

## Capacity is the check people skip

This is the check that changes the next step. In this lab the management cluster had about 255 GB of memory free out of 640 GB when verification ran. The workload domain adds a vCenter and three Medium NSX Managers on the management domain, which together take about 93 GB.

That removes N+1 headroom on the management cluster. It does not stop the build, and in a lab the trade-off is acceptable. In a design it needs a decision before the workload domain is created, not after.

## Remove the installer

The installer sits outside the management domain, on a temporary datastore on one of the workload hosts. Once the domain is verified:

1. Destroy the installer VM.
2. Unmount the temporary datastore.
3. Relabel the NVMe disk with a GPT label so it is eligible for vSAN.

```bash
partedUtil mklabel /vmfs/devices/disks/<disk-id> gpt
```

Do this before commissioning the workload hosts, so those hosts start clean.

## What to take from it

-> **Verify from VCF Operations, not from memory**: the fleet page is the source of truth for what was actually deployed.

-> **Look at capacity before creating the next domain**: the workload domain management components land on the management cluster.

-> **Clean up the installer on purpose**: a forgotten installer VM and a leftover datastore are the kind of detail that surprises you in the next phase.

-> **Record the versions**: the build numbers on this page are what later upgrade and support conversations start from.

## What's Next

Next in this series: host commissioning in 9.1.1, network pools and the API path for nested labs.

## Further Reading (Official Broadcom Documentation)

- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
