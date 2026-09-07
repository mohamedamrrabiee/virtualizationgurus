LinkedIn Draft (Option 2): Bundle Management: Online vs Offline/Air-Gapped
Source post: content/posts/vcf9-bundle-management.md
Image: social/linkedin-drafts/images/vcf9-bundle-management-linkedin.jpg
Status: DRAFT, needs review before posting

Configured your offline depot, but binaries still won't download? Check whether your depot server runs HTTPS before you file a support ticket.

VCF 9.1's software depot won't trust that connection automatically. You have to SSH into SDDC Manager, pull the depot server's TLS certificate with openssl, import it into the local Java certificate store with keytool, and restart the lifecycle service, all before the mode even connects. Skip that step and every symptom looks like a network problem instead of a trust problem.

That's one prerequisite inside a bigger distinction worth knowing: "air-gapped" isn't one mode in VCF 9.1, it's two.

→ Offline Depot assumes a standing server you own and maintain. The software depot proxies every request to it continuously, nothing downloads locally.
→ Disconnected assumes no server at all. You run the VCF Download Tool on any internet-connected machine, then manually upload binaries straight into the depot, one cycle at a time.
→ Only Disconnected has a cleanup command to delete what you uploaded. Connected and Offline Depot both cache internally with no delete option, that's permanent until you rebuild the depot.

The Payoff:
Configuring Offline Depot mode while actually running a Disconnected workflow isn't a small mismatch, it's why your prechecks keep failing for reasons that don't match what you're troubleshooting.

Before your next air-gapped upgrade, have you confirmed which of the two you're actually running, or are you assuming "no internet" means one thing?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-bundle-management/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-bundle-management

#VCF9 #VMware #Broadcom #LifecycleManagement #AirGapped #VirtualizationGurus #VMwareCommunity
