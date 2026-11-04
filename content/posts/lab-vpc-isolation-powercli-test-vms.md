---
title: "Proving VPC Isolation with PowerCLI Test VMs and a Ping Matrix"
date: 2026-11-08
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "VPC", "PowerCLI", "Testing"]
categories: ["VCF 9", "Lab Series"]
labPart: 19
cover:
  image: "/images/covers/lab-vpc-isolation-powercli-test-vms.jpg"
  alt: "Proving VPC Isolation with PowerCLI Test VMs and a Ping Matrix"
  relative: false
description: "Five Photon OS test VMs, deployed with PowerCLI, and a ping matrix that proves which paths should work and which should fail across two VPCs, the management network and the lab router."
---

## Overview

Two VPCs and three subnets exist, but nothing has proved that they behave the way the design says. This post adds five small test VMs and a ping matrix, run from inside each VM, so every path is checked against an expected result: reachable where it should be, and unreachable where isolation is the point.

In this lab 25 of 25 tested paths matched the expectation. The interesting part is the expectation itself, because several of the failures are the correct outcome.

## The test VMs

Five Photon OS 5 VMs, one vCPU and 1 GB each, in a Test VMs folder in each datacenter. One sits on the management domain management network, and four sit in the workload domain.

| VM | Network | Address |
|---|---|---|
| `vg1-m01-test01` | Management domain management port group, VLAN 3321 | 10.20.10.71, static |
| `vg1-w01-test01` | Workload domain management port group, VLAN 3321 | 10.20.10.72, static |
| `vg1-w01-app-priv01` | `app-private` in `vpc-app01` | 172.20.1.3, DHCP |
| `vg1-w01-app-pub01` | `app-public` in `vpc-app01` | 10.80.0.19, DHCP |
| `vg1-w01-dev-priv01` | `dev-private` in `vpc-dev01` | 172.20.17.3, DHCP |

The two VLAN VMs get static addresses because the management network has no DHCP. The three VPC VMs take their address from the NSX DHCP server of their subnet, which is also a useful check of the previous post: the address, gateway and DNS server all arrived correctly on every one of them.

![Workload domain management port group with two VMs](/images/lab/lab-S246.jpg)
*The workload domain management port group on VLAN 3321 with the two VLAN test VMs attached. The failed vLCM task in Recent Tasks is a patch definition download and is unrelated to the test VMs.*

## Deploying with PowerCLI

The VMs are imported from the Photon OS 5 OVA by a small PowerShell script using `VCF.PowerCLI`, which installs from the PowerShell Gallery like any module.

```bash
sudo snap install powershell --classic
pwsh -c "Install-Module VCF.PowerCLI -Scope CurrentUser -Force -AllowClobber"
pwsh -c "Import-Module VCF.PowerCLI; ./Deploy-TestVMs.ps1"
```

The script creates the Test VMs folder, imports the OVA to a host, connects the network adapter and sets the guest configuration. Three things needed a fix on the way:

-> **The OVA signature**: `Import-VApp` stopped with "The certificate used to sign the OVF package is not valid". The signing certificate of the Photon OVA was no longer valid, and `-Force` on `Import-VApp` is what let the import continue.

-> **Network adapter parameters**: `Set-NetworkAdapter` refused `-Portgroup` and `-StartConnected` in one call, because they belong to different parameter sets. Two separate calls solved it.

-> **Static addresses**: the cloud-init data applied the hostname and password but not the static network. The DHCP VMs worked from Photon's default configuration. The workload domain VLAN VM got its static network file through `Invoke-VMScript`, which runs inside the guest through VMware Tools and needs no network. The management domain VM was configured from its console, since there was no clipboard and no network path yet.

![Test VM console showing only an IPv6 link-local address](/images/lab/lab-S247.jpg)
*The management domain test VM console: only an IPv6 link-local address, and the temporary IPv4 address being set.*

![Test VM console after the address and sshd restart](/images/lab/lab-S248.jpg)
*10.20.10.71 set on `eth0` with a default route, and sshd restarted so SSH works from the jump host.*

Two details make it stick:

