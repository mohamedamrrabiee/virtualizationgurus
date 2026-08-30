---
title: "VCF 9 Identity Broker: Retiring VMware Identity Manager for Unified Fleet Authentication"
date: 2026-08-30
draft: false
tags: ["VCF", "VMware", "Identity Broker", "SSO", "Security", "Cloud Foundation"]
categories: ["VCF 9", "Security"]
description: "A technical breakdown of the VCF 9 Identity Broker, validated against official Broadcom documentation: how it replaces VMware Identity Manager, its two deployment modes, and the migration path from vIDM."
---

## Introduction

If Fleet collapsed three consoles into one control plane, the Identity Broker does the same job for authentication. VMware Identity Manager (vIDM) is superseded in VCF 9 by a fleet-native component called the Identity Broker. The new component takes over VCF single sign-on going forward, though Broadcom doesn't force a rip-and-replace cutover: existing vIDM instances can keep running (still managed via VMware Aria Suite Lifecycle 8.x) as an authentication source for components like VCF Automation while you migrate the rest of the fleet on your own schedule. This post covers what the Identity Broker actually is, the two ways you can deploy it, and what a real migration from vIDM looks like, based on Broadcom's official 9.1 documentation.

## From VMware Identity Manager to a Fleet-Native Identity Broker

VCF single sign-on is the mechanism that lets components across the fleet (vCenter, VCF Operations, VCF Automation, NSX, log management, VCF Operations for Networks, and VCF Operations Orchestrator) authenticate against a shared set of identity providers instead of maintaining separate logins. Two notable exceptions: SDDC Manager and ESX are not covered by VCF single sign-on and keep their own authentication paths. In earlier VCF releases, vIDM often filled the fleet-authentication role. In VCF 9.1, that job belongs to the Identity Broker, a purpose-built component for VCF single sign-on across the fleet.

## Two Deployment Modes: Embedded or Instance

According to Broadcom's documentation, the Identity Broker supports two deployment modes, and the choice affects where the component actually lives. Worth flagging up front: the change between releases isn't just a rename. In VCF 9.0, the non-embedded mode ran as a standalone, externally-deployed multi-node appliance cluster, and Broadcom called it "Appliance" mode. In VCF 9.1, that same role is filled by "Instance" mode, but the underlying architecture changed with it: it's now consolidated into VCF Management Services, the unified runtime VCF 9.1 introduced for centralized lifecycle and operations across components like Identity Broker, Log Management, and the License Server. Broadcom's own upgrade documentation confirms this directly: the 9.0 external vIDB appliance cluster is "migrated directly into VCF Management Services" as part of the 9.1 upgrade, not simply relabeled. If you're cross-referencing older 9.0-era material or blog posts, keep this in mind, the terminology changed because the architecture did.

-> Embedded mode, the Identity Broker is configured directly inside the management domain vCenter of a VCF Instance. This is the simpler option, typically used within a single VCF Instance. It's also a single point of failure: if the management domain vCenter goes down, the embedded Identity Broker goes down with it.

-> Instance mode, the Identity Broker is deployed as its own dedicated VCF management services component within the management domain, separate from vCenter, running as a three-node cluster that tolerates a single node failure. The first Identity Broker instance is deployed in the primary VCF Instance, and you can optionally deploy additional Identity Broker instances in other VCF Instances across the fleet, though Broadcom's guidance caps a single Instance-mode broker at up to five connected VCF Instances.

Broadcom's Identity Broker Detailed Design documentation covers the specific requirements and recommendations for choosing between the two.

## What Migration From vIDM Actually Involves

For environments coming from VMware Identity Manager 3.3.7 GA (or its latest patch), Broadcom provides a dedicated migration path in VCF 9.1, targeting an Instance-mode Identity Broker running 9.1 or later, built around export/import scripts rather than a one-click in-place upgrade:

-> Users and groups are migrated from vIDM to the Identity Broker directly.

-> Sync settings for existing identity providers are compared and displayed side by side, but not automatically migrated, you review the comparison and adjust the Identity Broker's sync settings yourself if needed.

-> Component updates, if VCF Operations, VCF Automation, or NSX currently authenticate through vIDM, a separate update step repoints each of them to the new Identity Broker once it's configured.

The migration tooling ships as OS-specific export/import binaries (Windows x86_64, macOS ARM64, Linux x86_64) that you download from Broadcom Support, run against your existing vIDM instance to export data, then import into the target Identity Broker with built-in data-integrity and compatibility validation.

## Migration Limitations Worth Knowing

A few constraints matter when planning a migration, straight from Broadcom's documented limitations:

-> Only the Instance deployment mode is a supported migration target, you can't migrate directly into an Embedded-mode Identity Broker.

-> Local accounts, and local accounts using multifactor authentication, aren't supported on the Identity Broker, nor is multifactor authentication paired with Active Directory.

-> OAuth clients don't migrate automatically, they need to be manually regenerated against the Identity Broker.

-> If a single vIDM instance currently serves multiple components, all of them get repointed to the same new Identity Broker as part of component migration, there's no partial cutover.

-> Component migration is only supported for three components: VCF Operations, VCF Automation, and NSX. Anything else authenticating through vIDM needs a separate plan.

## Architecture at a Glance

