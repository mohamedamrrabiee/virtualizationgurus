LinkedIn Draft: Private AI Workload Domain: GPU Nodes, AI Kubernetes, and NVIDIA NIM
Source post: content/posts/vcf9-private-ai-workload-domain.md
Image: social/linkedin-drafts/images/vcf9-private-ai-workload-domain-linkedin.jpg
Status: DRAFT, needs review before posting

"Stand up a GPU workload domain" sounds like one task. VMware Private AI Foundation with NVIDIA on VCF 9.1 actually gives you three distinct ways to consume that GPU capacity, and picking the wrong one changes your design before you've deployed a single workload.

→ Deep Learning VMs: pre-configured and validated by NVIDIA and VMware, deployable from the VCF Automation AI workstation catalog item or straight from the vSphere Client, the fastest way to prove the GPU stack is healthy
→ Private AI Services: the LLM-centric path, a Supervisor Service with a Model Gallery in Harbor, Model Runtime endpoints, a PostgreSQL vector database for RAG, and an Agent Builder, managed as one integrated service
→ GPU-accelerated VKS clusters: the AI Kubernetes Cluster catalog item deploys the NVIDIA GPU Operator on your worker nodes, with kubectl available for vGPU and passthrough when you need more control

The gotcha almost nobody catches before it's already a problem: Broadcom's requirements state that MIG sharing is incompatible with NVIDIA NIM. Inference with NIM needs time-sliced vGPU or a dedicated GPU, and changing GPU assignment after you've provisioned means reworking hosts and workloads.

Licensing spans two vendors. A VCF subscription and the Private AI Foundation add-on come from Broadcom, and NVIDIA AI Enterprise comes directly from NVIDIA for vGPU mode. New in 9.1, DirectPath enablement gives VMs and Kubernetes nodes exclusive GPU access without an NVAIE license, so your GPU mode now shapes your licensing bill too. The add-on also has a placement subtlety: capacity is allocated to the GPU workload domain, but the guided deployment UI and the VCF Automation quickstart wizard only appear if the license is also assigned to the management domain.

The Payoff:
A GPU workload domain that's technically deployed but built on the wrong consumption path or the wrong GPU mode isn't a working platform, it's a rebuild waiting to happen the first time an inference workload needs NIM and finds MIG.

Which consumption path are you actually building toward, and does your GPU assignment mode already match it?

Full technical breakdown on the blog: https://mohamedamrrabiee.github.io/virtualizationgurus/posts/vcf9-private-ai-workload-domain/?utm_source=linkedin&utm_medium=social&utm_campaign=vcf9-private-ai-workload-domain

#VCF9 #VMware #Broadcom #PrivateAI #NVIDIA #VirtualizationGurus #VMwareCommunity
