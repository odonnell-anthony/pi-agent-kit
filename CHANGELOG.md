# Changelog

## 1.4.1

- Move the base image pin to the 2026-11-21 index digest. This is a nightly
  rebuild of the same base recipe: `gh` 2.105.0, Ubuntu 26.04, Node 22.22.1,
  git, `rg`, `jq`, python3, and the agent user report the same versions as the
  previous pin. Pi stays at 1.6.0, which is the current npm release.
- Docs: make the published image optional. Document the three kit sources with
  their requirements: local directory, Git tag, and published image. A Git
  source needs its publisher in `kit.allowedSources`, which defaults to
  `docker.io/` and `dhi.io/`.
- Docs: name the Docker Hub namespace in the publish section and replace the
  placeholder verify identity with the GitHub signer identity and issuer the
  image is signed with. The previous example used a Google issuer, which fails
  verification.
- Record the 1.4.0 Docker Hub publication: a signed multi-arch image, keyless
  signature attached as an OCI referrer. 1.4.1 ships from GitHub only, so the
  published image stays at 1.4.0.

## 1.4.0

- Move Pi to 1.6.0. The base image digest is unchanged. Upstream adds the
  GPT-6.2 Astra and GPT-6.2 Sol models and makes Sol the default on the
  `openai`, `azure`, and `openai-codex` providers, adds `deepseek-v4.1-flash`
  and `deepseek-v4.1-flash-1017` to the Qwen Token Plan providers, updates
  `undici` to 8.12.4 for six security advisories, and makes extension
  `render()` return `readonly string[]`. The kit's OpenRouter default model is
  unchanged, and the kit uses no extensions, so no configuration changes are
  needed.

## 1.3.4

- Move the base image pin to the 2026-11-20 index digest. This is a nightly
  rebuild of the same base recipe: `gh` 2.105.0, Ubuntu 26.04, Node 22.22.1,
  git, `rg`, `jq`, python3, and the agent user report the same versions as the
  previous pin. Pi stays at 1.5.2, which is the current npm release.

## 1.3.3

- Move the base image pin to the 2026-11-19 index digest. This is a nightly
  rebuild of the same base recipe: `gh` 2.105.0, Ubuntu 26.04, Node 22.22.1,
  git, `rg`, `jq`, python3, and the agent user report the same versions as the
  previous pin. Pi stays at 1.5.2, which is the current npm release.

## 1.3.2

- Move the base image pin to the 2026-11-18 index digest. The base now carries
  `gh` 2.105.0. Ubuntu 26.04, Node 22.22.1, the other base tools, and the agent
  user are unchanged.

## 1.3.1

- Move the base image pin to the 2026-11-17 index digest. The base now carries
  `gh` 2.104.0. Ubuntu 26.04, Node 22.22.1, the other base tools, and the agent
  user are unchanged.

## 1.3.0

- Install `fd` in the image, so Pi's find tool does not download a release
  binary that the egress policy blocks.
- Allow `registry.npmjs.org`, so `pi install`, `pi update`, and startup package
  fetches work, and allow `release-assets.githubusercontent.com`, where GitHub
  release downloads redirect.
- Merge the `model` and `thinking` arguments into `settings.json` at create
  instead of rewriting the file, so packages and other settings survive a
  re-create with a retained volume.
- Install Pi as `agent`, so `pi update --self` can replace the package tree.
- Bind prompts after `--` in the declared session verbs, so a prompt that starts
  with a dash is not read as an option.
- Fail the build when the installed Pi does not report the pinned version.
- CI: pin the kit schema to a release commit, check that the descriptor and the
  Dockerfile agree on the Pi version, build both architectures, and take
  Dependabot updates.
- Docs: correct the egress model, the model override examples, and the smoke
  test paths.

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
