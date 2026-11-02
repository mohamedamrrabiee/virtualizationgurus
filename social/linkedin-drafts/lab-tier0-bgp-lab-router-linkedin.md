LinkedIn Draft: Tier-0 Active/Standby and eBGP to the Lab Router, Verified from Both Sides
Source post: content/posts/lab-tier0-bgp-lab-router.md
Image: social/linkedin-drafts/images/lab-tier0-bgp-lab-router-linkedin.jpg
Status: DRAFT, needs review before posting

A Tier-0 with four eBGP sessions looks simple until one of them sits in Connect while the wizard is still running.

In my VCF 9.1.1 lab the Tier-0 came up Active/Standby with two uplinks per Edge, four sessions to a single FRR router, and both Edges Up about 20 minutes after I started.

→ Active/Standby is the fit when VPCs need stateful services like NAT
→ The router sends a default route and accepts only the external block
→ The Edge 1 sessions dropped to Connect for a short time mid-workflow and recovered on their own
→ The router proves the sessions, NSX proves the Edge health, and I check both

The Payoff:
Judge BGP after the workflow finishes, and check it from both sides.

Do you check BGP from the router, from NSX, or both?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-tier0-bgp-lab-router/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-tier0-bgp-lab-router

#VCF9 #VMware #Broadcom #NSX #BGP #VirtualizationGurus #VMwareCommunity
