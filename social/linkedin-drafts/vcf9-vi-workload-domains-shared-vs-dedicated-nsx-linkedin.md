# LinkedIn Draft — VI Workload Domains: Shared vs Dedicated NSX
Source post: content/posts/vcf9-vi-workload-domains-shared-vs-dedicated-nsx.md
Image: social/linkedin-drafts/images/vcf9-vi-workload-domains-shared-vs-dedicated-nsx-linkedin.jpg
Status: DRAFT — needs review before posting

---

Shared or dedicated NSX Manager? It's a per-domain decision in VCF 9.1, and most fleets end up running both.

Every VI workload domain wizard asks this on the Networking page: join an existing NSX Manager, or deploy a new one. It looks like a simple toggle, but it quietly decides your footprint, blast radius, and upgrade path for that domain's entire lifecycle.

What actually changes depending on which button you click:
→ Shared NSX means lower footprint and one less HA cluster to maintain — but version compatibility can pin a domain to an older vCenter's feature set until every attached host catches up
→ Dedicated NSX buys independent availability, scaling, and lifecycle — at the cost of standing up and patching another three-node HA cluster
→ VCF 9.1 now lets a domain share the management domain's own NSX Manager, cutting out the need for a separate dedicated shared instance in some fleets

The payoff: matching the tradeoff to the domain instead of defaulting to one topology fleet-wide keeps you from overprovisioning NSX Manager clusters or from quietly running out of room on a shared one.

Before you choose shared for your next domain, do you actually know how many more vCenters that NSX Manager can take on before it's full?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-vi-workload-domains-shared-vs-dedicated-nsx/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-vi-workload-domains-shared-vs-dedicated-nsx

#VCF9 #VMware #Broadcom #NSX #WorkloadDomains #VirtualizationGurus
