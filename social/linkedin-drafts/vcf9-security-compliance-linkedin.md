# LinkedIn Draft — VCF 9 Security and Compliance
Source post: content/drafts/vcf9-security-compliance.md
Image: social/linkedin-drafts/images/vcf9-security-compliance-linkedin.jpg
Status: DRAFT — needs review before posting

---

Zero-trust in VCF 9 isn't a feature you turn on. It's how the platform is built by default.

Security is layered from the hypervisor up to the network edge, and VCF 9 changes some defaults that are worth knowing before you deploy.

Three layers worth understanding:
→ Distributed Firewall (DFW) — the primary control for east-west traffic, enforced at the hypervisor level on every VM.
→ VPC isolation — VPCs can't reach each other unless you explicitly connect them through a Transit Gateway.
→ Gateway Firewall — now disabled by default on new Tier-0/Tier-1 gateways, enabled only when perimeter inspection is actually needed.

The payoff: isolation-by-default architecture that's harder to misconfigure into an open network.

If you're hardening a new VCF 9 environment, start by confirming which of these defaults your team has intentionally changed, and which were simply left as-is.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #NSX #Security #VMware #Broadcom #VirtualizationGurus
