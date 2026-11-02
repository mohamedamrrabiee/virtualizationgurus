---
title: "VCF SSO Without Active Directory: Keycloak as an OIDC Provider"
date: 2026-11-02
draft: true
tags: ["VCF", "VMware", "Lab", "VCF SSO", "Keycloak", "OIDC", "Identity"]
categories: ["VCF 9", "Lab Series"]
labPart: 13
cover:
  image: "/images/covers/lab-vcf-sso-keycloak-oidc.jpg"
  alt: "VCF SSO Without Active Directory: Keycloak as an OIDC Provider"
  relative: false
description: "Setting up VCF SSO in instance mode with Keycloak as a generic OIDC provider in a lab with no Active Directory: the Keycloak objects, every wizard step, and the one failure that was a password that never applied."
---

## Overview

A nested lab usually has no Active Directory, but VCF SSO still needs an identity provider. This post uses Keycloak 26.3.0 as a generic OIDC provider for VCF SSO in instance mode, with the identity broker `vg1-m01-idb01`. The result is one sign-in that works on both vCenters and both NSX Managers.

The whole job took about one hour 35 minutes of wall clock, from the first wizard page at 16:45 to the vCenter linking group becoming Active at about 18:20. A large part of that was building the identity provider, because the wizard needs it before it can finish.

## The identity provider

Keycloak runs as a container on the jump host, with a certificate from a small lab CA. VCF SSO talks to it over HTTPS, so the certificate chain is part of the setup and not an afterthought.

| Item | Value |
|---|---|
| Keycloak | 26.3.0 in Docker on the jump host, HTTPS on 8443 |
| Certificate | Lab root CA, then a server certificate for the jump host name with a subject alternative name for the name and the IP |
| Realm | `vgurus` |
| Group | `vcf-admins` |
| User | `mrabiee`, member of `vcf-admins` |
| Client | `vcf`, OpenID Connect, confidential, standard flow only |
| Mapper `groups` | Group membership claim named `groups`, full path off |
| Mapper `domain` | Hardcoded claim `domain` with the value `vgurus.lab` |

The commands, trimmed to the parts that matter (secrets and passwords removed):

```bash
# Certificate: lab CA, then a server certificate with a SAN
openssl req -x509 -newkey rsa:4096 -sha256 -days 1095 -nodes -keyout ca.key -out ca.crt -subj "/CN=vgurus Lab Root CA"
openssl req -newkey rsa:2048 -nodes -keyout tls.key -out tls.csr -subj "/CN=jump.vgurus.lab"
printf "subjectAltName=DNS:jump.vgurus.lab,IP:10.20.10.20\nextendedKeyUsage=serverAuth\n" > san.ext
openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -days 825 -sha256 -extfile san.ext
cat tls.crt ca.crt > chain.pem

# Keycloak
docker run -d --name keycloak --restart unless-stopped -p 8443:8443 \
  -v ~/keycloak/certs:/opt/keycloak/conf/certs:ro -v ~/keycloak/data:/opt/keycloak/data \
  quay.io/keycloak/keycloak:26.3.0 start --hostname=https://jump.vgurus.lab:8443 \
  --https-certificate-file=/opt/keycloak/conf/certs/chain.pem \
  --https-certificate-key-file=/opt/keycloak/conf/certs/tls.key \
  --http-enabled=true --http-port=8080

# Realm, group, user and client with kcadm.sh
KC="docker exec keycloak /opt/keycloak/bin/kcadm.sh"
$KC create realms -s realm=vgurus -s enabled=true
$KC create groups -r vgurus -s name=vcf-admins
$KC create users -r vgurus -s username=mrabiee -s email=mrabiee@vgurus.lab -s enabled=true -s emailVerified=true
$KC create clients -r vgurus -s clientId=vcf -s protocol=openid-connect -s publicClient=false \
  -s standardFlowEnabled=true -s directAccessGrantsEnabled=false
```

Before touching VCF, confirm the provider answers from the machine that will use it:

