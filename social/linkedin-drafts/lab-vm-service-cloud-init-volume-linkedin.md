LinkedIn Draft: VMs Next to Containers: VM Service with cloud-init, and a Volume from the Local Consumption Interface
Source post: content/posts/post24_lab-vm-service-cloud-init-volume.md
Image: social/linkedin-drafts/images/lab-vm-service-cloud-init-volume-linkedin.jpg
Status: DRAFT, needs review before posting

Containers and VMs can live in the same Supervisor namespace, on the same network, with the same storage policy.

On the VCF 9.1.1 lab, I deployed an Ubuntu 24.04 VM with VM Service and cloud-init, reached it through a load balancer address, and gave it a 2 GiB volume created in the Local Consumption Interface.

→ VM images come from a separate content library that you add to the namespace
→ cloud-init through a secret keeps the user-data visible, and only a public key goes into it
→ The VM sits in the same list as the VKS node VMs, on the same workload network
→ Attaching the volume needs a JSON patch append, because a merge patch tries to remove the boot disk

The Payoff:
One namespace, one network and one policy model for both kinds of workload.

Where do VMs still belong next to your containers?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vm-service-cloud-init-volume/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vm-service-cloud-init-volume

#VCF9 #VMware #Broadcom #VMService #Kubernetes #vSAN #VirtualizationGurus #VMwareCommunity #vExpert
