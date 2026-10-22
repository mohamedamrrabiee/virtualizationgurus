LinkedIn Draft: Troubleshooting Bring-up 2: VPC Config Type and the NSX Version
Source post: content/posts/lab-troubleshooting-vpc-config-nsx-version.md
Image: social/linkedin-drafts/images/lab-troubleshooting-vpc-config-nsx-version-linkedin.jpg
Status: DRAFT, needs review before posting

Two bring-up failures in my VCF 9.1.1 lab turned out to be data problems in the deployment spec, not infrastructure problems.

The first: SDDC Manager rejected a VPC network configuration type that the installer had exported for a management domain. The second: the NSX version was null, because the spec carried no version and the new SDDC Manager had no bundles.

→ Removing the field and retrying through the installer API kept the existing vCenter and SDDC Manager
→ The depot has to be configured on SDDC Manager too, the bundles do not follow the installer
→ The workflow vault fix worked, but it is a lab recovery, not a production procedure

The Payoff:
Read the exported spec before the first bring-up. Both failures were already visible in the file.

Have you ever had to patch a running deployment workflow, and would you do it again?

Full technical breakdown on the blog: https://virtualizationgurus.pages.dev/posts/lab-troubleshooting-vpc-config-nsx-version/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-troubleshooting-vpc-config-nsx-version

#VCF9 #VMware #Broadcom #Troubleshooting #SDDCManager #VirtualizationGurus #VMwareCommunity
