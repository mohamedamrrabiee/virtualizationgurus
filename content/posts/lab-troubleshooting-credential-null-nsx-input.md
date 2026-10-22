---
title: "Troubleshooting Bring-up 3: Credential Null and NSX Input Data"
date: 2026-10-28
draft: true
tags: ["VCF", "VMware", "Lab", "Troubleshooting", "SDDC Manager", "NSX"]
categories: ["VCF 9", "Lab Series"]
labPart: 8
cover:
  image: "/images/covers/lab-troubleshooting-credential-null-nsx-input.jpg"
  alt: "Troubleshooting Bring-up 3: Credential Null and NSX Input Data"
  relative: false
description: "The last two critical failures of a VCF 9.1.1 management domain bring-up: a credential null error on the PSC record and a null NSX version at Generate NSX Input Data, both caused by missing version data, with the logs and fixes."
---

## Overview

The previous post fixed a spec problem and a missing NSX version. The next two failures looked like new problems, with new error codes and new stages. They were not. Both came from the same thing: a version value that was empty where SDDC Manager expected a string.

This is the last of the three troubleshooting posts. After these two fixes the management domain deployment ran to completion.

## Failure 1: credential null for the PSC

-> **Where**: bring-up, Configure vSphere cluster, Generate VCF Domain Runtime Data Model, at step 55 of 135.

-> **The error**: `FAILED_TO_GENERATE_ADD_VI_INTERNAL_MODEL` with `Error while retrieving credential null for device <psc-id>`, under the support code `LOQSE1`.

<!-- TODO screenshot after masking: S093 (Generate VCF Domain Runtime Data Model failed) -->

The message points at a credential, and the credential was fine. The Common Services log (`vcf-commonsvcs.log`) held the real error: `VMwareProductVersion can not be null or empty`.

The reading of the logs is this. The retry had created the PSC inventory record for the vCenter without a version. When Common Services returns PSC credentials it runs a version check, and that check throws on an empty value. The credentials were stored correctly. That sequence is an inference from the stack trace. No Broadcom article was found for it.

### The fix

1. **Snapshot SDDC Manager.**
2. **Back up** the credential, vCenter and PSC tables with `pg_dump`.
3. **Set the missing version** on the PSC record to the vCenter build, which came from `vpxd -v`.
4. **Retry from the UI.**

Configure vSphere cluster then completed all 135 steps.

-> **What was ruled out**: all services were ACTIVE, and restarting them, as the error text suggests, was not the fix.

-> **No credential was changed**: the credential data was never the problem.

## Failure 2: Generate NSX Input Data, version is null

-> **Where**: bring-up, Deploy and configure NSX, at step 3 of 103.

-> **The error**: `VCF_ERROR_INTERNAL_SERVER_ERROR` in `PrepareNsxtInputAction`, under the support code `P2KLT7`, with the cause line `Cannot invoke "String.split(String)" because "version" is null`.

<!-- TODO screenshot after masking: S094 (Deploy and configure NSX stopped at 3/103) -->

The earlier NSX version patch had covered two copies of the spec in the workflow vault and missed a third, where `productVersion` was absent altogether. The vCenter `productVersion` was also null in every copy.

### The fix

1. **Export the vault again** and keep a backup copy.
2. **Add `productVersion`** to every NSX configuration block that lacked it, and set the vCenter `productVersion` in every spec copy. A short script did this so no copy was missed.
3. **`PUT` the result back** and retry from the UI.

NSX then moved from 3 of 103 steps to 16 and completed in about 53 minutes.

-> **The lesson from the first patch**: patching one copy of a spec is not patching the spec. The workflow vault held several copies, and the step that failed read a different one.

## What to take from it

-> **A null in a log is a field name in a spec**: find which field the failing step reads, then check every copy of it.

-> **Take the snapshot and the database dump before any change**, and write down exactly what was changed. Direct database edits on SDDC Manager are not something to do on a production system without a support case.

-> **The support code names the step, not the cause**: `LOQSE1` and `P2KLT7` identified where it failed. The cause was in the service logs.

-> **Fix the spec once the platform is up**, so the next deployment from the same file does not need any of this.

## What's Next

Next in this series: Day-N starts in VCF Operations, verifying the management domain.

## Further Reading (Official Broadcom Documentation)

- [Broadcom KB 314620](https://knowledge.broadcom.com/external/article/314620): the workflow vault method
- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
