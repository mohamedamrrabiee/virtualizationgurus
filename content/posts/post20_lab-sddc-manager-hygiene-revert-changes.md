---
title: "Lab Hygiene: Reverting Troubleshooting Changes on SDDC Manager"
slug: "lab-sddc-manager-hygiene-revert-changes"
date: 2026-11-28
draft: true
tags: ["VCF", "VMware", "Lab", "SDDC Manager", "Troubleshooting", "Operations"]
categories: ["VCF 9", "Lab Series"]
labPart: 20
cover:
  image: "/images/covers/lab-sddc-manager-hygiene-revert-changes.jpg"
  alt: "Lab Hygiene: Reverting Troubleshooting Changes on SDDC Manager"
  relative: false
description: "The workarounds applied on SDDC Manager during bring-up and host commissioning, how they were reverted with backups and checks, and why a lab should end with a clean configuration."
---

## Overview

Bring-up and host commissioning in this lab needed a few edits on SDDC Manager: a vault access switch to retry a workflow, and a vSAN disk claim property that was tried during commissioning. Once the domains were healthy, those edits had no reason to stay. This post covers the revert, the checks that prove it, and why it is worth doing even in a lab.

The whole clean-up took a few minutes, including a 90 second wait for the services to restart.

## What was changed, and why it goes

Two kinds of change were made on the SDDC Manager appliance as root:

| Change | File | Why it was made |
|---|---|---|
| `vcf.vault.http-access=true` | `domainmanager` application-prod.properties | To read and replace the workflow spec of a failed deployment, the method in Broadcom KB 314620 |
| `vsan.esa.sddc.managed.disk.claim=true` | `domainmanager` and `operationsmanager` application-prod.properties | The disk claim property tried during host commissioning, from Broadcom KB 408300. It made no difference for commissioning in 9.1.1 |

Alongside those, the workflow exports and depot JSON files used during the retries sat in the root home directory. They held passwords.

Three reasons to remove all of it:

-> **Unsupported changes accumulate**: a property that was only a workaround stays in effect after the problem is gone, and the next person to troubleshoot does not know it is there.

-> **HTTP access to the vault is a door**: it was enabled for a specific task and has no job afterwards.

-> **Password-bearing files**: workflow exports and spec files contain credentials in clear text, so they should not outlive the task.

## The revert

The same pattern for each file: look, back up, change, restart, verify.

```bash
# SDDC Manager, su - to root
grep -n -i -E "vsan.esa|vault" /etc/vmware/vcf/domainmanager/application-prod.properties /etc/vmware/vcf/operationsmanager/application-prod.properties
D=/etc/vmware/vcf/domainmanager/application-prod.properties
O=/etc/vmware/vcf/operationsmanager/application-prod.properties
cp -p $D $D.pre-revert-$(date +%F); cp -p $O $O.pre-revert-$(date +%F)
sed -i '/^vcf.vault.http-access=true$/d; /^vsan.esa.sddc.managed.disk.claim=true$/d' $D
sed -i '/^vsan.esa.sddc.managed.disk.claim=true$/d' $O
systemctl restart domainmanager operationsmanager
sleep 90; systemctl is-active domainmanager operationsmanager
grep -n -i -E "vsan.esa|vault" $D $O || echo "clean"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/domainmanager/internal/vault/test
```

Each line has a purpose:

-> **The first grep**: shows the lines that are about to be removed, so you remove only those.

-> **`cp -p` with a dated suffix**: a backup that keeps ownership and permissions, so a mistake is a copy away from being undone.

-> **Anchored `sed` patterns**: `^...$` matches the whole line, so nothing similar gets deleted by accident.

-> **Restart and wait**: the two services read the file at start. Giving them 90 seconds avoids checking too early.

-> **The checks**: a final grep that prints `clean`, both services reporting `active`, and a request to the vault test endpoint.

The output of the first grep, before the change, and of the checks after:

```
application-prod.properties:18:vcf.vault.http-access=true            (before)
application-prod.properties:19:vsan.esa.sddc.managed.disk.claim=true (before)
clean
active
active
400
```

The `400` is the observation that matters for the vault. With HTTP access enabled, the vault answered normally. After the revert the endpoint no longer served the request. Anything other than a normal success response is the expected result here, and in this lab it was a 400.

![SDDC Manager root shell with the revert commands and the final checks](/images/lab/lab-S218.jpg)
*The revert on SDDC Manager: the lines before, the backups, the sed commands, the restart, and the final checks: clean, active, active, 400.*

## Temporary files

Workflow exports, the depot JSON and similar working files held passwords, so they were overwritten and removed with `shred`. The exact commands were not kept, but the pattern is plain: list what was created in the root home directory during the troubleshooting, and remove each file deliberately.

```bash
ls -la /root
shred -u /root/<exported-file>.json
```

## What to take from it

-> **Write down every change as you make it**: a one-line note per property or file means the revert is a list, not a memory test.

-> **Back up with `cp -p` before every edit**: dated copies cost nothing.

-> **Revert in the same order and verify**: grep for the keys, check the services, test the endpoint.

-> **Remove files with passwords**: shred what was exported, and check the home directory afterwards.

-> **Do this before the lab becomes a template**: a clone or a snapshot of a lab with leftover workarounds carries them forward.

## What's Next

Next in this series: activating a Supervisor on VPC networking, with the design choices, the wizard and the first 50 minutes.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [Broadcom KB 314620: Retry SDDC Manager workflows by modifying workflow spec files](https://knowledge.broadcom.com/external/article/314620)
- [Broadcom KB 408300: vSAN ESA Deployment: Override HCL Validation for Non-Certified Hardware](https://knowledge.broadcom.com/external/article/408300)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
