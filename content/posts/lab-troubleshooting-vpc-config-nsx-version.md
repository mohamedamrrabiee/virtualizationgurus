---
title: "Troubleshooting Bring-up 2: VPC Config Type and the NSX Version"
date: 2026-10-27
draft: true
tags: ["VCF", "VMware", "Lab", "Troubleshooting", "VCF Installer", "SDDC Manager"]
categories: ["VCF 9", "Lab Series"]
labPart: 7
cover:
  image: "/images/covers/lab-troubleshooting-vpc-config-nsx-version.jpg"
  alt: "Troubleshooting Bring-up 2: VPC Config Type and the NSX Version"
  relative: false
description: "Two critical failures in the Configure vSphere cluster stage of a VCF 9.1.1 bring-up: a VPC network configuration type rejected by SDDC Manager, and a null NSX version, with the installer API retry and the workflow vault edit that fixed them."
---

## Overview

The Configure vSphere cluster stage is the longest in a bring-up, and in this lab it is where the second and third critical failures appeared. Both were data problems in the deployment spec, not infrastructure problems: a field that should not have been there, and a field that was missing.

This post covers both, the retry method that fixed the first, and the workflow vault edit that fixed the second. Those methods change the state of a running deployment, so the caution at the end matters as much as the fix.

## Failure 1: the VPC network configuration type is not allowed

-> **Where**: bring-up, Configure vSphere cluster, Trigger SDDC Initialize workflow.

-> **The error**: `400 POST /v1/sddc/initialize: PUBLIC_DOMAINSPEC_VALIDATION_FAILED / VPC_NETWORK_CONFIG_TYPE_NOT_ALLOWED_FOR_NON_SHELL_DOMAIN`.

<!-- TODO screenshot after masking: S086 (Trigger SDDC Initialize workflow failed) -->

The spec the installer exported contained `nsxtSpec.vpcSpec.vpcNetworkConfigurationType=FULL_STACK_VPC`. The SDDC Manager API documentation describes that field as only applicable to shell domains, and this deployment was a management domain.

That the installer export is a defect in 9.1.1 is an inference. No Broadcom article was found for it.

### The fix: edit the spec and retry through the installer API

1. **Remove `vpcNetworkConfigurationType`** from the spec and keep the `dtgwSpec` block, because this lab uses distributed connectivity.
2. **Retry the existing deployment** through the installer API with `PATCH /v1/sddcs/<deployment-id>` and the corrected spec.

```bash
curl -sk -X PATCH "https://<installer>/v1/sddcs/<deployment-id>" \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d @spec-corrected.json
```

The call returned HTTP 200, the existing vCenter and SDDC Manager were kept, and the stage moved on. Broadcom documents this retry method in KB 424770. Use it with support guidance on anything that matters.

-> **Why the API and not the UI Retry**: the assumption was that the UI Retry resends the stored, uncorrected spec. That was not tested, so treat it as a reason for caution, not a finding.

## Failure 2: NSX version compliant with VCF is null

-> **Where**: bring-up, Configure vSphere cluster, Get NSX Version Compliant with VMware Cloud Foundation, after four retries.

-> **The error**: `FAILED_TO_GET_VCF_COMPLIANT_NSXT_VERSION`, with the SDDC Manager `domainmanager.log` showing `NSX version compliant with VCF: null`.

<!-- TODO screenshot after masking: S088 (Get NSX Version Compliant with VCF failed) -->

Two things were wrong at the same time:

-> **The spec had no NSX version**: for a management domain, decompiling the workflow class on SDDC Manager showed it reading the NSX product version from the domain spec. The spec had no `nsxtSpec.version`, so the value was null. The decompiled code is the source for that, not documentation.

-> **The bundles never reached the new SDDC Manager**: no depot was configured on it and every 9.1.1 bundle was in PENDING state. The installer had a depot configured. The new SDDC Manager did not.

### The fix

1. **Configure the same offline depot on SDDC Manager**, trust its certificate, and download the 9.1.1 bundles. Cancel the downloads you do not need.
2. **Snapshot SDDC Manager**, then enable HTTP access to the workflow vault.
3. **Export the workflow spec**, add `productVersion` to `nsxTConfigurationSpec`, `PUT` it back and retry from the UI.
4. **Add `nsxtSpec.version`** to the final spec so future runs do not need the patch.

The stage then passed. Whether the depot step was strictly needed is not proven, because both changes were made before the successful retry. In this lab the vault property sat in `application-prod.properties` and the `PUT` used `application/json`, which differs from the wording in the Broadcom article. Both worked.

## What to take from it

-> **Read the exported spec before the first bring-up**: both failures were visible in the spec file before anything was deployed.

-> **Configure the depot on SDDC Manager early** when the installer sits outside the domain. The bundles do not follow the installer.

-> **Retry through the installer API after a spec change**, so the corrected spec is the one that runs.

-> **Treat the workflow vault as a last resort**: snapshot SDDC Manager first, remove the HTTP access property afterwards, and expect support to ask what you changed.

-> **Do this on a production deployment only with a support case open.** These are lab recoveries, not procedures.

## What's Next

Next in this series: Troubleshooting bring-up 3, the two internal errors that came from the same missing version data.

## Further Reading (Official Broadcom Documentation)

- [Broadcom KB 424770](https://knowledge.broadcom.com/external/article/424770): the installer API retry method
- [Broadcom KB 314620](https://knowledge.broadcom.com/external/article/314620): the workflow vault method
- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