```
                    +--------------------------------+
                    | VMware Identity Manager (vIDM) |
                    |  Day-0 legacy identity source  |
                    +--------------------------------+
                                     |
                                     | export (users, groups, sync settings comparison)
                                     v
            +------------------------------------------------+
            |               MIGRATION TOOLING                |
            | (vidm-export / vidb-import / component-update) |
            +------------------------------------------------+
                                     |
                                     | import + validation
                                     v
     +--------------------------------------------------------------+
     |                       IDENTITY BROKER                        |
     | Embedded (in mgmt vCenter) or Instance (dedicated component) |
     +--------------------------------------------------------------+
                                     |
                                     | repointed via component-update
                                     v
                 +-------------------+-------------------+
                 |                   |                   |
        +----------------+  +----------------+  +----------------+
        | VCF Operations |  | VCF Automation |  |      NSX       |
        +----------------+  +----------------+  +----------------+
```

## The Mental Model Shift

| Legacy (vIDM era) | VCF 9 |
|---|---|
| VMware Identity Manager as a bolted-on identity source | Identity Broker as a native VCF single sign-on component |
| One identity config per tool | Shared Identity Broker across VCF Operations, VCF Automation, and NSX |
| Manual, ad hoc cutover between identity tools | Documented export/import/component-update migration path |
| Local accounts and MFA handled inconsistently | Local + MFA combinations explicitly unsupported on the Broker, third-party IdP/AD integration is the expected pattern |
| "Appliance mode": standalone external appliance cluster (VCF 9.0) | "Instance mode": consolidated into VCF Management Services (VCF 9.1), architecture changed, not just the name |

## Embedded to Instance Migration (VCF 9.1)

A separate migration path exists for a different scenario than the vIDM migration above: moving an Identity Broker that's already running in Embedded mode into Instance mode, without touching vIDM at all. This is new in VCF 9.1, Broadcom's release notes for VCF Operations 9.1 list it explicitly: "Migration from embedded to instance deployment of the identity broker: Support for the migration of the identity broker from embedded mode to instance mode in VCF Operations."

Worth correcting a common assumption up front: this is not a zero-touch, click-and-done migration. It's a supported, no-data-loss path, but it involves real manual steps on your end, including reconfiguring your external identity provider.

**Prerequisites:** your Embedded-mode Identity Broker must already be at version 9.1 (it upgrades automatically as part of the vCenter instance upgrade, no separate step needed), and you need an Instance-mode Identity Broker already deployed somewhere in the fleet to serve as the migration target. Only VCF Instances with an existing Instance-mode broker show up as valid targets, so if none exists yet, you deploy one first.

What the migration actually involves, from VCF Operations (Manage > Fleet Management > Identity & Access > VCF SSO Overview > select the broker > Actions > Migrate from Embedded to Instance):

-> **Data transfer is SFTP-based.** You provide an SFTP host, port, username, password, and path; the migration exports data from the embedded broker and imports it into the target instance over that connection. Broadcom's own guidance: use a dedicated, single-purpose SFTP account scoped to only that folder, and delete it once the migration completes.

-> **Identity provider config and user/group provisioning are suspended for the duration of the transfer.** Plan the migration window accordingly rather than treating it as a background operation.

-> **You manually update your external identity provider afterward.** The wizard shows you the new Identity Broker instance's service provider details, and you take those into your IdP's own admin console to update its configuration, there's no automatic push to a third-party IdP. A Test Login step lets you validate the new connection before committing further.

-> **Component reconnection is only partly automatic.** The wizard's "Update Components" step reconnects and sanity-tests the components it knows how to handle, but VCF Operations, HCX, log management, and VCF Operations for Networks all need manual follow-up, along with any automation scripts using API clients against the old configuration.

-> **Canceling mid-migration deletes the target's configuration**, not just aborts cleanly, so treat the confirmation step as a real go/no-go point rather than a formality.

Broadcom documents the exact procedure in "Migration of Identity Broker Embedded to Identity Broker Instance," linked below, worth a full read before scheduling this given the manual IdP and component-update work involved.

## What's Next

Next in this series: Bundle Management, Online vs Offline/Air-Gapped Depots.

## Further Reading (Official Broadcom Documentation)

- [Managing Identity and Access With VCF Single Sign-On](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/fleet-management/managing-identity-and-access-using-vcf-single-sign-on.html)
- [Deployment Modes of the Identity Broker](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/fleet-management/managing-identity-and-access-using-vcf-single-sign-on/what-is/deployment-models-for-sso.html)
- [Migrating VMware Identity Manager to Identity Broker](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/fleet-management/managing-identity-and-access-using-vcf-single-sign-on/migrating-vmware-identity-manager-to-vcf-identity-broker.html)
- [Upgrade to Identity Broker 9.1](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/deployment/upgrading-cloud-foundation/upgrade-vcf-identity-broker.html)
- [Migration of Identity Broker Embedded to Identity Broker Instance](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/fleet-management/managing-identity-and-access-using-vcf-single-sign-on/what-is/managing-vmware-cloud-foundation-operations-sso/migration-of-vcf-identity-broker-embedded-to-vcf-identity-broker-appliance.html)
- [VCF Management Services Models](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/design/vmware-cloud-foundation-concepts/vcf-management-services-models.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/virtualizationgurus/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
