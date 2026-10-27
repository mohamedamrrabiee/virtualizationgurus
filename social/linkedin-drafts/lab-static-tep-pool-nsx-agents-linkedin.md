LinkedIn Draft: After the Wizard: Static Host TEP Pool, NSX Agents and a Datacenter Rename
Source post: content/posts/lab-static-tep-pool-nsx-agents.md
Image: social/linkedin-drafts/images/lab-static-tep-pool-nsx-agents-linkedin.jpg
Status: DRAFT, needs review before posting

The workload domain deployed fine, and all three hosts showed Down in NSX.

The wizard had set the host TEPs to DHCP, and my TEP VLAN has no DHCP server. The hosts sat on 169.254 addresses.

→ I created a static TEP IP pool and set the transport node profile to Use IP Pool
→ vmkping with an 8972 byte packet and net-vdl2 confirmed the data plane was healthy
→ The status stayed Down until I restarted nsx-opsagent and nsx-proxy on each host, then all three came up with no alarms
→ The agent restart is what worked in my lab, not a Broadcom documented step

The Payoff:
Verify the data plane first, then decide whether the status is real or stale.

Have you hit a stale status in NSX that only an agent restart cleared?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-static-tep-pool-nsx-agents/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-static-tep-pool-nsx-agents

#VCF9 #VMware #Broadcom #NSX #Troubleshooting #VirtualizationGurus #VMwareCommunity
