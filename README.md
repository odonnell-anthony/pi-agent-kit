# pi-agent kit

[![build](https://img.shields.io/github/actions/workflow/status/odonnell-anthony/pi-agent-kit/ci.yml?branch=main&label=build)](https://github.com/odonnell-anthony/pi-agent-kit/actions/workflows/ci.yml)

Docker Sandboxes v3 workload kit that runs [Pi](https://pi.dev) inside a sandbox.

> **This is not a regular Docker project.** Docker Sandboxes (`sbx`) is a Docker
> product for running AI coding agents in isolated microVMs. It has its own CLI,
> kit format, and capability model. Do not suggest `docker-compose`, `docker run`,
> or `Dockerfile` testing workflows. Use `sbx kit validate`, `sbx run`, and
> `sbx exec` instead. See <https://docs.docker.com/ai/sandboxes/>.

## What it builds

`docker.io/sbx/shell-image:latest`, pinned to its multi-arch index digest
(`sha256:8953132089940e30f1387cfe8e77b504356ebbe48e02b15eed28e935f20ee732`; Ubuntu
26.04, Node 22.22.1, git, rg, python3, `agent` user uid 1000), plus
`@earendil-works/pi-coding-agent` installed globally under
`/usr/local/share/npm-global`, with `pi` as the launch command.

## Requirements

- `sbx` v0.51.0 or later. `agent-context@2` needs v0.51.0; `git-identity@1` and
  `ssh-agent@1` need v0.48.0.
- Docker with an OCI-capable Buildx builder (see [Prerequisites](#prerequisites)).
- Host Git `user.name` and `user.email` for commit attribution.
- An OpenRouter API key, and a GitHub credential or SSH key for GitHub access.

Hosts: Linux and macOS, on `linux/amd64` and `linux/arm64`.

## Capabilities

| Capability | Effect |
| --- | --- |
| `sbx@1` | sbx launches `pi` under bash as `agent`; provides `WORKSPACE_DIR`, `SANDBOX_NAME`, `SANDBOX_ID`, `IS_SANDBOX` |
| `network-policy@2` | runtime egress limited to `openrouter.ai`, `github.com` (443 and 22), `ssh.github.com`, `api.github.com`, `uploads.github.com`, `codeload.github.com`, `objects.githubusercontent.com` |
| `credential@1` (openrouter) | `OPENROUTER_API_KEY` holds the sentinel `proxy-managed`; host proxy sets `Authorization: Bearer <real key>` on `openrouter.ai` |
| `credential@1` (github) | `GH_TOKEN` holds a sentinel; proxy injects the real token on `github.com`, `api.github.com`, `uploads.github.com`. `gh` is preinstalled in the base image |
| `ssh-agent@1` | host ssh-agent forwarded into the sandbox; bounded to `git` signatures and `git@github.com` logins. Private keys never enter the sandbox |
| `git-identity@1` | commit `user.name` / `user.email` come from the host Git config |
| `volume@1` | `/home/agent/.pi` (2g, block) persists sessions and settings across stop and re-creation |
| `lifecycle@1` | writes `/home/agent/.pi/agent/settings.json` from the `model` and `thinking` arguments |
| `agent-context@2` | writes `/home/agent/.pi/agent/AGENTS.md` from the inline body (Pi's global instructions) |
| `agent-sessions@1` | declares headless `-p`, `--continue`, `--session` verbs. Declaration only: sbx accepts but does not execute them |
| `agent-interactive-sessions@1` | declares TUI verbs. Optional; sbx ignores it |
| `resources@1` | defaults to 4 CPU, 8 GiB |

## Prerequisites

Host buildx needs an OCI-capable builder, because sbx builds source kits with
`docker buildx build --output type=oci`, which the `docker` driver cannot export:

```console
docker buildx create --name sbx-kit --driver docker-container
```

`.bashrc` exports `BUILDX_BUILDER=sbx-kit` for this.

The kit needs approved credential bindings, recorded in
`~/.config/sbx/credentials.yaml`:

```yaml
bindings:
  openrouter:
    apiKey:
      domains: [openrouter.ai]
  github:
    apiKey:
      domains: [github.com, api.github.com, uploads.github.com]
```

The values come from `sbx secret set openrouter` and `sbx secret set github`.
The GitHub secret can track the host CLI:

```console
sbx secret set github --command 'gh auth token'
```

## Use

Examples assume the kit is at `./pi-agent` relative to the directory you run
from; adjust the path to where you cloned it. `sbx` mounts the current directory
as the workspace unless you pass another path.

```console
# validate
sbx kit validate ./pi-agent

# run (workspace = current directory)
sbx run --name pi-kit ./pi-agent

# headless — stdin must be closed, or Pi waits for EOF forever
sbx exec pi-kit -- bash -lc 'pi -p "list the files in this repo" </dev/null'
sbx exec pi-kit -- pi-headless -p "list the files in this repo"

# override arguments per sandbox
sbx run --name pi-opus ./pi-agent --kit-arg model=anthropic/claude-opus-latest
```

The default model is `deepseek/deepseek-v4.1-flash-1017` with `thinking: high`.
Both are kit arguments; a sandbox keeps the arguments it was created with, so
create a new named sandbox to change them. If the default is unavailable on your
OpenRouter account, override it with `--kit-arg`:

```console
sbx run --name pi-kit ./pi-agent --kit-arg model=anthropic/claude-sonnet-latest
```

## Local vs cloud

The kit targets **local** sandboxes. Cloud (`sbx --cloud`) degrades:

| Capability | Local | Cloud |
| --- | --- | --- |
| `sbx@1`, `resources@1` | full | CPU/memory applied |
| `network-policy@2` | full | host rules only; no HTTP method/path rules |
| `credential@1` | full | install-scoped credentials persist after setup |
| `agent-context@2` | writes `/home/agent/.pi/agent/AGENTS.md` | writes one profile in `/home/agent`, so Pi does not load it |
| `git-identity@1` | full | unsupported; optional, skipped |
| `ssh-agent@1` | full | unsupported; optional, skipped |
| `volume@1` | block, survives re-create | ordinary sandbox disk |

Use local sandboxes for full behaviour.

## Git and GitHub

Both transports work; the kit does not rewrite remotes.

- **HTTPS** — proxy-managed. `gh` and `git` authenticate with the sentinel in
  `GH_TOKEN`; never run `gh auth login` inside a sandbox.
- **SSH** — the host agent is forwarded into the sandbox at
  `/run/ssh-agent.sock`. `git@github.com:` remotes use it, so private keys stay
  on the host. Egress to `github.com:22` is allowed. The key must be registered
  on the GitHub account:

  ```console
  gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
  ```

## Data and sessions

Pi state lives in `/home/agent/.pi`: sessions, `settings.json`, and `AGENTS.md`.
That path is a `volume@1` block volume, scoped to the sandbox name and retained
across stop and re-creation.

- **Sessions**: resume inside the sandbox with `pi --session <id>` or
  `pi --continue`. `agent-sessions@1` is declaration-only here, so `sbx` never
  runs the declared verbs.
- **Reset**: a block volume survives sandbox removal and re-creation under the
  same name, so removing alone does not clear Pi. `sbx reset` clears all sandbox
  state; confirm its scope with `sbx reset --help` before relying on it.

## Extending

`npm install -g` and `apt-get` inside a sandbox last only for that sandbox. For
tools that must persist, package them in a v3 mixin and add it at creation:

```console
sbx run --name pi-kit ./pi-agent --kit ./my-tool-mixin
```

Pi extensions, skills, and prompt templates placed under `/home/agent/.pi` are
volume-backed and survive restarts.

## Local network access

Sandboxes can reach the LAN only when policy allows it. Grant per sandbox, or
omit `--sandbox` for all of them. IPs and CIDR prefixes are accepted:

```console
sbx policy allow network --sandbox pi-kit 10.1.0.0/24
sbx policy allow network --sandbox pi-kit 192.168.1.50:5432
sbx policy ls                             # rules, scopes, and IDs
sbx policy rm network --id <RULE_ID> --sandbox pi-kit --force
```

Policy rules apply within about five seconds, no restart needed. The host's
LAN address is reachable, and so is any service it binds on `0.0.0.0`.

A host service bound only to `127.0.0.1` is not reachable that way. The kit
route for that is the `host-port@1` capability, which relays one host loopback
port to `127.0.0.1:<port>` inside the sandbox and must be declared per port:

```yaml
  - type: com.docker.sandbox/host-port@1
    config: {host: 5432, container: 15432, transport: tcp}
```

## Publish ports to the host or the LAN

A sandbox port is not reachable from the host until it is published. The host
side is chosen at publish time; the kit needs no declaration:

```console
sbx ports pi-kit --publish 8080:3000            # loopback only (127.0.0.1:8080)
sbx ports pi-kit --publish 0.0.0.0:8080:3000    # all interfaces, visible on the LAN
sbx ports pi-kit --publish 3000                 # host picks an ephemeral port
sbx ports pi-kit                                # list mappings
sbx ports pi-kit --unpublish 0.0.0.0:8080:3000/tcp4
```

The binding is done by the host-side `sbx` process, so `0.0.0.0` exposes the
sandbox service to your LAN exactly like any local server would, with no extra
firewall rule. Unpublish with the same protocol suffix that `sbx ports`
reports, otherwise the mapping is left behind.

For the usual dev loop inside the sandbox:

```console
sbx exec -it pi-kit -- bash -lc 'cd "$WORKSPACE_DIR" && npm run dev -- --host 0.0.0.0'
```

A server must listen on `0.0.0.0` (or `::`) inside the sandbox, not on
`127.0.0.1`, or the forwarded connection is refused.

## Publish

```console
docker login
docker buildx build . -f pi-agent.yaml \
  --platform linux/amd64,linux/arm64 \
  --provenance=mode=min \
  -t docker.io/<NAMESPACE>/pi-agent:1.0.0 --push
sbx kit sign docker.io/<NAMESPACE>/pi-agent:1.0.0
sbx kit verify docker.io/<NAMESPACE>/pi-agent:1.0.0
```

Publish the digest, not just the tag, and have consumers verify:

```console
sbx kit verify docker.io/<NAMESPACE>/pi-agent@sha256:<digest>
sbx run --name pi-kit docker.io/<NAMESPACE>/pi-agent@sha256:<digest>
```

## CI

`.github/workflows/ci.yml` runs on every push and pull request:

- JSON-schema validation of `pi-agent.yaml` against the upstream v3 schema.
- `yamllint --strict`, `shellcheck`, and `hadolint`.
- A Buildx OCI build. The `# syntax=docker/sandbox-kit:3` frontend validates the
  descriptor and capability shape during the build.

`.github/workflows/smoke.yml` is manual (`workflow_dispatch`). It runs
`scripts/smoke.sh` on a self-hosted runner with `sbx`, KVM, a `sbx-kit`
container builder, and credential bindings. GitHub-hosted runners cannot run it
because sandboxes need KVM.

Run the same checks locally:

```console
uvx check-jsonschema --schemafile \
  https://raw.githubusercontent.com/docker/sandbox-kit-spec/main/schema/kit.schema.json \
  pi-agent.yaml
uvx yamllint --strict -c .yamllint pi-agent.yaml
shellcheck scripts/smoke.sh
docker run --rm -i hadolint/hadolint < pi-agent.dockerfile
BUILDX_BUILDER=sbx-kit ./scripts/smoke.sh
```

## Headless prompts

Pi reads stdin before running a one-shot prompt: piped input is prepended to the
prompt. A terminal keeps stdin open, so `sbx exec … -- pi -p "x"` produces no
output and blocks until `sbx` reports `context canceled`.

Always close stdin, or use the bundled wrapper:

```console
sbx exec pi-kit -- bash -lc 'pi -p "x" </dev/null'   # explicit
sbx exec pi-kit -- pi-headless -p "x"                # same, wrapped
```

`pi-headless` is `/usr/local/bin/pi-headless` in the image: `exec pi "$@" </dev/null`.
Interactive `pi` (the TUI) is unaffected; do not use the wrapper for it.

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `OCI exporter is not supported for the docker driver` | Buildx is using the docker driver | `docker buildx create --name sbx-kit --driver docker-container`, export `BUILDX_BUILDER=sbx-kit` |
| `pi -p` prints nothing and hangs, then `context canceled` | Pi blocks on open stdin | `pi -p "..." </dev/null`, or use `pi-headless` |
| `401` or model not found on first prompt | OpenRouter binding missing or model unavailable | `sbx secret set openrouter`; override `--kit-arg pi-agent.model=...` |
| `Permission denied (publickey)` over SSH | Host key not on GitHub, or agent not forwarded | `gh ssh-key add ...`; enable SSH-agent forwarding |
| Host unreachable, connection refused | Host not in the network policy | `sbx policy allow network --sandbox pi-kit <host>` |
| Published port not reachable | Service bound to `127.0.0.1` | Bind `0.0.0.0` inside the sandbox |
| `gh auth login` prompts inside | Normal; do not log in | The proxy injects the token from `GH_TOKEN` |
| New capability not applied | Existing sandboxes keep their original kit | Remove and recreate the sandbox |

## Notes

- `PI_SKIP_VERSION_CHECK=1` and `PI_TELEMETRY=0` are set in the image; the
  version check would otherwise fail against the restricted network policy.
- GitHub access is HTTPS and SSH. `/etc/gitconfig` supplies a credential helper
  that returns the `GH_TOKEN` sentinel for `https://github.com`; the proxy
  overwrites the header with a real `Authorization: Bearer`. SSH uses the
  forwarded host agent, so the GitHub account needs the public key registered.
- Add hosts to the network-policy capability if Pi must reach anything else;
  use `sbx policy allow network` for LAN addresses you don't want baked into
  the kit.
- The base image is pinned by digest. Update the `FROM` line deliberately when
  moving to a newer `shell-image`.
- `agent-interactive-sessions@1` is optional because Docker Sandboxes does not
  execute declared session commands; Pi's TUI still launches from the image
  entrypoint.
- `sbx kit validate --offline` does not work for v3 source kits; it needs the
  builder.
- Existing sandboxes keep their original kit; recreate the sandbox after
  changing capabilities.
