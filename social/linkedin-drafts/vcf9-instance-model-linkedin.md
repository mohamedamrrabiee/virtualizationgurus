# LinkedIn Draft — VCF 9 Instance Model
Source post: content/posts/vcf9-instance-model.md
Image: social/linkedin-drafts/images/vcf9-instance-model-linkedin.jpg
Status: DRAFT — needs review before posting

---

Edge locations in VCF 9 aren't just "a smaller HQ" — Broadcom gives them their own named deployment model, with hard numeric minimums you need to hit before you qualify.

Once you've internalized "one Fleet across every site," the real design question is how HQ, DR, and edge sites actually map onto Broadcom's supported topologies — and edge turns out to be more prescriptive than most architects expect.

What actually governs multi-site VCF 9 design:
→ HQ and DR — four fleet deployment designs, each building on the last: Basic (single site), Site HA (stretched across two zones), Disaster Recovery (a second Instance in another region via VMware Live Recovery), and Fault Domains + DR (both combined).
→ Edge — its own named model (VCF Edge, formerly Remote Clusters), with real minimums: at least 10 sites, 8 CPU cores per host, a 256-core cap per site, and hosts physically separated from your data center workloads.
→ Sovereign cloud — not a separate topology at all; it's one of the four designs above with in-country data residency and recovery controls layered on top.

The payoff: every one of these — HQ, DR, edge, sovereign — still reports into a single VCF fleet: one control plane, one inventory, regardless of how many sites you're running.

If you're scoping an edge rollout, have you actually checked it against the 10-site minimum and the 256-core-per-site ceiling — or assumed it's just "HQ, but smaller"?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-instance-model/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-instance-model

#VCF9 #VMware #Broadcom #DisasterRecovery #EdgeComputing #VirtualizationGurus
