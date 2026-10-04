LinkedIn Draft: Bundle Management: Online vs Offline/Air-Gapped
Source post: content/posts/vcf9-bundle-management.md
Image: social/linkedin-drafts/images/vcf9-bundle-management-linkedin.jpg
Status: DRAFT, needs review before posting

"Air-gapped" isn't one scenario in VCF 9.1, it's two, and treating them as the same thing is exactly why offline upgrade prechecks confuse people. Broadcom's software depot architecture defines three connection modes, not two, and the two covering no-internet environments are genuinely different operational models.

→ Connected: internet access, direct or proxy. Register with an activation code, and the depot pulls everything on its own. No manual delete option, it manages binaries internally.
→ Offline Depot: no internet, but you run a dedicated server. The software depot doesn't download anything itself, it proxies every request to that server. HTTPS on that server means a real prerequisite: pull its TLS cert, import it into SDDC Manager's certificate store, restart the lifecycle service, before the mode even connects.
→ Disconnected: no internet and no depot server at all. You download binaries on any internet-connected machine, then manually upload them straight into the depot. This is the only mode with a cleanup command to delete what you uploaded.

The real distinction between the last two: Offline Depot is a standing server you maintain, Disconnected is a manual action you repeat every time you need new binaries. Configure one expecting the other's behavior, and your upgrade planning starts from a wrong assumption before you've downloaded a single bundle.

The Payoff:
"We're air-gapped" isn't a configuration, it's a question you still have to answer, standing depot server or manual upload every cycle.

Which one are you actually running, and does your upgrade runbook assume the other one?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-bundle-management/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-bundle-management

#VCF9 #VMware #Broadcom #LifecycleManagement #AirGapped #VirtualizationGurus #VMwareCommunity
