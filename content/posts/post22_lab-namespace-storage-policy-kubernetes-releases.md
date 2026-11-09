---
title: "Namespaces, Storage Policies and Kubernetes Releases: Getting VKS Ready for a Team"
slug: "lab-namespace-storage-policy-kubernetes-releases"
date: 2026-11-23
draft: true
tags: ["VCF", "VMware", "Lab", "Supervisor", "VKS", "vSphere Namespace", "vSAN", "Storage Policy"]
categories: ["VCF 9", "Lab Series"]
labPart: 22
cover:
  image: "/images/covers/lab-namespace-storage-policy-kubernetes-releases.jpg"
  alt: "Namespaces, Storage Policies and Kubernetes Releases: Getting VKS Ready for a Team"
  relative: false
description: "Preparing a running Supervisor for its first team on VCF 9.1.1: CLI access, a vSphere Namespace with its own VPC, a vSAN RAID-5 storage policy that becomes a StorageClass, and the Kubernetes releases that VKS offers."
---

## Overview

The Supervisor from the previous post is running, but nobody can use it yet. A team needs a place to work, storage it can claim and a Kubernetes version to build on. In vSphere that place is a vSphere Namespace, the storage comes from a storage policy, and the versions come from Kubernetes releases that VKS publishes.

This post prepares all three on the lab Supervisor `vg1-w01-sup01`: CLI access from the jump host, the namespace `ns-app-dev` with its own VPC, a storage policy called `sp-vks-gold` and a look at the Kubernetes releases and the content library behind them. The next post builds a cluster on top.

## Architecture at a glance

What a team gets in the namespace, and where each piece comes from.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-namespace-storage-policy-kubernetes-releases-glance.svg"></object>
</div>

## CLI access from the jump host

VKS ships with the 9.1.1 Supervisor, so there is nothing separate to install. The Kubernetes CLI tools come from the Supervisor itself: the vSphere plugin is a download from the Supervisor API address, and it carries both `kubectl` and `kubectl-vsphere`.

```bash
curl -k -O https://10.80.0.6/wcp/plugin/linux-amd64/vsphere-plugin.zip
unzip -o vsphere-plugin.zip
sudo install -m 0755 bin/kubectl /usr/local/bin/kubectl
sudo install -m 0755 bin/kubectl-vsphere /usr/local/bin/kubectl-vsphere
kubectl vsphere login --server=10.80.0.6 --vsphere-username administrator@vsphere.local --insecure-skip-tls-verify
```

The `--insecure-skip-tls-verify` flag is a lab shortcut, because the Supervisor certificate is not issued by a CA the jump host trusts. The login token lasts about 10 hours.

![The vSphere plugin downloaded from the Supervisor and installed on the jump host](/images/lab/lab-S334.jpg)
*The plugin download from `10.80.0.6` and the install of `kubectl` and `kubectl-vsphere` on the jump host.*

## Check the Supervisor first

Two days after activation, the Supervisor was still healthy. From the Supervisor control plane shell, the checks that matter are short.

```bash
kubectl get nodes -o wide
kubectl get pods -A | grep -vE "Running|Completed"
kubectl get kr
```

![Supervisor health check: 6 nodes Ready, no unhealthy pods, three Kubernetes releases](/images/lab/lab-S335.jpg)
*Six nodes Ready (three control plane VMs and three ESX hosts as agents), no unhealthy pods, and three Kubernetes releases listed.*

## Create the namespace

A vSphere Namespace is the unit a team works in. It holds permissions, resource limits, storage, VM classes and content libraries, and on a VPC-based Supervisor it also gets a network.

The wizard asks for three things. First the Supervisor that will host it.

![New Namespace, step 1: select the Supervisor vg1-w01-sup01](/images/lab/lab-S338.jpg)
*Step 1: the location is the Supervisor `vg1-w01-sup01`.*

