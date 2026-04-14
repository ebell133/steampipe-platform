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
│   ├── values.yaml
│   └── templates/
│       ├── cnpg-cluster.yaml      # CloudNativePG Cluster resource
│       ├── bootstrap/             # SQL bootstrap (cache, providers, cron)
│       └── powerpipe/             # Powerpipe deployment + config
├── powerpipe/                     # Powerpipe image build + mod config
│   ├── Dockerfile
│   └── mod.pp
└── vendor/fdw/kubernetes/         # Self-built Kubernetes FDW binaries
```

## Kubernetes FDW

The Kubernetes FDW is not published as a prebuilt binary by Turbot due to upstream build issues ([steampipe-plugin-kubernetes#256](https://github.com/turbot/steampipe-plugin-kubernetes/issues/256)). This project includes a self-built version for Linux amd64 that works around:

- **Go dependency conflicts** between the FDW framework and the Kubernetes plugin's dependency tree (Helm, k8s client-go, Docker libraries)
- **Go compiler PIC relocation bug** affecting large binaries in `c-archive` buildmode, resolved by using `c-shared` buildmode with separate C/Go linking

The resulting extension requires two `.so` files installed in PostgreSQL's lib directory.

## Prerequisites

- Kubernetes cluster with [CloudNativePG operator](https://cloudnative-pg.io) installed
- `kubectl` and `helm` configured
- Cloud provider credentials (AWS IAM, GCP service account, Kubernetes kubeconfig)

## Quick Start

```bash
# Install the Helm chart
helm install steampipe ./steampipe-platform -n steampipe --create-namespace

# Port-forward Powerpipe dashboards
kubectl port-forward -n steampipe svc/steampipe-powerpipe 9033:9033

# Access dashboards at http://localhost:9033
```

## License

Apache 2.0
