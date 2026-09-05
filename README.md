# Modular Media Server

A modular, self-hosted media server platform built around **Docker and Docker Compose**.

The goal of this project is to make building a home media server approachable for beginners while still providing enough flexibility for experienced self-hosters.

Instead of forcing users to deploy one massive Docker stack, Modular Media Server lets users **choose the services they actually need**, automatically handles dependencies, and generates the required Docker Compose configuration.

It can run on a:

- NAS
- Mini PC
- Desktop PC
- Laptop
- Raspberry Pi or other ARM device
- Dedicated home server
- VPS
- Other hardware capable of running Docker

---

# ⚠️ IMPORTANT — COPYRIGHT, MEDIA & LEGAL NOTICE

**READ THIS BEFORE USING THIS PROJECT**

Modular Media Server is a **self-hosting and server-management project**. It does not provide, distribute, host, index, or endorse unauthorized copies of copyrighted movies, television shows, music, books, photographs, software, or other copyrighted material.

You are responsible for ensuring that **all media you download, store, archive, stream, share, or otherwise access through your server is legally obtained and that you have the necessary rights or permissions to use it.**

The presence of applications such as qBittorrent, Sonarr, Radarr, Lidarr, Jackett, Tube Archivist, ArchiveBox, or similar software **does not imply that they should be used to obtain copyrighted material without authorization.**

These applications are legitimate software with legitimate uses, including:

- Managing media you legally own
- Downloading content you have permission to download
- Accessing public-domain material
- Accessing Creative Commons or otherwise licensed material
- Managing personal recordings
- Managing content distributed by its copyright holder
- Creating lawful personal archives
- Downloading Linux distributions and other openly distributed software
- Managing legally obtained backups

**We explicitly disavow copyright infringement, piracy, unauthorized distribution, unauthorized access, and any other illegal activity.**

Nothing in this project should be interpreted as legal advice or as encouragement to violate copyright law, terms of service, or other applicable laws.

Copyright laws differ between countries and jurisdictions. **You are solely responsible for understanding and complying with the laws applicable to you.**

If you do not have the legal right to download, copy, store, or distribute something, **do not use this project to do so.**

---

## ⚠️ IMPORTANT — TORRENTS, DOWNLOADS & MALWARE

If you use qBittorrent, torrenting introduces security risks in addition to
the legal considerations described above.

Torrent files and downloaded content may come from untrusted sources and
could contain malware, ransomware, trojans, cryptominers, malicious scripts,
or other harmful software. A filename, file extension, torrent comment,
tracker, or indexer does not guarantee that a file is safe.

A VPN does NOT make downloaded files safe. A VPN primarily changes how your
network traffic is routed and does not protect you from malicious files.

Recommended precautions:

• Only download content from sources you trust.
• Only download content you are legally permitted to obtain.
• Keep your server, Docker Engine, Docker images, and applications updated.
• Do not blindly execute programs or scripts obtained through torrents.
• Avoid exposing download clients directly to the public Internet.
• Use appropriate firewall and network-access controls.
• Maintain current backups of important data.
• Consider malware scanning appropriate to your environment.
• Treat downloaded files as untrusted until you have verified them.

The Modular Media Server project does not scan, verify, guarantee, or endorse
the safety of files obtained through torrenting or other download mechanisms.
You are responsible for the security of your server and the files you choose
to download, store, or execute.

---

# Project Philosophy

## Build your server. Your way.

A media server doesn't need to start with 15+ containers.

Start with Jellyfin.

Add Sonarr and Radarr when you're ready.

Add qBittorrent and Gluetun when you need automated downloads.

Add Immich when you want photo management.

Add monitoring, archiving, backup, and other utilities as your server grows.

The project should make it possible to build a server incrementally without requiring users to understand every aspect of Docker before getting started.

---

# Features

## Modular Architecture

Users select individual services, or groups of services, depending on what they want their server to do.

Modules can have:

