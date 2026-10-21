LinkedIn Draft: VCF Installer in a Lab: Placement, Depot and Spec
Source post: content/posts/lab-vcf-installer-depot-spec.md
Image: social/linkedin-drafts/images/lab-vcf-installer-depot-spec-linkedin.jpg
Status: DRAFT, needs review before posting

With vSAN ESA there is no datastore on the management hosts before bring-up, so where does the VCF Installer run?

In my lab it runs on a temporary VMFS datastore on a workload host, outside the management domain, and gets removed afterwards so vSAN can claim that disk. That was the first of several small surprises on the way to a deployment spec that validates.

→ The depot host name was rejected as an invalid URL, the IP address worked
→ The installer listed 9.1.0.0 binaries until I selected 9.1.1.0 explicitly
→ The JSON generator needed a skip-edition-check flag to load in PowerShell on Linux
→ The two HCL switches for nested NVMe disks reset on every spec import

The Payoff:
None of these are hard, but each one costs a validation cycle if you meet it unprepared.

What is the smallest thing that has cost you the most time in a VCF deployment?

Full technical breakdown on the blog: https://virtualizationgurus.pages.dev/posts/lab-vcf-installer-depot-spec/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vcf-installer-depot-spec

#VCF9 #VMware #Broadcom #VCFInstaller #Deployment #VirtualizationGurus #VMwareCommunity
