# POC DevOps

Infrastructure-as-Code proof of concepts: Terraform provisioning for a k8s cluster (GCP) with supporting network, bastion, and Argo CD / Metabase deployments.

## Structure

```
*.tf                      # Terraform: network, bastion, cluster, APIs, outputs, variables
backend..tf.sample        # backend config sample (copy to backend.tf)
k8s/
├── argocd/               # Argo CD manifest + RBAC + deploy script
└── metabase/             # Metabase kustomization (namespace, deploy, service)
data/shutdown-script.sh   # node shutdown helper
```

## Usage

```bash
cp backend..tf.sample backend.tf   # fill in your backend
terraform init && terraform plan && terraform apply
# then deploy apps on the cluster
cd k8s/argocd && ./rbac/deploy.sh
```

## Status

POC — demonstrates end-to-end GitOps-style provisioning on GCP.
