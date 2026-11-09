---
title: "A VKS Cluster in 8 Minutes from the vSphere Client, Then an App with a Load Balancer and Storage"
slug: "lab-vks-cluster-app-load-balancer-storage"
date: 2026-11-24
draft: true
tags: ["VCF", "VMware", "Lab", "VKS", "Kubernetes", "Load Balancer", "vSAN", "Persistent Volume"]
categories: ["VCF 9", "Lab Series"]
labPart: 23
cover:
  image: "/images/covers/lab-vks-cluster-app-load-balancer-storage.jpg"
  alt: "A VKS Cluster in 8 Minutes, Then an App with a Load Balancer and Storage"
  relative: false
description: "Creating a VKS cluster from the vSphere Client on a VCF 9.1.1 Supervisor, checking it from the inside, then publishing a web app through an NSX VPC load balancer and proving a persistent volume survives a pod being recreated."
---

## Overview

The namespace `ns-app-dev` is ready, with a network, two VM classes and two storage policies. This post puts a Kubernetes cluster in it. The cluster is built from the vSphere Client with the Cluster API wizard, and it was running about 8 minutes after the Deploy button.

Then the cluster does real work: a small web application is published on an address from the external block through a LoadBalancer service, reached from the jump host over the BGP route, and a persistent volume is checked by deleting the pod that uses it.

## Architecture at a glance

The path from the jump host to a pod, and the storage behind it.

<div class="diagram-embed">
  <object type="image/svg+xml" data="/images/diagrams/lab-vks-cluster-app-load-balancer-storage-glance.svg"></object>
</div>

## The cluster wizard

The wizard lives under the namespace: Resources, Kubernetes Service, then New Kubernetes Cluster. It offers a default configuration and a custom one. The custom path is the one that matters, because it shows the Kubernetes Resource YAML on the right and updates it as each field changes. The wizard is a front end for a Cluster API object, and the YAML is what gets applied.

![New Kubernetes Cluster, step 1: Cluster API, Custom Configuration, with the live YAML panel](/images/lab/lab-S365.jpg)
*Step 1: the configuration type. The YAML panel on the right starts with an empty `Cluster` object.*

### General settings

The cluster is named `vks-app-dev01`. The wizard picks the ClusterClass `builtin-generic-v3.7.0` and offers the Kubernetes releases from the previous post. The lab uses `v1.34.8`, the VM class `best-effort-medium` for all nodes, and the storage class `vsan-esa-default-policy-raid5` for node disks.

![General settings: ClusterClass v3.7.0, Kubernetes release v1.34.8, VM class best-effort-medium](/images/lab/lab-S370.jpg)
*General settings: ClusterClass, Kubernetes release, VM class and storage class.*

### Network

The cluster gets an automatic primary network in the namespace VPC, so its nodes take addresses from the private range of the namespace. Two ranges live inside the cluster and are never routed by NSX: the pod CIDR and the service CIDR.

| Setting | Value |
|---|---|
| Pod CIDR | 192.168.0.0/16 |
| Service CIDR | 10.97.0.0/16 |
| Service domain | `cluster.local` |

The service CIDR was changed on purpose. The wizard default is 10.96.0.0/12, a range that contains the Supervisor service CIDR 10.96.0.0/23, so the guest cluster uses 10.97.0.0/16 to keep the two distinct.

![Network: automatic primary network, pods 192.168.0.0/16, services 10.97.0.0/16](/images/lab/lab-S371.jpg)
*Network: the automatic primary network and the two cluster-internal ranges.*

### Control plane and node pool

One control plane node is enough for a lab. The worker pool is one pool, `vks-app-dev01-np-01`, with two replicas.

![Node pools: one pool vks-app-dev01-np-01 with 2 replicas](/images/lab/lab-S374.jpg)
*One node pool with two replicas.*

### Review and deploy

The review page shows the final YAML. This is the part worth keeping, because the same object can be applied with `kubectl` the next time.

