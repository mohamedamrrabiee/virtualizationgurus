# LinkedIn Draft — Physical Network Design: VDS Separation, ToR Switches, and BGP Uplinks
Source post: content/posts/vcf9-physical-network-design.md
Image: social/linkedin-drafts/images/vcf9-physical-network-design-linkedin.jpg
Status: DRAFT — needs review before posting

---

The workload domain wizard's VDS traffic-separation dropdown is only as good as the ToR trunk and MTU underneath it -- and that part isn't configured in VCF at all.

Every VI workload domain design conversation starts in the wizard, but the physical fabric decisions that actually make or break it happen before SDDC Manager ever touches a host: rack layout, ToR uplink redundancy, and the MTU every switch in the Geneve path has to honor.

What the physical layer has to get right before the VDS profile matters:
→ ToR pairs carry every VLAN over an 802.1Q trunk, with each host connected via 2+ redundant ports at 25GbE or higher
→ Geneve overlay traffic sets the don't-fragment bit end to end -- 1600 MTU is the floor, 1700 is the recommended number that leaves headroom for header growth
→ Once traffic reaches NSX Edge, Tier-0 BGP uplinks need matching local/remote AS numbers, and Multipath Relax on top of ECMP if your uplinks advertise routes with different AS-path content

The payoff: a VDS traffic-separation profile that isolates NSX or storage traffic is only as resilient as the rack and MTU design it's built on top of -- fix the wizard settings and skip the physical layer, and you've isolated traffic onto a fabric that was never sized to carry it cleanly.

Before your next workload domain build, have you confirmed 1700 MTU end to end, or are you assuming the 1600 minimum is enough headroom?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-physical-network-design/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-physical-network-design

#VCF9 #VMware #Broadcom #Networking #BGP #VirtualizationGurus
