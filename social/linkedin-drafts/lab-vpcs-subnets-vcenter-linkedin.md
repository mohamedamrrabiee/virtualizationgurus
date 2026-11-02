LinkedIn Draft: VPCs and Subnets from vCenter: Private, Public, DHCP, DNS and NTP
Source post: content/posts/lab-vpcs-subnets-vcenter.md
Image: social/linkedin-drafts/images/lab-vpcs-subnets-vcenter-linkedin.jpg
Status: DRAFT, needs review before posting

Where do you set DNS and NTP for a VCF 9.1.1 VPC subnet? Not where I first looked.

I built two VPCs and three subnets from the vSphere Client in about 25 minutes. The subnet DHCP step showed DNS and NTP as Not Set, and the connectivity profile had no such fields.

→ Private subnets use VPC address space and leave through the VPC SNAT address
→ Public subnets draw from the external block, with no NAT and routes advertised over BGP
→ Subnet size cannot be changed after creation
→ DNS, NTP and lease time live in the VPC Service Profile, set once for every VPC that uses it

The Payoff:
Set the service profile first, and every subnet inherits working DHCP.

Where did you look first for VPC DNS settings?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vpcs-subnets-vcenter/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vpcs-subnets-vcenter

#VCF9 #VMware #Broadcom #NSX #VPC #VirtualizationGurus #VMwareCommunity
