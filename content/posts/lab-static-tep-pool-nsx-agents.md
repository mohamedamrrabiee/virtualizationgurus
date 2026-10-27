---
title: "After the Wizard: Static Host TEP Pool, NSX Agents and a Datacenter Rename"
date: 2026-11-01
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "Host TEP", "Troubleshooting"]
categories: ["VCF 9", "Lab Series"]
labPart: 12
cover:
  image: "/images/covers/lab-static-tep-pool-nsx-agents.jpg"
  alt: "After the Wizard: Static Host TEP Pool, NSX Agents and a Datacenter Rename"
  relative: false
description: "Fixing workload domain hosts that show Down in NSX because the TEP VLAN has no DHCP: a static IP pool in the transport node profile, the NSX agent restart that cleared the stale status, and renaming the default datacenter."
---

## Overview

The workload domain deployment succeeded, but the three w01 hosts showed Down in NSX, each with two alarms. Nothing was wrong with the deployment. The wizard had configured the host TEPs for DHCP, and the TEP VLAN has no DHCP server.

This post covers the fix, a second step that was needed even after the fix looked complete, and the small datacenter rename that finishes the post-deployment cleanup.

## The symptom

-> **In NSX Manager**: all three hosts Down, two alarms per host.

-> **On the host**: `esxcli network ip interface ipv4 get` showed the TEP interfaces (`vmk10`, `vmk11`) on 169.254.x.x addresses with DHCP as the type and gateway 0.0.0.0. The self-assigned address is what a DHCP client uses when nothing answers.

<!-- TODO screenshots after masking: S216 (NSX hosts still Down), S217 (host agent status, NSX_VDL2 Down) -->

The cause is on the wizard side: the default distributed switch profile offers only DHCP for host TEPs, and the lab router has no DHCP scope on VLAN 3328. The addressing in this lab is below.

| VLAN | Purpose | Subnet | Pool |
|---|---|---|---|
| 3325 | m01 host TEP | 10.20.14.0/24 | pool in the installer spec |
| 3328 | w01 host TEP | 10.20.24.0/24 | 10.20.24.11 to .30, gateway .1 |
| 3329 | w01 Edge TEP (later) | 10.20.25.0/24 | 10.20.25.11 to .20, gateway .1 |

## Fix 1: a static IP pool

1. In the w01 NSX Manager, open Networking, then IP Address Pools, and add a pool `vg1-w01-cl01-tep01` with the range 10.20.24.11 to .30, CIDR 10.20.24.0/24 and gateway .1.
2. Under System, Fabric, Hosts, open the transport node profile and edit the host switch. Change the IPv4 assignment from DHCP to Use IP Pool and select the pool.

<!-- TODO screenshots after masking: S165 (pool created), S210 (subnet range), S214 and S215 (IPv4 assignment, Use IP Pool selected) -->

The hosts picked up static TEP addresses straight away. Three checks confirmed the data plane:

```bash
esxcli network ip interface ipv4 get | grep vmk1          # 10.20.24.x, STATIC
vmkping ++netstack=vxlan -I vmk10 -d -s 8972 -c 3 10.20.24.1
net-vdl2 -l                                                # VTEPs UP, control plane in sync
```

The 8972-byte ping to the gateway and to another host TEP had no loss, so jumbo frames pass on the TEP network, and `net-vdl2` showed the VTEPs up with the control plane in sync.

## Fix 2: restart the NSX agents

The hosts still showed Down. The pool had been applied and the data plane was healthy, but the host agent status said NSX_VDL2 Down. The status was stale.

```bash
/etc/init.d/nsx-opsagent restart && /etc/init.d/nsx-proxy restart     # on all three hosts
```

After the restart all three hosts showed Up with no alarms.

<!-- TODO screenshot after masking: S167 (all three hosts Up) -->

-> **The agent restart as the fix is from this lab only**: it is not from a Broadcom document. Treat it as something to try when the data plane checks pass and the status does not follow.

-> **Check the data plane first**: if `vmkping` and `net-vdl2` are healthy, the restart is low risk. If they are not, restarting agents hides the real problem.

## Rename the default datacenter

The workload domain wizard created the datacenter as `w01-DC`. It was renamed to `vg1-w01-dc01` in vCenter so it follows the naming pattern, and VCF Operations picked up the new name in its inventory.

-> **Rename the datacenter, nothing else**: do not rename the distributed switch or its port groups. VCF tracks those, and a rename there is not a supported edit.

-> **Follow the Broadcom article**: it lists which VCF objects can be renamed and how.

<!-- TODO screenshot after masking: S208 (VCF Operations inventory with the renamed datacenter) -->

## What to take from it

-> **Plan TEP addressing before the wizard**: if the VLAN has no DHCP, you will do this fix. A static pool can also be chosen later in the transport node profile.

-> **Verify the data plane, then the status**: `vmkping` with the vxlan netstack and `net-vdl2 -l` tell you whether the network works, regardless of what NSX shows.

-> **Know the stale-status case**: after changing the TEP assignment, the hosts can stay Down until the NSX agents are restarted.

-> **Finish the naming work early**: the datacenter name is one command away right after deployment and harder to explain later.

## What's Next

Next in this series: VCF SSO without Active Directory, using Keycloak as an OIDC provider.

## Further Reading (Official Broadcom Documentation)

- [Broadcom KB 316012: Renaming VCF SDDC manager objects](https://knowledge.broadcom.com/external/article/316012)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
