# LinkedIn Draft — VI Workload Domains: Shared vs Dedicated NSX
Source post: content/drafts/vcf9-vi-workload-domains-shared-vs-dedicated-nsx.md
Image: social/linkedin-drafts/images/vcf9-vi-workload-domains-shared-vs-dedicated-nsx-linkedin.jpg
Status: DRAFT — needs review before posting

---

Shared or dedicated NSX Manager? It's a per-domain decision in VCF 9.1, and most fleets end up running both.

Every VI workload domain wizard asks this on the Networking page: join an existing NSX Manager, or deploy a new one. It looks like a simple toggle, but it quietly decides your footprint, blast radius, and upgrade path for that domain's entire lifecycle.

→ Shared NSX means lower footprint and one less HA cluster to maintain -- but version compatibility can pin a domain to an older vCenter's feature set until every attached host catches up
→ Dedicated NSX buys independent availability, scaling, and lifecycle -- at the cost of standing up and patching another three-node HA cluster
→ VCF 9.1 now lets a domain share the management domain's own NSX Manager, removing the need for a separate dedicated shared instance in some fleets

At 40 workload domains per VCF instance, this choice compounds fast -- decide it deliberately per domain, not by default.

Practical tip: before choosing shared, check the NSX-to-vCenter version compatibility table -- a mismatch pins your new domain to an older feature set until every host is upgraded to match.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #VMware #Broadcom #CloudInfrastructure #PrivateCloud #VirtualizationGurus
