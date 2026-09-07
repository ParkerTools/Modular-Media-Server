#!/usr/bin/env bash
#
# Modular Media Server — installer
#
#   Start small. Add what you need. Understand what you're running.
#
# Builds a docker-compose.yml, .env, .env.example, .gitignore and README.md
# for a self-hosted media stack. Does the same job as the website generator,
# without the website.
#
#   curl -fsSL https://parkertools.github.io/Modular-Media-Server/install.sh -o install.sh
#   less install.sh          # read it before you run it. always.
#   bash install.sh
#
# Licence: MIT. The applications it deploys are separate projects with their
# own licences and their own terms — see the README it writes for you.
#
set -euo pipefail

VERSION="0.1.0"

# ─────────────────────────────────────────────────────────────── output ──

if [[ -t 1 ]] && [[ "${NO_COLOR:-}" == "" ]]; then
  B=$'\e[1m'; DIM=$'\e[2m'; R=$'\e[0m'
  BLUE=$'\e[38;5;31m'; TEAL=$'\e[38;5;37m'; CORAL=$'\e[38;5;209m'
  RED=$'\e[38;5;167m'; GREEN=$'\e[38;5;71m'
else
  B=""; DIM=""; R=""; BLUE=""; TEAL=""; CORAL=""; RED=""; GREEN=""
fi

say()   { printf '%s\n' "$*"; }
info()  { printf '%s\n' "${DIM}$*${R}"; }
step()  { printf '\n%s\n' "${B}${BLUE}$*${R}"; }
ok()    { printf '%s %s\n' "${GREEN}✓${R}" "$*"; }
warn()  { printf '%s %s\n' "${CORAL}!${R}" "$*"; }
die()   { printf '\n%s %s\n\n' "${RED}✗${R}" "$*" >&2; exit 1; }

rule()  { printf '%s\n' "${DIM}────────────────────────────────────────────────────────────${R}"; }

banner() {
  printf '\n%s\n' "${B}  modular${CORAL}.${BLUE}media${R}"
  printf '%s\n\n' "${DIM}  media server installer · v${VERSION}${R}"
}

# ─────────────────────────────────────────────────────────────── config ──

INSTALL_DIR=""
PRESET=""
ASSUME_YES=0
DRY_RUN=0
DO_DEPLOY=""

TZ_VALUE=""
PUID_VALUE=""
PGID_VALUE=""
CONFIG_ROOT=""
MEDIA_ROOT=""
DOWNLOADS_ROOT=""
PHOTOS_ROOT=""

VPN_PROVIDER=""
VPN_TYPE="wireguard"
VPN_PRIVATE_KEY=""
VPN_ADDRESSES=""
VPN_USER=""
VPN_PASSWORD=""
VPN_COUNTRIES=""

SELECTED=()

# every module this script knows how to write
ALL_MODULES=(
  arcane jellyfin jellyseerr sonarr radarr lidarr bazarr
  gluetun qbittorrent jackett immich kima uptime-kuma
  archivebox tubearchivist caddy tailscale cloudflared pocket-id
)

module_label() {
  case "$1" in
    arcane)        echo "Arcane — Docker management in a browser" ;;
    jellyfin)      echo "Jellyfin — media server" ;;
    jellyseerr)    echo "Jellyseerr — request & discovery" ;;
    sonarr)        echo "Sonarr — TV automation" ;;
    radarr)        echo "Radarr — film automation" ;;
    lidarr)        echo "Lidarr — music automation" ;;
    bazarr)        echo "Bazarr — subtitles" ;;
    gluetun)       echo "Gluetun — VPN container" ;;
    qbittorrent)   echo "qBittorrent — download client (needs Gluetun)" ;;
    jackett)       echo "Jackett — indexer proxy" ;;
    immich)        echo "Immich — photos & video" ;;
    kima)          echo "Kima — music streaming" ;;
    uptime-kuma)   echo "Uptime Kuma — monitoring" ;;
    archivebox)    echo "ArchiveBox — web archiving" ;;
    tubearchivist) echo "Tube Archivist — YouTube archiving" ;;
    caddy)         echo "Caddy — reverse proxy with automatic HTTPS" ;;
    tailscale)     echo "Tailscale — private mesh network (host install is simpler)" ;;
    cloudflared)   echo "Cloudflare Tunnel — no open ports; routing set in Cloudflare" ;;
    pocket-id)     echo "Pocket ID — passkey single sign-on (needs Caddy + domain)" ;;
    *)             echo "$1" ;;
  esac
}

preset_modules() {
  case "$1" in
    player)     echo "jellyfin" ;;
    basic)      echo "arcane jellyfin jellyseerr" ;;
    automated)  echo "arcane jellyfin jellyseerr sonarr radarr bazarr gluetun qbittorrent jackett" ;;
    music)      echo "arcane jellyfin lidarr kima gluetun qbittorrent" ;;
    photos)     echo "arcane immich" ;;
    archive)    echo "arcane archivebox tubearchivist" ;;
    monitoring) echo "arcane uptime-kuma" ;;
    remote)     echo "arcane jellyfin caddy pocket-id" ;;
    *)          echo "" ;;
  esac
}

# ────────────────────────────────────────────────────────────── helpers ──

has()      { command -v "$1" >/dev/null 2>&1; }
selected() { local m; for m in "${SELECTED[@]:-}"; do [[ "$m" == "$1" ]] && return 0; done; return 1; }
add_module() { selected "$1" || SELECTED+=("$1"); }

ask() { # ask <prompt> <default> -> echoes answer
  local prompt="$1" default="${2:-}" reply=""
  if (( ASSUME_YES )); then printf '%s' "$default"; return; fi
  if [[ -n "$default" ]]; then
    read -r -p "$(printf '%s %s[%s]%s ' "$prompt" "$DIM" "$default" "$R")" reply </dev/tty || true
  else
    read -r -p "$(printf '%s ' "$prompt")" reply </dev/tty || true
  fi
  printf '%s' "${reply:-$default}"
}

confirm() { # confirm <prompt> <default y|n>
  local prompt="$1" default="${2:-n}" reply=""
  if (( ASSUME_YES )); then [[ "$default" == "y" ]]; return; fi
  local hint="y/N"; [[ "$default" == "y" ]] && hint="Y/n"
  read -r -p "$(printf '%s %s[%s]%s ' "$prompt" "$DIM" "$hint" "$R")" reply </dev/tty || true
  reply="${reply:-$default}"
  # Written the long way on purpose: ${var,,} needs bash 4, and macOS ships 3.2.
  reply="$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')"
  [[ "$reply" == "y" || "$reply" == "yes" ]]
}

