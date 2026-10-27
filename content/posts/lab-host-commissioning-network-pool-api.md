---
title: "Host Commissioning in 9.1.1: Network Pools and the API Path for Nested Labs"
date: 2026-10-30
draft: true
tags: ["VCF", "VMware", "Lab", "SDDC Manager", "Host Commissioning", "vSAN ESA"]
categories: ["VCF 9", "Lab Series"]
labPart: 10
cover:
  image: "/images/covers/lab-host-commissioning-network-pool-api.jpg"
  alt: "Host Commissioning in 9.1.1: Network Pools and the API Path for Nested Labs"
  relative: false
description: "Preparing three nested ESX hosts for a VCF 9.1.1 workload domain: the network pool, the certificate name problem that blocks validation, and commissioning through the SDDC Manager API when the vSAN ESA HCL check rejects virtual NVMe disks."
---

## Overview

The management domain is verified and the installer is gone. Before a workload domain can be created, its hosts have to be commissioned into SDDC Manager. In this lab that took three steps and two critical issues: a network pool, a certificate that did not match the host name, and a vSAN HCL check that the UI offers no way to bypass.

In VCF 9.1 the work starts in VCF Operations and the VCF view in vCenter. The SDDC Manager UI is deprecated, but its API and Developer Center remain available, and the last step of this post uses them.

## Step 1: the network pool

The pool defines the vMotion and vSAN networks the new hosts will use. It is created in vSphere under Hosts, then Network Pools.

| Network | VLAN | Subnet | IP range | MTU |
|---|---|---|---|---|
| vMotion | 3326 | 10.20.22.0/24 | 10.20.22.11 to .20 | 9000 |
| vSAN | 3327 | 10.20.23.0/24 | 10.20.23.11 to .20 | 9000 |

-> **Press ADD for each range before saving**: a range typed into the field but not added is not saved.

-> **Values are locked once the pool is saved**: check that the vMotion and vSAN VLANs and subnets are not swapped before you save. A mistake means a new pool.

<!-- TODO screenshot after masking: S117 (Create Network Pool) -->

## Step 2: the host certificate name (CI-07)

Validation of the first host failed with a generic message: "Failed to connect to the host. Ensure that the host is reachable, it has a valid certificate with a fully qualified domain name in its Common Name, and credentials are valid." No fingerprint was shown.

DNS, `hostd`, `envoy` and the credentials were all fine. The certificate was the problem.

-> **Root cause**: the host name had been set to the full FQDN. When the certificate was generated, the domain was appended again, so the Common Name and SAN read `vg1-w01-esx01.vgurus.lab.vgurus.lab`.

-> **The fix**: set the short name and the domain separately, regenerate the certificate, restart the services, and check the name from SDDC Manager.

```bash
# On vg1-w01-esx01
esxcli system hostname set --host=vg1-w01-esx01 --domain=vgurus.lab
/sbin/generate-certificates
services.sh restart

# From SDDC Manager
echo | openssl s_client -connect vg1-w01-esx01.vgurus.lab:443 2>/dev/null | openssl x509 -noout -subject
```

The certificates post in this series covers the same rule from the other direction: the short name and the domain belong in separate fields.

## Step 3: the Commission Hosts wizard and the vSAN HCL check (CI-08)

The Commission Hosts wizard starts with a checklist to accept. Then you add the hosts with storage type vSAN ESA and the w01 network pool.

<!-- TODO screenshot after masking: S122 (Commission Hosts checklist) -->

Validation then failed on all three hosts:

-> **The error**: "Failed to validate vSAN HCL status", with `HOST_VSAN_HCL_VALIDATION_FAILURE` in the SDDC Manager log.

-> **The cause**: the virtual NVMe disks are not on the vSAN ESA HCL. The HCL database itself was current. The SDDC Manager log shows the HCL check for the NVMe device failing with a yellow status.

The same cause stopped the vSAN configuration during the installer run. There the Storage step had a switch for it. The Commission Hosts wizard in 9.1.1 has no such field.

### What did not work

-> **The disk claim property from the Broadcom override article**: adding `vsan.esa.sddc.managed.disk.claim=true` to the `domainmanager` and `operationsmanager` properties, with the related feature flag, changed nothing for host commissioning in 9.1.1. That article is about the installer path, and in this lab it did not carry over. This is an observation from this lab, not a statement about every build.

### What did work: commission through the API

The SDDC Manager API accepts a flag on the host specification that skips the vSAN ESA HCL check: `skipHclCompatibilityPrecheck`. The API reference describes it as bypassing the HCL validation during host commissioning. It is available from the Developer Center in the SDDC Manager UI.

```
GET   /v1/network-pools          # find the id of the w01 pool
POST  /v1/hosts                  # all three hosts, storageType VSAN_ESA,
                                 # networkPoolId <id>, skipHclCompatibilityPrecheck: true
GET   /v1/tasks/<task-id>        # watch the task
```

<!-- TODO screenshot after masking: S128 (Developer Center, POST /v1/hosts, task queued) -->

The task completed and VCF Operations showed the commissioning task as Successful. The three hosts then appeared as unassigned, ready for the workload domain.

## What to take from it

-> **Production hosts do not need any of this**: the HCL check exists to protect you. With vSAN ESA ReadyNodes and certified disks, commissioning from the wizard works. The API flag is for non-certified hardware, and the API documentation itself recommends certified disks.

-> **Check the network pool twice**: it cannot be edited after it is saved.

-> **Read the certificate before you read the logs**: a validation failure that names the host name and the certificate is usually the certificate.

-> **The wizard is not the whole product**: when the UI has no field for something, the API often does.

## What's Next

Next in this series: creating the workload domain from VCF Operations.

## Further Reading (Official Broadcom Documentation)

- [Broadcom KB 408300: vSAN ESA Deployment: Override HCL Validation for Non-Certified Hardware](https://knowledge.broadcom.com/external/article/408300)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
