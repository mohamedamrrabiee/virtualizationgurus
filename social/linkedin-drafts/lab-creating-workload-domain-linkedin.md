LinkedIn Draft: Creating the Workload Domain from VCF Operations
Source post: content/posts/lab-creating-workload-domain.md
Image: social/linkedin-drafts/images/lab-creating-workload-domain-linkedin.jpg
Status: DRAFT, needs review before posting

The VCF workload domain wizard does not let you set everything you would expect.

I created the w01 workload domain from VCF Operations in my nested VCF 9.1.1 lab. It took 1 hour 12 minutes with no failures, but three limits are worth knowing before you start.

→ There is no datacenter name field, so it is created as <domain>-DC and renamed later
→ Medium is the smallest NSX Manager size offered, and three of them run on the management cluster
→ Host TEP assignment in the default switch profile is DHCP only, which matters if your TEP VLAN has no DHCP

The Payoff:
Decide TEP addressing and naming before the wizard, not after.

What do you settle on paper before you open the workload domain wizard?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-creating-workload-domain/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-creating-workload-domain

#VCF9 #VMware #Broadcom #NSX #VCFOperations #VirtualizationGurus #VMwareCommunity
