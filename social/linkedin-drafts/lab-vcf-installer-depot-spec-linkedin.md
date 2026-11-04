LinkedIn Draft: VCF Installer in a Lab: Placement, Depot and Spec
Source post: content/posts/lab-vcf-installer-depot-spec.md
Image: social/linkedin-drafts/images/lab-vcf-installer-depot-spec-linkedin.jpg
Status: DRAFT, needs review before posting

With vSAN ESA there is no datastore on the management hosts before bring-up, so where does the VCF Installer run?

In my lab it runs outside the management domain, on a temporary VMFS datastore on a workload host. It gets removed after bring-up so vSAN can claim that disk.

Three things I would set up before the first validation:

→ Place the installer outside the management domain, on the build that matches your target release
→ Connect the offline depot by IP address and select 9.1.1.0 explicitly
→ Generate the spec from a saved and recalculated planning workbook, then set the HCL switches again after every import

The Payoff:
Get the placement, the depot and the spec right once, and validation becomes a formality instead of a loop.

What do you prepare before your first VCF Installer validation?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-vcf-installer-depot-spec/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-vcf-installer-depot-spec

#VCF9 #VMware #Broadcom #VCFInstaller #Deployment #VirtualizationGurus #VMwareCommunity #vExpert
