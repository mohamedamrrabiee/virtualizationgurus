LinkedIn Draft: Advanced Services for VCF: VPC, Load Balancing, and Network Observability
Source post: content/posts/vcf9-advanced-services.md
Image: social/linkedin-drafts/images/vcf9-advanced-services-linkedin.jpg
Status: DRAFT, needs review before posting

Planning to run application load balancing on the NSX load balancer in VCF 9? Check the entitlement before you finalize the design.

Starting with VCF 9.0, general-purpose load balancing is no longer part of the VCF entitlement. The built-in NSX load balancer stays for two use cases, and Broadcom recommends Avi for everything else. It is the kind of detail that is cheap to learn on paper and expensive to learn after go-live.

That is the middle of the final post in the VCF 9 series, which covers the three things that sit on top of the platform once workloads arrive.

→ VPC service profiles bundle DHCP, DNS forwarder and subnet profiles, so you define them once and reuse them across VPCs
→ NSX load balancing covers VCF infrastructure components and Layer 4 for Supervisor, while Avi adds GSLB, analytics, container ingress and WAF
→ VCF Operations for Networks turns IPFIX flow data into flow analytics, path topology and VPC migration planning

The Payoff:
A self-service network only stays supportable if you can see it, and a load balancing design only survives audit if you know what you are entitled to.

Which of the three do you usually design last, and which one has bitten you after go-live?

Full technical breakdown on the blog: https://virtualizationgurus.pages.dev/posts/vcf9-advanced-services/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-advanced-services

#VCF9 #VMware #Broadcom #NSX #LoadBalancing #VirtualizationGurus #VMwareCommunity
