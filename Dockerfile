# Use Ubuntu LTS as a base
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV MAMBA_ROOT_PREFIX=/opt/micromamba

# 1) Install system prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git zsh wget bzip2 \
      build-essential procps && \
    rm -rf /var/lib/apt/lists/*

# 2) Install micromamba (user‑space conda)
RUN mkdir -p $MAMBA_ROOT_PREFIX && \
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
      | tar -xvj -C $MAMBA_ROOT_PREFIX --strip-components=1 bin/micromamba

ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

# 3) Copy your installer and configs
WORKDIR /root
COPY . /root/bioinf-shell-setup
WORKDIR /root/bioinf-shell-setup

# 4) Make sure install.sh is executable
RUN chmod +x install.sh

# 5) Default entrypoint: start zsh after install
ENTRYPOINT [ "zsh", "-c" ]
CMD [ "echo 'Container ready. Run install.sh to provision the env.'; exec zsh" ]