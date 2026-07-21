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
  curl --fail --show-error --location --proto '=https' --tlsv1.2 \
    https://get.docker.com | sudo sh

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
  curl --fail --silent --show-error --location https://astral.sh/uv/install.sh | sh
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
