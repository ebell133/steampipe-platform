FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git && \
    curl -fsSL https://powerpipe.io/install/powerpipe.sh | sh && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN powerpipe mod init && \
    powerpipe mod install github.com/turbot/steampipe-mod-aws-insights && \
    powerpipe mod install github.com/turbot/steampipe-mod-gcp-insights

COPY mod.pp /workspace/mod.pp

EXPOSE 9033

CMD ["powerpipe", "server", "--listen", "network", "--port", "9033"]