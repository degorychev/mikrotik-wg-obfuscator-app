# WireGuard Obfuscator Custom App for MikroTik

Custom RouterOS App packaging for [ClusterM/wg-obfuscator](https://github.com/ClusterM/wg-obfuscator). It runs next to the native RouterOS WireGuard client and is intended for connections to a self-hosted WireGuard Obfuscator or WireGuard Obfuscator Easy server.

## What is included

- a multi-architecture (`arm64`, `amd64`) wrapper image;
- a RouterOS Custom App catalog for GitHub Pages;
- an idempotent RouterOS integration installer;
- diagnostics and uninstall scripts;
- a GitHub Actions workflow that publishes the image to GHCR and the catalog to Pages.

## Publish your copy

1. Create an empty public GitHub repository.
2. Push this directory to the repository's `main` branch.
3. In **Settings → Pages**, select **GitHub Actions** as the source.
4. Run the `Publish App` workflow or push to `main`.
5. After the first workflow run, open the GHCR package settings and make the package public.

The catalog will be available at:

```text
https://GITHUB_USER.github.io/REPOSITORY/app-store.yml
```

Add it to RouterOS 7.22+:

```routeros
/app/settings set app-store-urls="https://GITHUB_USER.github.io/REPOSITORY/app-store.yml"
```

## Installation flow

1. Install the RouterOS `container` package and enable container device mode.
2. Run `/app/setup` or the Apps setup wizard in WebFig.
3. Add this custom catalog and install `wg-obfuscator-client`.
4. Change the App environment values:
   - `WG_OBF_TARGET` to the Easy server's public `host:port`;
   - `WG_OBF_KEY` to the generated obfuscation key;
   - keep `WG_OBF_MASKING=STUN` unless you know it is unnecessary.
5. Start the App and confirm that its logs report a listener on UDP port 13255.
6. Download `routeros/install.template.rsc`, replace its `CHANGE_ME` values, upload and import it.
7. Delete the uploaded installer because it contains the WireGuard private key.
8. Import `routeros/diagnose.rsc` to verify the App, handshake, route, and counters.

## Security notes

- Never commit WireGuard private keys or the obfuscation key.
- Pin release tags before distributing the catalog broadly; `latest` is used only for the initial prototype.
- The RouterOS App environment exposes `WG_OBF_KEY` to administrators. This key is for traffic obfuscation, not WireGuard encryption, but it should still be treated as sensitive.
- The installer only creates objects carrying the `wg-obfuscator-app` comment or fixed names. The uninstall script intentionally leaves the App and its stored data intact.
- The wrapper files are MIT-licensed. The redistributed `wg-obfuscator` binary remains GPL-3.0-or-later; see `container/THIRD_PARTY_NOTICES.md` and the upstream source.

## Development

Render the Pages artifact locally from a POSIX shell:

```sh
GITHUB_REPOSITORY=example/mikrotik-wg-obfuscator-app \
GITHUB_REPOSITORY_OWNER=example \
sh scripts/render-site.sh
```

Build the wrapper image:

```sh
docker build -t wg-obfuscator-app:dev container
```
