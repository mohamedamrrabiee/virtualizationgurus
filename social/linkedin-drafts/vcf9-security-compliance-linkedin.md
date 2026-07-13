# LinkedIn Draft — VCF 9 Security and Compliance
Source post: content/posts/vcf9-security-compliance.md
Image: social/linkedin-drafts/images/vcf9-security-compliance-linkedin.jpg
Status: DRAFT — needs review before posting

---

In VCF 9, the Gateway Firewall is off by default on new gateways — but only if you're deploying fresh. Upgrade an existing VCF instance to 9.0, and it stays on by default for new gateways. Same version, two different postures, one easy audit finding if you don't know which path your environment took.

The change is deliberate: NSX 9.0's VPC model handles tenant isolation and the Distributed Firewall handles east-west micro-segmentation, so the Gateway Firewall's old perimeter role matters less by default — and Broadcom folded the whole firewall and threat-prevention stack into a new brand, VMware vDefend, along the way.

What actually changed in VCF 9 security, worth knowing before your next design review or interview:
→ Gateway Firewall — off by default for greenfield deployments (the Auto-Activate Gateway Firewall on New Gateways toggle); on by default for new gateways on an environment upgraded from an earlier VCF release.
→ DFW / ATP rebrand — "NSX Distributed Firewall" and "NSX ATP" are now the vDefend Distributed Firewall and vDefend Advanced Threat Prevention, with IDS/IPS and Malware Prevention sitting under separate license tiers.
→ VCF Health — Skyline Advisor and Skyline Health Diagnostics findings are now native to VCF Operations, re-checked on a 4-hour cycle, including certificate expiry.

The payoff: fewer moving parts to license and monitor separately — but only if you actually verify which default your environment landed on.

If you inherited a VCF 9 environment, do you actually know whether it came from a greenfield build or an in-place upgrade? The Gateway Firewall default depends on it.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-security-compliance/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-security-compliance

#VCF9 #VMware #Broadcom #NSX #CloudSecurity #VirtualizationGurus
