# LinkedIn Draft — VCF 9 NSX VPC Deep Dive
Source post: content/drafts/vcf9-nsx-vpc-deep-dive.md
Image: social/linkedin-drafts/images/vcf9-nsx-vpc-deep-dive-linkedin.jpg
Status: DRAFT — needs review before posting

---

Multi-tenant networking in VCF 9 doesn't look like NSX networking in 5.x anymore.

Instead of manually building overlay segments and Tier-1 gateways for every tenant, NSX 9.0 introduces Virtual Private Clouds (VPCs), a self-service networking abstraction that's isolated by default and consumable straight from vCenter, VCF Automation, or vSphere Supervisor.

Three pieces make VPCs work:
→ VPC — private and public subnets, isolated from other VPCs unless explicitly connected.
→ Transit Gateway — centralized or distributed routing hub for inter-VPC and external traffic.
→ Connectivity and Service Profiles — pre-defined patterns so app teams pick a profile instead of designing topology.

The payoff: application teams request networking like a cloud service, while platform teams keep centralized control over routing and security.

If you're coming from a 5.x background, this is the shift to internalize: stop designing individual overlay segments, start designing VPC and Transit Gateway profiles that teams can self-serve from.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #NSX #VMware #Broadcom #PrivateCloud #VirtualizationGurus
