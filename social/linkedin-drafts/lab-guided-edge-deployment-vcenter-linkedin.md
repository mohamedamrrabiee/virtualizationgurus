LinkedIn Draft: Guided Edge Deployment from vCenter: Port Group, TEP Pool and the Edge Cluster
Source post: content/posts/post15_lab-guided-edge-deployment-vcenter.md
Image: social/linkedin-drafts/images/lab-guided-edge-deployment-vcenter-linkedin.jpg
Status: DRAFT, needs review before posting

You can deploy an NSX Edge cluster from the vSphere Client in VCF 9.1.1, but two things have to exist first.

In my lab the wizard took about 20 minutes and ended with two Edge nodes Up. The preparation before it took about 10.

→ A VM management port group on the workload domain VDS, because the default switch profile has none
→ A static IP pool for the Edge TEPs, because the TEP VLAN has no DHCP
→ Two Medium Edges with MTU 9000, and the Clone action copies the first node's settings for the second
→ A one-line VLAN table (management, host TEP, Edge TEP) prevents mix-ups

The Payoff:
Prepare the port group and the pool first, and the wizard becomes the easy part.

What do you create before you open an Edge deployment wizard?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-guided-edge-deployment-vcenter/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-guided-edge-deployment-vcenter

#VCF9 #VMware #Broadcom #NSX #Edge #VirtualizationGurus #VMwareCommunity #vExpert
