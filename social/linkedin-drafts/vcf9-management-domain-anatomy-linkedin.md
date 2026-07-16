# LinkedIn Draft — VCF 9 Management Domain Anatomy
Source post: content/posts/vcf9-management-domain-anatomy.md
Image: social/linkedin-drafts/images/vcf9-management-domain-anatomy-linkedin.jpg
Status: DRAFT — needs review before posting

---

SDDC Manager is still in every VCF 9 management domain — but it's not the component doing the Day-2 automation anymore. That's a separate appliance now.

Every VCF Instance starts with a management domain, and it never stops carrying more weight than a normal workload domain — starting with two components that are easy to conflate.

What's actually running inside a VCF 9 management domain:
→ SDDC Manager — still installed, still listed as a component, but its UI and lifecycle workflows are deprecated as of 9.0. The automation now comes from a separate fleet management appliance that extends VCF Operations, not from SDDC Manager itself.
→ A dedicated License Server — as of VCF 9.1, licensing runs in its own appliance instead of inside VCF Operations.
→ Fleet-level components only in the first Instance — VCF Operations and VCF Automation live in whichever management domain deployed first; every other management domain in the fleet carries instance-level components only.

The payoff: knowing which component actually does what saves you from troubleshooting SDDC Manager for a Day-2 automation issue that's really happening in VCF Operations Fleet Management.

If you're still describing SDDC Manager as "where the automation happens" in VCF 9, that mental model is a version behind — where do you actually point troubleshooting first?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-management-domain-anatomy/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-management-domain-anatomy

#VCF9 #VMware #Broadcom #SDDCManager #CloudInfrastructure #VirtualizationGurus
