#!/usr/bin/env bash
# Idempotent installer: each phase checks what is already installed and only
# installs what is missing or upgrades what is outdated.
#
#   ./install.sh                  install missing, upgrade outdated
#   ./install.sh --check          report what would change, change nothing
#   ./install.sh --only nvim,go   run only the named phases
#   ./install.sh --force          reinstall everything
#   ./install.sh --no-upgrade     install missing only, leave existing versions
#   ./install.sh --list           list phase names

set -uo pipefail

# Pinned versions. Everything else tracks the latest release.
NVIM_VERSION="v0.11.6"
NERD_FONT_VERSION="v3.5.1"
NODE_MAJOR="26"
UV_PYTHON="3.13"

APT_PACKAGES=(
  xclip
  stow
  build-essential # compiles treesitter parsers
  unzip           # several Mason-installed tools (stylua, selene, terraform-ls, tflint, ...) ship as .zip
  ripgrep         # used by pickers/live-grep
  fd-find         # used by pickers/live-grep
  python3-pip     # Mason installs Python-based tools (e.g. nginx-config-formatter) into their own venv
  python3-venv
  htop
  btop
  # plus libicuNN, resolved at runtime: marksman (Markdown LSP) is a .NET binary
  # that aborts (SIGABRT) on startup without an ICU package installed on the system
)

# Non-interactive `bash install.sh` doesn't source .bashrc, so make the
# user-level install locations visible to the version checks.
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.atuin/bin:$PNPM_HOME:/usr/local/go/bin:$PATH"

if [[ -t 1 ]]; then
  GREEN=$'\e[32m' YELLOW=$'\e[33m' ORANGE=$'\e[38;5;208m' RED=$'\e[31m' BOLD=$'\e[1m' RESET=$'\e[0m'
else
  GREEN="" YELLOW="" ORANGE="" RED="" BOLD="" RESET=""
fi

phase_line() { # color message
  printf '%s%sPhase %d/%d %s:%s %s%s\n' "$1" "$BOLD" "$PHASE_NUM" "$PHASE_TOTAL" "$PHASE_NAME" "$RESET$1" "$2" "$RESET"
}

skip() {
  OUTCOME[$PHASE_NAME]=skipped
  phase_line "$GREEN" "skipped, no changes needed ($1)"
}

# Check functions report what they found as three lines: want, have, and an
# optional note shown instead of the version when the phase is skipped.
found() {
  # An empty want means a lookup failed (a failing `$(...)` used as an
  # argument doesn't trigger set -e)
  [[ -n $1 ]] || { echo "could not determine target version" >&2; return 1; }
  printf '%s\n%s\n%s\n' "$1" "$2" "${3:-}"
}

