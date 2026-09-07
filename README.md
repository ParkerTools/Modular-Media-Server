# Modular Media Server

**[parkertools.github.io/Modular-Media-Server](https://parkertools.github.io/Modular-Media-Server/)**

A friendly guide and Compose generator for building a self-hosted media server. Pick the
services you want, get a working `docker-compose.yml` with dependencies resolved and secrets
generated, and follow click-by-click setup for each app afterwards.

Start with one thing. Add another when you need it.

---

## What's here

| | |
|---|---|
| **[Quickstart](https://parkertools.github.io/Modular-Media-Server/#quickstart)** | Empty machine to a monitored server in about 30 minutes |
| **[Setup guide](https://parkertools.github.io/Modular-Media-Server/guide.html)** | Two routes — manage from a browser, or generate files yourself |
| **[Platform guides](https://parkertools.github.io/Modular-Media-Server/platforms.html)** | Docker on Windows, macOS, Linux and NAS |
| **[Compose generator](https://parkertools.github.io/Modular-Media-Server/generator.html)** | 18 modules, dependency resolution, secrets in your browser |
| **[App setup](https://parkertools.github.io/Modular-Media-Server/setup.html)** | Configuring each app and wiring them together |
| **[Access & accounts](https://parkertools.github.io/Modular-Media-Server/access.html)** | Remote access, Pocket ID single sign-on, user management |
| **[Hardware & cost](https://parkertools.github.io/Modular-Media-Server/hardware.html)** | What to run it on, and honest pricing |
| **[Documentation](https://parkertools.github.io/Modular-Media-Server/documentation.html)** | Concepts and a reference entry per module |
| **[Troubleshooting](https://parkertools.github.io/Modular-Media-Server/faq.html)** | Searchable answers for when something breaks |

## Modules

**Media** Jellyfin · Jellyseerr
**Automation** Sonarr · Radarr · Lidarr · Bazarr
**Downloads** Gluetun · qBittorrent · Jackett
**Photos & music** Immich · Kima
**Monitoring & archives** Uptime Kuma · ArchiveBox · Tube Archivist
**Connection** Caddy · Tailscale
**Authentication** Pocket ID
**Management** Arcane

## Two ways to generate a stack

**In the browser** — the [generator](https://parkertools.github.io/Modular-Media-Server/generator.html)
runs entirely client-side. Nothing is uploaded; secrets come from `crypto.getRandomValues` and
are masked on screen by default.

**In a terminal** — `install.sh` does the same job with presets and a dry-run flag:

```sh
curl -fsSL https://parkertools.github.io/Modular-Media-Server/install.sh -o install.sh
less install.sh          # read it before you run it
bash install.sh --preset automated --dry-run
```

Both emit identical images and configuration.

## Design decisions worth knowing

- **qBittorrent is never generated without a VPN.** Selecting it adds Gluetun automatically and
  binds it with `network_mode: service:gluetun`, so if the VPN drops the client loses its network.
- **Shared storage layout by default.** Downloads and media sit under one `/data` mount so imports
  hardlink instead of copying. The split layout is available but warns you.
- **The Caddyfile refuses to publish dangerous services.** Arcane, qBittorrent and the \*arr apps
  are excluded and named in a comment explaining why.
- **`.env` is never committed.** The generated `.gitignore` excludes it, and Arcane's Git Sync only
  pulls the Compose file anyway — so real values go in Arcane's own variables.

## Repository layout

```
index.html            Home and quickstart
guide.html            Setup guide
platforms.html        Docker per operating system
generator.html        Compose generator (self-contained, no dependencies)
setup.html            Per-app configuration
access.html           Remote access and SSO
hardware.html         Hardware and cost
documentation.html    Concepts and module reference
faq.html              Troubleshooting
install.sh            CLI equivalent of the generator
.nojekyll             Tells GitHub Pages to skip Jekyll
```

Static HTML with no build step. Every page is self-contained; the only external requests are
Google Fonts.

## Contributing

Issues and pull requests are welcome. The CI workflow validates generated Compose files, checks
link integrity and colour contrast in both themes, and runs `shellcheck` on `install.sh` — please
make sure it passes.

## Licence and attribution

This project is MIT licensed — see [LICENSE](LICENSE).

**That covers this documentation and the generator only.** Every application it deploys is a
separate open-source project owned by its own developers and under its own licence. This project
claims no ownership of Jellyfin, Sonarr, Radarr, Lidarr, Bazarr, qBittorrent, Gluetun, Jackett,
Immich, Kima, Uptime Kuma, ArchiveBox, Tube Archivist, Caddy, Tailscale, Pocket ID or Arcane.
Consult each project's own documentation and licence before deploying it.

## Legal

This project does not provide, host, index or endorse copyrighted material. You are responsible
for ensuring anything you download, store, stream or share is legally obtained and that you hold
the necessary rights. Copyright law differs between countries, and nothing here is legal advice.

Downloaded files can carry malware. A VPN changes how traffic is routed — it does not inspect
files, verify sources, or make anything safe.
