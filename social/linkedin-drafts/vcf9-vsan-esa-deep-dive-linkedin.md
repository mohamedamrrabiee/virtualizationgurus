# LinkedIn Draft — VCF 9 vSAN ESA Deep Dive
Source post: content/drafts/vcf9-vsan-esa-deep-dive.md
Image: social/linkedin-drafts/images/vcf9-vsan-esa-deep-dive-linkedin.jpg
Status: DRAFT — needs review before posting

---

Storage design in VCF 9 starts with one decision: vSAN ESA is now the default, not an option.

Express Storage Architecture (ESA) rethinks the original vSAN's disk-group model entirely: a single storage pool per host, a log-structured file system, and compression built in from the start rather than bolted on.

What's different in practice:
→ Architecture — no more cache/capacity tier split; every device contributes to performance and capacity.
→ Performance — higher throughput and lower latency than the original architecture, especially under all-flash workloads.
→ New resilience features — including Dying Disk Handling, which proactively evacuates data before a drive fully fails.

The payoff: simpler capacity planning and fewer storage policy compromises, since you're no longer balancing cache tier sizing against capacity.

If you're still running the original vSAN architecture, this post is a good gut-check on whether your next hardware refresh should move to ESA.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #vSAN #VMware #Broadcom #PrivateCloud #VirtualizationGurus
