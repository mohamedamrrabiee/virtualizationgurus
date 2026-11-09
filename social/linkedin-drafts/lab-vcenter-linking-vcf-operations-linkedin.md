LinkedIn Draft: One vSphere Client for Two Domains: vCenter Linking in VCF Operations
Source post: content/posts/post14_lab-vcenter-linking-vcf-operations.md
Image: social/linkedin-drafts/images/lab-vcenter-linking-vcf-operations-linkedin.jpg
Status: DRAFT, needs review before posting

Two vCenters, two isolated SSO domains, one vSphere Client.

After VCF SSO was in place in my VCF 9.1.1 lab, I created a vCenter linking group in VCF Operations. It went from In Progress to Active in about two minutes, and both inventories appeared in a single sign-in.

→ Linking builds on VCF SSO, so do SSO first
→ Confirm the Enable vCenter Linking task completed, not only the group status
→ The SSO role cannot grant every privilege, so vCenter refused a permission I tried to assign as the SSO user
→ Keep the local vCenter administrator as a break-glass account

The Payoff:
One identity for day-to-day work, and a clear idea of what the SSO role cannot do.

Do you manage your workload domain vCenters from one client yet?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vcenter-linking-vcf-operations/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vcenter-linking-vcf-operations

#VCF9 #VMware #Broadcom #vCenter #VCFSSO #VirtualizationGurus #VMwareCommunity #vExpert
