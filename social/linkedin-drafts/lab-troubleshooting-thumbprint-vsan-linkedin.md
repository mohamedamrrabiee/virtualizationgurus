LinkedIn Draft: Troubleshooting Bring-up 1: Thumbprint Mismatch and vSAN ESA Disk Eligibility
Source post: content/posts/lab-troubleshooting-thumbprint-vsan.md
Image: social/linkedin-drafts/images/lab-troubleshooting-thumbprint-vsan-linkedin.jpg
Status: DRAFT, needs review before posting

My first VCF bring-up failed at Deploy vCenter, and the cleanup caused a second failure that looked completely unrelated.

The first error was a host thumbprint mismatch. To retry, I tore down the bootstrap vSAN on the first host. The next validation then failed on vSAN ESA disk eligibility, even though the disks showed as eligible on the host. The disks were fine. The service reporting them was not.

→ The installer log gave the real cause, the task list only said which step failed
→ vdq showed the disks as eligible while the installer's query returned a system fault
→ Restarting the management services does not restart vsanmgmtd, that needed its own restart

The Payoff:
When the host and the installer disagree about a disk, suspect the service in between.

Do you check the installer log first, or the task list?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-troubleshooting-thumbprint-vsan/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-troubleshooting-thumbprint-vsan

#VCF9 #VMware #Broadcom #Troubleshooting #vSAN #VirtualizationGurus #VMwareCommunity
