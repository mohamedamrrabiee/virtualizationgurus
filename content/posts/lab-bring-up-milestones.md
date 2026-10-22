---
title: "Bring-up Milestones: What Each Stage Builds and How Long It Took"
date: 2026-10-25
draft: true
tags: ["VCF", "VMware", "Lab", "VCF Installer", "Bring-up", "Timing"]
categories: ["VCF 9", "Lab Series"]
labPart: 5
cover:
  image: "/images/covers/lab-bring-up-milestones.jpg"
  alt: "Bring-up Milestones: What Each Stage Builds and How Long It Took"
  relative: false
description: "The seven bring-up milestones of a VCF 9.1.1 management domain deployment in a nested lab, with the duration of each stage as shown by the installer and what to expect while it runs."
---

## Overview

Once validation passes, the installer takes over and builds the management domain as a series of milestones. In a nested lab nothing is fast, and knowing what each stage is doing tells you whether a long pause is normal or a problem.

This post lists the milestones in order, with the durations the installer showed in this lab. The durations include time spent paused on failures, which the troubleshooting posts cover, so read them as a ceiling for a clean run, not a benchmark.

## The milestones

| Milestone | Duration | Steps | Critical issues hit |
|---|---|---|---|
| Deploy vCenter | 18m 19s (successful retry) | | CI-02 |
| Deploy SDDC Manager | 23m 24s | | |
| Configure vSphere cluster | 3h 56m 23s | 135 | CI-03, CI-04, CI-05 |
| Deploy and configure NSX | 52m 58s | 103 | CI-06 |
| Deploy and configure VCF Management Platform | 1h 48m 49s | 15 | |
| Deploy and configure the operations appliance | 58m 17s | 15 | |
| Deploy and configure VCF Management Services | 1h 2m 49s | 18 | |

The final run started on 16 October at 22:13 and completed on 17 October at 12:38, about 14 hours 25 minutes of wall clock time including every troubleshooting pause.

## What each stage does

-> **Deploy vCenter**: the first appliance the installer deploys, onto the first management host. A thumbprint mismatch on the host certificate stops it here, which is why the certificate work comes first.

-> **Deploy SDDC Manager**: deploys the new SDDC Manager appliance. The installer itself is not part of the domain and is removed afterwards.

-> **Configure vSphere cluster**: the longest stage by far, at 135 steps. It builds the cluster, the distributed switch and the vSAN datastore and initializes the domain in SDDC Manager. Three critical issues paused it in this lab, which is why it shows almost four hours.

-> **Deploy and configure NSX**: 103 steps. The three NSX Manager appliances deploy in parallel, so you see three OVF deployments at once in vCenter.

-> **VCF Management Platform, operations appliance and VCF Management Services**: the three VCF 9 layers on top. Together they took about three hours 50 minutes in this lab, with no failures.

<!-- TODO screenshots after masking: S082 (Deploy SDDC Manager in progress), S096 (three NSX Manager OVF deployments), S099 (NSX complete, VCF Management Platform in progress), S100 (deployment completed) -->

## What the stages tell you while you wait

-> **A stage that sits still is not a stage that is stuck**: the installer shows step counts per stage. Compare the step count against the table, and look at vCenter tasks before assuming a hang.

-> **Failures stop the stage, not the deployment**: when a step failed, the installer paused with an error and kept its state, so the deployment could be retried after the fix rather than rebuilt.

-> **Plan for a long day**: even a clean run is several hours in a nested lab. Start it when you can watch the first hour, since vCenter and SDDC Manager are where host-level problems appear.

## When it completes

The installer shows a completed deployment and a panel of next steps for VCF Operations.

<!-- TODO screenshot after masking: S100 -->

The first thing to verify afterwards is that every fleet component is listed with its 9.1.1 version in VCF Operations, which the day-N post covers.

## What's Next

Next in this series: Troubleshooting bring-up, thumbprint mismatch and vSAN ESA disk eligibility.

## Further Reading (Official Broadcom Documentation)

- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)
- [Components in VCF](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/vcf-management-appliances.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
