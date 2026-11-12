---
title: "Micro-segmentation Between VPCs with the Distributed Firewall, Proven with Traceflow"
slug: "lab-dfw-vpc-tag-microsegmentation"
date: 2026-12-03
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "DFW", "VPC", "Traceflow", "Security"]
categories: ["VCF 9", "Lab Series"]
labPart: 25
cover:
  image: "/images/covers/lab-dfw-vpc-tag-microsegmentation.jpg"
  alt: "Micro-segmentation Between VPCs with the Distributed Firewall"
  relative: false
description: "A tag-based Distributed Firewall policy in an NSX VPC on a nested VCF 9.1.1 lab: groups, five rules, the SNAT source trap, a gap closed by rule 5, and every decision proven with Traceflow."
---

## Overview

Posts 18 and 19 built two VPCs and proved their isolation with a ping matrix. This post adds the next layer: a Distributed Firewall policy inside the app VPC, written with NSX tags, and proven rule by rule with Traceflow.

The policy has five rules and three groups. Two of the rules exist because the first design had a gap and a wrong assumption, and both are worth knowing before you write your own.

## Architecture at a glance

The three groups and five rules of the policy, and the path each rule controls.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-dfw-vpc-tag-microsegmentation-glance.svg"></object>
</div>

## The test bed

| VM | IP | NSX tag (scope `tier`) |
|---|---|---|
| `app-pub01` | 10.80.0.19 | `public` |
| `app-pub02` | 10.80.0.20 | `public` |
| `app-pub03` | 10.80.0.21 | none at rest, used for a live tag change |
| `app-priv01` | 172.20.1.3 | `private` |
| `dev-priv01` | 172.20.17.3 | `dev`, in the second VPC, leaves through SNAT 10.80.0.1 |

The default Layer 3 rule in this lab is Allow, so every restriction in the policy has to be an explicit rule.

![Default DFW rules with the default Layer 3 rule set to Allow](/images/lab/lab-S463.jpg)
*The starting point: the default Layer 3 rule allows everything, so every block must be written explicitly.*

## Groups: tags, not addresses

The groups use NSX VM tags with the scope `tier`. A VM joins `grp-app-public` when it carries the tag `public` with scope `tier`, and `grp-app-private` when it carries `private`.

![grp-app-public membership criteria: Virtual Machine, Tag equals public, Scope equals tier](/images/lab/lab-S464.jpg)
*Membership criteria: Virtual Machine, Tag equals `public`, Scope equals `tier`.*

Two details cost time:

-> **vCenter tags are not NSX tags.** An NSX group does not read tags applied in vCenter. A group that matches on a tag stays empty until the VM is tagged in NSX, either in Inventory > Virtual Machines or from the VPC VM view. Broadcom documents this in KB 446869.

-> **The (+) trap.** In the tag dialog, a tag that is typed but not added with the (+) button is dropped when you press Save. The tag only exists once it shows as a chip in the dialog.

![NSX Virtual Machines inventory showing the tags on the test VMs](/images/lab/lab-S467.jpg)
*Tags applied in NSX, visible in the Virtual Machines inventory.*

Membership can be checked directly from the group.

![View Members for grp-app-public showing app-pub01 and app-pub02](/images/lab/lab-S468.jpg)
*`grp-app-public` resolves to `app-pub01` and `app-pub02`.*

## Why one group matches an IP

A third group, `grp-dev-snat`, has no tag criteria. It contains the single IP address 10.80.0.1.

![grp-dev-snat defined as the IP address 10.80.0.1](/images/lab/lab-S465.jpg)
*`grp-dev-snat`: the SNAT address of the dev VPC.*

Traffic from `dev-priv01` leaves its VPC through SNAT and reaches the app VPC from 10.80.0.1. The destination VPC never sees the VM, so a tag on `dev-priv01` can never match there. To block the dev VPC you match the address the traffic arrives from, not the VM it came from.

## The policy

| ID | Rule | Source | Destination | Service | Action |
|---|---|---|---|---|---|
| 1005 | R1-mgmt-to-public | 10.20.10.0/24 | `grp-app-public` | SSH, HTTP, ICMP ALL | Allow |
| 1006 | R2-public-to-private | `grp-app-public` | `grp-app-private` | SSH, ICMP ALL | Allow |
| 1007 | R3-block-dev-to-app | `grp-dev-snat` | both app groups | Any | Drop |
| 1008 | R4-deny-to-private | Any | `grp-app-private` | Any | Drop |
| 1009 | R5-deny-private-to-public | `grp-app-private` | `grp-app-public` | Any | Drop |

