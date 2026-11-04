LinkedIn Draft: Proving VPC Isolation with PowerCLI Test VMs and a Ping Matrix
Source post: content/posts/lab-vpc-isolation-powercli-test-vms.md
Image: social/linkedin-drafts/images/lab-vpc-isolation-powercli-test-vms-linkedin.jpg
Status: DRAFT, needs review before posting

How do you prove two VPCs are really isolated? Not with a diagram.

I deployed five Photon OS test VMs with PowerCLI across private and public subnets in two VPCs, then pinged every VM from every other VM and from the lab router.

→ The pattern of replies shows what the design does, not what it was meant to do
→ Private subnets stay inside their VPC and leave through SNAT
→ Public subnets answer from outside because the external block is advertised over BGP
→ Static addressing and open ICMP had to be set before the results meant anything

The Payoff:
A ping matrix takes minutes to run and settles the isolation question with evidence.

Which test do you run first after building a network design?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vpc-isolation-powercli-test-vms/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vpc-isolation-powercli-test-vms

#VCF9 #VMware #Broadcom #NSX #PowerCLI #VirtualizationGurus #VMwareCommunity #vExpert