Then a name, `ns-app-dev`. The option to override the default network settings stays unticked, which is the important choice. With the defaults, the namespace gets its own VPC in the Default project, a private range carved from the Supervisor private VPC CIDR 172.21.0.0/16, and public addresses for load balancers from the 10.80.0.0/22 external block.

![New Namespace, step 2: name ns-app-dev with the default network settings](/images/lab/lab-S341.jpg)
*Step 2: the name `ns-app-dev`, default network settings kept.*

The last step is the zone. A Supervisor on a single cluster has one zone, `vg1-w01-az01`, which is also its management zone.

![New Namespace, step 3: zone vg1-w01-az01](/images/lab/lab-S342.jpg)
*Step 3: the zone `vg1-w01-az01`.*

The summary page shows the result. The namespace is Running and Active, with one storage policy, two VM classes and one content library already associated, and the whole build took about 13 minutes including the settings below.

![ns-app-dev summary: Running and Active, storage policy, VM classes and content library](/images/lab/lab-S353.jpg)
*The `ns-app-dev` summary right after creation.*

| Setting | Value |
|---|---|
| Supervisor and zone | `vg1-w01-sup01`, `vg1-w01-az01` |
| Network | Own VPC in the Default project, private range from 172.21.0.0/16 |
| VM classes | `best-effort-small` (2 vCPU, 4 GiB), `best-effort-medium` (2 vCPU, 8 GiB) |
| Limits | None set |
| Content library | Kubernetes Service Content Library |

### Permissions

The namespace was configured as `administrator@vsphere.local`, which holds the Supervisor Administrator role on the Supervisor and therefore covers every namespace. Granting a namespace role to the VCF SSO user from the earlier posts failed with a message that the user does not hold the privileges being granted. vCenter only lets a user grant privileges that the user holds, and the VCF SSO user's role in this lab does not include some Administrator privileges. For a lab, the local administrator is the simple answer. In a real environment, give the delegating role a set of privileges that is a subset of what the granting user holds.

## A storage policy that the cluster can satisfy

A namespace uses storage policies to decide where persistent volumes land and how they are protected. The Supervisor already uses `vSAN ESA Default Policy - RAID5` for its own disks, and the lab keeps that as the default policy for the namespace. A second policy, `sp-vks-gold`, shows how a team gets a named tier it can ask for.

The rules are vSAN rules only.

![Create VM Storage Policy, vSAN availability: no site disaster tolerance, 1 failure RAID-5](/images/lab/lab-S392.jpg)
*Availability with Auto-RAID off: no site disaster tolerance, and failures to tolerate set to 1 failure, RAID-5.*

RAID-5 is a deliberate choice for three hosts. RAID-6 needs more hosts than the w01 cluster has, so on a three-host cluster the policy that every disk can satisfy is RAID-5.

![Create VM Storage Policy, advanced rules: thin provisioning, checksum on, force provisioning off](/images/lab/lab-S394.jpg)
*Advanced rules: one stripe, IOPS limit 0, thin provisioning, checksum on, force provisioning off.*

![Create VM Storage Policy, review and finish: sp-vks-gold](/images/lab/lab-S396.jpg)
*Review and finish for `sp-vks-gold`. Encryption and data reduction stay at No preference, and the storage type is All flash.*

| Rule | Value |
|---|---|
| Auto-RAID | Off |
| Site disaster tolerance | None, standard cluster |
| Failures to tolerate | 1 failure, RAID-5 |
| Number of disk stripes | 1 |
| IOPS limit | 0 |
| Object space reservation | Thin provisioning |
| Checksum | On |
| Force provisioning | Off |
| Compatible datastore | `vg1-w01-cl01-vsan01` |

Adding the policy to the namespace is a single action on the Storage tab. The namespace then lists both policies, and each shows its capacity from the datastore.

![ns-app-dev storage: vSAN ESA Default Policy RAID5 and sp-vks-gold](/images/lab/lab-S398.jpg)
*The Storage tab of `ns-app-dev` with both policies.*

### From policy to StorageClass

