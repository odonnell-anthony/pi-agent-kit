# Security policy

## Reporting a vulnerability

Do not open a public issue. Use GitHub private vulnerability reporting:

<https://github.com/odonnell-anthony/pi-agent-kit/security/advisories/new>

Include the affected capability or file, reproduction steps, and impact.

## Security model

- Credentials are proxy-managed. `OPENROUTER_API_KEY` and `GH_TOKEN` hold the
  sentinel `proxy-managed` inside the sandbox; the host proxy injects the real
  values on requests to the allowed domains. Real keys never enter the sandbox.
- Egress is limited to an explicit allow-list. Any other host fails unless a
  policy rule is added on the host.
- SSH uses a forwarded host agent, bounded to `git` signatures and
  `git@github.com` logins. Private keys never enter the sandbox.
- `PI_TELEMETRY=0` and `PI_SKIP_VERSION_CHECK=1` are set in the image.
- The base image is pinned by digest.

Never commit secrets. `scripts/smoke.sh` reads credentials from the host `sbx`
bindings, not from files in the repository.
