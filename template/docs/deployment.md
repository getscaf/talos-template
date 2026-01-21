# :package: How to Deploy a Talos Cluster

This guide walks through deploying a Talos Linux Kubernetes cluster on AWS, from infrastructure provisioning to cluster bootstrap.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- **AWS CLI** - Configured with appropriate credentials
- **Terraform/OpenTofu** - Infrastructure provisioning (v1.6+)
- **talosctl** - Talos cluster management CLI
- **kubectl** - Kubernetes command-line tool
- **Task** - Task runner for automation
- **1Password CLI** (optional) - For secrets injection

## Deployment Overview

The deployment process consists of two main phases:

1. **Infrastructure Provisioning** - Use Terraform to create AWS resources
2. **Cluster Bootstrap** - Use Talos to initialize the Kubernetes cluster

## Step 1: Configure AWS Credentials

Ensure your AWS credentials are configured:

```bash
aws configure
# OR
export AWS_PROFILE=your-profile
```

Verify access:

```bash
aws sts get-caller-identity
```

## Step 2: Choose Your Environment

The template supports three environments:

- **sandbox** - Testing and experimentation
- **staging** - Pre-production validation
- **production** - Production workloads

For this guide, we'll use **sandbox**. Replace with your chosen environment as needed.

## Step 3: Provision Infrastructure with Terraform

### Initialize Terraform

Navigate to the environment directory:

```bash
cd terraform/sandbox
```

Initialize Terraform (first time only):

```bash
tofu init
```

### Review and Apply

Review the planned changes:

```bash
tofu plan
```

Apply the infrastructure:

```bash
tofu apply
```

Type `yes` when prompted to confirm.

### What Gets Created

Terraform provisions:

- VPC with public subnets across availability zones
- Security groups for Kubernetes and Talos APIs
- EC2 instances with Talos Linux AMI (control plane nodes)
- Elastic Load Balancer for control plane access
- Route53 DNS record for cluster API endpoint
- IAM roles for EC2 instances

**Note:** EC2 instances will boot with Talos OS but the Kubernetes cluster is NOT yet initialized.

## Step 4: Bootstrap the Talos Cluster

After infrastructure is provisioned, bootstrap the Kubernetes cluster.

### Navigate to Bootstrap Directory

```bash
cd ../../bootstrap-cluster/sandbox
```

### Review Environment Configuration

Check the `.env` file for your environment:

```bash
cat .env
```

This contains:
- `TALOS_FACTORY_IMAGE` - Talos version (v1.12.1)
- `TOFU_DIR` - Path to Terraform directory

### Run Bootstrap Process

Execute the bootstrap task:

```bash
export ENV=sandbox
task talos:bootstrap
```

This automated task performs the following steps:

1. **Generate Configs** - Creates `talosconfig` and `controlplane.yaml`
2. **Set Node IPs** - Configures Talos endpoints from Terraform output
3. **Apply Configuration** - Pushes Talos config to all nodes
4. **Bootstrap Kubernetes** - Initializes the Kubernetes cluster
5. **Generate kubeconfig** - Creates kubectl configuration
6. **Upgrade Talos** - Updates to specific v1.12.1 factory image

### Monitor the Process

You can monitor the bootstrap process via AWS Serial Console:

1. Go to AWS Console → EC2 → Instances
2. Select a control plane instance
3. Actions → Monitor and troubleshoot → Get system log

## Step 5: Verify Cluster Status

### Check Talos Node Health

```bash
export TALOSCONFIG=./sandbox/talosconfig
talosctl health --nodes <first-node-ip>
```

### Check Talos Version

```bash
talosctl version --nodes <node-ip>
```

### Access Kubernetes Cluster

```bash
export KUBECONFIG=./sandbox/kubeconfig
kubectl get nodes
```

Expected output:
```
NAME                 STATUS   ROLES           AGE   VERSION
my-cluster-0         Ready    control-plane   5m    v1.31.x
my-cluster-1         Ready    control-plane   5m    v1.31.x
my-cluster-2         Ready    control-plane   5m    v1.31.x
```

### Check Kubernetes Components

```bash
kubectl get pods -n kube-system
```

All system pods should be Running.

## Step 6: Store Credentials Securely

The bootstrap process stores credentials in AWS Secrets Manager:

- **Talosconfig** - Stored as `${ENV}_talosconfig_yaml`
- **Kubeconfig** - Stored as `${ENV}_kubeconfig_yaml`

Retrieve them later with:

```bash
# Get talosconfig
aws secretsmanager get-secret-value \
  --secret-id sandbox_talosconfig_yaml \
  --query SecretString --output text | base64 -d > talosconfig

# Get kubeconfig
aws secretsmanager get-secret-value \
  --secret-id sandbox_kubeconfig_yaml \
  --query SecretString --output text | base64 -d > kubeconfig
```

## Common Bootstrap Tasks

The `Taskfile.yml` in `bootstrap-cluster/` provides several useful tasks:

### List Available Tasks

```bash
task --list
```

### Individual Bootstrap Steps

If you need to run steps individually:

```bash
# Generate Talos configuration
task talos:generate_configs

# Apply config to nodes
task talos:apply_talos_config

# Bootstrap Kubernetes
task talos:bootstrap_kubernetes

# Generate kubeconfig
task talos:generate_kubeconfig

# Upgrade Talos version
task talos:upgrade_talos

# Check cluster health
task talos:health
```

## Upgrading Talos

To upgrade to a new Talos version:

1. Update `TALOS_FACTORY_IMAGE` in `bootstrap-cluster/.env`
2. Run the upgrade task:

```bash
export ENV=sandbox
task talos:upgrade_talos
```

## Destroying Infrastructure

**WARNING:** This will destroy all resources and data.

### Destroy the Cluster

```bash
cd terraform/sandbox
tofu destroy
```

Type `yes` when prompted.

### Clean Up Local State

```bash
cd ../../bootstrap-cluster/sandbox
rm -f talosconfig kubeconfig controlplane.yaml
```

## Troubleshooting

### Terraform Issues

**Error:** "Error creating VPC"
- Check AWS credentials and region configuration
- Verify account limits for VPCs

**Error:** "No Talos AMI found"
- Verify the AWS region has Talos AMIs available
- Check the AMI filter in `terraform/modules/base/ec2.tf`

### Bootstrap Issues

**Error:** "failed to dial"
- Ensure security groups allow port 50000 (Talos API)
- Verify EC2 instances are running
- Check public IPs are accessible

**Error:** "context deadline exceeded"
- Talos nodes may still be booting (wait 2-3 minutes)
- Check AWS Serial Console for boot logs

### Cluster Not Healthy

```bash
# Check Talos service status
talosctl --nodes <ip> services

# View Talos logs
talosctl --nodes <ip> logs kubelet

# Check etcd health
talosctl --nodes <ip> etcd members
```

## Next Steps

After successfully deploying your cluster:

1. **Deploy workloads** - Use `kubectl apply` to deploy applications
2. **Install cluster add-ons** - CNI, CSI drivers, ingress controllers, etc.
3. **Configure monitoring** - Deploy Prometheus, Grafana, or other monitoring tools
4. **Set up GitOps** - Consider ArgoCD or Flux for application deployment
5. **Review security** - Configure RBAC, network policies, pod security standards

For more information:
- See [Architecture Documentation](./architecture.md)
- Read the [Talos Documentation](https://www.talos.dev/docs/)
- Check [Terraform README](../terraform/README.md)
