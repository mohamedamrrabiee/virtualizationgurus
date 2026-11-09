---
title: "Distributed Firewall for Kubernetes Workloads: Pods and VMs in the Namespace VPC"
slug: "lab-dfw-namespace-vpc-kubernetes-labels"
date: 2026-11-27
draft: true
tags: ["VCF", "VMware", "Lab", "NSX", "DFW", "Supervisor", "vSphere Pods", "VM Service"]
categories: ["VCF 9", "Lab Series"]
labPart: 26
cover:
  image: "/images/covers/lab-dfw-namespace-vpc-kubernetes-labels.jpg"
  alt: "Distributed Firewall for Kubernetes Workloads in the Namespace VPC"
  relative: false
description: "Writing Distributed Firewall rules in a Supervisor namespace VPC with groups built from Kubernetes labels, separating a VM Service VM from vSphere Pods, and proving both directions with Traceflow."
---

## Overview

The previous post wrote a Distributed Firewall policy for VMs with NSX tags. A Supervisor namespace needs the same control for workloads that are not tagged by hand: vSphere Pods and VM Service VMs created from Kubernetes manifests.

The answer in a namespace VPC is that Kubernetes labels become NSX tags on the workload's subnet port, and groups match on those tags. This post builds a two-rule policy between a VM and a set of pods and proves each direction with Traceflow.

## Architecture at a glance

How Kubernetes labels reach the firewall as tags, and where the two one-way rules sit.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-dfw-namespace-vpc-kubernetes-labels-glance.svg"></object>
</div>

## The workloads

| Workload | Kind | Address | Kubernetes label |
|---|---|---|---|
| `web-demo2` | Deployment, 3 vSphere Pod replicas | 172.31.0.34 to .36 | `app: web-demo2` |
| `vm-demo01` | VM Service VM | 172.21.0.35 | `vm-selector: vm-demo01` |

Both live in the namespace `ns-app-dev`, which is backed by its own VPC. The pods take addresses from the private transit gateway block 172.31.0.0/16, and the VM from the namespace private VPC range 172.21.0.0/16.

![The VPC list in NSX showing the namespace VPC for ns-app-dev](/images/lab/lab-S478.jpg)
*The namespace VPC for `ns-app-dev` next to the system VPCs, with its private CIDR 172.21.0.0/16.*

![The vm-demo01 detail page in the vSphere Client showing the label vm-selector: vm-demo01](/images/lab/lab-S480.jpg)
*`vm-demo01` in the vSphere Client, with the label `vm-selector: vm-demo01` that the firewall will use.*

## Labels become NSX tags

Each workload gets a subnet port in the namespace VPC, and the Supervisor writes tags onto that port. Some describe where the object came from, for example the namespace and the pod name. The Kubernetes labels arrive with the label key as the tag scope and the label value as the tag.

![Subnet port tags of a web-demo2 pod: namespace, pod name, and the app label as tag web-demo2 with scope app](/images/lab/lab-S479.jpg)
*The tags on a `web-demo2` pod port. The label `app: web-demo2` appears as tag `web-demo2` with scope `app`.*

So no tagging happens in NSX. Labeling the workload in Kubernetes is the whole job.

## Groups on subnet ports

The groups use the member type Subnet Port and match on a tag and scope.

![grp-web-demo2: Subnet Port, Tag equals web-demo2, Scope equals app](/images/lab/lab-S481.jpg)
*`grp-web-demo2`: Subnet Port, Tag `web-demo2`, Scope `app`.*

![grp-vm-demo01: Subnet Port, Tag equals vm-demo01, Scope equals vm-selector](/images/lab/lab-S482.jpg)
*`grp-vm-demo01`: Subnet Port, Tag `vm-demo01`, Scope `vm-selector`.*

| Group | Tag (scope) | Members |
|---|---|---|
| `grp-web-demo2` | `web-demo2` (`app`) | 3 vSphere Pod ports |
| `grp-vm-demo01` | `vm-demo01` (`vm-selector`) | 1 VM Service VM port |

The effective members confirm the match.

![grp-vm-demo01 members: one subnet port, 172.21.0.35](/images/lab/lab-S483.jpg)
*`grp-vm-demo01` resolves to one subnet port, 172.21.0.35.*

![grp-web-demo2 members: three subnet ports, 172.31.0.34, .35 and .36](/images/lab/lab-S484.jpg)
*`grp-web-demo2` resolves to three subnet ports, one per pod.*

## The policy: two one-way rules

| ID | Rule | Source | Destination | Action |
|---|---|---|---|---|
| 1012 | R1: deny-vm-to-web | `grp-vm-demo01` | `grp-web-demo2` | Drop |
| 1013 | R2: deny-web-to-vm | `grp-web-demo2` | `grp-vm-demo01` | Drop |

The policy is two rules and not one because of how a single rule would behave. A rule with both groups on both sides would also drop traffic between pods inside `web-demo2`, since each pod is both a source and a destination in that rule. Two one-way rules cut only the path between the two groups and leave pod-to-pod traffic alone.

![Namespace VPC policy with rules 1012 and 1013](/images/lab/lab-S487.jpg)
*The policy `pol-nsappdev-demo`: rules 1012 and 1013, both Drop.*

## Proof with Traceflow

Each direction was traced from the real workload.

![Traceflow from vm-demo01 to a web-demo2 pod, dropped by rule 1012 at the VM vNIC](/images/lab/lab-S485.jpg)
*VM to pod: Dropped by Firewall Rule ID 1012 at `vm-demo01-eth0` on the host `esx01`.*

![Traceflow from a web-demo2 pod to vm-demo01, dropped by rule 1013 at the pod vNIC](/images/lab/lab-S486.jpg)
*Pod to VM: Dropped by rule 1013 at the pod vNIC on the host `esx03`.*

The two results show where the Distributed Firewall acts. Each packet is dropped at the vNIC of its own source, on the host that runs it, before it reaches the network. A VM and a pod on different hosts are enforced independently by the same policy.

## What to take from it

-> **Label in Kubernetes, group in NSX**: Kubernetes labels become tags on the subnet port, with the label key as scope.

-> **Use the Subnet Port member type**: pods and VM Service VMs are subnet ports in a namespace VPC.

-> **Write one-way rules for group-to-group blocks**: a rule with the same group on both sides also breaks traffic inside the group.

-> **Check effective members before testing**: the member count (3 pods, 1 VM) tells you the labels matched.

-> **Prove each direction separately**: one Traceflow per rule, with the rule ID in the result.

## What's Next

This is the last post in the series. The lab now runs from the first host to a Supervisor with VKS clusters, VMs and a Distributed Firewall that follows both NSX tags and Kubernetes labels.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [Adding Groups in an NSX VPC (NSX 4.2 documentation)](https://docs.vmware.com/en/VMware-NSX/4.2/administration/GUID-AB609CE1-BFD9-400D-B89B-B23500C90D75.html)
- [Broadcom KB 441571: Traceflow drop reason FW_RULE](https://knowledge.broadcom.com/external/article/441571/traceflow-drop-reason-fwrule.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
