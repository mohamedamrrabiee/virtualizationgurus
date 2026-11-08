LinkedIn Draft: Distributed Firewall for Kubernetes Workloads: Pods and VMs in the Namespace VPC
Source post: content/posts/lab-dfw-namespace-vpc-kubernetes-labels.md
Image: social/linkedin-drafts/images/lab-dfw-namespace-vpc-kubernetes-labels-linkedin.jpg
Status: DRAFT, needs review before posting

You do not tag Kubernetes workloads in NSX. You label them in Kubernetes.

In a Supervisor namespace VPC on VCF 9.1.1, I separated a VM Service VM from three vSphere Pods with two Distributed Firewall rules, and proved both directions with Traceflow.

→ Kubernetes labels become NSX tags on the workload's subnet port, with the label key as the scope
→ Groups use the Subnet Port member type and resolve to 3 pods and 1 VM
→ Two one-way rules, because one rule with both groups on both sides would also break pod-to-pod traffic
→ Each drop happens at the source vNIC, with the rule ID in the Traceflow result

The Payoff:
Label the workload once, and the firewall follows it.

How are you segmenting VMs and containers on the same platform?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-dfw-namespace-vpc-kubernetes-labels/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-dfw-namespace-vpc-kubernetes-labels

#VCF9 #VMware #Broadcom #NSX #Kubernetes #VirtualizationGurus #VMwareCommunity #vExpert
