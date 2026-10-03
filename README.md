# ubi-agent-base

Lean Red Hat UBI 9 init userspace for [exe.dev](https://exe.dev/), with [Herdr](https://herdr.dev/) terminal workspaces.

```sh
ssh exe.dev new --image=ghcr.io/aditya-konarde/ubi-agent-base:latest
```

Use the hostname returned by exe.dev:

```sh
ssh -t YOUR-MACHINE.exe.xyz herdr
```

Herdr starts its persistent local server when launched. It is installed as a tool, not started as a system service. Agent CLIs and API credentials are configured separately; no credentials are included in the image.

## Included

- UBI 9 init and systemd, with exe.dev provisioning and Shelley integration.
- Herdr 0.9.3, uv 0.12.22, ripgrep 15.2.0.
- Python 3.12, Git, curl, jq, sudo, basic Linux utilities.
- Login user `exedev`, with passwordless sudo as expected by exe.dev.

No browser, Node.js, compiler toolchain or model weights are installed. exe.dev supplies the kernel and Shelley binary. This is an OCI userspace image, not a full RHEL VM or CoreOS installation.

## Build and verify

```sh
podman build -t ubi-agent-base -f Containerfile .
podman run --rm --user exedev --entrypoint bash \
  -v "$PWD/scripts/smoke.sh:/tmp/smoke.sh:ro" ubi-agent-base /tmp/smoke.sh
```

Docker works with the same commands by replacing `podman` with `docker`.

The workflow builds Linux amd64, tests a real Herdr shell command and a Python 3.12 virtual environment, then publishes `latest` and an unique commit-and-run tag on main. Pull requests build and test without publishing. Weekly rebuilds refresh the UBI base and RPM packages; Herdr, uv and ripgrep remain pinned until explicitly updated. `herdr-release.json` records official release URLs and SHA256 checksums. ARM64 is not covered by CI.

## Operational notes

Use `python3.12` explicitly in noninteractive SSH commands: exe.dev's command PATH can select the system Python 3.9. Login shells and uv environments use the configured Python 3.12. The RHEL system Python remains installed for OS tooling.

Journald persistent storage is capped at 64 MiB. exe.dev disk allocation is separate from the image footprint. Stop active work and run `sync` before a control-plane restart; Herdr keeps terminals through client disconnects, but live processes do not survive a VM reboot.

Existing machines are not updated when `latest` changes. Create a new machine to use a newly published image. For reproducible provisioning, use a published build tag or image digest.

## Licenses

The custom build recipe is Apache-2.0. Bundled components retain their own licenses, including the Red Hat UBI EULA. See `NOTICE` and `licenses/`; copies are installed under `/usr/share/licenses/ubi-agent/`. The image is built using UBI repositories and publicly available upstream releases.