```bash
curl -s --cacert ~/keycloak/certs/ca.crt https://jump.vgurus.lab:8443/realms/vgurus/.well-known/openid-configuration | head -c 100
```

The discovery document returned the issuer `https://jump.vgurus.lab:8443/realms/vgurus`. That issuer value is exactly what the wizard asks for later.

<!-- TODO screenshot after masking: S193 (Keycloak container start log) -->

## The VCF SSO wizard

The Configure VCF SSO flow runs from VCF Operations. In this lab the steps and values were:

| Step | Setting used |
|---|---|
| Deployment mode | Instance (recommended), identity broker `vg1-m01-idb01` |
| Provider type | Generic OIDC |
| Identity provider configuration | Client `vcf`, the client secret, the OpenID discovery address, and the CA chain file |
| Provisioning method | JIT, unique identifier `sub` |
| Group provisioning | Groups Pre-provisioning |
| Domain details | `vgurus.lab` |
| Pre-provisioned groups | `vcf-admins` |
| Attribute mapping | Group attribute `groups` |
| Review | Directory and authentication information, secret masked |
| Test Login | Six checks: discovery, authorization, callback, ID token, token exchange, validation |
| Assign VCF roles | Group `vcf-admins`, scope components with the identity broker, role VCF Administrator, never expires |
| Enable SSO | vCenter and NSX components, all four Configured |

<!-- TODO screenshots after masking: S189 (deployment mode), S195 (JIT, unique identifier sub), S196 (Groups Pre-provisioning warning), S200 (attribute mapping with groups), S159 (Test Login, six checks), S205 (role assignment), S161 (four components Configured) -->

Three details are worth knowing before you click Next:

-> **The redirect URI comes from the wizard**: I created the Keycloak client with a wildcard redirect for the broker host first, then replaced it with the exact URI the wizard showed, which ends in `/federation/t/CUSTOMER/auth/response/oauth2`. A wildcard is fine for a first pass, but the exact value is what you keep.

-> **Group provisioning cannot be changed later**: the wizard warns that Groups Pre-provisioning is permanent for this configuration. Choose it deliberately, because changing it later means resetting the identity provider.

-> **The group claim has to match the mapper**: the attribute mapping step reads the group attribute `groups`, which is the claim name the Keycloak group membership mapper writes. With the field empty, the group is not recognized.

## The one failure: ISS-028

At 18:07 the Keycloak sign-in page returned "Invalid username or password" for the SSO user. The cause was not VCF and not the client configuration: the first `kcadm set-password` command had not applied, and I had not checked its output.

The fix was three steps: run the `set-password` command again, sign in to Keycloak directly with the user, and only then run Test Login again. All six checks passed at 18:08.

<!-- TODO screenshot after masking and cropping: S203 (Keycloak sign-in error). The realm title shows in large letters, crop it before use. -->

## What the result looks like

After the wizard finished, signing in on the w01 vCenter and the w01 NSX Manager worked as the SSO user, and VCF Operations accepted it too. VCF SSO pushed the VCF Administrator role down to vCenter and NSX, so no manual permissions were needed on either. It also connected all four components while vCenter was still on its evaluation license, so there was no license block.

<!-- TODO screenshots after masking: S206 (w01 vCenter signed in as the SSO user), S164 (w01 NSX Manager signed in as the SSO user) -->

## What to take from it

-> **Build the identity provider first**: the wizard cannot finish without a working discovery address, a client secret and a trusted certificate chain.

-> **Test the user directly before Test Login**: signing in to Keycloak with the user takes seconds and separates a user problem from a VCF problem.

-> **Check the output of every admin command**: ISS-028 was a command that returned without applying and without an obvious error.

-> **This is a lab identity provider**: Keycloak runs with its default development database and a self-signed CA on a single host, which is fine for a lab and fragile for anything else. A real deployment uses an enterprise identity provider with a certificate from a trusted CA.

## What's Next

Next in this series: one vSphere Client for two domains, using vCenter linking in VCF Operations.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [Keycloak documentation](https://www.keycloak.org/documentation)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
