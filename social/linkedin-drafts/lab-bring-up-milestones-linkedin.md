LinkedIn Draft: Bring-up Milestones: What Each Stage Builds and How Long It Took
Source post: content/posts/lab-bring-up-milestones.md
Image: social/linkedin-drafts/images/lab-bring-up-milestones-linkedin.jpg
Status: DRAFT, needs review before posting

My VCF 9.1.1 management domain bring-up took about 14 hours 25 minutes of wall clock time. Most of that was one stage.

The installer builds the domain in seven milestones. Configure vSphere cluster alone ran for almost four hours across 135 steps, and it was the stage that paused on three separate critical issues. The three VCF layers on top (management platform, operations appliance and management services) took about three hours 50 minutes with no failures at all.

→ Deploy vCenter 18 minutes, Deploy SDDC Manager 23 minutes
→ Deploy and configure NSX 53 minutes, with the three managers deploying in parallel
→ A stage that sits still is not necessarily stuck, compare the step count first

The Payoff:
Knowing what each stage is doing tells you whether a long pause is normal or a problem.

How long did your last management domain bring-up take, and where did the time go?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/lab-bring-up-milestones/?utm_source=linkedin&utm_medium=social&utm_campaign=lab-bring-up-milestones

#VCF9 #VMware #Broadcom #VCFInstaller #Deployment #VirtualizationGurus #VMwareCommunity
