Planning to run application load balancing on NSX in VCF 9.1.1? Check the entitlement before finalizing your design.

Starting with VCF 9.0, general-purpose load balancing is no longer included in the VCF entitlement for the built-in NSX Load Balancer. Its permitted use is limited to load balancing VCF infrastructure components and Layer 4 load balancing for vSphere Supervisor.

For general-purpose and advanced application delivery, Broadcom recommends Avi Load Balancer, which adds capabilities such as GSLB, advanced analytics, container ingress, and Web Application Firewall (WAF).

This is the final post in the VCF 9 series, covering three capabilities that matter once workloads arrive on the platform.

→ VPC service profiles bundle reusable network services and configuration, including DHCP, DNS forwarding, and subnet settings.
→ NSX Load Balancer vs. Avi: NSX covers the permitted infrastructure and Supervisor use cases, while Avi provides advanced application delivery capabilities.
→ VCF Operations for Networks turns network flow data into flow analytics and end-to-end visibility, helping teams troubleshoot connectivity and plan network migrations.

The payoff: a self-service network is only as supportable as your visibility into it. And a load-balancing architecture is only as sound as your understanding of its capabilities, licensing entitlements, and migration requirements.

Design for the platform you're entitled to run, not just the features you can configure.

Full technical breakdown on the blog: https://virtualizationgurus.pages.dev/posts/vcf9-advanced-services/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-advanced-services

#VCF9 #VMware #Broadcom #NSX #LoadBalancing #VirtualizationGurus #VMwareCommunity #vExpert