![Review and confirm, with the final cluster YAML](/images/lab/lab-S375.jpg)
*Review and confirm. The YAML on the right is the cluster definition that Deploy applies.*

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: vks-app-dev01
  namespace: ns-app-dev
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["192.168.0.0/16"]
    services:
      cidrBlocks: ["10.97.0.0/16"]
    serviceDomain: cluster.local
  topology:
    class: builtin-generic-v3.7.0
    classNamespace: vmware-system-vks-public
    version: v1.34.8+vmware.1-vkr.1
    controlPlane:
      replicas: 1
    workers:
      machineDeployments:
      - class: node-pool
        name: vks-app-dev01-np-01
        replicas: 2
    variables:
    - name: vmClass
      value: best-effort-medium
    - name: storageClass
      value: vsan-esa-default-policy-raid5
```

The wizard showed a CNI selector for release `v1.35.5` but not for `v1.34.8`. Without a selection the cluster uses Antrea, the Supervisor default, which is what this lab runs.

## Eight minutes

Deploy was clicked at 12:32 and the cluster reported Available at 12:40. The build can be followed from the Supervisor with one command.

```bash
watch -n 15 'kubectl get cluster,machines -n ns-app-dev; kubectl get vm -n ns-app-dev -o wide'
```

![Cluster AVAILABLE True with 1 control plane and 2 workers Running, VMs at 172.21.0.2 to .4](/images/lab/lab-S380.jpg)
*The cluster is Available: one control plane and two workers, all Running on `v1.34.8`, with VMs at 172.21.0.2 to 172.21.0.4.*

Each node is a VM on the Supervisor, so `kubectl get vm` shows them with their image, class and address. The control plane was the oldest at about 8 minutes and the two workers at about 4.

The content library tells the other half of the story. The first cluster of a release downloads its image on demand, which is why the library in the previous post grew from 1.13 MB to 8.38 GB.

## Inside the cluster

The Supervisor publishes the cluster's admin kubeconfig as a secret in the namespace. It is a credential with full rights, so keep it on a host you control and remove it when the lab ends. For people, prefer a short-lived login that names the namespace and cluster.

```bash
kubectl vsphere login --server=10.80.0.6 --vsphere-username administrator@vsphere.local \
  --tanzu-kubernetes-cluster-namespace ns-app-dev --tanzu-kubernetes-cluster-name vks-app-dev01 \
  --insecure-skip-tls-verify
```

From inside, the checks are the usual three: nodes, anything not Running, and the system pods.

```bash
kubectl get nodes -o wide
kubectl get pods -A | grep -vE "Running|Completed"
kubectl get pods -n kube-system | grep -E "antrea|coredns"
```

![Inside vks-app-dev01: 3 nodes Ready on v1.34.8 Photon 5, Antrea controller and 3 agents, CoreDNS](/images/lab/lab-S381.jpg)
*Three nodes Ready on Kubernetes `v1.34.8` with Photon OS 5, no pod outside Running, one Antrea controller, three Antrea agents and two CoreDNS pods.*

## An app behind a load balancer

The application is a small nginx deployment with two replicas and a Service of type LoadBalancer. The image is `nginxinc/nginx-unprivileged`, which listens on 8080 and runs as a non-root user, so it satisfies the restricted Pod Security Standard without any exemption.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: web-demo
spec:
  replicas: 2
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      securityContext:
        runAsNonRoot: true
        seccompProfile: {type: RuntimeDefault}
      containers:
      - name: nginx
        image: nginxinc/nginx-unprivileged:stable
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          capabilities: {drop: ["ALL"]}
---
apiVersion: v1
kind: Service
metadata:
  name: web-lb
  namespace: web-demo
spec:
  type: LoadBalancer
  selector: {app: web}
  ports:
  - port: 80
    targetPort: 8080
```

Applying it with the guest kubeconfig creates both objects, and the service gets its external address within seconds.

![web-demo: deployment, two pods on two workers, LoadBalancer service with external IP 10.80.0.10](/images/lab/lab-S383.jpg)
*Two `web` pods Running and the `web-lb` service with the external address `10.80.0.10`.*