gen_secret() { # url-safe, no padding
  if has openssl; then
    openssl rand -base64 36 | tr -d '\n=' | tr '+/' '-_' | cut -c1-43
  elif [[ -r /dev/urandom ]]; then
    LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 43
  else
    die "No openssl and no /dev/urandom — cannot generate secrets safely."
  fi
}

gen_hex32() {
  if has openssl; then
    openssl rand -hex 16
  else
    LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 32
  fi
}

detect_tz() {
  if [[ -n "${TZ:-}" ]]; then echo "$TZ"
  elif [[ -r /etc/timezone ]]; then cat /etc/timezone
  elif has timedatectl; then timedatectl show -p Timezone --value 2>/dev/null || echo "Etc/UTC"
  elif [[ -L /etc/localtime ]]; then readlink /etc/localtime | sed 's|.*/zoneinfo/||'
  else echo "Etc/UTC"
  fi
}

# ───────────────────────────────────────────────────────────────── usage ──

usage() {
  cat <<EOF
${B}Modular Media Server installer${R} v${VERSION}

  bash install.sh [options]

${B}Options${R}
  --dir <path>        Where to write the stack   (default: ./modular-media-server)
  --preset <name>     Skip the menu and use a preset
  --yes               Accept every default, ask nothing
  --dry-run           Print what would be written, write nothing
  --deploy            Run 'docker compose up -d' when finished
  --no-deploy         Never offer to deploy
  --version           Print version
  --help              This

${B}Presets${R}
  player       Jellyfin on its own
  basic        Arcane, Jellyfin, Jellyseerr
  automated    The full media stack with downloads behind a VPN
  music        Jellyfin, Lidarr, Kima, downloads
  photos       Immich
  archive      ArchiveBox and Tube Archivist
  monitoring   Uptime Kuma
  remote       Jellyfin behind Caddy with Pocket ID single sign-on

${B}Examples${R}
  bash install.sh
  bash install.sh --preset basic --dir /opt/media
  bash install.sh --preset automated --dry-run

${DIM}qBittorrent will not be written without VPN credentials. That is on purpose.${R}
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)        INSTALL_DIR="${2:-}"; shift 2 ;;
    --preset)     PRESET="${2:-}"; shift 2 ;;
    --yes|-y)     ASSUME_YES=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    --deploy)     DO_DEPLOY=1; shift ;;
    --no-deploy)  DO_DEPLOY=0; shift ;;
    --version|-V) echo "$VERSION"; exit 0 ;;
    --help|-h)    usage; exit 0 ;;
    *)            die "Unknown option: $1  (try --help)" ;;
  esac
done

# ────────────────────────────────────────────────────────────── preflight ──

banner

if [[ -n "$PRESET" ]] && [[ -z "$(preset_modules "$PRESET")" ]]; then
  die "No preset called '$PRESET'. Run --help to see the list."
fi

step "Checking the basics"

PLATFORM="linux"
IS_DESKTOP=0   # Docker Desktop / VM-backed runtime rather than native Linux

case "$(uname -s)" in
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      PLATFORM="wsl"; IS_DESKTOP=1
      ok "Windows detected (WSL2)."
    else
      PLATFORM="linux"
      ok "Linux detected."
    fi
    ;;
  Darwin)
    PLATFORM="macos"; IS_DESKTOP=1
    ok "macOS detected."
    ;;
  MINGW*|MSYS*|CYGWIN*)
    PLATFORM="gitbash"; IS_DESKTOP=1
    warn "Running under Git Bash on Windows."
    info "This works, but WSL2 is a much better home for a media server."
    info "See the platform guide before going further."
    ;;
  *)
    warn "Untested on $(uname -s). Continuing, but expect rough edges."
    ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  ok "Architecture: $ARCH" ;;
  aarch64|arm64) ok "Architecture: $ARCH"
                 ARM_HOST=1
                 info "On ARM, not every image has a matching build." ;;
  *)             warn "Architecture $ARCH is unusual. Some images may not have a build." ;;
esac

DOCKER_OK=0
if has docker; then
  if docker info >/dev/null 2>&1; then
    ok "Docker is installed and running."
    DOCKER_OK=1
  else
    warn "Docker is installed but not responding."
    info "Either the daemon is stopped, or your user isn't in the docker group."
    info "Try:  sudo systemctl start docker   and   sudo usermod -aG docker \$USER"
    info "After adding yourself to the group, log out and back in."
  fi
else
  warn "Docker isn't installed."
  say ""
  say "  The official convenience script will install it:"
  say "    ${DIM}curl -fsSL https://get.docker.com | sudo sh${R}"
  say "    ${DIM}sudo usermod -aG docker \$USER${R}   ${DIM}# then log out and back in${R}"
  say ""
  info "This installer won't run that for you — piping a remote script into a"
  info "root shell should be a decision you make deliberately, not a side effect."
fi

if (( DOCKER_OK )); then
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose plugin found."
  else
    warn "The 'docker compose' plugin is missing."
    info "Install docker-compose-plugin from your package manager."
  fi
fi

has openssl && ok "openssl found — secrets will be generated with it." \
            || warn "openssl not found — falling back to /dev/urandom."

if (( IS_DESKTOP )); then
  say ""
  warn "Docker here runs inside a Linux virtual machine. Two consequences:"
  info "  · Hardware transcoding (/dev/dri) is not available. Jellyfin will"
  info "    transcode on CPU only, which limits you to roughly one stream."
  info "  · Files kept on the Windows/macOS side are reached over a network"
  info "    filesystem and are slow. Keep libraries on the Linux side."
  info ""
  info "Fine for trying this out or a modest library. For an always-on server"
  info "with several viewers, native Linux is a large step up."
fi

# ─────────────────────────────────────────────────────────────── modules ──

if [[ -n "$PRESET" ]]; then
  step "Preset: $PRESET"
  read -r -a SELECTED <<< "$(preset_modules "$PRESET")"
  for m in "${SELECTED[@]}"; do say "  · $(module_label "$m")"; done
