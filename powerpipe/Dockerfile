FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git && \
    curl -fsSL https://powerpipe.io/install/powerpipe.sh | sh && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 powerpipe && \
    useradd -m -u 1000 -g powerpipe powerpipe && \
    mkdir -p /workspace && \
    chown -R powerpipe:powerpipe /workspace

USER powerpipe
WORKDIR /workspace

RUN powerpipe mod init && \
    powerpipe mod install github.com/turbot/steampipe-mod-aws-insights && \
    powerpipe mod install github.com/turbot/steampipe-mod-gcp-insights && \
    powerpipe mod install github.com/turbot/steampipe-mod-kubernetes-insights

COPY --chown=powerpipe:powerpipe mod.pp /workspace/mod.pp
RUN mkdir -p /home/powerpipe/.powerpipe/config
COPY --chown=powerpipe:powerpipe steampipe.ppc /home/powerpipe/.powerpipe/config/steampipe.ppc

EXPOSE 9033

CMD ["powerpipe", "server", "--listen", "network", "--port", "9033"]