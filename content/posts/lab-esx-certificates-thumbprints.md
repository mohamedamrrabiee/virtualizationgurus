---
title: "Preparing Nested ESX Hosts: Certificates and Thumbprints Done Right"
date: 2026-10-22
draft: true
tags: ["VCF", "VMware", "Lab", "ESX", "Certificates", "Troubleshooting"]
categories: ["VCF 9", "Lab Series"]
labPart: 2
cover:
  image: "/images/covers/lab-esx-certificates-thumbprints.jpg"
  alt: "Preparing Nested ESX Hosts: Certificates and Thumbprints Done Right"
  relative: false
description: "How ESX host certificates and SHA-256 thumbprints decide whether VCF Installer validation, vCenter deployment and host commissioning succeed, with two real failures from a VCF 9.1.1 lab and the order of operations that avoids both."
---

## Overview

The VCF Installer does not trust an ESX host because of its name. It trusts the certificate fingerprint you put in the deployment spec and then checks that the host still presents that certificate on port 443. If the two differ at any point, validation fails or, worse, a deployment fails halfway through.

Two of the most expensive problems in this lab were certificate problems. Both were avoidable. This post covers the host preparation order that avoids them, with the exact commands and what each failure looked like.

## The order that works

Do the certificate work once, early, and never again during bring-up.

1. **Set the host name correctly**: short name in the host field, DNS domain in the domain field.
2. **Regenerate the self-signed certificate** so the CN and SAN match the FQDN.
3. **Restart the management services** so port 443 serves the new certificate.
4. **Verify what port 443 actually presents**, then capture the SHA-256 thumbprint.
5. **Put that thumbprint in the spec**, and leave the hosts alone until bring-up finishes.

```bash
# On each ESX host (SSH)
esxcli system hostname get                 # Host Name must be the short name
esxcli system hostname set --host=vg1-m01-esx01 --domain=vgurus.lab
/sbin/generate-certificates
services.sh restart
```

```bash
# From the jump host: what port 443 serves, and its SHA-256 thumbprint
echo | openssl s_client -connect vg1-m01-esx01.vgurus.lab:443 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName -fingerprint -sha256
```

Check two things in that output. The subject and the SAN must both contain the FQDN exactly once, and the fingerprint must match the certificate on disk (`/etc/vmware/ssl/rui.crt`) on the host. If they differ, the host is still serving an old certificate.

## Failure 1: the host name that doubled the domain

During host commissioning for the workload domain, validation failed on the first host with a message that asked for "a valid certificate with a fully qualified domain name in its Common Name". DNS, credentials and connectivity were all fine.

-> **Cause**: the host name had been set to the full FQDN. `generate-certificates` appends the domain to the host name, so the CN and SAN became `vg1-w01-esx01.vgurus.lab.vgurus.lab`.

-> **Fix**: set the short name and the domain separately, regenerate, restart services, then verify the CN and SAN with `openssl` from SDDC Manager.

```bash
esxcli system hostname set --host=vg1-w01-esx01 --domain=vgurus.lab
/sbin/generate-certificates
services.sh restart
```

The error message never mentions a thumbprint or a doubled domain. The only way to see the problem is to read the certificate the host actually presents.

## Failure 2: the old certificate that kept being served

The first management domain bring-up failed at the Deploy vCenter step, in Datacenter Creation, after three automatic retries. The installer log held the real reason:

```
Failed to obtain vc thumbprint: HTTPSConnectionPool(host='vg1-m01-esx01.vgurus.lab', port=443): ...
(Caused by SSLError('Fingerprints did not match. Expected "<sha1-thumbprint>", got "<sha1-thumbprint>"'))
```

-> **What had happened**: the certificates were renewed a day earlier and only `hostd` and `vpxa` were restarted. In the lab, port 443 kept serving the old certificate, and the installer held the old fingerprint.

-> **A second trap**: running `generate-certificates` again later wrote new files to disk, but port 443 still served the old certificate until `services.sh restart` ran.

-> **Fix that worked**: `services.sh restart` on all four hosts, confirm that port 443 matched the certificate on disk, recapture the SHA-256 thumbprints into the spec, then deploy a fresh installer appliance and re-import the spec. Deploy vCenter then completed in about 18 minutes.

The lesson is simple to state. A certificate on disk is not a certificate in use. Always compare what port 443 serves against the file before you capture a thumbprint.

## A related trap: the locked root account

Validation attempts with a placeholder password in the spec locked the root account on the hosts, and every later validation then failed with "Cannot complete login due to an incorrect user name or password", even with the correct password.

```bash
faillock --user root --reset               # or wait 15 minutes
```

Put the real password in the spec before the first validation run, and validate once.

## Before you move on

-> **Host name**: short name and domain set separately on every host.

-> **Certificate**: CN and SAN contain the FQDN once.

-> **Port 443**: serves the same certificate as the file on disk.

-> **Thumbprint**: SHA-256 captured after the restart, and stored in the spec.

-> **NTP**: all hosts point at the lab router, service running and set to start with the host.

-> **Do not touch certificates again** until the fleet is deployed.

## What's Next

Next in this series: VCF Installer placement, the offline depot and a deployment spec built from the planning workbook.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 Planning and Preparation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/planning-and-preparation.html)
- [Broadcom KB 320280: Restarting the Management agents on an ESXi host](https://knowledge.broadcom.com/external/article/320280)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
