LinkedIn Draft: Preparing Nested ESX Hosts: Certificates and Thumbprints
Source post: content/posts/lab-esx-certificates-thumbprints.md
Image: social/linkedin-drafts/images/lab-esx-certificates-thumbprints-linkedin.jpg
Status: DRAFT, needs review before posting

Two of the most expensive failures in my VCF 9.1.1 lab were certificate problems, and neither showed the real cause in the UI.

The VCF Installer does not trust a host by name. It trusts the fingerprint in your spec and then checks that port 443 still serves that certificate. In one case a renewed certificate sat on disk while port 443 kept serving the old one. In another, setting the full FQDN as the host name made the certificate CN end in the domain twice.

→ Set the short host name and the domain separately, then regenerate the certificate
→ Restart the management services, because a certificate on disk is not a certificate in use
→ Compare what port 443 serves against the file before capturing the SHA-256 thumbprint
→ Validate once, because a placeholder password can lock root on every host

The Payoff:
Do the certificate work once, early, and never again during bring-up.

When did a certificate last cost you a deployment retry?

Full technical breakdown on the blog: https://virtualizationgurus.pages.dev/posts/lab-esx-certificates-thumbprints/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-esx-certificates-thumbprints

#VCF9 #VMware #Broadcom #Troubleshooting #ESX #VirtualizationGurus #VMwareCommunity
