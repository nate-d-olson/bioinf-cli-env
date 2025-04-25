# Bioinformatics CLI Environment Dockerfile
FROM ubuntu:24.04

# Use bash (with pipefail) for all subsequent RUN commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive installation and prevent prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    zsh \
    nano \
    tmux \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    parallel \
    libfuse2 \
    libevent-dev \
    libncurses-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
ARG USERNAME=biouser
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL >/etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# Copy the environment files
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/bioinf-cli-env

# Create required directories
RUN mkdir -p /home/$USERNAME/.local/bin \
    && mkdir -p /home/$USERNAME/.local/share/bioinf-cli-env \
    && mkdir -p /home/$USERNAME/.local/log

# Create a non-interactive config file
RUN cp /home/$USERNAME/bioinf-cli-env/config.ini.template /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_OH_MY_ZSH=.*/INSTALL_OH_MY_ZSH=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_MODERN_TOOLS=.*/INSTALL_MODERN_TOOLS=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_MICROMAMBA=.*/INSTALL_MICROMAMBA=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_JOB_MONITORING=.*/INSTALL_JOB_MONITORING=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_PALETTE_SELECTOR=.*/INSTALL_PALETTE_SELECTOR=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_AZURE_OPENAI=.*/INSTALL_AZURE_OPENAI=false/' /home/$USERNAME/bioinf-cli-env/config.ini

# Install the environment
WORKDIR /home/$USERNAME/bioinf-cli-env
RUN ./install.sh --non-interactive --config /home/$USERNAME/bioinf-cli-env/config.ini

# Set zsh as the default shell for the non-root user
RUN usermod --shell /usr/bin/zsh $USERNAME

# Set up entrypoint initialization script
RUN echo '#!/bin/bash\n\
# Source zsh config\n\
source ~/.zshrc\n\
\n\
# Initialize micromamba\n\
eval "$(micromamba shell hook --shell=bash)"\n\
micromamba activate base\n\
\n\
# Execute the provided command or start zsh\n\
if [ $# -eq 0 ]; then\n\
    exec zsh\n\
else\n\
    exec "$@"\n\
fi' > /home/$USERNAME/entrypoint.sh \
    && chmod +x /home/$USERNAME/entrypoint.sh

# Set WORKDIR and ENTRYPOINT
WORKDIR /home/$USERNAME
ENTRYPOINT ["/home/biouser/entrypoint.sh"]