-> **Persist the address**: after a reboot the VM lost its IPv4 address, because the cloud-init network file (`10-cloud-init-nics.network`, which matches every `e*` interface with DHCP) sorts before `10-static-eth0.network`. Naming the static file `05-static-eth0.network` and disabling cloud-init networking with `network: {config: disabled}` in `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` fixed it.

-> **Open ICMP everywhere first**: Photon's firewall allows only SSH inbound. Open ICMP on every VM before the first test, not one VM at a time. The first run opened it in sequence, so early pings to later VMs failed for no real reason.

## The ping matrix

`Test-Matrix.ps1` connects to the workload vCenter, runs a ping probe inside each workload VM with `Invoke-VMScript`, and compares each result with a table of expected results. Every row prints the source, the target, the expectation, the actual result and a reason, so a mismatch is obvious.

```bash
pwsh -c "Import-Module VCF.PowerCLI; ./Test-Matrix.ps1"
```

The probe is small enough to read in full:

```bash
echo "SELF $(ip -4 -o addr show eth0 | awk '{print $4}')"
for t in 10.20.10.1 10.20.10.71 10.20.10.72 10.80.0.19 172.20.1.3 172.20.17.3; do
  if ping -c2 -W1 $t >/dev/null 2>&1; then echo "$t PASS"; else echo "$t FAIL"; fi
done
```

The result, from each source to each target. FAIL is the expected result in every FAIL cell.

| From \ To | Router 10.20.10.1 | m01-test 10.20.10.71 | w01-test 10.20.10.72 | app-pub 10.80.0.19 | app-priv 172.20.1.3 | dev-priv 172.20.17.3 |
|---|---|---|---|---|---|---|
| `vg1-m01-test01` | PASS | self | PASS | PASS (BGP) | FAIL (private) | FAIL (private) |
| `vg1-w01-test01` | PASS | PASS | self | PASS (BGP) | FAIL (private) | FAIL (private) |
| `app-priv01` | PASS (SNAT) | PASS | PASS | PASS (same VPC) | self | FAIL (isolated) |
| `app-pub01` | PASS (no NAT) | PASS | PASS | self | PASS (same VPC) | FAIL (isolated) |
| `dev-priv01` | PASS (SNAT) | PASS | PASS | PASS (via transit gateway) | FAIL (isolated) | self |

What each pattern proves:

-> **Management to public subnet works**: 10.80.0.19 is reachable from the management network, which proves the whole chain: router, BGP, Tier-0, transit gateway and the public subnet of the VPC.

-> **Management to private subnets fails**: 172.20.1.3 and 172.20.17.3 are private VPC ranges that were never advertised, which is the point of the previous posts.

-> **Private to outside works**: outbound traffic leaves through the VPC SNAT address and returns normally.

-> **VPC to VPC, private to private fails**: `app-priv01` cannot reach `dev-priv01`, and the reverse, because their private ranges are local to their VPCs.

-> **Dev to app public works**: `dev-priv01` reaches `app-pub01` through the transit gateway, using the dev VPC SNAT address as its source. That path is what the Distributed Firewall blocks later in this series.

The SNAT source address itself was not captured on the router. The routes the router learned, the `/32` SNAT addresses and the public `/28`, are consistent with it.

## What to take from it

-> **Write the expectation first**: a ping matrix is only useful when the expected result is decided in advance, including the FAIL cells.

-> **Test from inside the VMs**: `Invoke-VMScript` through VMware Tools needs no network path to the VM, which makes it usable even when the network is what you are testing.

-> **Open ICMP before any test**: otherwise the first run punishes the VMs you configured last.

-> **Keep the script**: the same matrix runs again after every change, and it becomes the baseline for the firewall tests later in the series.

## What's Next

Next in this series: lab hygiene, reverting the troubleshooting changes made on SDDC Manager during bring-up.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [VCF.PowerCLI module on the PowerShell Gallery](https://www.powershellgallery.com/packages/VCF.PowerCLI/9.1.1.25718932)
- [PowerCLI Installation Guide (Broadcom Developer)](https://developer.broadcom.com/powercli/installation-guide)
- [Subnets in an NSX VPC (NSX 4.2 documentation)](https://docs.vmware.com/en/VMware-NSX/4.2/administration/GUID-CC2A7BC0-3021-4312-AF8C-941A995EE8E5.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
