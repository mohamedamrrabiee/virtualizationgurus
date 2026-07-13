# LinkedIn Draft — VCF 9 Lifecycle Management with VCF Operations
Source post: content/posts/vcf9-lifecycle-management.md
Image: social/linkedin-drafts/images/vcf9-lifecycle-management-linkedin.jpg
Status: DRAFT — needs review before posting

---

SDDC Manager in VCF 5.x already gave us BOM-driven upgrades — one source of truth for compatible ESX, vCenter, NSX, and vSAN versions. What it didn't give us was a fleet-wide view: every instance orchestrated its own upgrades independently.

VCF 9 changes that. The SDDC Manager UI is deprecated, and its lifecycle management workflows now live inside VCF Operations Fleet Management — the same BOM-driven discipline, now spanning every domain across every VCF instance you run, from one place.

The upgrade flow now runs in five stages:
→ Plan — VCF Operations checks Broadcom Customer Connect (or a local depot) for available bundles.
→ Stage — update images are downloaded and validated against every component in the domain.
→ Pre-check — hardware compatibility, health, and license checks run before anything changes.
→ Upgrade — ESX, vCenter, NSX, and vSAN are updated in the correct sequence automatically.
→ Post-check — health validation confirms every component landed on the expected version.

The payoff: the same disciplined, BOM-driven upgrade process you already trust — now scaled across your entire fleet instead of one instance at a time.

If you're managing more than one VCF instance, this is the post that shows what actually changes for you.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-lifecycle-management/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-lifecycle-management

#VCF9 #VMware #Broadcom #CloudInfrastructure #PrivateCloud #VirtualizationGurus
