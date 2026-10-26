LinkedIn Draft: Walking the VCF Installer Wizard for a New Fleet
Source post: content/posts/lab-installer-wizard-new-fleet.md
Image: social/linkedin-drafts/images/lab-installer-wizard-new-fleet-linkedin.jpg
Status: DRAFT, needs review before posting

The VCF Installer wizard is where a naming plan turns into a deployment, and on nested hardware one step decides whether validation passes.

I walked through the management domain wizard in my VCF 9.1.1 lab, step by step: general information, networks, VCF Operations, vCenter, storage, distributed switch and NSX. The step that needed extra care was storage. Virtual NVMe disks are not on the vSAN ESA HCL, so the first validation failed on all four hosts.

→ One spec setting and two switches in the Storage step make the installer claim the disks anyway
→ Both switches reset on every spec import and on every new installer appliance
→ The remaining HCL warnings have to be acknowledged before deploying

The Payoff:
A lab workaround is only useful if you know exactly which settings it touches and when they reset.

Which wizard step has cost you the most validation runs?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-installer-wizard-new-fleet/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-installer-wizard-new-fleet

#VCF9 #VMware #Broadcom #VCFInstaller #vSAN #VirtualizationGurus #VMwareCommunity
