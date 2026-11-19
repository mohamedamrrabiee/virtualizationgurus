---
title: "Bring-up Milestones: What Each Stage Builds and How Long It Took"
slug: "lab-bring-up-milestones"
date: 2026-11-19
draft: false
tags: ["VCF", "VMware", "Lab", "VCF Installer", "Bring-up", "Timing"]
categories: ["VCF 9", "Lab Series"]
labPart: 5
cover:
  image: "/images/covers/lab-bring-up-milestones.jpg"
  alt: "Bring-up Milestones: What Each Stage Builds and How Long It Took"
  relative: false
description: "What the VCF Installer automates in a VCF 9.1.1 management domain deployment: seven milestones, what each stage builds, how long each took in this lab, and what to expect while it runs."
---

## Overview

Once validation passes, the VCF Installer takes over and builds the management domain from the single validated configuration you gave it. vCenter, SDDC Manager, the cluster with its distributed switch and vSAN datastore, three NSX Managers and the three VCF 9 layers on top are deployed and configured in the right order, with no manual sequencing between them. That is the real benefit: one input, one workflow, a repeatable result.

This post lists the seven milestones in order, with the steps the installer tracks in each and the duration it showed in this lab. The durations include time spent paused on failures, which the troubleshooting posts cover, so read them as a ceiling for a clean run, not a benchmark.

## What the installer automates

-> **Dependency order**: each stage starts only when the one it depends on is complete, so you never build NSX before the cluster exists.
-> **Tracked progress**: more than 280 steps are tracked across the stages, so you always know which stage is running and how far it is.
-> **Pause, fix, retry**: a failed step pauses the stage and keeps state, so the deployment continues after the fix instead of starting over.
-> **Repeatability**: the same validated input produces the same domain every time, which is what makes it consistent across environments.

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

The final run started on 16 October at 22:13 and completed on 17 October at 12:38, about 14 hours 25 minutes of wall clock time including every troubleshooting pause. All of it ran from one configuration, with no manual deployment steps between the stages.

## What each stage does

-> **Deploy vCenter**: the first appliance the installer deploys, onto the first management host. A thumbprint mismatch on the host certificate stops it here, which is why the certificate work comes first.

-> **Deploy SDDC Manager**: deploys the new SDDC Manager appliance. The installer itself is not part of the domain and is removed afterwards.

-> **Configure vSphere cluster**: the longest stage by far, at 135 steps. It builds the cluster, the distributed switch and the vSAN datastore and initializes the domain in SDDC Manager. Three critical issues paused it in this lab, which is why it shows almost four hours.

-> **Deploy and configure NSX**: 103 steps. The three NSX Manager appliances deploy in parallel, so you see three OVF deployments at once in vCenter.

-> **VCF Management Platform, operations appliance and VCF Management Services**: the three VCF 9 layers on top. Together they took about three hours 50 minutes in this lab, with no failures.

![VCF Installer with Deploy SDDC Manager in progress](/images/lab/lab-S082.jpg)
*Deploy SDDC Manager in progress.*

![vCenter task list showing three NSX Manager OVF deployments](/images/lab/lab-S096.jpg)
*Deploy and configure NSX: three NSX Manager OVF deployments running in parallel in vCenter.*

![VCF Installer with NSX complete and VCF Management Platform in progress](/images/lab/lab-S099.jpg)
*NSX complete, VCF Management Platform in progress.*

## What the stages tell you while you wait

-> **A stage that sits still is not a stage that is stuck**: the installer shows step counts per stage. Compare the step count against the table, and look at vCenter tasks before assuming a hang.

-> **Failures stop the stage, not the deployment**: when a step failed, the installer paused with an error and kept its state, so the deployment could be retried after the fix rather than rebuilt.

-> **Start it when you can watch the first hour**: vCenter and SDDC Manager are where host-level problems appear, and the rest runs on its own once they are through.

-> **Preparation decides the outcome**: the installer rewards a validated input. The better the preparation, the less there is to pause on.

## When it completes

The installer shows a completed deployment and a panel of next steps for VCF Operations.

![VCF Installer showing the deployment completed successfully](/images/lab/lab-S100.jpg)
*Deployment completed, with the next steps panel for VCF Operations.*

The first thing to verify afterwards is that every fleet component is listed with its 9.1.1 version in VCF Operations, which the day-N post covers.

## What's Next

Next in this series: Troubleshooting bring-up, thumbprint mismatch and vSAN ESA disk eligibility.

## Further Reading (Official Broadcom Documentation)

- [Deploying a New VCF Platform](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/deploying-a-new-vmware-cloud-foundation-or-vmware-vsphere-foundation-private-cloud-.html)
- [Components in VCF](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/vcf-management-appliances.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
