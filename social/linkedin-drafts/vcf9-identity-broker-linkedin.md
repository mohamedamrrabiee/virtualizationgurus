LinkedIn Draft: VCF 9 Identity Broker: Retiring VMware Identity Manager for Unified Fleet Authentication
Source post: content/posts/vcf9-identity-broker.md
Image: social/linkedin-drafts/images/vcf9-identity-broker-linkedin.jpg
Status: DRAFT, needs review before posting

Moving your Identity Broker from Embedded to Instance mode in VCF 9.1? It's not the one-click operation you'd assume. It's SFTP-based data transfer, a manual update to your external identity provider, and reconnecting several components by hand afterward.

That's one of two Identity Broker migrations VCF 9.1 supports. The other retires VMware Identity Manager, and it's tied to an architecture change most people read right past: "Appliance" mode didn't just get renamed to "Instance" mode between 9.0 and 9.1, it got consolidated into VCF Management Services, the new unified runtime.

→ Deployment modes: "Embedded" (lives in the management domain vCenter, a single point of failure) or a 3-node cluster. In 9.0 that cluster ran as its own standalone appliance. In 9.1 it's absorbed into VCF Management Services and renamed "Instance." Broadcom's own docs confirm the 9.0 appliance is "migrated directly" into that shared runtime, not just relabeled.
→ vIDM migration: export/import scripts, not an in-place upgrade. Instance mode is the only supported target. Local accounts, MFA, and OAuth clients don't carry over automatically.
→ Embedded to Instance migration: data suspends mid-transfer, your identity provider needs manual reconfiguration, and VCF Operations, HCX, and log management all need reconnecting by hand once it's done.

Two migrations, same fleet-native identity plane, neither one is actually hands-off.

Which one are you planning, and have you budgeted for the manual steps neither one skips?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-identity-broker/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-identity-broker

#VCF9 #VMware #Broadcom #IdentityBroker #SSO #VirtualizationGurus
