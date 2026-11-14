# Contributing

## Layout

- `pi-agent.yaml`: v3 kit descriptor (capabilities, credentials, args).
- `pi-agent.dockerfile`: image recipe.
- `scripts/smoke.sh`: end-to-end test.
- `.github/workflows/`: CI.

## Develop and test

Requires `sbx` v0.51.0 or later, Docker with an OCI-capable Buildx builder, and
credential bindings (see the README).

```console
docker buildx create --name sbx-kit --driver docker-container
export BUILDX_BUILDER=sbx-kit

sbx kit validate .
BUILDX_BUILDER=sbx-kit ./scripts/smoke.sh
```

Run the static checks CI runs:

```console
uvx check-jsonschema --schemafile \
  https://raw.githubusercontent.com/docker/sandbox-kit-spec/6b0bc2504942eb9335447d5035425536d9c495d6/schema/kit.schema.json \
  pi-agent.yaml
uvx yamllint --strict -c .yamllint pi-agent.yaml
shellcheck scripts/smoke.sh
docker run --rm -i hadolint/hadolint < pi-agent.dockerfile
```

The schema URL is pinned to the commit behind tag `v3.0.0-m.12`. Move it in a
separate commit when the kit moves to a newer schema, so a draft change cannot
break CI silently.

## Bumping Pi

Change `args.version.default` in `pi-agent.yaml` and `ARG PI_VERSION` in
`pi-agent.dockerfile`. CI fails when the two differ, and the build fails when
the installed binary does not report that version.

## Pull requests

- Keep capability changes in the descriptor, not in ad hoc host commands.
- Update the README and CHANGELOG for behaviour changes.
- Confirm CI is green. Capability changes need a real `sbx run` check.
