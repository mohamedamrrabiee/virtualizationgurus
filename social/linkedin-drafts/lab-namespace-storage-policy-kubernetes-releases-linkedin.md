LinkedIn Draft: Namespaces, Storage Policies and Kubernetes Releases: Getting VKS Ready for a Team
Source post: content/posts/lab-namespace-storage-policy-kubernetes-releases.md
Image: social/linkedin-drafts/images/lab-namespace-storage-policy-kubernetes-releases-linkedin.jpg
Status: DRAFT, needs review before posting

A running Supervisor is not a platform yet. A team still needs a place to work, storage to claim and a Kubernetes version to build on.

On the VCF 9.1.1 lab, I prepared all three: a vSphere Namespace with its own VPC, a vSAN RAID-5 policy that became two StorageClasses, and a look at the Kubernetes releases that VKS offers.

→ The namespace wizard with default network settings gives every namespace its own VPC and a private range
→ RAID-5 is the policy a three-host cluster can satisfy, so that is the one worth naming and assigning
→ Each assigned policy turns into StorageClasses that appear inside every cluster in under 40 seconds
→ The Kubernetes Service library grew from 1.13 MB to 8.38 GB after the first cluster, because images download on demand

The Payoff:
Assign the policy before the cluster, and the cluster inherits it.

How do you hand a Supervisor over to an application team?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-namespace-storage-policy-kubernetes-releases/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-namespace-storage-policy-kubernetes-releases

#VCF9 #VMware #Broadcom #VKS #Kubernetes #vSAN #VirtualizationGurus #VMwareCommunity #vExpert
