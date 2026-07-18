FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf install -y \
      docker \
      git \
      shadow-utils \
      tar \
      gzip \
      procps-ng \
      curl \
    && dnf clean all \
    && rm -rf /var/cache/dnf

COPY setup-env.sh /usr/local/bin/setup-env
RUN chmod +x /usr/local/bin/setup-env

WORKDIR /workspace
CMD ["/bin/bash"]
