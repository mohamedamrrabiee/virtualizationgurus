# LinkedIn Draft -- VCF 9 Management Domain Anatomy
Source post: content/drafts/vcf9-management-domain-anatomy.md
Image: social/linkedin-drafts/images/vcf9-management-domain-anatomy-linkedin.jpg
Status: DRAFT -- needs review before posting
---

Every VCF Instance starts with a management domain. Here's exactly what runs inside it.

The management domain is the first workload domain deployed in any VCF Instance, and it never stops being special. Beyond the baseline every VCF domain shares -- vCenter, clusters, distributed switches, NSX Manager, storage -- the management domain carries extra responsibility.

-> Deployed first, always -- created during initial deployment or convergence, before any workload domain exists.
-> Houses the fleet's control plane -- in the first Instance of a fleet, it's where License server, VCF Operations, VCF management services, and VCF Automation actually run.
-> Runs SDDC Manager workflows -- adding Day-2 automation on top of VCF Operations.
-> Can still run business workloads -- it's not purely infrastructure, though most designs keep it dedicated for lifecycle isolation.

The payoff: understanding this anatomy tells you exactly why the first management domain in a fleet needs more headroom than every one after it.

One tradeoff worth flagging early: shared vs. dedicated NSX per workload domain changes your blast radius during a failure -- dedicated costs more footprint but isolates upgrades and outages per domain.

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/

#VCF9 #VMware #Broadcom #ManagementDomain #NSX #CloudInfrastructure #VirtualizationGurus
