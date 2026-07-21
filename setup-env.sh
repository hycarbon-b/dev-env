#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./setup-env.sh           Install Docker and uv on Amazon Linux.
  ./setup-env.sh --check   Verify Docker, uv, and the compose environment.
EOF
}

check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'error: required command not found: %s\n' "$1" >&2
    return 1
  }
}

check_environment() {
  check_command docker
  check_command uv
  docker compose version >/dev/null
  docker info >/dev/null

  [[ -f .env ]] || {
    printf 'error: .env is required; this tutorial intentionally does not ignore it\n' >&2
    return 1
  }
  [[ -n "${MYSQL_ROOT_PASSWORD:-}" ]] || {
    printf 'error: MYSQL_ROOT_PASSWORD is missing from .env\n' >&2
    return 1
  }
  [[ -n "${MYSQL_PASSWORD:-}" ]] || {
    printf 'error: MYSQL_PASSWORD is missing from .env\n' >&2
    return 1
  }
  docker compose config --quiet
  printf 'environment check passed: Docker is usable and compose secrets are loaded from .env\n'
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    return
  fi

  # Official Docker installation script for the latest stable release.
  local installer
  local installer_shell
  installer="$(mktemp)"
  trap 'rm -f "$installer"' RETURN
  curl --fail --show-error --location --proto '=https' --tlsv1.2 \
    https://get.docker.com --output "$installer" || {
    printf 'error: failed to download Docker installer from get.docker.com\n' >&2
    return 1
  }
  installer_shell="$(sed -n 's/^#!//p;q' "$installer")"
  if [[ -z "$installer_shell" ]]; then
    printf 'error: Docker installer has no shebang\n' >&2
    return 1
  fi
  local -a docker_installer_cmd
  case "$installer_shell" in
    "/bin/sh")
      docker_installer_cmd=(/bin/sh)
      ;;
    "/usr/bin/env sh")
      docker_installer_cmd=(/usr/bin/env sh)
      ;;
    *)
      printf 'error: unexpected Docker installer interpreter: %s\n' "$installer_shell" >&2
      return 1
      ;;
  esac
  if ! sudo "${docker_installer_cmd[@]}" "$installer"; then
    printf 'error: Docker installer failed\n' >&2
    return 1
  fi

  sudo systemctl enable --now docker
  local docker_user="${SUDO_USER:-}"
  if [[ -z "$docker_user" || "$docker_user" == root ]]; then
    docker_user="$(logname 2>/dev/null || true)"
  fi
  if [[ -n "$docker_user" && "$docker_user" != root ]]; then
    sudo usermod -aG docker "$docker_user"
  else
    printf 'Docker is ready for root; run usermod -aG docker USER for a non-root login.\n'
  fi
  printf 'Docker installed. Log in again if Docker commands require the new group membership.\n'
}

install_uv() {
  if command -v uv >/dev/null 2>&1; then
    return
  fi

  # Official uv installer for Linux/macOS.
  local installer
  local installer_shell
  installer="$(mktemp)"
  trap 'rm -f "$installer"' RETURN
  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    https://astral.sh/uv/install.sh --output "$installer" || {
    printf 'error: failed to download uv installer from astral.sh\n' >&2
    return 1
  }
  installer_shell="$(sed -n 's/^#!//p;q' "$installer")"
  if [[ -z "$installer_shell" ]]; then
    printf 'error: uv installer has no shebang\n' >&2
    return 1
  fi
  local -a uv_installer_cmd
  case "$installer_shell" in
    "/bin/sh")
      uv_installer_cmd=(/bin/sh)
      ;;
    "/usr/bin/env sh")
      uv_installer_cmd=(/usr/bin/env sh)
      ;;
    *)
      printf 'error: unexpected uv installer interpreter: %s\n' "$installer_shell" >&2
      return 1
      ;;
  esac
  if ! "${uv_installer_cmd[@]}" "$installer"; then
    printf 'error: uv installer failed\n' >&2
    return 1
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
  check_command uv
}

main() {
  case "${1:-}" in
    --check)
      check_environment
      ;;
    "" )
      install_docker
      install_uv
      check_environment
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac
}

main "$@"
