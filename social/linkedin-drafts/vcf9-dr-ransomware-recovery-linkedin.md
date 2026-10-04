LinkedIn Draft: DR & Ransomware Recovery: Isolated Recovery, Protection and Recovery, and VPC Isolation
Source post: content/posts/vcf9-dr-ransomware-recovery.md
Image: social/linkedin-drafts/images/vcf9-dr-ransomware-recovery-linkedin.jpg
Status: DRAFT, needs review before posting

Disaster recovery and ransomware recovery get planned as the same runbook more often than not. Broadcom's architecture says they shouldn't be, operational DR assumes your primary environment is healthy but unreachable. Cyber recovery assumes it's actively compromised. A runbook tuned for one is dangerous applied to the other.

The Isolated Recovery Environment (IRE) exists for exactly one purpose: a clean room, disconnected from production, to safely power on and inspect ransomware-infected workloads. Broadcom's validated design is explicit that it's not for test/dev or burst capacity, ever.

→ A dedicated vSAN ESA storage cluster plus its own compute and NSX edge clusters, fully separate from production infrastructure
→ A Python isolation script creates graduated network isolation levels, and it needs its own Distributed Firewall license, worth budgeting for before an incident, not during one
→ DNS and NTP inside the IRE are intentionally separate from production, so the recovery environment's path to the internet never retraces anything the compromised environment touched
→ Cyber recovery is supported with vSAN snapshots and replication, with two built-in presets, Ransomware Recovery (1-hour RPO, retention out to 6 months) and Short-Term Retention for less critical workloads

The naming has moved twice: SRM became VMware Live Site Recovery, and Live Recovery is now VCF Protection and Recovery. Broadcom's validated ransomware recovery design still refers to SRM and vSphere Replication for the recovery plan, but it's no longer the only path, Protection and Recovery adds vSAN-snapshot operational recovery and a clean-room cyber recovery workflow beside it. "SRM handles failover" isn't wrong, it's just incomplete.

The Payoff:
An IRE that's ready on paper but never budgeted its own DFW license or its own DNS infrastructure isn't ready, it's a design decision nobody actually implemented yet.

Does your DR runbook assume production is impaired, or does it assume production is compromised, because those aren't the same plan?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-dr-ransomware-recovery/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-dr-ransomware-recovery

#VCF9 #VMware #Broadcom #RansomwareRecovery #DisasterRecovery #VirtualizationGurus #VMwareCommunity
