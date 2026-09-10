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
| **[Compose generator](https://parkertools.github.io/Modular-Media-Server/generator.html)** | 21 modules, dependency resolution, secrets in your browser |
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
**Connection** Caddy · Cloudflare Tunnel · Tailscale
**Authentication** Pocket ID
**Dashboard** Homarr
**Management** Arcane · Docker Socket Proxy

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

> **On Windows, run this inside Ubuntu (WSL), not PowerShell.** PowerShell aliases
> `curl` to `Invoke-WebRequest`, which rejects these options with *"A parameter
> cannot be found that matches parameter name 'fsSL'"*. The script is bash and
> needs a Linux shell regardless. Press Start, type **Ubuntu**. If it is not
> installed, `wsl --install -d Ubuntu` from an admin terminal, then restart.

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

TEMPLATE.md           Brief for building a sibling site in this style
starter.html          The design system as a working page. Marked noindex —
                      it is a reference, not part of the site
```

Static HTML with no build step. Every page is self-contained; the only external requests are
Google Fonts.

## Project status

| Phase | State | Notes |
|---|---|---|
| 1 · Documentation | Done | Docker/Compose intros, Arcane, storage, permissions, networking, per-module reference, legal notices |
| 2 · Compose files | Done | Generated on demand rather than kept static — the generator and `install.sh` emit identical output, checked by CI |
| 3 · Generator | Done | 21 modules, dependency resolution, storage layouts, credentials, secrets, validation, ZIP download |
| 4 · Hardware & hosting | Done | Requirements, device guidance, self-hosting, VPS comparison, costs, buying guidance |
| 5 · Utilities | Partly | Documented and linked on the hardware page; no per-utility setup guides |

### Deliberate departures from the original plan

Three things in the original outline were not built as written. Each was a decision, not an omission.

| Planned | Built instead | Why |
|---|---|---|
| Drag-and-drop module picker | Click to add or remove | Dragging is poor on phones and unusable by keyboard or screen reader. Clicking works everywhere. |
| API key fields in the generator | Documented in `setup.html` | The \*arr apps generate their own API keys on first run — no value exists to collect beforehand. |
| Password length / charset options | Fixed 32 random bytes | These are machine credentials nobody types. Options only create a way to make them weaker. |

### Not built yet

- **Split stack output** — the generator writes one `docker-compose.yml`. Splitting into `media.yml`,
  `downloads.yml` and so on would suit people who restart one group without the others.
- **Optional integrations** — required and recommended dependencies are modelled; genuinely optional
  pairings like Kometa alongside Jellyfin are documented but not offered in the generator.
- **Per-utility setup guides** — utilities link to their own projects rather than having walkthroughs.
- **Self-hosted fonts** — typefaces load from Google, which is a third-party request on every page.

## Amazon affiliate links

`hardware.html` has a hardware picks section using Amazon Associates links. **It ships with
no tracking IDs**, so links work but earn nothing until you add yours.

Edit the `AMAZON_TAGS` map near the bottom of `hardware.html`:

```js
var AMAZON_TAGS = {
  "com":    "parkertoolsme-20",   // US — approved
  "co.uk":  "",                   // add if you get UK approval
  "ca":     "",
  "de":     "",
  "com.au": ""
};
```

Each marketplace needs its own Associates approval and its own tag. A region left blank
links to Amazon without a tag — no earnings, but nothing breaks.

**Compliance notes**, because Amazon terminates for material breach with no warning:

- The required statement — *As an Amazon Associate I earn from qualifying purchases* — appears
  above the links and in every page footer. Do not remove it.
- **No prices are displayed anywhere near these links, on purpose.** Amazon prohibits static
  prices; showing them requires their API with frequent refresh. The links go to live listings
  instead.
- **No product images**, for the same reason — images must come through Amazon's API, not be
  downloaded and self-hosted.
- Links carry `rel="nofollow sponsored"` and a visible *paid link* label.
- You also need a privacy policy on the site to satisfy the Operating Agreement.
- Amazon closes accounts that make no qualifying sales within 180 days of approval.

The picks are searches rather than specific products, so links do not rot as models go out
of stock.

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
