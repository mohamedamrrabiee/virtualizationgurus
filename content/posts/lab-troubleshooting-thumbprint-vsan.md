---
title: "Troubleshooting Bring-up 1: Thumbprint Mismatch and vSAN ESA Disk Eligibility"
date: 2026-10-26
draft: true
tags: ["VCF", "VMware", "Lab", "Troubleshooting", "vSAN ESA", "VCF Installer"]
categories: ["VCF 9", "Lab Series"]
description: "The first bring-up failure in a VCF 9.1.1 lab: a host thumbprint mismatch at Deploy vCenter, and the vSAN ESA disk eligibility failure that followed when the bootstrap vSAN was torn down, with the cleanup that fixed both."
---

## Overview

The first bring-up attempt failed at Deploy vCenter. The fix for the root cause is covered in the certificates post. This post covers what the failure left behind, because the cleanup caused a second, different failure that looks unrelated: vSAN ESA disk eligibility.

Both failures came from the same event, and both are easy to misread. This is the diagnostic path from the symptom in the installer to the fix on the host.

## Failure 1: Deploy vCenter fails at Datacenter Creation

-> **Where**: bring-up, Deploy vCenter, step Datacenter Creation, after three automatic retries.

-> **What it left behind**: the first management host (`vg1-m01-esx01`) held the vCenter VM and a one-node vSAN cluster.

-> **The error**: the installer log shows `Failed to obtain vc thumbprint` with `Fingerprints did not match`, the expected and received SHA-1 values differing.

<!-- TODO screenshot after masking: S032 (Deploy vCenter Appliance failed after automatic retries) -->

The cause was a certificate renewed the day before with only `hostd` and `vpxa` restarted. In this lab, port 443 kept serving the old certificate, and the installer held the old thumbprint. The certificates post has the commands.

## Failure 2: vSAN ESA disk eligibility, after the cleanup

To retry, the bootstrap vSAN on `vg1-m01-esx01` was torn down. The next validation then failed:

-> **The error**: `VSAN_ESA_DISK_AVAILABILITY_VALIDATION.error`, "vSAN ESA Disks Availability Validation Failed".

-> **What the installer's disk query returned**: `vmodl.fault.SystemError`.

-> **What the host said**: `vdq -qH` showed the disks as eligible. The disks were fine. The service answering the query was not.

<!-- TODO screenshots after masking: S055 (vSAN ESA Disks Eligibility failed on esx01), S056 (vdq -qH during the disk cleanup) -->

The cause was `vsanmgmtd` on that host being in a bad state after the teardown. The link between the teardown and the bad state is an inference from the logs, not something Broadcom documents. A Broadcom KB on vSAN disk availability validation was checked and was not the cause here.

## The cleanup that fixed it

1. **Remove the vCenter VM** from `vg1-m01-esx01`.
2. **Leave the vSAN cluster** and relabel both capacity disks.
3. **Restart the management services** on all four hosts and confirm that port 443 serves the certificate on disk.
4. **Recapture the SHA-256 thumbprints** into the spec.
5. **Restart `vsanmgmtd`** on the first host, then check that `vdq -qH` reports the disks as eligible.
6. **Deploy a fresh installer appliance** and re-import the spec.

```bash
services.sh restart
esxcli vsan cluster leave
partedUtil mklabel /vmfs/devices/disks/<disk-id> gpt     # each capacity disk
/etc/init.d/vsanmgmtd restart
vdq -qH
```

Deploy vCenter then completed in about 18 minutes.

-> **A fresh installer, not a retry**: the installer held old state, so a new appliance with the corrected spec was cleaner than retrying the failed deployment.

-> **`services.sh restart` does not reset `vsanmgmtd`**: that needed its own restart.

-> **The HCL switches reset again**: on the new installer, the two HCL options in the Storage step had to be set again.

## What to take from it

-> **Read the installer log, not just the task list**: the task list said Datacenter Creation failed. The log said why.

-> **Check the service, not just the disk**: if `vdq -qH` says the disks are eligible and the installer disagrees, suspect the service that reports them.

-> **After a vSAN teardown, restart `vsanmgmtd`**.

-> **Avoid the whole class of problem**: finalize certificates, restart all services, and capture thumbprints once, before the installer is deployed.

## What's Next

Next in this series: Troubleshooting bring-up 2, the VPC config type and the NSX version.

## Further Reading (Official Broadcom Documentation)

- [Broadcom KB 320280: Restarting the Management agents on an ESXi host](https://knowledge.broadcom.com/external/article/320280)
- [Broadcom KB 443077: vsanmgmtd and host SSL certificate files](https://knowledge.broadcom.com/external/article/443077)
- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
