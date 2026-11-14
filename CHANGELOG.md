# Changelog

## 1.2.0

- Expose the host's shared skills store to Pi at `/home/agent/.agents/skills`
  via `agent-skills@1`, read-only and optional.

## 1.1.0

- Seed Pi's MCP config with the sandbox MCP gateway via a lifecycle install
  hook, so registered servers are available without manual configuration. The
  hook creates the agent directory when absent, so first-run on a fresh volume
  works.

## 1.0.0

First public release.

- Pi 1.5.2 in a Docker Sandboxes v3 workload kit.
- Proxy-managed OpenRouter and GitHub credentials.
- GitHub over HTTPS and SSH (forwarded host agent).
- Persistent `/home/agent/.pi` volume.
- Inline global instructions via `agent-context@2`.
- Headless `pi-headless` wrapper.
- CI: schema validation, linting, OCI build. Manual smoke workflow.