The order matters. R1 and R2 allow the intended paths, R3 removes the dev VPC, R4 closes the private tier to everything else, and R5 closes the reverse direction.

![Rules R1 to R4 published with IDs 1005 to 1008](/images/lab/lab-S466.jpg)
*The first version of the policy, published as rules 1005 to 1008.*

## Proving it with Traceflow

Each rule was tested with a Traceflow between the real VMs. Traceflow injects a packet at the source vNIC and reports where it was delivered or which rule dropped it.

| # | Source | Destination | Protocol | Result |
|---|---|---|---|---|
| 1 | `app-priv01` | `app-pub01` | ICMP | Delivered (before R5 existed) |
| 2 | `app-priv01` | `app-pub01` | ICMP | Dropped, rule 1009 |
| 3 | `app-pub01` | `app-priv01` | ICMP | Delivered by R2 |
| 4 | `app-pub01` | `app-priv01` | TCP 80 | Dropped, rule 1008 |
| 5 | `dev-priv01` | `app-pub01` | ICMP | Dropped, rule 1007 |

### The gap that needed R5

With R1 to R4 only, a probe from the private VM to a public VM was delivered. R4 blocks traffic into the private group, but nothing blocked traffic that the private tier starts.

![Traceflow from app-priv01 to app-pub01 delivered before rule 5](/images/lab/lab-S469.jpg)
*Before R5: private to public is Delivered.*

R5 closes the gap, and the same trace is dropped by rule 1009.

![Traceflow from app-priv01 to app-pub01 dropped by firewall rule 1009](/images/lab/lab-S470.jpg)
*After R5: Dropped by Firewall Rule ID 1009.*

### The allowed and the denied path

![Traceflow from app-pub01 to app-priv01 delivered under R2](/images/lab/lab-S471.jpg)
*Public to private, allowed by R2: Delivered.*

![Traceflow from app-pub01 to app-priv01 dropped by firewall rule 1008](/images/lab/lab-S472.jpg)
*Public to private on a service R2 does not allow: Dropped by rule 1008.*

### The dev VPC

![Traceflow from dev-priv01 to app-pub01 dropped by firewall rule 1007](/images/lab/lab-S476.jpg)
*The dev VM, through SNAT, is dropped by rule 1007 before it can reach the app VPC.*

## A live tag change

The strongest proof is a tag changed while a trace is running. `app-pub03` has no tag at rest, so it belongs to no group.

![Traceflow to app-pub03 delivered while the VM is untagged](/images/lab/lab-S473.jpg)
*`app-priv01` to `app-pub03`: Delivered, because `app-pub03` is in no group yet.*

![Adding the public tier tag to app-pub03](/images/lab/lab-S474.jpg)
*The tag `public`, scope `tier`, added to `app-pub03` in NSX.*

![Traceflow to app-pub03 dropped by rule 1009 after tagging](/images/lab/lab-S475.jpg)
*The same trace seconds later: Dropped by rule 1009.*

No rule was edited. The VM changed group membership, and the policy followed it.

![Final rule table, R1 to R5](/images/lab/lab-S477.jpg)
*The final policy `pol-app01-microseg`: five rules, IDs 1005 to 1009.*

## What to take from it

-> **Tag in NSX, not in vCenter**: group membership reads NSX tags only.

-> **Add every tag with (+) before Save**: the dialog silently drops a tag that was only typed.

-> **Match SNAT traffic by address**: the destination VPC sees the SNAT IP, so a VM tag on the source never matches.

-> **Block both directions of a tier**: a deny into the private group does not stop traffic that the private tier initiates.

-> **Prove each rule with Traceflow**: a Delivered and a Dropped result per rule is the evidence, and the rule ID is in the result.

-> **Use a tag change as the test of intent**: if a policy follows a tag in seconds, the design works as written.

## What's Next

Next in this series: the same Distributed Firewall in the namespace VPC, where the groups come from Kubernetes labels instead of NSX tags.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [Adding Groups in an NSX VPC (NSX 4.2 documentation)](https://docs.vmware.com/en/VMware-NSX/4.2/administration/GUID-AB609CE1-BFD9-400D-B89B-B23500C90D75.html)
- [Broadcom KB 446869: Virtual Machines configured with vCenter Tags are not populating in NSX Groups](https://knowledge.broadcom.com/external/article/446869/virtual-machines-configured-with-vcenter.html)
- [Broadcom KB 441571: Traceflow drop reason FW_RULE](https://knowledge.broadcom.com/external/article/441571/traceflow-drop-reason-fwrule.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
