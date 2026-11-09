LinkedIn Draft: VCF SSO Without Active Directory: Keycloak as an OIDC Provider
Source post: content/posts/post13_lab-vcf-sso-keycloak-oidc.md
Image: social/linkedin-drafts/images/lab-vcf-sso-keycloak-oidc-linkedin.jpg
Status: DRAFT, needs review before posting

No Active Directory in your lab? VCF SSO still works.

I set up VCF SSO in my nested VCF 9.1.1 lab with Keycloak as a generic OIDC provider. The result is one sign-in on both vCenters and both NSX Managers, and the whole job took about 1 hour 35 minutes.

→ Keycloak runs in Docker on the jump host, with a certificate from a small lab CA, because VCF SSO needs a trusted HTTPS chain
→ The client, the groups mapper and the domain mapper decide whether the wizard recognizes your group
→ Groups Pre-provisioning cannot be changed later, so choose it on purpose
→ My one failure was a Keycloak password that never applied, because I did not check the command output

The Payoff:
Build the identity provider first, and test the user directly before you run Test Login.

What do you use as an identity provider in your lab?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vcf-sso-keycloak-oidc/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vcf-sso-keycloak-oidc

#VCF9 #VMware #Broadcom #Keycloak #VCFSSO #VirtualizationGurus #VMwareCommunity #vExpert
