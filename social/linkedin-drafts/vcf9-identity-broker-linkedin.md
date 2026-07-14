# LinkedIn Draft — VCF 9 Identity Broker
Source post: content/posts/vcf9-identity-broker.md
Image: social/linkedin-drafts/images/vcf9-identity-broker-linkedin.jpg
Status: DRAFT — needs review before posting

---

VMware Identity Manager isn't quite "retired" in VCF 9 — it's just no longer the identity broker of record. And if you're planning the migration, there's a naming trap worth knowing about first: Broadcom renamed one of the two Identity Broker deployment modes between 9.0 and 9.1.

In VCF 9.1, vIDM hands fleet single sign-on off to the new Identity Broker component — but Broadcom doesn't force an immediate cutover; existing vIDM instances can keep serving as an auth source (for VCF Automation, for example) while you migrate the rest of the fleet on your own schedule.

What's actually worth knowing before you plan this migration:
→ Deployment modes — "Embedded" (inside the management domain vCenter, a single point of failure) or a standalone three-node cluster mode that Broadcom called "Appliance" in the 9.0 docs and renamed to "Instance" in 9.1 — same component, different name depending on which doc you're reading.
→ Migration path — export/import scripts, not an in-place upgrade, and only Instance-mode Identity Broker is a supported migration target; Embedded doesn't qualify.
→ Real limitations — local accounts and MFA aren't supported on the Broker at all, and OAuth clients don't migrate automatically; you regenerate them by hand.

The payoff: a fleet-native identity plane that scales past a single vCenter — but only if you plan around what doesn't carry over automatically.

If you're scoping a vIDM-to-Identity-Broker migration, have you confirmed which deployment mode you're actually targeting — and whether the doc you're reading calls it "Appliance" or "Instance"?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-identity-broker/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-identity-broker

#VCF9 #VMware #Broadcom #IdentityBroker #SSO #VirtualizationGurus
