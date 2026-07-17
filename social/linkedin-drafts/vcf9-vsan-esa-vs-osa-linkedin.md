# LinkedIn Draft — vSAN ESA vs OSA: Storage Architecture Decisions
Source post: content/posts/vcf9-vsan-esa-vs-osa.md
Image: social/linkedin-drafts/images/vcf9-vsan-esa-vs-osa-linkedin.jpg
Status: DRAFT — needs review before posting

---

vSAN ESA doesn't have cache devices and capacity devices anymore -- every NVMe drive in the pool does both jobs at once.

That single change reshapes the hardware conversation for a new workload domain. OSA still organizes storage into disk groups with a clear cache/capacity split; ESA collapses that into one unified pool per host, and the certification requirements, memory sizing, and even the cluster types available in the wizard all shift as a result.

What changes when you drop the cache/capacity split:
→ OSA needs disk groups: at least one cache device and one capacity device per host, typically sized with the vSAN Sizer tool
→ ESA needs at least one NVMe TLC device per storage pool, separately certified from OSA's cache/capacity devices in the Broadcom Compatibility Guide, plus a flat 128GB host memory minimum
→ ESA adds LSFS inline compression and CLAD near-zero-impact snapshots, plus Proactive Hardware Management for NVMe drives -- once a Hardware Support Manager is registered, it surfaces OEM predictive-failure signals so you can remediate before a dying drive takes the pool down

The payoff: OSA still wins on hardware you already own; ESA wins the moment you're buying new NVMe -- but that's a decision made at workload domain creation, not something you patch around later.

Before you spec the next domain's hardware, have you checked the NVMe TLC certification list separately from OSA's cache/capacity list -- or are you assuming one compatibility guide covers both?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-vsan-esa-vs-osa/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-vsan-esa-vs-osa

#VCF9 #VMware #Broadcom #vSAN #StorageArchitecture #VirtualizationGurus