- Required dependencies
- Recommended dependencies
- Optional integrations
- Configuration requirements
- Storage requirements
- API keys
- External credentials
- Automatically generated secrets

The system should understand these relationships automatically.

---

# Official Project Sources

Modular Media Server is built around existing open-source projects.

**We do not claim ownership of these projects.**

Each project remains owned and licensed by its respective developers and contributors.

Users should consult each project's official documentation and license before deployment.

## Core Management

### Arcane

Modern Docker management interface.

- [Official GitHub](https://github.com/getarcaneapp/arcane)
- [Official Website](https://getarcane.app/)

Arcane is developed by the `getarcaneapp` organization and is licensed under the BSD-3-Clause license.

---

# Media Modules

## Jellyfin

Self-hosted media server for movies, television, music, and other personal media.

- [Official GitHub](https://github.com/jellyfin/jellyfin)
- [Official Website](https://jellyfin.org/)

Jellyfin describes itself as a free software media system for managing and streaming personal media.

## Jellyseerr

Media request and discovery application that integrates with Jellyfin, Plex, and Emby and can work with services such as Sonarr and Radarr.

- [Official GitHub](https://github.com/CTXP/jellyseerr)



---

# Media Automation

## Sonarr

Automated television-series management.

- [Official GitHub](https://github.com/Sonarr/Sonarr)
- [Official Website](https://sonarr.tv/)

Sonarr supports automated monitoring, searching, downloading, renaming, and organization of television content.

## Radarr

Automated movie management.

- [Official GitHub](https://github.com/Radarr/Radarr)
- [Official Website](https://radarr.video/)

Radarr manages movie libraries and integrates with download clients and indexers.

## Lidarr

Automated music collection management.

- [Official GitHub](https://github.com/Lidarr/Lidarr)
- [Official Website](https://lidarr.audio/)

Lidarr manages music collections and can monitor feeds and interact with download clients.

## Bazarr

Subtitle management companion for Sonarr and Radarr.

- [Official GitHub](https://github.com/morpheus65535/bazarr)
- [Official Website](https://www.bazarr.media/)

Bazarr manages subtitles for media already managed by Sonarr and Radarr.

---

# Download Modules

## qBittorrent

Open-source BitTorrent client.

- [Official Website](https://www.qbittorrent.org/)
- [Official Downloads](https://www.qbittorrent.org/download)
- [Official GitHub](https://github.com/qbittorrent/qBittorrent)

qBittorrent provides legitimate uses including downloading freely distributable and authorized content. Its use does not grant permission to download copyrighted material without authorization.

## Gluetun

VPN client container designed to provide VPN networking to Docker applications.

- [Official GitHub](https://github.com/qdm12/gluetun)

Gluetun supports numerous VPN providers and can be used as the network layer for applications such as qBittorrent.

### qBittorrent Dependency

The Compose Generator should treat qBittorrent as requiring:

```text
qBittorrent
    ↓
Gluetun
    ↓
VPN Provider
```

A user should not be able to generate the qBittorrent stack until the required VPN configuration has been supplied.

---

# Indexers

## Jackett

Indexer proxy supporting integration with applications such as Sonarr, Radarr, Lidarr, and qBittorrent.

- [Official GitHub](https://github.com/Jackett/Jackett)

Jackett translates application queries into tracker-specific requests and exposes standardized APIs such as Torznab.

**Important:** Users remain responsible for ensuring that any trackers and content they access are lawful in their jurisdiction.

---

# Photo Management

## Immich

Self-hosted photo and video management platform.

- [Official GitHub](https://github.com/immich-app/immich)
- [Official Website](https://immich.app/)

Immich provides photo/video management, mobile backup, albums, and related functionality.

The Compose Generator should automatically account for Immich's required supporting infrastructure.

---

# Music

## Kima

Kima is a self-hosted music streaming platform designed around a user's own music collection.

- [Official GitHub](https://github.com/Chevron7Locked/kima-hub)

Kima integrates with services including Lidarr and Audiobookshelf and provides its own database/cache components in its all-in-one container.

---

# Monitoring

## Uptime Kuma

Self-hosted monitoring and status-page application.

- [Official GitHub](https://github.com/louislam/uptime-kuma)
- [Official Website](https://uptimekuma.org/)

Uptime Kuma can monitor services and provide status pages and notifications.

---

# Archiving

## ArchiveBox

Self-hosted web archiving application.

- [Official GitHub](https://github.com/ArchiveBox/ArchiveBox)
- [Official Documentation](https://docs.archivebox.io/)

ArchiveBox can preserve web content in formats including HTML, PDF, screenshots, WARC, JSON, and other archival formats.

**Archiving content does not override copyright restrictions. Users must ensure that their archiving activities are lawful.**

## Tube Archivist

Self-hosted YouTube media archiving and management application.

- [Official GitHub](https://github.com/tubearchivist/tubearchivist)
- [Official Documentation](https://docs.tubearchivist.com/)
- [Official Website](https://www.tubearchivist.com/)

Tube Archivist uses yt-dlp and provides indexing, searching, subscriptions, and playback for archived YouTube content.

**Users are responsible for complying with YouTube's terms, copyright law, and any other applicable restrictions.**

---

# Compose Generator

The Compose Generator is a central feature of the project.

Its purpose is to allow users to create a working Docker Compose deployment without needing to manually write or understand a Compose file.

## Basic Workflow

```text
Choose Modules
      ↓
Resolve Dependencies
      ↓
Configure Storage
      ↓
Configure Credentials
      ↓
Generate Secure Secrets
      ↓
Validate Configuration
      ↓
Generate Compose Files
```

---

# Drag-and-Drop Interface

The generator should provide a visual interface.

```text
┌─────────────────────────────────────────────────────────────┐
│                 MODULAR MEDIA SERVER                        │
│                 Compose Generator                           │
├──────────────────┬──────────────────────────┬───────────────┤
│ MODULES          │       YOUR STACK         │ CONFIGURATION  │
│                  │                          │               │
│ Search           │ Jellyfin                 │ Server Name   │
│                  │ Jellyseerr               │ Timezone      │
│ MEDIA            │                          │ Storage       │
│ Jellyfin         │ Sonarr                   │ Credentials   │
│ Jellyseerr       │ Radarr                   │ VPN           │
│                  │                          │               │
│ AUTOMATION       │ qBittorrent              │               │
│ Sonarr           │   └── Gluetun            │               │
│ Radarr           │                          │               │
│ Lidarr           │                          │               │
│ Bazarr           │                          │               │
│                  │                          │               │
│ DOWNLOADS        │                          │               │
│ qBittorrent      │                          │               │
│ Gluetun          │                          │               │
│ Jackett          │                          │               │
│                  │                          │               │
│ PHOTOS           │                          │               │
│ Immich           │                          │               │
├──────────────────┴──────────────────────────┴───────────────┤
│              Validate       Generate Compose                │
└─────────────────────────────────────────────────────────────┘
```

Users should be able to drag modules into their stack.

---

# Dependency System

Modules should define their dependencies through metadata.

There are three types of relationships.

## Required

The module cannot operate correctly without the dependency.

Example:

```text
qBittorrent
    ↓
Gluetun
    ↓
VPN Provider
```

## Recommended

The module works without the dependency, but the dependency provides useful functionality.

Example:

```text
Jellyfin
    ↓
Recommended: Jellyseerr
```

## Optional

Useful integrations that are completely optional.

Example:

```text
Jellyfin
    ↓
Optional: Kometa
```

---

# Configuration Management

The generator should collect configuration in one place.

Configuration should include:

- Storage paths
- Timezone
- API keys
- Tokens
- VPN credentials
- Database credentials
- Application passwords
- Other required environment variables

---

# Storage Configuration

Users should not need to manually edit every volume mapping.

Example:

```text
Docker Configuration
/volume1/docker/media-server

Media
/volume1/media

Downloads
/volume1/downloads
```

The generator should convert these into reusable environment variables.

```env
CONFIG_ROOT=/volume1/docker/media-server
MEDIA_ROOT=/volume1/media
DOWNLOADS_ROOT=/volume1/downloads
```

Compose files then reference these values:

```yaml
volumes:
  - ${MEDIA_ROOT}:/media
  - ${MOVIES_ROOT}:/movies
  - ${TV_ROOT}:/tv
```

---

# API Keys

The generator should automatically identify API keys required by selected modules.

Example:

```text
Configuration Required

Sonarr
API Key: [________________]

Radarr
API Key: [________________]

Immich
API Key: [________________]
```

Compose files should reference environment variables instead of containing the actual keys.

```yaml
API_KEY: ${SONARR_API_KEY}
```

---

# Secure Password Generation

The generator should automatically create secure credentials where appropriate.

Potential generated secrets include:

- Database passwords
- Redis passwords
- Internal service passwords
- JWT secrets
- Encryption keys

Passwords should be generated using a cryptographically secure random number generator.

Example:

```text
Length: [ 32 ]

☑ Uppercase
☑ Lowercase
☑ Numbers
☑ Symbols

[ Generate New Passwords ]
```

The generated values should be stored in `.env`.

---

# Environment Files

Generated projects should contain:

```text
docker-compose.yml
.env
.env.example
.gitignore
README.md
```

## `.env`

Contains the user's actual configuration and secrets.

## `.env.example`

Contains placeholders without real credentials.

## `.gitignore`

Must automatically contain:

```gitignore
.env
```

Users should never commit `.env` files containing credentials to public repositories.

---

# Stack Validation

Before generating a stack:

```text
STACK VALIDATION

✓ Docker configuration
✓ Storage paths
✓ Network configuration
✓ Jellyfin
✓ Sonarr
✓ Radarr
✓ qBittorrent
✓ Gluetun
✓ VPN provider

READY TO DEPLOY
```

If something is missing:

```text
STACK VALIDATION

✓ Jellyfin
✓ Sonarr
✓ Radarr
✓ qBittorrent
✓ Gluetun

✕ VPN provider not configured

qBittorrent cannot be deployed until a VPN
provider has been configured.

[ Configure VPN ]
```

---

# Preset Stacks

## Media Player

```text
Jellyfin
```

## Basic Media Server

```text
Jellyfin
Jellyseerr
```

## Automated Media Server

```text
Jellyfin
Jellyseerr
Sonarr
Radarr
Bazarr
qBittorrent
Gluetun
```

## Music Server

```text
Jellyfin
Lidarr
Kima
qBittorrent
Gluetun
```

## Photo Server

```text
Immich
```

## Archive Server

```text
ArchiveBox
Tube Archivist
```

Presets should remain editable after selection.

---

# Compose Output

The generator should eventually support:

### Complete Stack

```text
docker-compose.yml
.env
.env.example
.gitignore
README.md
```

### Separate Stacks

```text
stacks/
├── media.yml
├── downloads.yml
├── photos.yml
├── archives.yml
└── monitoring.yml
```

### Complete Installation Package

```text
docker-compose.yml
.env
.env.example
.gitignore
README.md
scripts/
```

---

# VPN Recommendations & Affiliate Disclosure

The project may recommend VPN providers that work with Gluetun.

Gluetun currently supports a wide range of providers, including Mullvad, NordVPN, Private Internet Access, Proton VPN, Surfshark, AirVPN, and others.

Some provider links may be affiliate links.

**If we receive compensation when a user purchases a service through one of our links, that relationship will be clearly disclosed next to the link.**

Affiliate relationships will **not** determine whether a service is technically compatible with Modular Media Server.

## Potential VPN Partners

### Private Internet Access

PIA currently operates an affiliate program and advertises commissions on new sales.

**Official service:**  
[Private Internet Access](https://www.privateinternetaccess.com/)

**Affiliate application:**  
[PIA Affiliate Program](https://www.privateinternetaccess.com/affiliate-program)

Once approved, the project's actual affiliate tracking URL should replace the normal service link.

### Surfshark

Surfshark currently advertises a 40% revenue share on new sales through its affiliate program.

**Official service:**  
[Surfshark](https://surfshark.com/)

**Affiliate program:**  
[Surfshark Affiliate Program](https://surfshark.com/affiliate)

### NordVPN

NordVPN currently operates affiliate and other partner programs.

**Official service:**  
[NordVPN](https://nordvpn.com/)

**Partner program:**  
[NordVPN Partner Program](https://nordvpn.com/become-a-partner/)

### Other Providers

Additional VPN providers may be added after verifying:

- Gluetun compatibility
- Current affiliate availability
- Pricing
- Privacy/security characteristics
- Geographic availability
- Terms of service

The project should never recommend a VPN solely because it pays a commission.

---

# VPS Recommendations & Affiliate Disclosure

The same principle applies to VPS providers.

VPS recommendations should consider:

- Price
- CPU
- RAM
- Storage
- Bandwidth
- Transfer limits
- Locations
- Reliability
- Docker compatibility
- IPv4/IPv6 availability
- Backup options
- Overall value

Affiliate links may be used where available.

## DigitalOcean

DigitalOcean currently operates an affiliate program and states that referred new paying users can generate 10% commission each month for one year.

**Official service:**  
[DigitalOcean](https://www.digitalocean.com/)

**Affiliate program:**  
[DigitalOcean Affiliate Program](https://www.digitalocean.com/affiliates)

**Important:** The actual production website should use our approved affiliate tracking URL once the account has been approved.

## Future VPS Partners

Potential providers to investigate:

- DigitalOcean
- Vultr
- Hetzner
- Hostinger
- Other reputable VPS providers

Each provider should be independently evaluated before being added.

---

# Affiliate Policy

The project should maintain a clear policy:

### We may earn money from some links.

Affiliate links help fund:

- Hosting
- Development
- Domain costs
- Documentation
- Testing hardware
- Development of the Compose Generator
- Project maintenance

### Affiliate links do not guarantee recommendations.

A service should never be recommended simply because it pays us.

### Prices and promotions change.

Users should verify current pricing directly with the provider before purchasing.

### We don't control third-party services.

The project is not responsible for:

- VPN outages
- VPS outages
- Price changes
- Provider policy changes
- Account cancellations
- Data loss
- Third-party service behavior

---

# Hardware

The documentation will cover:

- NAS systems
- Mini PCs
- Used business PCs
- Laptops
- Raspberry Pi/ARM systems
- Custom servers
- Hardware transcoding
- Storage
- Networking
- Power consumption

---

# Hardware Requirements

General guidelines:

| Workload | CPU | RAM | GPU | Storage |
|---|---:|---:|---|---|
| Jellyfin | Low | Low | Optional | High |
| Sonarr | Low | Low | No | Medium |
| Radarr | Low | Low | No | Medium |
| Lidarr | Low | Low | No | Medium |
| Immich | Medium | Medium | Helpful | Very High |
| ArchiveBox | Medium | Medium | No | Medium |
| Tube Archivist | Medium | Medium | No | High |
| Multiple services | Medium–High | High | Depends | Very High |

These are general guidelines and should be refined through testing.

---

# Self-Hosting

The project will cover:

- Internet upload speeds
- Dynamic IP addresses
- CGNAT
- Port forwarding
- Reverse proxies
- VPNs
- Cloudflare
- Tailscale
- Backups
- Power outages
- Hardware failure
- Security

---

# VPS Hosting

The documentation will explain when a VPS makes sense.

## Good VPS Workloads

- Uptime Kuma
- Reverse proxies
- Websites
- Lightweight services
- Monitoring
- VPN endpoints
- Remote management

## Poor VPS Workloads

- Large Jellyfin libraries
- Large Immich libraries
- Large torrent libraries
- Massive archives

Storage and bandwidth costs can make VPS hosting significantly more expensive than local hardware for storage-heavy workloads.

---

# Pricing Comparison

Example comparison:

| Option | Up-front Cost | Monthly Cost | Storage | Performance | Difficulty |
|---|---:|---:|---|---|---|
| Used Mini PC | $100–200 | ~$0 | Low | Good | Easy |
| Used Desktop | $150–400 | ~$0 | Medium | Very Good | Medium |
| NAS | $300–1,000+ | ~$0 | Excellent | Good | Easy |
| Custom Server | $500–2,000+ | ~$0 | Excellent | Excellent | Hard |
| VPS | $0 | $5–50+ | Limited | Good | Easy |
| VPS + Cloud Storage | $0 | $20–100+ | Excellent | Good | Medium |

Actual pricing should be researched and updated regularly.

---

# Other Useful Utilities

## Networking

- Cloudflare
- Tailscale
- WireGuard
- Nginx Proxy Manager
- Caddy

## Docker Management

- Arcane
- Portainer
- Dozzle

## Monitoring

- Uptime Kuma
- Glances
- Netdata

## Backups

- Rclone
- Restic
- Borg
- Duplicati

## File Management

- File Browser
- Syncthing
- Nextcloud

## Security

- CrowdSec
- Fail2ban
- Authelia
- Authentik

## Media

- Kometa
- Tdarr
- Unmanic
- Audiobookshelf
- Kavita

---

# Recommended Storage Architecture

Example:

```text
/volume1/
│
├── docker/
│   └── modular-media-server/
│       ├── jellyfin/
│       ├── sonarr/
│       ├── radarr/
│       ├── lidarr/
│       ├── bazarr/
│       └── qbittorrent/
│
├── media/
│   ├── movies/
│   ├── tv/
│   └── music/
│
├── downloads/
│   ├── torrents/
│   └── incomplete/
│
└── photos/
```

The exact structure remains configurable through the Compose Generator.

---

# Documentation Philosophy

Every module should use a consistent documentation format.

## Purpose

What does the application do?

## Difficulty

Easy / Moderate / Advanced

## Resource Requirements

CPU, RAM, storage, GPU requirements.

## How It Fits

Explain its role in the larger Modular Media Server.

## Dependencies

Required services.

## Recommended Modules

Useful integrations.

## Storage

Required directories and volume mappings.

## Networking

Ports and network requirements.

## Configuration

Environment variables, API keys, credentials, and other settings.

## Docker Compose

Example deployment.

## Troubleshooting

Common problems and solutions.

## Official Sources

Link to the project's official website, GitHub repository, documentation, and license where appropriate.

---

# Security Principles

Security should be part of the project from the beginning.

The project should:

- Never hard-code passwords into Compose files
- Never encourage committing `.env` files
- Generate secure random secrets where possible
- Keep API keys in environment variables
- Explain safe remote access
- Explain VPN usage
- Explain reverse proxies
- Explain firewall configuration
- Warn users about exposing services directly to the internet
- Clearly distinguish internal Docker networking from publicly accessible services

---

# Repository Structure

```text
modular-media-server/
│
├── README.md
│
├── docs/
│   ├── getting-started/
│   ├── modules/
│   ├── hardware/
│   ├── hosting/
│   ├── pricing/
│   ├── utilities/
│   └── legal/
│
├── modules/
│   ├── jellyfin/
│   ├── jellyseerr/
│   ├── sonarr/
│   ├── radarr/
│   ├── lidarr/
│   ├── gluetun/
│   ├── qbittorrent/
│   ├── jackett/
│   ├── bazarr/
│   ├── immich/
│   ├── kima/
│   ├── uptime-kuma/
│   ├── archivebox/
│   └── tube-archivist/
│
├── stacks/
│   ├── media/
│   ├── downloads/
│   ├── photos/
│   ├── archives/
│   └── monitoring/
│
├── scripts/
│
├── generator/
│   ├── frontend/
│   ├── backend/
│   ├── modules/
│   └── presets/
│
└── hardware/
```

---

# Roadmap

## Phase 1 — Documentation

- [ ] Create GitHub repository
- [ ] Build GitHub Pages site
- [ ] Write Docker introduction
- [ ] Write Docker Compose introduction
- [ ] Document Arcane
- [ ] Document storage
- [ ] Document networking
- [ ] Document permissions
- [ ] Create module documentation
- [ ] Create copyright/legal documentation
- [ ] Create affiliate disclosure

## Phase 2 — Compose Files

- [ ] Create individual Compose files
- [ ] Create modular stacks
- [ ] Create presets
- [ ] Create installation scripts
- [ ] Standardize environment variables
- [ ] Standardize directory structure
- [ ] Add official source references

## Phase 3 — Compose Generator

- [ ] Build module library
- [ ] Build drag-and-drop interface
- [ ] Create module metadata format
- [ ] Implement required dependencies
- [ ] Implement recommended dependencies
- [ ] Implement optional integrations
- [ ] Implement dependency resolution
- [ ] Add storage configuration
- [ ] Add API key configuration
- [ ] Add VPN provider configuration
- [ ] Add secure password generation
- [ ] Add `.env` generation
- [ ] Add `.env.example`
- [ ] Add `.gitignore`
- [ ] Build validation system
- [ ] Build Compose generation
- [ ] Build preset stacks
- [ ] Add secret/credential warnings
- [ ] Add legal-use warnings for relevant modules

## Phase 4 — Hardware & Hosting

- [ ] Hardware requirements
- [ ] NAS recommendations
- [ ] Mini PC recommendations
- [ ] Used hardware recommendations
- [ ] VPS comparison
- [ ] Cloud storage comparison
- [ ] Self-hosting guide
- [ ] Remote access guide
- [ ] Pricing calculator/comparison
- [ ] Affiliate provider integrations

## Phase 5 — Utilities

- [ ] Networking utilities
- [ ] Monitoring utilities
- [ ] Backup utilities
- [ ] Security utilities
- [ ] Media utilities
- [ ] File management utilities

---

# End Goal

The finished project should make the process of building a self-hosted media server look like this:

```text
             CHOOSE HARDWARE
                    │
                    ▼
             INSTALL DOCKER
                    │
                    ▼
              INSTALL ARCANE
                    │
                    ▼
             CHOOSE MODULES
                    │
                    ▼
          AUTOMATIC DEPENDENCIES
                    │
                    ▼
           CONFIGURE STORAGE
                    │
                    ▼
          CONFIGURE API KEYS
                    │
                    ▼
          CONFIGURE VPN/NETWORK
                    │
                    ▼
           GENERATE SECRETS
                    │
                    ▼
             VALIDATE STACK
                    │
                    ▼
          GENERATE COMPOSE FILE
                    │
                    ▼
                 DEPLOY
                    │
                    ▼
            BACK UP & MAINTAIN
```

The user shouldn't have to understand Docker Compose syntax, networking, or dependency management just to get started.

At the same time, every generated file should remain transparent, editable, and understandable for experienced users.

---

# Summary

**Modular Media Server** is intended to be more than a collection of Docker Compose files.

It is a complete learning resource and configuration platform for building self-hosted media servers.

The project combines:

- Beginner-friendly documentation
- Modular Docker services
- Dependency management
- Docker Compose stacks
- Installation scripts
- A visual drag-and-drop Compose Generator
- Automatic environment variable management
- Storage configuration
- API key management
- VPN configuration
- Secure password generation
- Hardware recommendations
- VPS comparisons
- Pricing information
- Backup and security guidance
- Useful self-hosting utilities
- Transparent affiliate disclosures
- Clear copyright and legal-use guidance

The core principle is simple:

> **Start small. Add what you need. Understand what you're running.**

Build the server around your needs instead of adapting your needs to someone else's giant Docker stack.
