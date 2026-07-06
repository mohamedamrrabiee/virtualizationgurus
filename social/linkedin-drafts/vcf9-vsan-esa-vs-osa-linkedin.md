# LinkedIn Draft — vSAN ESA vs OSA: Storage Architecture Decisions
Source post: content/drafts/vcf9-vsan-esa-vs-osa.md
Image: social/linkedin-drafts/images/vcf9-vsan-esa-vs-osa-linkedin.jpg
Status: DRAFT — needs review before posting

---

vSAN ESA doesn't have cache devices and capacity devices anymore -- every NVMe drive in the pool does both jobs at once.

That single change reshapes the hardware conversation for a new workload domain. OSA still organizes storage into disk groups with a clear cache/capacity split; ESA collapses that into one unified pool per host, and the certification requirements, memory sizing, and even the cluster types available in the wizard all shift as a result.

→ OSA needs disk groups: at least one cache device and one capacity device per host, typically sized with the vSAN Sizer tool
→ ESA needs at least one NVMe TLC device per storage pool, separately certified from OSA's cache/capacity devices in the Broadcom Compatibility Guide, plus a flat 128GB host memory minimum
→ ESA adds LSFS inline compression, CLAD near-zero-impact snapshots, and new Dying Disk Handling that auto-evacuates a failing NVMe drive before it takes the pool down

OSA still wins on hardware you already own; ESA wins the moment you're buying new NVMe.

Practical tip: check the Broadcom Compatibility Guide before committing to ESA -- its NVMe certification list is separate from OSA's cache/capacity device list, and mixing assumptions between the two is a common sizing mistake.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #VMware #Broadcom #CloudInfrastructure #PrivateCloud #VirtualizationGurus
