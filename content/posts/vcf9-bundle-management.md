---
title: "Bundle Management: Online vs Offline/Air-Gapped"
date: 2026-09-06
draft: false
tags: ["Lifecycle Management", "Software Depot", "Air-Gapped", "VCF Download Tool"]
categories: ["VCF 9", "Lifecycle Management"]
description: "VCF 9.1 didn't just add an offline option to bundle management, it formalized three distinct software depot connection modes. What Connected, Offline Depot, and Disconnected actually mean, and why conflating the last two causes real prechecks to fail."
---

## Introduction

"Air-gapped" gets treated as a single scenario in most VCF conversations, you either have internet access or you don't. VCF 9.1's software depot architecture disagrees: it defines three distinct connection modes, and the two that cover no-internet environments, Offline Depot and Disconnected, are genuinely different operational models, not two names for the same workaround. Picking the wrong one, or assuming they're interchangeable, is a common source of confused prechecks during upgrade planning.

## Software Depot: The Component Behind All Three Modes

Starting with VCF 9, lifecycle management for every VCF component runs through a single component called the software depot, accessed via the VCF Operations UI. Every VCF fleet has one fleet-level software depot, deployed on the first VCF Instance, that can serve binaries to every other Instance in the fleet. When you deploy a new VCF Instance on version 9.1 or later, the fleet-level depot is assigned to it automatically. If you're upgrading an existing fleet to 9.1, whatever depot configuration was already set in VCF Installer or SDDC Manager carries forward into the new fleet-level depot rather than needing to be redone.

There's also a scaling knob worth knowing: if network latency between your first Instance's software depot and another Instance in the fleet exceeds 150 ms, Broadcom's guidance is to deploy a secondary, local software depot within that other Instance rather than have it pull binaries across a slow link.

## Three Connection Modes, Not Two

Every software depot instance is configured in exactly one of three modes, and Broadcom's own documentation is explicit that the choice depends entirely on how your environment reaches the internet:

-> **Connected**: your environment has internet access, direct or through a proxy. The software depot registers directly with Broadcom, downloading binaries, hardware compatibility data, software interoperability data, and lifecycle metadata on its own. Registration itself has a specific flow: you copy the depot's software depot ID, log into the VCF Business Services console, register the component under the correct tenant, generate an activation code against that ID, then paste the code back into VCF Operations to validate. Binaries are cached and managed internally, and there's no manual delete option in this mode.

-> **Offline Depot**: your environment can't reach the internet, but you own a private server that can. You run the VCF Download Tool against that server to pull binaries down, and the software depot doesn't download anything locally itself, it proxies every request from VCF components straight to your privately-owned server. If that server serves content over HTTPS, there's a real prerequisite step: SSH into SDDC Manager, pull the depot server's TLS certificate with `openssl s_client`, import it into the local Java certificate store with `keytool`, and restart the `lcm` service, all before the mode will actually connect.

-> **Disconnected**: your environment can't reach the internet and you don't have an offline depot server at all. You run the VCF Download Tool on any separate computer that does have internet access, then manually upload the resulting binaries straight into the software depot. This is the one mode where a cleanup command exists to delete uploaded binaries again, Connected and Offline Depot both cache internally with no delete option.

## Why the Offline Depot vs Disconnected Distinction Actually Matters

Read those last two modes again: the practical difference is whether a dedicated, always-on depot server exists in your environment. Offline Depot assumes one does, and the software depot proxies to it continuously. Disconnected assumes one doesn't, and every set of binaries you need gets manually carried in and uploaded as a one-off action. Treating "we're air-gapped" as a single answer skips over a real infrastructure decision, standing up and maintaining a depot server is a genuinely different operational commitment than running the download tool on a laptop each time you need new binaries.

This is also where mismatched assumptions cause real friction during upgrade planning: someone configures Offline Depot mode expecting the software depot to actively fetch on demand, when what's actually been built is a Disconnected workflow, binaries staged manually, no ongoing proxy behavior. The two look similar from a distance, "no internet, binaries come from somewhere else", but the software depot treats them as fundamentally different connection types, and troubleshooting one as if it were the other wastes real time.

## The VCF Download Tool Is the Common Thread

Both Offline Depot and Disconnected modes rely on the same underlying utility: the VCF Download Tool, a command-line tool purpose-built for downloading and managing VCF component and ESX binaries and metadata in environments without internet access. It provides commands for downloading, uploading, listing, and cleaning up binaries, the same tool, pointed at either a depot server (Offline Depot) or a direct upload target (Disconnected), depending on which mode you're actually running.

## Architectural Overview

```
                        Broadcom Online Repository
                                     |
             +-----------------------+-----------------------+
             |                       |                       |
         Connected             Offline Depot           Disconnected
             |                       |                       |
       direct/proxy          VCF Download Tool       VCF Download Tool
       registration           to owned server       to any internet PC
             |                       |                       |
             v                       v                       v
          +----------------------------------------------------+
          |                   SOFTWARE DEPOT                   |
          |         (fleet-level, first VCF Instance)          |
          +----------------------------------------------------+
                                     |
                   latency to another Instance > 150ms?
                                     |
                                     v
                  +------------------------------------+
                  |      SECONDARY SOFTWARE DEPOT      |
                  |  (deployed within that Instance)   |
                  +------------------------------------+
```

## Choosing Between Them: A Quick Checklist

- **Full internet access, direct or via proxy?** Connected, register once with an activation code and you're done.
- **No internet, but you can stand up and maintain a dedicated server?** Offline Depot, plan for the TLS certificate import step if that server runs HTTPS.
- **No internet, and no appetite to run a standing depot server?** Disconnected, budget the recurring manual effort of downloading and uploading binaries per upgrade cycle.
- **Multi-Instance fleet with a slow link to one of them?** Deploy a secondary software depot in that Instance regardless of which of the three modes your fleet-level depot uses.

## What's Next

Next in this series: Day-2 Operations, Lifecycle, Patching, and Compliance via VCF Operations.

## Further Reading (Official Broadcom Documentation)

- [Binary Management for VMware Cloud Foundation](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/lifecycle-management/binary-management-for-vmware-cloud-foundation.html)
- [Configure a Software Depot Connection Mode](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/lifecycle-management/binary-management-for-vmware-cloud-foundation/connect-sddc-manager-to-a-software-depot-for-downloading-bundles.html)
- [Download Binaries to an Offline Depot by Using the VCF Download Tool](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/lifecycle-management/binary-management-for-vmware-cloud-foundation/download-bundles-to-an-offline-depot.html)
- [Download Binaries to Software Depot in Disconnected Mode by Using the VCF Download Tool](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/lifecycle-management/binary-management-for-vmware-cloud-foundation/offline-download-of-vmware-cloud-foundation-5-2-upgrade-bundles.html)
- [VCF Download Tool Command Reference Information](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/lifecycle-management/binary-management-for-vmware-cloud-foundation/what-is-the-vcf-download-tool-.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