elif (( ASSUME_YES )); then
  step "No preset given — using 'basic'"
  read -r -a SELECTED <<< "$(preset_modules basic)"
  for m in "${SELECTED[@]}"; do say "  · $(module_label "$m")"; done
else
  step "What do you want to run?"
  say "Type numbers to turn things on and off. Enter on its own when you're done."
  say ""
  while true; do
    local_i=1
    for m in "${ALL_MODULES[@]}"; do
      if selected "$m"; then
        printf '  %s%2d%s %s●%s %s\n' "$DIM" "$local_i" "$R" "$TEAL" "$R" "$(module_label "$m")"
      else
        printf '  %s%2d%s %s○%s %s%s%s\n' "$DIM" "$local_i" "$R" "$DIM" "$R" "$DIM" "$(module_label "$m")" "$R"
      fi
      local_i=$((local_i+1))
    done
    say ""
    picks="$(ask "  Toggle (e.g. 2 3 4), or Enter to continue:" "")"
    [[ -z "$picks" ]] && break
    for p in $picks; do
      if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= ${#ALL_MODULES[@]} )); then
        target="${ALL_MODULES[$((p-1))]}"
        if selected "$target"; then
          tmp=(); for m in "${SELECTED[@]}"; do [[ "$m" != "$target" ]] && tmp+=("$m"); done
          SELECTED=("${tmp[@]:-}")
          [[ -z "${SELECTED[0]:-}" ]] && SELECTED=()
        else
          SELECTED+=("$target")
        fi
      else
        warn "  '$p' isn't on the list."
      fi
    done
    say ""
  done
fi

[[ ${#SELECTED[@]} -eq 0 ]] && die "Nothing selected, nothing to build."

# ────────────────────────────────────────────────────── dependency rules ──

step "Sorting out dependencies"

DEPS_ADDED=0

if selected qbittorrent && ! selected gluetun; then
  add_module gluetun
  ok "Added Gluetun — qBittorrent is not written without a VPN container."
  DEPS_ADDED=1
fi

if selected pocket-id && ! selected caddy; then
  add_module caddy
  ok "Added Caddy — Pocket ID needs HTTPS, and passkeys will not work without it."
  DEPS_ADDED=1
fi

if selected jellyseerr && ! selected jellyfin; then
  warn "Jellyseerr expects a media server. Add Jellyfin, or point it at an existing one later."
fi

if selected bazarr && ! selected sonarr && ! selected radarr; then
  warn "Bazarr fetches subtitles for Sonarr and Radarr libraries. On its own it has little to do."
fi

if selected jackett && ! selected sonarr && ! selected radarr && ! selected lidarr; then
  warn "Jackett feeds indexers to the *arr apps. Nothing selected will use it."
fi

(( DEPS_ADDED )) || ok "Nothing extra needed."

# ─────────────────────────────────────────────────────────────── the VPN ──

if selected gluetun; then
  step "VPN configuration"
  say "Gluetun needs real credentials. qBittorrent routes all of its traffic"
  say "through it, so if this is wrong, the download client will not start."
  say ""

  if (( ASSUME_YES )); then
    VPN_PROVIDER="CHANGEME"
    VPN_PRIVATE_KEY="CHANGEME"
    VPN_ADDRESSES="CHANGEME"
    warn "Non-interactive mode: writing CHANGEME placeholders."
    warn "The stack will not start until you edit .env."
  else
    say "  Providers Gluetun supports include: mullvad, protonvpn, private internet access,"
    say "  nordvpn, surfshark, airvpn, windscribe and many more."
    say ""
    VPN_PROVIDER="$(ask "  Provider (lowercase, as Gluetun spells it):" "mullvad")"
    VPN_TYPE="$(ask "  Connection type (wireguard/openvpn):" "wireguard")"

    if [[ "$VPN_TYPE" == "wireguard" ]]; then
      VPN_PRIVATE_KEY="$(ask "  WireGuard private key:" "")"
      VPN_ADDRESSES="$(ask "  WireGuard address (e.g. 10.64.0.2/32):" "")"
      if [[ -z "$VPN_PRIVATE_KEY" || -z "$VPN_ADDRESSES" ]]; then
        warn "Left blank — writing CHANGEME placeholders instead."
        VPN_PRIVATE_KEY="${VPN_PRIVATE_KEY:-CHANGEME}"
        VPN_ADDRESSES="${VPN_ADDRESSES:-CHANGEME}"
      fi
    else
      VPN_USER="$(ask "  OpenVPN username:" "")"
      VPN_PASSWORD="$(ask "  OpenVPN password:" "")"
      VPN_USER="${VPN_USER:-CHANGEME}"
      VPN_PASSWORD="${VPN_PASSWORD:-CHANGEME}"
    fi
    VPN_COUNTRIES="$(ask "  Server country (blank for provider default):" "")"
  fi
fi

# ──────────────────────────────────────────────────────────────── domain ──

BASE_DOMAIN=""
POCKETID_ENCRYPTION_KEY=""

if selected caddy; then
  step "Domain"
  say "Caddy obtains HTTPS certificates automatically, but it needs a real"
  say "domain name that already points at this machine."
  say ""
  if (( ASSUME_YES )); then
    BASE_DOMAIN="example.com"
    warn "Non-interactive mode: using example.com as a placeholder."
    warn "Edit the Caddyfile and .env before starting."
  else
    BASE_DOMAIN="$(ask "  Your domain (e.g. example.com):" "")"
    if [[ -z "$BASE_DOMAIN" ]]; then
      BASE_DOMAIN="example.com"
      warn "Left blank — writing example.com as a placeholder."
    fi
  fi

  if selected pocket-id; then
    say ""
    info "  Pocket ID will be at https://id.${BASE_DOMAIN}"
    info "  Passkeys need that address to resolve and serve valid HTTPS."
    info "  Register two passkeys on separate devices once it is running."
  fi
fi

# ─────────────────────────────────────────────────────────────── storage ──

step "Where should everything live?"

DEFAULT_DIR="${INSTALL_DIR:-$PWD/modular-media-server}"
INSTALL_DIR="$(ask "  Stack directory:" "$DEFAULT_DIR")"
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

case "$PLATFORM" in
  wsl)
    DEF_MEDIA="$HOME/media"; DEF_DL="$HOME/downloads"; DEF_PHOTOS="$HOME/photos"
    say "  ${DIM}Keep these inside WSL (under $HOME), not on /mnt/c. Paths on the${R}"
    say "  ${DIM}Windows drive are far slower and lose Linux file permissions.${R}"
    say ""
    ;;
  macos|gitbash)
    DEF_MEDIA="$HOME/media"; DEF_DL="$HOME/downloads"; DEF_PHOTOS="$HOME/photos"
    say "  ${DIM}Anything under your home folder needs to be shared with Docker${R}"
    say "  ${DIM}Desktop under Settings → Resources → File sharing.${R}"
    say ""
    ;;
  *)
    DEF_MEDIA="/srv/media"; DEF_DL="/srv/downloads"; DEF_PHOTOS="/srv/photos"
    ;;
esac

CONFIG_ROOT="$(ask "  Application config:" "$INSTALL_DIR/config")"
MEDIA_ROOT="$(ask "  Media library:" "$DEF_MEDIA")"
DOWNLOADS_ROOT="$(ask "  Downloads:" "$DEF_DL")"
selected immich && PHOTOS_ROOT="$(ask "  Photos:" "$DEF_PHOTOS")"

if [[ "$PLATFORM" == "wsl" ]] && [[ "$MEDIA_ROOT" == /mnt/[a-z]/* ]]; then
  warn "That path is on a Windows drive. Expect slow scans and permission trouble."
fi

CONFIG_ROOT="${CONFIG_ROOT/#\~/$HOME}"
MEDIA_ROOT="${MEDIA_ROOT/#\~/$HOME}"
DOWNLOADS_ROOT="${DOWNLOADS_ROOT/#\~/$HOME}"
PHOTOS_ROOT="${PHOTOS_ROOT/#\~/$HOME}"

step "Ownership and time"

DEF_PUID="$(id -u 2>/dev/null || echo 1000)"
DEF_PGID="$(id -g 2>/dev/null || echo 1000)"

if [[ "$PLATFORM" == "macos" || "$PLATFORM" == "gitbash" ]]; then
  # Docker Desktop maps ownership at the VM boundary; the host uid rarely applies.
  DEF_PUID=1000; DEF_PGID=1000
  info "  Docker Desktop handles file ownership itself, so 1000 is the safe"
  info "  default here regardless of your account's real user id."
fi

PUID_VALUE="$(ask "  PUID (user id that should own files):" "$DEF_PUID")"
PGID_VALUE="$(ask "  PGID (group id):" "$DEF_PGID")"
TZ_VALUE="$(ask "  Timezone:" "$(detect_tz)")"

# ─────────────────────────────────────────────────────────────── secrets ──

step "Generating secrets"

ARCANE_ENCRYPTION_KEY=""; ARCANE_JWT_SECRET=""
IMMICH_DB_PASSWORD=""; TA_PASSWORD=""; TA_ES_PASSWORD=""; ARCHIVEBOX_PASSWORD=""
KIMA_SESSION_SECRET=""; KIMA_ENCRYPTION_KEY=""

if selected arcane; then
  ARCANE_ENCRYPTION_KEY="$(gen_secret)"; ARCANE_JWT_SECRET="$(gen_secret)"
  ok "Arcane encryption key and JWT secret."
fi
if selected immich; then
  IMMICH_DB_PASSWORD="$(gen_secret)"; ok "Immich database password."
fi
if selected tubearchivist; then
  TA_PASSWORD="$(gen_secret)"; TA_ES_PASSWORD="$(gen_secret)"
  ok "Tube Archivist admin and Elasticsearch passwords."
fi
if selected archivebox; then
  ARCHIVEBOX_PASSWORD="$(gen_secret)"; ok "ArchiveBox admin password."
fi
if selected pocket-id; then
  POCKETID_ENCRYPTION_KEY="$(gen_secret)"; ok "Pocket ID encryption key."
fi
if selected kima; then
  KIMA_SESSION_SECRET="$(gen_secret)"; KIMA_ENCRYPTION_KEY="$(gen_secret)"
  ok "Kima session secret and settings encryption key."
fi
[[ -z "$ARCANE_ENCRYPTION_KEY$IMMICH_DB_PASSWORD$TA_PASSWORD$ARCHIVEBOX_PASSWORD" ]] \
  && info "Nothing selected needs a generated secret."

# ──────────────────────────────────────────────────────────── validation ──

step "Checking before writing"

PROBLEMS=0

if selected qbittorrent; then
  if selected gluetun; then
    if [[ "$VPN_PRIVATE_KEY" == "CHANGEME" || "$VPN_PROVIDER" == "CHANGEME" \
       || "$VPN_USER" == "CHANGEME" ]]; then
      warn "VPN credentials are placeholders. qBittorrent will not start until you fill them in."
      PROBLEMS=$((PROBLEMS+1))
    else
      ok "qBittorrent is behind a configured VPN."
    fi
  else
    die "qBittorrent without Gluetun. Refusing to write this."
  fi
fi

if [[ "${ARM_HOST:-0}" == "1" ]]; then
  if selected tubearchivist; then
    warn "Tube Archivist's Elasticsearch image has limited ARM support."
    info "If it won't start on this machine, that's why."
    PROBLEMS=$((PROBLEMS+1))
  fi
  selected archivebox && info "ArchiveBox on ARM works, but Chrome-based captures can be slower."
fi

ok "${#SELECTED[@]} services selected."
ok "Storage roots set."
(( PROBLEMS == 0 )) && ok "No blockers." || warn "$PROBLEMS thing(s) need your attention after install."

# ───────────────────────────────────────────────────────── compose parts ──

emit_header() {
  cat <<'YAML'
# ─────────────────────────────────────────────────────────────────────────
#  Modular Media Server
#  Generated by install.sh — edit freely, it's yours now.
#
#  Values live in .env alongside this file.
#  Bring it up with:  docker compose up -d
# ─────────────────────────────────────────────────────────────────────────

services:
YAML
}

emit_arcane() {
  cat <<'YAML'

  # Docker management in a browser. Mounts the Docker socket, which is
  # equivalent to root on this host — do not expose it to the internet.
  arcane:
    image: ghcr.io/getarcaneapp/arcane:latest
    container_name: arcane
    ports:
      - "3552:3552"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${CONFIG_ROOT}/arcane:/app/data
      - ${STACK_DIR}:/app/data/projects
    environment:
      - APP_URL=${ARCANE_APP_URL}
      - PUID=${PUID}
      - PGID=${PGID}
      - ENCRYPTION_KEY=${ARCANE_ENCRYPTION_KEY}
      - JWT_SECRET=${ARCANE_JWT_SECRET}
    restart: unless-stopped
YAML
}

emit_jellyfin() {
  cat <<'YAML'

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    user: "${PUID}:${PGID}"
    ports:
      - "8096:8096"
    volumes:
      - ${CONFIG_ROOT}/jellyfin/config:/config
      - ${CONFIG_ROOT}/jellyfin/cache:/cache
      - ${MEDIA_ROOT}:/media:ro
    environment:
      - TZ=${TZ}
YAML
  if (( IS_DESKTOP )); then
    cat <<'YAML'
    # Hardware transcoding isn't reachable through Docker Desktop's VM.
    # Transcoding here is CPU-only. On native Linux you would add:
    #   devices:
    #     - /dev/dri:/dev/dri
YAML
  else
    cat <<'YAML'
    # For Intel QuickSync hardware transcoding, uncomment:
    # devices:
    #   - /dev/dri:/dev/dri
YAML
  fi
  cat <<'YAML'
    restart: unless-stopped
YAML
}

emit_jellyseerr() {
  cat <<'YAML'

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    ports:
      - "5055:5055"
    volumes:
      - ${CONFIG_ROOT}/jellyseerr:/app/config
    environment:
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

emit_arr() { # emit_arr <name> <port> <extra volume line>
  cat <<YAML

  $1:
    image: lscr.io/linuxserver/$1:latest
    container_name: $1
    ports:
      - "$2:$2"
    volumes:
      - \${CONFIG_ROOT}/$1:/config
$3
      - \${DOWNLOADS_ROOT}:/downloads
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    restart: unless-stopped
YAML
}

emit_bazarr() {
  cat <<'YAML'

  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    ports:
      - "6767:6767"
    volumes:
      - ${CONFIG_ROOT}/bazarr:/config
      - ${MEDIA_ROOT}/movies:/movies
      - ${MEDIA_ROOT}/tv:/tv
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

emit_gluetun() {
  local ports=""
  selected qbittorrent && ports+=$'      - "8080:8080"   # qBittorrent web UI\n'
  selected qbittorrent && ports+=$'      - "6881:6881"\n      - "6881:6881/udp"\n'
  selected jackett     && ports+=$'      - "9117:9117"   # Jackett\n'
  cat <<YAML

  # Everything that routes through the VPN publishes its ports here,
  # because those containers share this container's network stack.
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
$ports    volumes:
      - \${CONFIG_ROOT}/gluetun:/gluetun
    environment:
      - VPN_SERVICE_PROVIDER=\${VPN_SERVICE_PROVIDER}
      - VPN_TYPE=\${VPN_TYPE}
YAML
  if [[ "$VPN_TYPE" == "wireguard" ]]; then
    cat <<'YAML'
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
YAML
  else
    cat <<'YAML'
      - OPENVPN_USER=${OPENVPN_USER}
      - OPENVPN_PASSWORD=${OPENVPN_PASSWORD}
YAML
  fi
  cat <<'YAML'
      - SERVER_COUNTRIES=${VPN_SERVER_COUNTRIES}
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

emit_qbittorrent() {
  cat <<'YAML'

  # network_mode ties this container to Gluetun. If the VPN drops,
  # this container loses its network too. That is the point.
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "service:gluetun"
    volumes:
      - ${CONFIG_ROOT}/qbittorrent:/config
      - ${DOWNLOADS_ROOT}:/downloads
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - WEBUI_PORT=8080
    depends_on:
      gluetun:
        condition: service_started
    restart: unless-stopped
YAML
}

emit_jackett() {
  if selected gluetun; then
    cat <<'YAML'

  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    network_mode: "service:gluetun"
    volumes:
      - ${CONFIG_ROOT}/jackett:/config
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    depends_on:
      gluetun:
        condition: service_started
    restart: unless-stopped
YAML
  else
    cat <<'YAML'

  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    ports:
      - "9117:9117"
    volumes:
      - ${CONFIG_ROOT}/jackett:/config
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
YAML
  fi
}

emit_immich() {
  cat <<'YAML'

  immich-server:
    image: ghcr.io/immich-app/immich-server:release
    container_name: immich_server
    ports:
      - "2283:2283"
    volumes:
      - ${PHOTOS_ROOT}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    environment:
      - DB_HOSTNAME=immich_postgres
      - DB_USERNAME=postgres
      - DB_PASSWORD=${IMMICH_DB_PASSWORD}
      - DB_DATABASE_NAME=immich
      - REDIS_HOSTNAME=immich_redis
      - TZ=${TZ}
    depends_on:
      - immich-redis
      - immich-postgres
    restart: unless-stopped

  immich-machine-learning:
    image: ghcr.io/immich-app/immich-machine-learning:release
    container_name: immich_ml
    volumes:
      - ${CONFIG_ROOT}/immich/ml-cache:/cache
    restart: unless-stopped

  immich-redis:
    image: docker.io/valkey/valkey:8-bookworm
    container_name: immich_redis
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped

  immich-postgres:
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
    container_name: immich_postgres
    environment:
      - POSTGRES_PASSWORD=${IMMICH_DB_PASSWORD}
      - POSTGRES_USER=postgres
      - POSTGRES_DB=immich
      - POSTGRES_INITDB_ARGS=--data-checksums
    volumes:
      - ${CONFIG_ROOT}/immich/postgres:/var/lib/postgresql/data
    restart: unless-stopped
YAML
}

emit_kima() {
  cat <<'YAML'

  # All-in-one container: it runs its own Postgres and Redis internally,
  # so there are no separate database services to add.
  kima:
    image: chevron7locked/kima:latest
    container_name: kima
    ports:
      - "3030:3030"
    volumes:
      - ${MEDIA_ROOT}/music:/music
      - kima_data:/data
    environment:
      - SESSION_SECRET=${KIMA_SESSION_SECRET}
      - SETTINGS_ENCRYPTION_KEY=${KIMA_ENCRYPTION_KEY}
      - TZ=${TZ}
    # Lets Lidarr reach Kima's webhook callback on Linux hosts.
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
YAML
}

emit_uptime_kuma() {
  cat <<'YAML'

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    ports:
      - "3001:3001"
    volumes:
      - ${CONFIG_ROOT}/uptime-kuma:/app/data
    # Uncomment for "Docker Container" monitors. Read-only, but socket
    # access is still powerful — HTTP monitors need none of this.
    #  - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

emit_archivebox() {
  cat <<'YAML'

  archivebox:
    image: archivebox/archivebox:latest
    container_name: archivebox
    ports:
      - "8000:8000"
    volumes:
      - ${CONFIG_ROOT}/archivebox:/data
    environment:
      - ALLOWED_HOSTS=*
      - PUBLIC_INDEX=False
      - PUBLIC_SNAPSHOTS=False
      - PUBLIC_ADD_VIEW=False
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=${ARCHIVEBOX_PASSWORD}
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

emit_tubearchivist() {
  cat <<'YAML'

  tubearchivist:
    image: bbilly1/tubearchivist:latest
    container_name: tubearchivist
    ports:
      - "8001:8000"
    volumes:
      - ${MEDIA_ROOT}/youtube:/youtube
      - ${CONFIG_ROOT}/tubearchivist/cache:/cache
    environment:
      - ES_URL=http://tubearchivist-es:9200
      - REDIS_CON=redis://tubearchivist-redis:6379
      - HOST_UID=${PUID}
      - HOST_GID=${PGID}
      - TA_HOST=http://localhost:8001
      - TA_USERNAME=admin
      - TA_PASSWORD=${TA_PASSWORD}
      - ELASTIC_PASSWORD=${TA_ES_PASSWORD}
      - TZ=${TZ}
    depends_on:
      - tubearchivist-es
      - tubearchivist-redis
    restart: unless-stopped

  tubearchivist-redis:
    image: redis:7
    container_name: tubearchivist_redis
    volumes:
      - ${CONFIG_ROOT}/tubearchivist/redis:/data
    depends_on:
      - tubearchivist-es
    restart: unless-stopped

  tubearchivist-es:
    image: bbilly1/tubearchivist-es:latest
    container_name: tubearchivist_es
    environment:
      - ELASTIC_PASSWORD=${TA_ES_PASSWORD}
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
      - xpack.security.enabled=true
      - discovery.type=single-node
      - path.repo=/usr/share/elasticsearch/data/snapshot
    volumes:
      - ${CONFIG_ROOT}/tubearchivist/es:/usr/share/elasticsearch/data
    restart: unless-stopped
YAML
}

emit_caddy() {
  cat <<'YAML'

  # Terminates HTTPS and routes by hostname. Only this container should
  # have ports open to the world — 80 and 443, nothing else.
  caddy:
    image: caddy:latest
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ${STACK_DIR}/Caddyfile:/etc/caddy/Caddyfile:ro
      - ${CONFIG_ROOT}/caddy/data:/data
      - ${CONFIG_ROOT}/caddy/config:/config
    environment:
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

emit_tailscale() {
  cat <<'YAML'

  # Private mesh network — nothing is published publicly.
  # Installing Tailscale on the host is usually simpler and covers every
  # service at once; use this when you cannot install on the host.
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: media-server
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - ${CONFIG_ROOT}/tailscale:/var/lib/tailscale
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
    restart: unless-stopped
YAML
}

emit_cloudflared() {
  cat <<'YAML'

  # Outbound-only connection to Cloudflare — nothing is opened on your router.
  # Which hostname maps to which service is configured in the Zero Trust
  # dashboard, not in this file.
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: tunnel --no-autoupdate run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    restart: unless-stopped
YAML
}

emit_pocket_id() {
  cat <<'YAML'

  # Passkey-only identity provider. APP_URL must match the address you
  # visit exactly — passkeys are bound to that origin.
  pocket-id:
    image: ghcr.io/pocket-id/pocket-id:v2
    container_name: pocket-id
    expose:
      - "1411"
    volumes:
      - ${CONFIG_ROOT}/pocket-id:/app/data
    environment:
      - APP_URL=${POCKETID_URL}
      - ENCRYPTION_KEY=${POCKETID_ENCRYPTION_KEY}
      - TRUST_PROXY=true
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
YAML
}

build_caddyfile() {
  cat <<EOF
# Caddyfile — generated by install.sh
#
# Caddy requests a certificate for every name below, so each one must
# already resolve to this machine. Remove any you are not using.
#
# While testing, uncomment the staging line to avoid rate limits:
# {
#     acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
# }

EOF
  selected pocket-id && cat <<EOF
id.${BASE_DOMAIN} {
    reverse_proxy pocket-id:1411
}

EOF
  selected jellyfin && cat <<EOF
jellyfin.${BASE_DOMAIN} {
    reverse_proxy jellyfin:8096
}

EOF
  selected jellyseerr && cat <<EOF
requests.${BASE_DOMAIN} {
    reverse_proxy jellyseerr:5055
}

EOF
  selected immich && cat <<EOF
photos.${BASE_DOMAIN} {
    reverse_proxy immich-server:2283
}

EOF
  cat <<'EOF'
# Deliberately not proxied: Arcane, qBittorrent, Sonarr, Radarr, Lidarr,
# Jackett and Bazarr. These hold the Docker socket, write files anywhere,
# or authenticate weakly. Reach them over Tailscale or your LAN instead.
EOF
  return 0
}

build_compose() {
  emit_header
  selected arcane        && emit_arcane
  selected jellyfin      && emit_jellyfin
  selected jellyseerr    && emit_jellyseerr
  selected sonarr        && emit_arr sonarr 8989 '      - ${MEDIA_ROOT}/tv:/tv'
  selected radarr        && emit_arr radarr 7878 '      - ${MEDIA_ROOT}/movies:/movies'
  selected lidarr        && emit_arr lidarr 8686 '      - ${MEDIA_ROOT}/music:/music'
  selected bazarr        && emit_bazarr
  selected gluetun       && emit_gluetun
  selected qbittorrent   && emit_qbittorrent
  selected jackett       && emit_jackett
  selected immich        && emit_immich
  selected kima          && emit_kima
  selected uptime-kuma   && emit_uptime_kuma
  selected archivebox    && emit_archivebox
  selected tubearchivist && emit_tubearchivist
  selected caddy         && emit_caddy
  selected tailscale     && emit_tailscale
  selected cloudflared   && emit_cloudflared
  selected pocket-id     && emit_pocket_id
  # Kima's docs recommend a named volume for /data rather than a bind mount.
  selected kima && printf '\nvolumes:\n  kima_data:\n'
  return 0
}

build_env() { # build_env <real|example>
  local mode="$1" secret placeholder="CHANGEME"
  cat <<EOF
# Modular Media Server — environment
# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)
$( [[ "$mode" == "example" ]] && echo "# Template. Copy to .env and fill in." || echo "# Real values. Never commit this file." )

# ── Paths ────────────────────────────────────────────────────────────────
STACK_DIR=$INSTALL_DIR
CONFIG_ROOT=$CONFIG_ROOT
MEDIA_ROOT=$MEDIA_ROOT
DOWNLOADS_ROOT=$DOWNLOADS_ROOT
EOF
  selected immich && echo "PHOTOS_ROOT=$PHOTOS_ROOT"
  cat <<EOF

# ── Ownership and time ───────────────────────────────────────────────────
PUID=$PUID_VALUE
PGID=$PGID_VALUE
TZ=$TZ_VALUE
EOF

  if selected arcane; then
    if [[ "$mode" == "example" ]]; then
      secret="$placeholder"
      cat <<EOF

# ── Arcane ───────────────────────────────────────────────────────────────
# Generate each with: openssl rand -base64 32
ARCANE_APP_URL=http://localhost:3552
ARCANE_ENCRYPTION_KEY=$secret
ARCANE_JWT_SECRET=$secret
EOF
    else
      cat <<EOF

# ── Arcane ───────────────────────────────────────────────────────────────
ARCANE_APP_URL=http://localhost:3552
ARCANE_ENCRYPTION_KEY=$ARCANE_ENCRYPTION_KEY
ARCANE_JWT_SECRET=$ARCANE_JWT_SECRET
EOF
    fi
  fi

  if selected gluetun; then
    cat <<EOF

# ── VPN ──────────────────────────────────────────────────────────────────
# Provider names must match Gluetun's spelling exactly.
VPN_SERVICE_PROVIDER=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$VPN_PROVIDER" )
VPN_TYPE=$VPN_TYPE
VPN_SERVER_COUNTRIES=$( [[ "$mode" == "example" ]] && echo "" || echo "$VPN_COUNTRIES" )
EOF
    if [[ "$VPN_TYPE" == "wireguard" ]]; then
      cat <<EOF
WIREGUARD_PRIVATE_KEY=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$VPN_PRIVATE_KEY" )
WIREGUARD_ADDRESSES=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$VPN_ADDRESSES" )
EOF
    else
      cat <<EOF
OPENVPN_USER=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$VPN_USER" )
OPENVPN_PASSWORD=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$VPN_PASSWORD" )
EOF
    fi
  fi

  if selected caddy; then
    cat <<EOF

# ── Domain ───────────────────────────────────────────────────────────────
BASE_DOMAIN=$BASE_DOMAIN
EOF
  fi

  if selected cloudflared; then
    cat <<EOF

# ── Cloudflare Tunnel ────────────────────────────────────────────────────
# Zero Trust dashboard -> Networks -> Tunnels -> your tunnel -> token.
CLOUDFLARE_TUNNEL_TOKEN=CHANGEME
EOF
  fi

  if selected tailscale; then
    cat <<EOF

# ── Tailscale ────────────────────────────────────────────────────────────
# Generate in the Tailscale admin console under Settings → Keys.
TS_AUTHKEY=CHANGEME
EOF
  fi

  if selected pocket-id; then
    cat <<EOF
POCKETID_URL=https://id.$BASE_DOMAIN
POCKETID_ENCRYPTION_KEY=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$POCKETID_ENCRYPTION_KEY" )
EOF
  fi

  if selected immich; then
    cat <<EOF

# ── Immich ───────────────────────────────────────────────────────────────
IMMICH_DB_PASSWORD=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$IMMICH_DB_PASSWORD" )
EOF
  fi

  if selected kima; then
    cat <<EOF

# ── Kima ─────────────────────────────────────────────────────────────────
# SETTINGS_ENCRYPTION_KEY is required; Kima will not start without it.
KIMA_SESSION_SECRET=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$KIMA_SESSION_SECRET" )
KIMA_ENCRYPTION_KEY=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$KIMA_ENCRYPTION_KEY" )
EOF
  fi

  if selected archivebox; then
    cat <<EOF

# ── ArchiveBox ───────────────────────────────────────────────────────────
ARCHIVEBOX_PASSWORD=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$ARCHIVEBOX_PASSWORD" )
EOF
  fi

  if selected tubearchivist; then
    cat <<EOF

# ── Tube Archivist ───────────────────────────────────────────────────────
TA_PASSWORD=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$TA_PASSWORD" )
TA_ES_PASSWORD=$( [[ "$mode" == "example" ]] && echo "$placeholder" || echo "$TA_ES_PASSWORD" )
EOF
  fi
  return 0
}

service_url() {
  case "$1" in
    arcane) echo "http://localhost:3552" ;;
    jellyfin) echo "http://localhost:8096" ;;
    jellyseerr) echo "http://localhost:5055" ;;
    sonarr) echo "http://localhost:8989" ;;
    radarr) echo "http://localhost:7878" ;;
    lidarr) echo "http://localhost:8686" ;;
    bazarr) echo "http://localhost:6767" ;;
    qbittorrent) echo "http://localhost:8080" ;;
    jackett) echo "http://localhost:9117" ;;
    immich) echo "http://localhost:2283" ;;
    kima) echo "http://localhost:3030" ;;
    uptime-kuma) echo "http://localhost:3001" ;;
    archivebox) echo "http://localhost:8000" ;;
    tubearchivist) echo "http://localhost:8001" ;;
    caddy) echo "https://${BASE_DOMAIN:-your-domain}" ;;
    pocket-id) echo "https://id.${BASE_DOMAIN:-your-domain}" ;;
    tailscale) echo "(no web interface)" ;;
    cloudflared) echo "(no web interface)" ;;
    *) echo "" ;;
  esac
}

build_readme() {
  cat <<EOF
# My media server

Generated by the Modular Media Server installer on $(date -u +%Y-%m-%d).

## Running it

    docker compose up -d      # start everything
    docker compose ps         # what's running
    docker compose logs -f    # watch the logs
    docker compose pull       # fetch newer images
    docker compose down       # stop everything

## What's here

| Service | Address |
| --- | --- |
EOF
  for m in "${SELECTED[@]}"; do
    local u; u="$(service_url "$m")"
    [[ -n "$u" ]] && echo "| $(module_label "$m") | $u |"
  done

  cat <<EOF

Replace \`localhost\` with the server's address if you're connecting from
another machine.

## Files

- \`docker-compose.yml\` — the stack
- \`.env\` — your real settings and secrets, **never commit this**
- \`.env.example\` — a blank template that is safe to share
- \`.gitignore\` — keeps \`.env\` out of git

## First steps

1. Set a password on every service that asks. Some start wide open.
2. Point the *arr apps at your download client and indexers.
3. Check the paths inside containers match what you set in \`.env\`.
EOF

  if selected qbittorrent; then
    cat <<EOF

## Before you download anything

Confirm the VPN is actually carrying the traffic:

    docker compose exec gluetun wget -qO- https://ipinfo.io/ip

That must not be your home address. If Gluetun is unhealthy, qBittorrent
loses its network with it — that's intended, not a fault.

Downloaded files can carry malware. A VPN changes how traffic is routed;
it does not make a file safe. Only download what you're legally entitled to.
EOF
  fi

  cat <<EOF

## Backups

Back up \`$CONFIG_ROOT\` and this directory. That's your configuration and
your secrets. Media can be re-acquired; a working setup and your photos
often can't.

## Licences

Each application here is a separate open-source project with its own
licence and terms. This file doesn't grant you any rights to content —
you're responsible for what you store and share.
EOF
  return 0
}

# ───────────────────────────────────────────────────────────────── write ──

if (( DRY_RUN )); then
  step "Dry run — nothing will be written"
  rule
  build_compose
  rule
  say ""
  info "# .env would contain:"
  build_env real
  if selected caddy; then
    rule
    info "# Caddyfile would contain:"
    build_caddyfile
  fi
  rule
  exit 0
fi

step "Writing files"

mkdir -p "$INSTALL_DIR" || die "Can't create $INSTALL_DIR"
cd "$INSTALL_DIR"

if [[ -f docker-compose.yml ]] && ! (( ASSUME_YES )); then
  confirm "  docker-compose.yml already exists here. Overwrite?" "n" \
    || die "Left everything alone."
fi

if [[ -f .env ]]; then
  cp .env ".env.backup.$(date +%Y%m%d%H%M%S)"
  warn "Existing .env backed up."
fi

build_compose > docker-compose.yml;  ok "docker-compose.yml"
build_env real > .env;               ok ".env"
build_env example > .env.example;    ok ".env.example"
build_readme > README.md;            ok "README.md"

if selected caddy; then
  if [[ -f Caddyfile ]]; then
    cp Caddyfile "Caddyfile.backup.$(date +%Y%m%d%H%M%S)"
    warn "Existing Caddyfile backed up."
  fi
  build_caddyfile > Caddyfile;       ok "Caddyfile"
fi

cat > .gitignore <<'EOF'
# Never commit real secrets.
.env
.env.backup.*
config/
data/
EOF
ok ".gitignore"

chmod 600 .env 2>/dev/null && ok ".env locked to your user only."

mkdir -p "$CONFIG_ROOT" 2>/dev/null && ok "Config directory ready." \
  || warn "Couldn't create $CONFIG_ROOT — you may need to make it yourself."

for d in "$MEDIA_ROOT" "$DOWNLOADS_ROOT" ${PHOTOS_ROOT:+"$PHOTOS_ROOT"}; do
  if [[ ! -d "$d" ]]; then
    mkdir -p "$d" 2>/dev/null && ok "Created $d" \
      || warn "Couldn't create $d — make it before starting, or the mount will be empty."
  fi
done

if selected sonarr || selected radarr || selected lidarr || selected jellyfin; then
  mkdir -p "$MEDIA_ROOT"/{movies,tv,music} 2>/dev/null || true
fi

# ────────────────────────────────────────────────────────────────── done ──

step "Done"
rule
say ""
say "  ${B}Your stack is in${R} $INSTALL_DIR"
say ""
for m in "${SELECTED[@]}"; do
  u="$(service_url "$m")"
  printf '    %s%-16s%s %s\n' "$TEAL" "$m" "$R" "${DIM}${u}${R}"
done
say ""

if (( PROBLEMS > 0 )); then
  warn "Edit .env and replace every CHANGEME before starting."
  say ""
fi

if selected arcane; then
  say "  ${DIM}Arcane mounts the Docker socket, which gives it full control of this${R}"
  say "  ${DIM}host. Keep it on your local network or behind a VPN, never public.${R}"
  say ""
fi

if selected caddy; then
  say "  ${B}Before starting Caddy:${R}"
  say "  ${DIM}· Point your DNS records at this machine${R}"
  say "  ${DIM}· Forward ports 80 and 443 on your router — those two only${R}"
  say "  ${DIM}· Review the Caddyfile and remove any hostnames you are not using${R}"
  say ""
fi

if selected pocket-id; then
  say "  ${B}Once Pocket ID is up at https://id.${BASE_DOMAIN}:${R}"
  say "  ${DIM}· Complete the setup wizard and register a passkey${R}"
  say "  ${DIM}· Register a SECOND passkey on another device straight away${R}"
  say "  ${DIM}  One passkey on one device means a lost phone locks you out.${R}"
  say ""
fi

should_deploy=0
if [[ "$DO_DEPLOY" == "1" ]]; then
  should_deploy=1
elif [[ "$DO_DEPLOY" == "0" ]]; then
  should_deploy=0
elif (( DOCKER_OK )) && (( PROBLEMS == 0 )) && ! (( ASSUME_YES )); then
  confirm "  Start it now?" "y" && should_deploy=1
fi

if (( should_deploy )); then
  (( DOCKER_OK )) || die "Docker isn't available, so there's nothing to start."
  step "Starting"
  docker compose up -d
  say ""
  ok "Running. 'docker compose ps' shows the current state."
else
  say "  When you're ready:"
  say "    ${DIM}cd $INSTALL_DIR && docker compose up -d${R}"
fi

say ""
info "  Only store and share content you have the right to. Downloaded files"
info "  can be malicious — a VPN routes traffic, it doesn't sanitise files."
say ""
