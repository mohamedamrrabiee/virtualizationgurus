LinkedIn Draft: Host Commissioning in 9.1.1: Network Pools and the API Path for Nested Labs
Source post: content/posts/lab-host-commissioning-network-pool-api.md
Image: social/linkedin-drafts/images/lab-host-commissioning-network-pool-api-linkedin.jpg
Status: DRAFT, needs review before posting

The VCF UI blocked my host commissioning. The API did not.

Commissioning three nested ESX hosts in VCF 9.1.1 took two fixes before it would go through.

→ A host certificate CN with the domain twice (host.domain.domain) had to be fixed with a hostname set and certificate regeneration
→ The vSAN HCL validation failed in the UI, and the KB property method did not help for commissioning in 9.1.1
→ POST /v1/hosts with skipHclCompatibilityPrecheck succeeded, and all three hosts were commissioned
→ Network pool values are locked once saved, so check VLAN, range and MTU before you press ADD

The Payoff:
Know the API path before you need it, and treat a skipped HCL check as a lab-only decision.

Have you ever had to bypass a precheck in a lab to get past a UI block?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-host-commissioning-network-pool-api/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-host-commissioning-network-pool-api

#VCF9 #VMware #Broadcom #Troubleshooting #SDDCManager #VirtualizationGurus #VMwareCommunity