# plan <want> <have> [note]: prints the phase outcome and returns 0 when the
# phase should go ahead and install/update, 1 when there is nothing to do (or
# --check). Sets ACTION to install|update for the install function.
plan() {
  local want=${1#v} have=${2#v} note=${3:-} verb
  if [[ -z $have ]]; then
    ACTION=install
  elif [[ $want == "$have" && $FORCE == 0 ]] || [[ $NO_UPGRADE == 1 && $FORCE == 0 ]]; then
    skip "${note:-$have}"
    return 1
  else
    ACTION=update
  fi

  verb=$([[ $CHECK == 1 ]] && echo "would " || echo "")
  if [[ $ACTION == install ]]; then
    phase_line "$YELLOW" "${verb}install $want"
  elif [[ $want == "$have" ]]; then
    phase_line "$ORANGE" "${verb}reinstall $have (--force)"
  else
    phase_line "$ORANGE" "${verb}update $have → $want"
  fi

  if [[ $CHECK == 1 ]]; then
    OUTCOME[$PHASE_NAME]=would-$ACTION
    return 1
  fi
  OUTCOME[$PHASE_NAME]=$ACTION
}

# Latest release tag via the /releases/latest redirect, avoiding the GitHub
# API's 60 requests/hour limit for unauthenticated calls.
latest_gh_tag() {
  curl -fsSI "https://github.com/$1/releases/latest" | grep -Pio '^location:.*/tag/v?\K[^\r\n]+'
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

load_nvm() {
  # nvm.sh trips over `set -u`
  set +u
  [[ -s $NVM_DIR/nvm.sh ]] && . "$NVM_DIR/nvm.sh"
  set -u
}

apt_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

latest_icu() {
  apt-cache pkgnames libicu 2>/dev/null | grep -E '^libicu[0-9]+$' | sort -V | tail -1 || true
}

check_apt() {
  local icu missing=() pkg
  icu=$(latest_icu)
  for pkg in "${APT_PACKAGES[@]}" ${icu:-}; do
    apt_installed "$pkg" || missing+=("$pkg")
  done
  [[ -z $icu ]] && missing+=("libicu")
  if [[ ${#missing[@]} -eq 0 ]]; then
    found present present "${#APT_PACKAGES[@]} packages + $icu present"
  else
    found "${missing[*]}" ""
  fi
}
install_apt() {
  local icu
  sudo apt-get update
  icu=$(latest_icu)
  sudo apt-get install -y "${APT_PACKAGES[@]}" ${icu:+"$icu"}
}

# Debian/Ubuntu installs fd-find's binary as `fdfind`, not `fd` (the name `fd`
# was already taken in their archive), so symlink it to the name most tools expect
check_fd_link() {
  local have=""
  [[ $(readlink /usr/local/bin/fd 2>/dev/null) == "$(command -v fdfind || echo /usr/bin/fdfind)" ]] && have=linked
  found linked "$have"
}
install_fd_link() {
  sudo ln -sf "$(command -v fdfind || echo /usr/bin/fdfind)" /usr/local/bin/fd
}

# Neovim, pinned to a known-good version rather than whatever the distro's
# apt repo happens to carry (older Ubuntu releases ship Neovim versions far
# too old for AstroNvim). Installs to /opt/nvim-linux64 (matches the PATH
# entry already in .bashrc) and symlinks into /usr/local/bin, which comes
# before /usr/bin on PATH, so this wins even if a distro neovim package is
# also present.
check_nvim() {
  found "$NVIM_VERSION" "$(/opt/nvim-linux64/bin/nvim --version 2>/dev/null | grep -Po '^NVIM \K\S+' || true)"
}
install_nvim() {
  curl -fLo "$TMP/nvim.tar.gz" "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  sudo rm -rf /opt/nvim-linux64
  sudo tar -C /opt -xzf "$TMP/nvim.tar.gz"
  sudo mv /opt/nvim-linux-x86_64 /opt/nvim-linux64
  sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
}

check_lazygit() {
  found "$(latest_gh_tag jesseduffield/lazygit)" "$(lazygit --version 2>/dev/null | grep -Po ', version=\K[^,]+' || true)"
}
install_lazygit() {
  curl -fLo "$TMP/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${WANT}/lazygit_${WANT}_Linux_x86_64.tar.gz"
  tar -C "$TMP" -xf "$TMP/lazygit.tar.gz" lazygit
  sudo install -D -t /usr/local/bin/ "$TMP/lazygit"
}

# fzf, from GitHub releases: the apt package is too old for `fzf --bash`
# (added in 0.48), which .bashrc uses. Installs to ~/.local/bin, which comes
# before /usr/bin on PATH, so this wins over any apt fzf.
check_fzf() {
  found "$(latest_gh_tag junegunn/fzf)" "$("$HOME/.local/bin/fzf" --version 2>/dev/null | awk '{print $1}' || true)"
}
install_fzf() {
  curl -fLo "$TMP/fzf.tar.gz" "https://github.com/junegunn/fzf/releases/download/v${WANT}/fzf-${WANT}-linux_amd64.tar.gz"
  tar -C "$TMP" -xf "$TMP/fzf.tar.gz" fzf
  install -D -t ~/.local/bin "$TMP/fzf"
}

# Rust toolchain via rustup: creates ~/.cargo/env, which .bashrc sources
check_rust() {
  local want have
  have=$(rustc +stable --version 2>/dev/null | awk '{print $2}' || true)
  want=$(rustup check 2>/dev/null | grep -Pio '^stable-.*-> \K[0-9.]+' || true)
  found "${want:-${have:-stable}}" "$have"
}
install_rust() {
  if [[ $ACTION == install ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  else
    rustup update stable
  fi
}

# cargo-binstall: fetches prebuilt release binaries instead of compiling crates
check_binstall() {
  found "$(latest_gh_tag cargo-bins/cargo-binstall)" "$(cargo binstall -V 2>/dev/null | awk '{print $NF}' || true)"
}
# Release tarball directly: the official install script runs under `set -x` and floods the output.
install_binstall() {
  curl -fLo "$TMP/binstall.tgz" "https://github.com/cargo-bins/cargo-binstall/releases/download/v${WANT}/cargo-binstall-x86_64-unknown-linux-musl.tgz"
  tar -C "$TMP" -xzf "$TMP/binstall.tgz" cargo-binstall
  install -D -t ~/.cargo/bin "$TMP/cargo-binstall"
}

# just (task runner for the justfile), prebuilt binary via cargo-binstall into ~/.cargo/bin
check_just() {
  found "$(latest_gh_tag casey/just)" "$(just --version 2>/dev/null | awk '{print $2}' || true)"
}
install_just() {
  cargo binstall --no-confirm --force "just@$WANT"
}

# atuin: the installer creates ~/.atuin/bin/env, which .bashrc sources.
# Local-only history afterwards: `atuin import auto` (no cloud sync).
check_atuin() {
  found "$(latest_gh_tag atuinsh/atuin)" "$(atuin --version 2>/dev/null | awk '{print $2}' || true)"
}
install_atuin() {
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
}

# zoxide: official installer puts the binary in ~/.local/bin
check_zoxide() {
  found "$(latest_gh_tag ajeetdsouza/zoxide)" "$(zoxide --version 2>/dev/null | awk '{print $2}' || true)"
}
install_zoxide() {
  curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

# Go, from the official tarball into /usr/local/go (the PATH entry already in .bashrc).
# Mason builds gopls, delve, goimports etc. with `go install`.
check_go() {
  local want have
  want=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
  have=$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}' || true)
  found "${want#go}" "${have#go}"
}
install_go() {
  curl -fLo "$TMP/go.tar.gz" "https://go.dev/dl/go${WANT}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$TMP/go.tar.gz"
}

# nvm (sourced by .bashrc). Re-running the installer updates an existing nvm.
check_nvm() {
  found "$(latest_gh_tag nvm-sh/nvm)" "$(load_nvm && nvm --version 2>/dev/null || true)"
}
install_nvm() {
  curl -fsSo- "https://raw.githubusercontent.com/nvm-sh/nvm/v${WANT}/install.sh" | PROFILE=/dev/null bash
}

# Node via nvm: Mason installs biome, yaml-language-server, json-lsp and
# mdx-analyzer with npm. Without nvm yet (fresh machine), the check can only
# say "install"; `nvm install` picks the newest release of the major anyway.
check_node() {
  local have
  load_nvm
  if ! command -v nvm >/dev/null; then
    found "$NODE_MAJOR.x" ""
    return
  fi
  have=$(nvm version "$NODE_MAJOR")
  found "$(nvm version-remote "$NODE_MAJOR")" "${have/#N\/A/}"
}
install_node() {
  load_nvm
  if [[ $ACTION == install ]]; then
    nvm install "$NODE_MAJOR"
  else
    nvm install "$NODE_MAJOR" --reinstall-packages-from="$HAVE"
  fi
  nvm alias default "$NODE_MAJOR"
}

# pnpm, standalone installer (needs no Node, but sits with the other JS tooling)
check_pnpm() {
  found "$(latest_gh_tag pnpm/pnpm)" "$(pnpm --version 2>/dev/null || true)"
}
install_pnpm() {
  if [[ $ACTION == install ]]; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  else
    pnpm self-update
  fi
}

check_uv() {
  found "$(latest_gh_tag astral-sh/uv)" "$(uv --version 2>/dev/null | awk '{print $2}' || true)"
}
install_uv() {
  if [[ $ACTION == install ]]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  else
    uv self update
  fi
}

# Python 3.13 via uv: the distro's python3 can be newer than Mason's Python tools
# support (nginx-language-server needs <3.14). uv puts python3.13 in ~/.local/bin,
# which Mason finds as a versioned candidate without replacing the system python3.
check_python() {
  local have
  have=$(uv python list --only-installed --managed-python "$UV_PYTHON" 2>/dev/null |
    grep -Po '^cpython-\K[0-9.]+' | head -1 || true)
  found "$UV_PYTHON" "${have:+$UV_PYTHON}" "$have"
}
install_python() {
  uv python install "$UV_PYTHON"
}

# kubectl, latest stable release, installed to /usr/local/bin
check_kubectl() {
  found "$(curl -fsSL https://dl.k8s.io/release/stable.txt)" \
    "$(kubectl version --client 2>/dev/null | grep -Po 'Client Version: \K\S+' || true)"
}
install_kubectl() {
  curl -fLo "$TMP/kubectl" "https://dl.k8s.io/release/${WANT}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 "$TMP/kubectl" /usr/local/bin/kubectl
}

# Inconsolata Nerd Font, per-user install to ~/.local/share/fonts.
# A .version marker records which release is installed.
FONT_DIR=~/.local/share/fonts/InconsolataNerdFont
check_font() {
  local have=""
  if [[ -f $FONT_DIR/.version ]]; then
    have=$(<"$FONT_DIR/.version")
  elif compgen -G "$FONT_DIR/*.ttf" >/dev/null; then
    have=unknown
  fi
  found "$NERD_FONT_VERSION" "$have"
}
install_font() {
  curl -fLo "$TMP/Inconsolata.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/Inconsolata.zip"
  mkdir -p "$FONT_DIR"
  unzip -o -q "$TMP/Inconsolata.zip" '*.ttf' -d "$FONT_DIR"
  echo "$NERD_FONT_VERSION" >"$FONT_DIR/.version"
  fc-cache -f ~/.local/share/fonts
}

# Docker Engine from Docker's apt repo. Skipped when any docker CLI is already
# present (e.g. Docker Desktop's WSL integration); updates come via apt upgrade.
check_docker() {
  local have
  have=$(docker --version 2>/dev/null | grep -Po 'version \K[^,]+' || true)
  found "${have:-docker-ce}" "$have" "$have, updates via apt upgrade"
}
install_docker() {
  # Add Docker's official GPG key
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources
  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Use docker (and lazydocker) without sudo; takes effect in new login shells
  sudo usermod -aG docker "$USER"
}

# lazydocker: official install/update script puts the binary in ~/.local/bin
check_lazydocker() {
  found "$(latest_gh_tag jesseduffield/lazydocker)" \
    "$(lazydocker --version 2>/dev/null | grep -Po '^Version: \K\S+' || true)"
}
install_lazydocker() {
  curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
}

PHASES=(apt fd_link nvim lazygit fzf rust binstall just atuin zoxide go nvm node pnpm uv python kubectl font docker lazydocker)

CHECK=0 FORCE=0 NO_UPGRADE=0 ONLY=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --check) CHECK=1 ;;
    --force) FORCE=1 ;;
    --no-upgrade) NO_UPGRADE=1 ;;
    --only) ONLY=${2:?--only needs a comma-separated list}; shift ;;
    --only=*) ONLY=${1#--only=} ;;
    --list) printf '%s\n' "${PHASES[@]}"; exit 0 ;;
    -h | --help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done

if [[ -n $ONLY ]]; then
  for name in ${ONLY//,/ }; do
    [[ " ${PHASES[*]} " == *" $name "* ]] || { echo "unknown phase: $name (see --list)" >&2; exit 2; }
  done
fi

# Ask for the sudo password once, up front
if [[ $CHECK == 0 ]]; then
  sudo -v || exit 1
fi

selected() { [[ -z $ONLY || ",$ONLY," == *",$1,"* ]]; }

# Run every version check in parallel; each writes want/have/note to a file.
CHECK_DIR="$TMP/checks"
mkdir -p "$CHECK_DIR"
declare -A CHECK_PID=()
for name in "${PHASES[@]}"; do
  selected "$name" || continue
  ( set -e; "check_$name" ) >"$CHECK_DIR/$name" 2>"$CHECK_DIR/$name.err" &
  CHECK_PID[$name]=$!
done
printf '%sChecking %d phases...%s' "$BOLD" "${#CHECK_PID[@]}" "$RESET"
declare -A CHECK_RC=()
for name in "${!CHECK_PID[@]}"; do
  wait "${CHECK_PID[$name]}"
  CHECK_RC[$name]=$?
done
printf ' done in %ds\n\n' "$SECONDS"

# Install/update/skip sequentially, in phase order.
declare -A OUTCOME=()
PHASE_TOTAL=${#PHASES[@]}
FAILED=()
for i in "${!PHASES[@]}"; do
  PHASE_NAME=${PHASES[$i]}
  PHASE_NUM=$((i + 1))
  selected "$PHASE_NAME" || continue

  if [[ ${CHECK_RC[$PHASE_NAME]} -ne 0 ]]; then
    OUTCOME[$PHASE_NAME]=failed
    FAILED+=("$PHASE_NAME")
    phase_line "$RED" "FAILED version check: $(tail -1 "$CHECK_DIR/$PHASE_NAME.err")"
    continue
  fi

  { read -r WANT; read -r HAVE; read -r NOTE; } <"$CHECK_DIR/$PHASE_NAME"
  plan "$WANT" "$HAVE" "$NOTE" || continue

  # Subshell with `set -e` so a failing step aborts only its own phase.
  # (Not inside `if`, which would silently disable set -e.)
  ( set -e; "install_$PHASE_NAME" )
  rc=$?
  if [[ $rc -ne 0 ]]; then
    OUTCOME[$PHASE_NAME]=failed
    FAILED+=("$PHASE_NAME")
    phase_line "$RED" "FAILED (exit $rc)"
  elif [[ $ACTION == install ]]; then
    phase_line "$YELLOW" "installed"
  else
    phase_line "$ORANGE" "updated"
  fi
done

# Summary
declare -A count=()
for o in "${OUTCOME[@]}"; do
  count[$o]=$((${count[$o]:-0} + 1))
done
echo
printf '%sSummary:%s ' "$BOLD" "$RESET"
[[ -n ${count[skipped]:-} ]] && printf '%s%d up to date%s  ' "$GREEN" "${count[skipped]}" "$RESET"
[[ -n ${count[install]:-} ]] && printf '%s%d installed%s  ' "$YELLOW" "${count[install]}" "$RESET"
[[ -n ${count[update]:-} ]] && printf '%s%d updated%s  ' "$ORANGE" "${count[update]}" "$RESET"
[[ -n ${count[would-install]:-} ]] && printf '%s%d to install%s  ' "$YELLOW" "${count[would-install]}" "$RESET"
[[ -n ${count[would-update]:-} ]] && printf '%s%d to update%s  ' "$ORANGE" "${count[would-update]}" "$RESET"
[[ ${#FAILED[@]} -gt 0 ]] && printf '%s%d failed (%s)%s' "$RED" "${#FAILED[@]}" "${FAILED[*]}" "$RESET"
echo

[[ ${#FAILED[@]} -eq 0 ]]
