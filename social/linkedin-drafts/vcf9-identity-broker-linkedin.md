# LinkedIn Draft -- VCF 9 Identity Broker: Retiring VMware Identity Manager
Source post: content/drafts/vcf9-identity-broker.md
Image: social/linkedin-drafts/images/vcf9-identity-broker-linkedin.jpg
Status: DRAFT -- needs review before posting
---

VMware Identity Manager is being retired in VCF 9. Here's what replaces it -- and how the migration actually works.

If your environment still authenticates through vIDM, VCF 9.1 introduces a fleet-native replacement: the Identity Broker. It's not just a rename -- it changes how you deploy identity, and Broadcom ships an actual migration path to get there.

-> Two deployment modes: Embedded, living inside the management domain vCenter, or Instance, a dedicated VCF management services component that can extend across multiple VCF Instances.
-> Migration path: export users, groups, and sync-setting comparisons from vIDM, then import into the Identity Broker with built-in validation -- no one-click in-place upgrade.
-> Component cutover: VCF Operations, VCF Automation, and NSX each get individually repointed to the new Identity Broker once it's configured.

The payoff: one identity source, natively built for the fleet, instead of a bolted-on tool inherited from the vSphere era.

If you're planning this migration, note that only Instance-mode Identity Broker is a supported target -- and local accounts with MFA aren't supported on the Broker side, so map your identity providers before you start.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #VMware #Broadcom #IdentityBroker #SSO #Security #VirtualizationGurus
