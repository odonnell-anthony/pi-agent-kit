# Changelog

## 1.4.6

- Move the base image pin to the 2026-11-25 index digest. This is a nightly
  rebuild of the same base recipe. `docker-ce-cli` 29.10.0 to 29.10.1 and
  `libsqlite3-0` 3.46.1-9ubuntu0.3 to 3.46.1-9ubuntu0.4 are the only package
  changes. Ubuntu 26.04.1, Node 22.22.1, npm 9.2.0, `gh` 2.105.0, git 2.53.0,
  `rg` 15.1.0, `jq` 1.8.1, python3 3.14.4, `tzdata` 2026f, and the agent user
  with uid 1000 report the same versions as the previous pin. Pi stays at
  1.6.0, which is the current npm release.
- Publish 1.4.6 to Docker Hub from the tag workflow, so the published image,
  its keyless signature, and the recorded digest match this source.

## 1.4.5

- Move the base image pin to the 2026-11-24 index digest. This is a nightly
  rebuild of the same base recipe, and `tzdata` 2026e to 2026f is the only
  package that changed. `gh` 2.105.0, Ubuntu 26.04, Node 22.22.1, npm 9.2.0,
  git 2.53.0, `rg` 15.1.0, `jq` 1.8.1, python3 3.14.4, and the agent user with
  uid 1000 report the same versions as the previous pin. Pi stays at 1.6.0,
  which is the current npm release.
- Publish 1.4.5 to Docker Hub from the tag workflow, so the published image,
  its keyless signature, and the recorded digest match this source.

## 1.4.4

- Retry the signature check for up to five minutes. Docker Hub's referrers
  index lags the signature push, so an immediate read reports an unsigned
  image for a signature that is already stored. The CI failure on the 1.4.2 and
  1.4.3 tags was that lag, not a missing signature; both verify from outside CI
  against the workflow identity for their tag.
- Docs: record the published tag and digest for each version on Docker Hub, use
  the current digest in the verify and run examples, and state the referrers lag
  that the workflow retries through.

## 1.4.3

- Sign after an `sbx login` session, the credential source `sbx kit sign`
  prefers, and keep the published-digest check as a job gate. The gate failed on
  the 1.4.2 and 1.4.3 tags although both signatures were attached, because
  Docker Hub's referrers index lags the push. Both images verify from outside
  CI; 1.4.4 makes the gate wait for the index.

## 1.4.2

- Publish the image to Docker Hub from CI. `.github/workflows/publish.yml` runs
  on a `v<version>` tag, builds both architectures, pushes `<version>`, signs
  it keyless with the workflow's own OIDC identity, and verifies the signature
  before the job succeeds. The registry needs `DOCKERHUB_USERNAME` and
  `DOCKERHUB_TOKEN` secrets; signing needs none, so no long-lived key is stored.
- Docs: replace the manual publish procedure with the workflow and its dispatch
  form for a republish, and document the signer identity, which is the workflow
  file at the tag ref. 1.4.0 predates the workflow and is signed by the
  maintainer's GitHub login, which the README now records.

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
