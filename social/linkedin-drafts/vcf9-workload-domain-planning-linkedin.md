# LinkedIn Draft — VCF 9 Workload Domain Planning and Deployment
Source post: content/drafts/vcf9-workload-domain-planning.md
Image: social/linkedin-drafts/images/vcf9-workload-domain-planning-linkedin.jpg
Status: DRAFT — needs review before posting

---

Your VCF 9 management domain is up. Now what actually runs your applications?

That's the workload domain, a self-contained unit of compute, storage, and networking that your teams provision apps into. VCF 9 gives you more decisions to make here than you might expect, and getting them right early avoids expensive redesigns later.

Three decisions shape every workload domain:
→ Deployment model — dedicated NSX per domain vs. shared NSX across domains, depending on isolation and scale needs.
→ Storage choice — vSAN ESA as the default, with guidance on when OSA or external storage still make sense.
→ Networking readiness — designing for VPC consumption from day one instead of retrofitting it later.

The payoff: workload domains that scale cleanly as you add capacity, without re-architecting networking or storage down the line.

If you're planning your first workload domain, validate your design against the official Broadcom documentation before you deploy. VCF 9 changed enough from 5.x that old runbooks don't fully apply.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #VMware #Broadcom #CloudInfrastructure #PrivateCloud #VirtualizationGurus
