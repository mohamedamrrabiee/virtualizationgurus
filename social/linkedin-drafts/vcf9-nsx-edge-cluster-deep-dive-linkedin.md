# LinkedIn Draft — NSX Edge Cluster Deep Dive
Source post: content/posts/vcf9-nsx-edge-cluster-deep-dive.md
Image: social/linkedin-drafts/images/vcf9-nsx-edge-cluster-deep-dive-linkedin.jpg
Status: DRAFT — needs review before posting

---

Your Tier-0 gateway's HA mode decides whether NAT, load balancing, and VPN even work -- before you ever touch a firewall rule.

NSX Edge clusters get treated as a checkbox in a lot of designs, but the HA mode you pick there cascades into everything stateful downstream. Active-active gives you load-balanced throughput across both Edge nodes -- but SNAT, DNAT, load balancing, stateful firewall, and VPN simply aren't supported in that mode. Active-standby is the only option once you need any of them.

What the HA mode actually gates:
→ Tier-0 is your one-per-Edge-node front door to the physical network; Tier-1 handles segment downlinks and has no direct northbound uplink of its own
→ IPSec VPN and the vDefend Gateway Firewall both require active-standby HA -- and VPN state synchronizes to the standby node so tunnels survive failover without renegotiating
→ Preemptive vs non-preemptive failover changes whether the original node reclaims active status once it recovers

The payoff: designing the HA mode first, then layering NAT, VPN, and firewall policy on top of it, means you never discover a stateful-services gap after the config is already built out.

If you're deploying an Edge cluster this quarter, have you confirmed active-standby before or after writing the NAT and VPN rules that depend on it?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-nsx-edge-cluster-deep-dive/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-nsx-edge-cluster-deep-dive

#VCF9 #VMware #Broadcom #NSX #EdgeCluster #VirtualizationGurus
