LinkedIn Draft: Activating a Supervisor on VPC Networking: Design Choices, the Wizard and the First 50 Minutes
Source post: content/posts/post21_lab-supervisor-vpc-networking.md
Image: social/linkedin-drafts/images/lab-supervisor-vpc-networking-linkedin.jpg
Status: DRAFT, needs review before posting

A Supervisor with HA needs five consecutive management IPs, and one of them stays free on purpose.

I activated a Supervisor on VPC networking in a nested VCF 9.1.1 lab. From Finish to Running took about 52 minutes.

→ Three control plane VMs, a floating IP on the etcd leader and one spare for replacement and upgrades
→ RAID-5 storage policy, because RAID-6 needs more hosts than the 3 in this cluster
→ Default VPC CIDR and Service CIDR changed so nothing overlapped
→ Verified with six Ready nodes and an HTTP 200 from the API VIP through BGP

The Payoff:
Settle the IP plan and the storage policy first, and the wizard is the easy part.

What was the longest wait you have had on a Kubernetes activation?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-supervisor-vpc-networking/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-supervisor-vpc-networking

#VCF9 #VMware #Broadcom #Kubernetes #VKS #VirtualizationGurus #VMwareCommunity #vExpert
