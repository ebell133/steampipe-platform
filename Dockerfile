FROM ghcr.io/cloudnative-pg/postgresql:14-bookworm

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates postgresql-14-cron && \
    # AWS FDW
    curl -L -o /tmp/aws-fdw.tar.gz \
      "https://github.com/turbot/steampipe-plugin-aws/releases/latest/download/steampipe_postgres_aws.pg14.linux_amd64.tar.gz" && \
    tar -xzf /tmp/aws-fdw.tar.gz -C /tmp && \
    cp /tmp/steampipe_postgres_aws.pg14.linux_amd64/steampipe_postgres_aws.so "$(pg_config --pkglibdir)/" && \
    cp /tmp/steampipe_postgres_aws.pg14.linux_amd64/steampipe_postgres_aws.control "$(pg_config --sharedir)/extension/" && \
    cp /tmp/steampipe_postgres_aws.pg14.linux_amd64/steampipe_postgres_aws--1.0.sql "$(pg_config --sharedir)/extension/" && \
    # GCP FDW
    curl -L -o /tmp/gcp-fdw.tar.gz \
      "https://github.com/turbot/steampipe-plugin-gcp/releases/latest/download/steampipe_postgres_gcp.pg14.linux_amd64.tar.gz" && \
    tar -xzf /tmp/gcp-fdw.tar.gz -C /tmp && \
    cp /tmp/steampipe_postgres_gcp.pg14.linux_amd64/steampipe_postgres_gcp.so "$(pg_config --pkglibdir)/" && \
    cp /tmp/steampipe_postgres_gcp.pg14.linux_amd64/steampipe_postgres_gcp.control "$(pg_config --sharedir)/extension/" && \
    cp /tmp/steampipe_postgres_gcp.pg14.linux_amd64/steampipe_postgres_gcp--1.0.sql "$(pg_config --sharedir)/extension/" && \
    # Kubernetes FDW (self-built, hosted on GitHub release)
    curl -L -o /tmp/k8s-fdw.tar.gz \
      "https://github.com/ebell133/steampipe-platform/releases/download/k8s-fdw-v1.0.0/steampipe_postgres_kubernetes.pg14.linux_amd64.tar.gz" && \
    tar -xzf /tmp/k8s-fdw.tar.gz -C /tmp && \
    cp /tmp/steampipe_postgres_kubernetes.so "$(pg_config --pkglibdir)/" && \
    cp /tmp/steampipe_postgres_fdw_go.so "$(pg_config --pkglibdir)/" && \
    cp /tmp/steampipe_postgres_kubernetes.control "$(pg_config --sharedir)/extension/" && \
    cp /tmp/steampipe_postgres_kubernetes--1.0.sql "$(pg_config --sharedir)/extension/" && \
    rm -rf /tmp/* /var/lib/apt/lists/*

USER 26