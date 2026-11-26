# Pinned to the multi-arch index digest of sbx/shell-image:latest for
# reproducibility. Update deliberately when moving to a new base image.
FROM docker.io/sbx/shell-image:latest@sha256:f047ad67e61b33410f70f3160c114a4bc8543232d39198224946ddc4ea2afad0

ARG PI_VERSION=1.6.1

USER root

# Pi's find tool probes for fd/fdfind and otherwise downloads a release binary
# from GitHub. Bake Ubuntu's package (installed as fdfind) so the probe is a
# hit, and add the conventional name for use at the shell.
RUN apt-get update \
    && apt-get install -y --no-install-recommends fd-find \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# Git over HTTPS authenticates through the sandbox proxy: GH_TOKEN holds a
# sentinel and the proxy swaps in the real token on requests to github.com.
# SSH remotes (git@github.com:) work through the host ssh-agent; no rewrite.
RUN printf '%s\n' \
        '[credential "https://github.com"]' \
        '    helper = "!f() { echo username=oauth2; echo password=${GH_TOKEN:-proxy-managed}; }; f"' \
        > /etc/gitconfig

RUN printf '%s\n' \
        '#!/bin/sh' \
        '# One-shot Pi with stdin closed. Pi waits for EOF on stdin before' \
        '# running the prompt, so a terminal blocks `pi -p` forever.' \
        'exec pi "$@" </dev/null' \
        > /usr/local/bin/pi-headless \
    && chmod 0755 /usr/local/bin/pi-headless \
    && mkdir -p /home/agent/.pi/agent \
    && chown -R agent:agent /home/agent/.pi

# The global npm prefix is agent-owned, so install as agent. Installing as root
# would leave a root-owned tree that `pi update --self` cannot replace.
# `pi --version` gates the build: npm only warns on an engines mismatch and
# exits 0, so running the binary is what fails the build for a release this
# image cannot execute.
USER agent
RUN npm install -g "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force \
    && test "$(pi --version)" = "${PI_VERSION}"

ENV PI_SKIP_VERSION_CHECK=1 \
    PI_TELEMETRY=0 \
    GH_PAGER=cat \
    TERM=xterm-256color

WORKDIR /home/agent/workspace
ENTRYPOINT ["pi"]
CMD []
