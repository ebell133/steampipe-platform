> **Work in Progress** — This project is under active development and not yet production-ready. APIs, configurations, and architecture may change without notice.

# Steampipe Platform

A self-hosted cloud inventory platform built on [Steampipe](https://steampipe.io) Foreign Data Wrappers and [Powerpipe](https://powerpipe.io) dashboards, deployed on Kubernetes via [CloudNativePG](https://cloudnative-pg.io).

## Overview

Steampipe Platform provides a unified SQL interface for querying cloud infrastructure across multiple providers and accounts. Instead of running Steampipe as a CLI tool, it embeds Steampipe's Postgres FDW extensions directly into a CloudNativePG-managed PostgreSQL cluster, with Powerpipe serving dashboards on top.

### Supported Providers

| Provider | FDW Source | Multi-Account/Project |
|----------|-----------|----------------------|
| AWS | [steampipe-plugin-aws](https://github.com/turbot/steampipe-plugin-aws) (prebuilt) | Yes (IAM role assumption) |
| GCP | [steampipe-plugin-gcp](https://github.com/turbot/steampipe-plugin-gcp) (prebuilt) | Yes (service account per project) |
| Kubernetes | [steampipe-plugin-kubernetes](https://github.com/turbot/steampipe-plugin-kubernetes) (self-built) | Yes (kubeconfig per cluster) |

### Architecture

```
Cloud APIs / K8s APIs
        |
  Steampipe FDW (foreign tables in PostgreSQL)
        |
  Materialized Views (cache.* with pg_cron refresh)
        |
  Aggregation Views (aws_all / gcp_all / k8s_all)
        |
  Powerpipe Dashboards (AWS Insights, GCP Insights, K8s Insights)
```

- **PostgreSQL 14** on CloudNativePG with Steampipe FDW extensions for each provider
- **pg_cron** schedules materialized view refreshes with staggered cron jobs
- **Retry logic** automatically retries failed refreshes (configurable max retries)
- **Multi-account/project/cluster** support with per-entity schemas and `*_all` aggregation views
- **Powerpipe** serves Turbot's Insights mods as dashboards over the same database

## Repository Structure

```
.
├── Dockerfile                     # Custom CNPG PostgreSQL image with FDW extensions
├── steampipe-platform/            # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml                # Generic defaults (all providers disabled)
│   ├── examples/                  # Example values files
│   │   └── values-multi-account.yaml
│   └── templates/
│       ├── cnpg-cluster.yaml      # CloudNativePG Cluster resource
│       ├── bootstrap/             # SQL bootstrap (cache, providers, cron)
│       └── powerpipe/             # Powerpipe deployment + service
├── powerpipe/                     # Powerpipe image build + mod config
│   ├── Dockerfile
│   ├── mod.pp
│   └── steampipe.ppc
└── vendor/fdw/kubernetes/         # Self-built Kubernetes FDW extension metadata
```

## Kubernetes FDW

The Kubernetes FDW is not published as a prebuilt binary by Turbot due to upstream build issues ([steampipe-plugin-kubernetes#256](https://github.com/turbot/steampipe-plugin-kubernetes/issues/256)). This project includes a self-built version for Linux amd64 that works around:

- **Go dependency conflicts** between the FDW framework and the Kubernetes plugin's dependency tree (Helm, k8s client-go, Docker libraries)
- **Go compiler PIC relocation bug** affecting large binaries in `c-archive` buildmode, resolved by using `c-shared` buildmode with separate C/Go linking

The resulting extension requires two `.so` files installed in PostgreSQL's lib directory.

## Prerequisites

- Kubernetes cluster with [CloudNativePG operator](https://cloudnative-pg.io) installed
- `kubectl` and `helm` configured
- Cloud provider credentials (AWS IAM keys, GCP service account, or Kubernetes kubeconfig)

## Quick Start

### 1. Build the container images

The chart requires two images that you build and push to your own registry:

```bash
# PostgreSQL image with Steampipe FDW extensions
docker build -t your-registry/steampipe-pg14:14.3-bookworm .
docker push your-registry/steampipe-pg14:14.3-bookworm

# Powerpipe dashboard image
docker build -t your-registry/powerpipe:latest ./powerpipe
docker push your-registry/powerpipe:latest
```

### 2. Create your values file

Copy the example and customize for your environment:

```bash
cp steampipe-platform/examples/values-multi-account.yaml my-values.yaml
# Edit my-values.yaml with your image names, credentials, accounts, and tables
```

See [`steampipe-platform/values.yaml`](steampipe-platform/values.yaml) for all available options with documentation.

### 3. Create prerequisite secrets

```bash
# AWS credentials
kubectl -n steampipe create secret generic aws-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=<your-key-id> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<your-secret-key> \
  --from-literal=AWS_REGION=<your-default-region>

# GCP credentials (if using GCP)
kubectl -n steampipe create secret generic gcp-credentials \
  --from-file=credentials.json=<path-to-service-account-key.json>
```

### 4. Install the chart

**From a local clone:**

```bash
helm install steampipe ./steampipe-platform -f my-values.yaml \
  -n steampipe --create-namespace
```

**From OCI registry:**

```bash
helm install steampipe oci://ghcr.io/<org>/steampipe-platform \
  --version 0.1.0 -f my-values.yaml -n steampipe --create-namespace
```

### 5. Access dashboards

```bash
kubectl port-forward -n steampipe svc/steampipe-powerpipe 9033:9033
# Open http://localhost:9033
```

## Configuration

All providers are disabled by default. Enable each one you need in your values file:

```yaml
providers:
  aws:
    enabled: true
    credentialsSecretName: aws-credentials
    cachedTables:
      - name: aws_ec2_instance
        uniqueKey: [instance_id, region]
        schedule: "0 */6 * * *"
```

For a complete multi-provider example, see [`steampipe-platform/examples/values-multi-account.yaml`](steampipe-platform/examples/values-multi-account.yaml).

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.imageName` | CNPG PostgreSQL image with FDW extensions **(required)** | `""` |
| `database.instances` | Number of PostgreSQL replicas | `1` |
| `database.storageSize` | PVC size for each instance | `10Gi` |
| `providers.aws.enabled` | Enable AWS provider | `false` |
| `providers.gcp.enabled` | Enable GCP provider | `false` |
| `providers.kubernetes.enabled` | Enable Kubernetes provider | `false` |
| `powerpipe.image` | Powerpipe container image **(required)** | `""` |
| `powerpipe.port` | Powerpipe server port | `9033` |

## License

Apache 2.0
