# LinkedIn Draft — VCF 9 Lifecycle Management with VCF Operations
Source post: content/drafts/vcf9-lifecycle-management.md
Image: social/linkedin-drafts/images/vcf9-lifecycle-management-linkedin.jpg
Status: DRAFT — needs review before posting

---

In VCF 5.x, upgrading meant coordinating ESX, vCenter, NSX, and vSAN separately, each with its own compatibility matrix.

VCF 9 replaces that with one orchestrated workflow through VCF Operations, the single management plane that took over from SDDC Manager.

The upgrade flow now runs in five stages:
→ Plan — VCF Operations checks Broadcom Customer Connect (or a local depot) for available bundles.
→ Stage — update images are downloaded and validated against every component in the domain.
→ Pre-check — hardware compatibility, health, and license checks run before anything changes.
→ Upgrade — ESX, vCenter, NSX, and vSAN are updated in the correct sequence automatically.
→ Post-check — health validation confirms every component landed on the expected version.

The payoff: one workflow, one dashboard, and far less risk of upgrading components out of order.

If your team still tracks upgrade order in a spreadsheet, this is the post that shows what VCF Operations now does for you automatically.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #VMware #Broadcom #CloudInfrastructure #PrivateCloud #VirtualizationGurus