The address comes from the external IP block 10.80.0.0/22, the same block that carries the Supervisor VIPs. It is the one range the lab router learns over BGP, so a VIP is reachable from outside the VPC without any static route.

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://10.80.0.10
ip route get 10.80.0.10
```

![Jump host: HTTP 200 from 10.80.0.10 over the BGP route](/images/lab/lab-S382.jpg)
*From the jump host, `10.80.0.10` answers HTTP 200 and the route goes through the lab router, `10.20.10.1`.*

The path the request takes is worth naming, because each hop is something built earlier in the series:

-> **Jump host to lab router**: an ordinary route to the gateway of VLAN 3321.

-> **Lab router to Tier-0**: the router learned the `/32` for the VIP over eBGP from the Edge nodes.

-> **Tier-0 to the VPC load balancer**: the VIP belongs to a load balancer in the namespace VPC, reached through the transit gateway.

-> **Load balancer to a node, then to a pod**: the load balancer targets the two worker nodes on one NodePort, and the Kubernetes service on the node sends the request to one of the two `web` pods.

The Supervisor shows the load balancer side of this. Each `LoadBalancer` service in the guest cluster is mirrored in the namespace as a service of the same type, and its endpoints are the worker nodes.

```bash
kubectl get svc,endpoints -n ns-app-dev
```

```text
NAME                                          TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
service/vks-app-dev01                         LoadBalancer   10.96.0.164   10.80.0.9     6443/TCP  19d
service/vks-app-dev01-f9580c8a37280d0fc8555   LoadBalancer   10.96.0.99    10.80.0.10    80/TCP    19d

NAME                                            ENDPOINTS                           AGE
endpoints/vks-app-dev01                         172.21.0.2:6443                     19d
endpoints/vks-app-dev01-f9580c8a37280d0fc8555   172.21.0.3:31109,172.21.0.4:31109   19d
```

The address `10.80.0.10` is the `web-lb` VIP from earlier, and its endpoints are the two workers, `172.21.0.3` and `172.21.0.4`, on NodePort 31109. The API VIP `10.80.0.9` points at the control plane node `172.21.0.2` on 6443.

## A persistent volume that survives the pod

The second half of the test is storage. A claim `web-data` of 1 GiB on the class `vsan-esa-default-policy-raid5` was created in the guest cluster and Bound within seconds. A small pod mounts it on `/data`, writes a timestamp and is deleted. A new pod that mounts the same claim reads the same line.

```bash
kubectl --kubeconfig $KC -n web-demo exec data-test -- sh -c 'echo "written $(date -u)" > /data/proof.txt; df -h /data'
kubectl --kubeconfig $KC -n web-demo delete pod data-test
kubectl --kubeconfig $KC apply -f vks07-datapod.yaml
kubectl --kubeconfig $KC -n web-demo exec data-test -- cat /data/proof.txt
```

![Persistence test: /dev/sdb of 1 GB on /data, and the same timestamp after the pod was recreated](/images/lab/lab-S385.jpg)
*The claim is Bound, the pod sees `/dev/sdb` on `/data`, and the timestamp written before the delete is read back from the new pod.*

The disk the pod sees is a vSAN object attached to the worker VM, created by the vSphere CSI driver on behalf of the claim. It stays on the datastore when the pod goes away, which is the behavior a stateful workload needs.

## What to take from this

-> **The wizard is a Cluster API front end**: the YAML panel shows the object, so the first cluster doubles as a template for the CLI.

-> **Change the service CIDR default**: keep cluster-internal ranges distinct from the Supervisor ranges, even though they are not routed.

-> **Plan for the first download**: the first cluster of a release pulls its image, so it takes longer and moves several GB.

-> **Use unprivileged images**: an image that runs as non-root and drops its capabilities satisfies the restricted Pod Security Standard without exemptions.

-> **A LoadBalancer service is a BGP route**: the VIP comes from the external block and the router learns it, so the lab needs no static routes.

## What's Next

Next in this series: VMs next to containers, using VM Service with cloud-init and a volume from the Local Consumption Interface.

## Further Reading (Official Broadcom Documentation)

- [Deploy a Supervisor with VPC Networking (VCF 9.1)](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1/vsphere-supervisor-installation-and-configuration/supervisor-networking-with-virtual-private-clouds/deploy-a-supervisor-with-nsx-vpc.html)
- [VCF 9.1 documentation on TechDocs](https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-1.html)

<div style="text-align:center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(56,189,248,0.2);">
<img src="/images/logo.svg" alt="Virtualization Gurus" style="height:56px; width:auto; opacity:0.85;" />
</div>
