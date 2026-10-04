# LinkedIn Draft — VCF 9 vSAN ESA Deep Dive
Source post: content/posts/vcf9-vsan-esa-deep-dive.md
Image: social/linkedin-drafts/images/vcf9-vsan-esa-deep-dive-linkedin.jpg
Status: DRAFT — needs review before posting

---

Storage design in VCF 9.1 just got a lot less manual.

vSAN Express Storage Architecture (ESA) is the default for all new VCF 9 deployments — single storage pool per host, log-structured file system, compression built in rather than bolted on. VCF 9.1 goes a step further with Auto-RAID: a single system-managed policy that senses your cluster size and applies the optimal RAID level automatically, no manual FTT/RAID selection required.

What's different in practice:
→ Architecture — no cache/capacity tier split; every NVMe device contributes to performance and capacity.
→ Auto-RAID (new in 9.1) — 6+ hosts get RAID-6/FTT=2, 3-5 hosts get RAID-5/FTT=1, applied and re-evaluated automatically as the cluster scales.
→ Proactive Hardware Management — predictive NVMe failure detection through the Hardware Support Manager, so you can act before a drive fully fails.

The payoff: fewer storage policy decisions, fewer capacity-planning surprises, and resilience that adjusts itself as your cluster grows.

If you're still running the original vSAN architecture — or manually picking RAID-5 vs RAID-6 per cluster — this is worth a look before your next hardware refresh.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-vsan-esa-deep-dive/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-vsan-esa-deep-dive

#VCF9 #vSAN #VMware #Broadcom #PrivateCloud #VirtualizationGurus
