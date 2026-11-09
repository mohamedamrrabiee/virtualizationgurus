LinkedIn Draft: Micro-segmentation Between VPCs with the Distributed Firewall, Proven with Traceflow
Source post: content/posts/post25_lab-dfw-vpc-tag-microsegmentation.md
Image: social/linkedin-drafts/images/lab-dfw-vpc-tag-microsegmentation-linkedin.jpg
Status: DRAFT, needs review before posting

Why does a Distributed Firewall rule on a VM tag never match traffic from another VPC?

In a VCF 9.1.1 lab I wrote a five-rule policy for an app VPC and proved every rule with Traceflow. Two of the rules came from mistakes in the first design.

→ Traffic from the dev VPC arrives through SNAT, so the app VPC sees 10.80.0.1, not the VM
→ A deny into the private tier did not stop traffic the private tier started, until rule five
→ vCenter tags never populate NSX groups, so tag the VM in NSX
→ A tag added live flipped a Traceflow from Delivered to Dropped with no rule change

The Payoff:
Traceflow gives you the rule ID, so every rule can be shown to work.

How do you prove a firewall policy does what you intended?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-dfw-vpc-tag-microsegmentation/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-dfw-vpc-tag-microsegmentation

#VCF9 #VMware #Broadcom #NSX #DFW #VirtualizationGurus #VMwareCommunity #vExpert
