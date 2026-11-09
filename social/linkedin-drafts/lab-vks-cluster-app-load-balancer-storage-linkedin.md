LinkedIn Draft: A VKS Cluster in 8 Minutes from the vSphere Client, Then an App with a Load Balancer and Storage
Source post: content/posts/post23_lab-vks-cluster-app-load-balancer-storage.md
Image: social/linkedin-drafts/images/lab-vks-cluster-app-load-balancer-storage-linkedin.jpg
Status: DRAFT, needs review before posting

A Kubernetes cluster that is Available 8 minutes after clicking Deploy, from the vSphere Client.

On the VCF 9.1.1 lab, I built a VKS cluster with one control plane and two workers, published an nginx app on a LoadBalancer address, and proved a persistent volume survives a pod being deleted.

→ The cluster wizard is a Cluster API front end, and the YAML panel doubles as a template for the CLI
→ The service CIDR default overlaps the Supervisor range, so the lab uses 10.97.0.0/16 inside the cluster
→ The VIP comes from the external block, and the lab router learns it over BGP, so no static routes
→ A 1Gi claim kept its data after the pod was recreated, with the same timestamp read back

The Payoff:
A LoadBalancer service on VCF is just a BGP route.

What is the first thing you test on a new Kubernetes cluster?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vks-cluster-app-load-balancer-storage/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vks-cluster-app-load-balancer-storage

#VCF9 #VMware #Broadcom #VKS #Kubernetes #NSX #VirtualizationGurus #VMwareCommunity #vExpert
