LinkedIn Draft: Centralized Transit Gateway and IP Blocks: What Gets Advertised and What Does Not
Source post: content/posts/lab-centralized-transit-gateway-ip-blocks.md
Image: social/linkedin-drafts/images/lab-centralized-transit-gateway-ip-blocks-linkedin.jpg
Status: DRAFT, needs review before posting

The centralized connectivity wizard asks for two IP blocks, and only one of them should ever leave your Tier-0.

In my VCF 9.1.1 lab the external block was 10.80.0.0/22 and the private transit gateway block was the one VCF created during bring-up. After the VPCs existed, the lab router had learned two SNAT /32s and the public /28, and nothing private.

→ External block: routable, advertised over BGP, used for public subnets, NAT addresses and VIPs
→ Private transit gateway block: internal plumbing, never advertised
→ Documented minimums: /24 or larger external, /23 or larger private
→ show ip route bgp on the router is the proof of what actually left the Tier-0

The Payoff:
Check what the router learned, not only what you configured.

How do you verify what your Tier-0 advertises?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-centralized-transit-gateway-ip-blocks/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-centralized-transit-gateway-ip-blocks

#VCF9 #VMware #Broadcom #NSX #VPC #VirtualizationGurus #VMwareCommunity
