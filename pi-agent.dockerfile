# Pinned to the multi-arch index digest of sbx/shell-image:latest for
# reproducibility. Update deliberately when moving to a new base image.
FROM docker.io/sbx/shell-image:latest@sha256:8953132089940e30f1387cfe8e77b504356ebbe48e02b15eed28e935f20ee732

USER root
ARG PI_VERSION=1.5.2
# Git over HTTPS authenticates through the sandbox proxy: GH_TOKEN holds a
# sentinel and the proxy swaps in the real token on requests to github.com.
# SSH remotes (git@github.com:) work through the host ssh-agent; no rewrite.
RUN npm install -g "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force \
    && mkdir -p /home/agent/.pi/agent \
    && chown -R agent:agent /home/agent/.pi \
    && printf '%s\n' \
        '[credential "https://github.com"]' \
        '    helper = "!f() { echo username=oauth2; echo password=${GH_TOKEN:-proxy-managed}; }; f"' \
        > /etc/gitconfig \
    && printf '%s\n' \
        '#!/bin/sh' \
        '# One-shot Pi with stdin closed. Pi waits for EOF on stdin before' \
        '# running the prompt, so a terminal blocks `pi -p` forever.' \
        'exec pi "$@" </dev/null' \
        > /usr/local/bin/pi-headless \
    && chmod 0755 /usr/local/bin/pi-headless

USER agent
ENV PI_SKIP_VERSION_CHECK=1 \
    PI_TELEMETRY=0 \
    GH_PAGER=cat \
    TERM=xterm-256color

WORKDIR /home/agent/workspace
ENTRYPOINT ["pi"]
CMD []
