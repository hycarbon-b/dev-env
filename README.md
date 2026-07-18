# dev-env

This repository is a tutorial for preparing an Amazon Linux development
environment with Docker and `uv`.

## Amazon Linux

Build and start the example image:

```bash
docker build -t dev-env-amazonlinux .
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/workspace" \
  dev-env-amazonlinux
```

Inside the container, run:

```bash
/usr/local/bin/setup-env
```

The script installs Docker and `uv`, then verifies that Docker can answer
`docker info` and that the compose environment is valid. On a real Amazon
Linux host, run `./setup-env.sh` directly instead of using Docker-in-Docker.

## MySQL, Python, and Node

The compose tutorial starts all three services and waits for MySQL health:

```bash
docker compose up
```

The example credentials are stored in the committed `.env` file and are
referenced by `compose.yaml`; there is intentionally no `.gitignore` for this
tutorial. These are public, disposable tutorial credentials, not production
secrets. Replace them through `.env` before using this setup anywhere real.

CI runs `setup-env.sh --check`, which verifies Docker usability, `uv`, the
presence of `.env` passwords, and `docker compose config`.