Once a policy is assigned to a namespace, the Supervisor turns it into Kubernetes StorageClasses. Each policy produces two, one with immediate binding and one with late binding.

```bash
kubectl get storageclass | grep sp-vks-gold
```

```text
sp-vks-gold               csi.vsphere.vmware.com   Delete   Immediate              true
sp-vks-gold-latebinding   csi.vsphere.vmware.com   Delete   WaitForFirstConsumer   true
```

A VKS cluster created in the namespace receives the same classes without any action. In the lab they appeared inside the cluster in under 40 seconds, and a 1 GiB test claim on `sp-vks-gold` was Bound 15 seconds after it was applied.

![Supervisor and guest cluster StorageClasses, and PVC gold-test Bound on sp-vks-gold](/images/lab/lab-S400.jpg)
*The same two StorageClasses on the Supervisor and inside the guest cluster, and the test claim `gold-test` Bound on `sp-vks-gold`.*

## Kubernetes releases and the content library

Which Kubernetes versions a team can build is not a vSphere setting. It comes from VKS and from a content library the Supervisor is associated with.

The Supervisor runs the VKS service version 3.7.0, delivered with the 9.1.1 Supervisor as `svc-tkg`. It reconciled 13 packages, including Cluster API and the Cluster API provider for vSphere. Three Kubernetes releases are available, all READY and COMPATIBLE.

| Release | Notes |
|---|---|
| `v1.33.6+vmware.1-fips-vkr.2` | FIPS build |
| `v1.34.8+vmware.1-vkr.1` | Used for the lab cluster |
| `v1.35.5+vmware.1-vkr.1` | Newest |

The cluster shape is defined by a ClusterClass, `builtin-generic-v3.7.0`, in the namespace `vmware-system-vks-public`.

```bash
kubectl get kr
kubectl get clusterclass -A
```

![Kubernetes releases READY and COMPATIBLE, and the ClusterClasses in vmware-system-vks-public](/images/lab/lab-S357.jpg)
*The three releases and the ClusterClasses, listed from the Supervisor.*

The images behind the releases live in the Kubernetes Service Content Library, associated with the Supervisor under Configure, Kubernetes Service.

![Supervisor Configure, Kubernetes Service: one subscribed content library](/images/lab/lab-S356.jpg)
*The Kubernetes Service Content Library on the Supervisor, subscribed and 1.13 MB in size.*

That size is the point. The library is subscribed with the download set to happen when needed, so before the first cluster it holds only metadata. After the first cluster was built from `v1.34.8`, the same library held 8.38 GB.

![Kubernetes Service Content Library after the first cluster: 8.38 GB stored](/images/lab/lab-S377.jpg)
*The library after the first cluster. The image for the release in use was downloaded on demand.*

Plan for that first download in an environment with a slow link to the depot, because the first cluster of each release pays for it.

## Checklist for a namespace that is ready for a team

-> **Supervisor healthy**: all nodes Ready and no unhealthy pods before anything is layered on it.

-> **CLI on the jump host**: the plugin from the Supervisor address, so versions of `kubectl` and the plugin always match the Supervisor.

-> **Default network settings**: one VPC per namespace gives a private range and a path for load balancer VIPs without extra work.

-> **A policy every disk can satisfy**: RAID-5 on three hosts, with thin provisioning, instead of a policy that needs more hosts than exist.

-> **Policies assigned before clusters**: each assigned policy becomes StorageClasses that appear inside every cluster in the namespace.

-> **Permissions through the right account**: grant roles that are a subset of your own privileges, or use the account that already holds Supervisor Administrator.

## What's Next

Next in this series: a VKS cluster in about 8 minutes from the vSphere Client, then an application behind a load balancer with persistent storage.

## Further Reading (Official Broadcom Documentation)

- [Deploy a Supervisor with VPC Networking (VCF 9.1)](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsphere-supervisor-installation-and-configuration/supervisor-networking-with-virtual-private-clouds/deploy-a-supervisor-with-nsx-vpc.html)
- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
