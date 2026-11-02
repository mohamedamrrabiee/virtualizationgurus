---
title: "One vSphere Client for Two Domains: vCenter Linking in VCF Operations"
date: 2026-11-03
draft: true
tags: ["VCF", "VMware", "Lab", "vCenter Linking", "VCF SSO", "VCF Operations"]
categories: ["VCF 9", "Lab Series"]
labPart: 14
cover:
  image: "/images/covers/lab-vcenter-linking-vcf-operations.jpg"
  alt: "One vSphere Client for Two Domains: vCenter Linking in VCF Operations"
  relative: false
description: "Creating a vCenter linking group in VCF Operations so one vSphere Client shows the management and workload domain vCenters, what it needs from VCF SSO, and one permission limit the SSO user hits."
---

## Overview

The management domain and the workload domain each have their own vCenter, and each has its own isolated SSO domain. vCenter linking puts several vCenters in one vSphere Client session, so you sign in once and see all their inventories.

In this lab the linking group went from In Progress to Active in about two minutes. This post covers the steps, what to check afterwards, and a permission limit that only shows up when you try to grant access as the SSO user.

## Prerequisites

The documentation lists these requirements for a linking group:

-> **Two to 15 vCenters**, all version 9.0 or later, with forward and reverse DNS resolving for each.

-> **Not in an Enhanced Linked Mode ring**: a vCenter that is part of an ELM ring is not eligible.

-> **A common identity provider** configured on every vCenter in the group.

In this lab the common identity provider was the one from the previous post: both vCenters were already Configured under the identity broker, and the SSO user `mrabiee@vgurus.lab` could already sign in to the w01 vCenter.

## Creating the linking group

| Item | Value |
|---|---|
| Where | VCF Operations, Operate, Administration, Configurations, Logical Groupings, vCenter Linking |
| Linking group | `vg1-vc-link` |
| Members | `vg1-m01-vc01` and `vg1-w01-vc01` |
| Time to Active | About two minutes, In Progress at 18:18 and Active at 18:20 |

Right after creation both vCenters show In Progress, and a task named "Enable vCenter Linking" appears. When it completes, both show Active.

![vCenter linking group with both vCenters In Progress](/images/lab/lab-S207.jpg)
*Right after creation: both vCenters In Progress.*

![vCenter linking group with both vCenters Active](/images/lab/lab-S162.jpg)
*About two minutes later: both vCenters Active.*

## What you see afterwards

Sign in to either vCenter as the SSO user and the vSphere Client shows both vCenters in the inventory tree. The sign-in is the VCF SSO one, so there is no second login and no separate account on the other vCenter.

![vSphere Client showing both vCenters and the completed Enable vCenter Linking task](/images/lab/lab-S163.jpg)
*One vSphere Client with both vCenters in the tree, and the Enable vCenter Linking task completed.*

Linking does not copy everything. Permissions are assigned per vCenter, and roles, tags and global permissions are not synchronized between the linked vCenters.

Two checks worth doing at this point:

-> **Both vCenters under one tree**: the management and workload datacenters are both visible, which is what the linking group promises.

-> **The task finished, not just the status**: open Recent Tasks and confirm "Enable vCenter Linking" completed.

## A permission limit with the SSO user

Later in the lab, I tried to add a permission on a Supervisor namespace as the SSO user and vCenter answered "You do not hold privileges". The Permissions dialog was asking for privileges such as AutoDeploy and Cryptographic operations in the role being assigned.

This is vCenter's own rule: a user can grant only privileges that user holds. The documentation maps the VCF Administrator role to the vCenter Administrator role, and from 9.1.1 to membership of the local Administrators group, so I expected full rights. In this lab the SSO user still could not grant some privileges, so treat this as a lab observation and check it on your own build before relying on either behavior. The way around it in this lab was simple: the vSphere local administrator already held the Supervisor Administrator role on the Supervisor, which covers every namespace, so the namespace settings were done as `administrator@vsphere.local`.

-> **Plan a break-glass account**: keep the local vCenter administrator available for tasks the SSO role does not cover.

-> **Check the role you assign**: if a dialog refuses a privilege, the cause is the assigning user's role, not the target.

## What to take from it

-> **Do SSO first, linking second**: linking has nothing to join until both vCenters accept the same identity.

-> **Give it a couple of minutes**: the group moves from In Progress to Active on its own, and that is normal.

-> **Know what the SSO role can and cannot grant**: day-to-day administration worked, and granting every privilege did not in this lab.

## What's Next

Next in this series: guided Edge deployment from vCenter, starting with a port group, an Edge TEP pool and the Edge cluster.

## Further Reading (Official Broadcom Documentation)

- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)
- [Configuring vCenter group linking on VCF (Broadcom KB 444621)](https://knowledge.broadcom.com/external/article/444621/configuring-vcenter-group-linking-on-vcf.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
