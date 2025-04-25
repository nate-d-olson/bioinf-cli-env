# Bioinformatics CLI Environment Dockerfile
FROM ubuntu:24.04

# Use bash (with pipefail) for all subsequent RUN commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive installation and prevent prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Create and set up non-root user
ARG USERNAME=biouser
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y --no-install-recommends sudo=1.9.13p3-* \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/* \
    && usermod --shell /usr/bin/zsh $USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME/bioinf-cli-env

# Copy the environment files
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/bioinf-cli-env

# Create required directories and set up environment
RUN mkdir -p /home/$USERNAME/.local/bin \
    && mkdir -p /home/$USERNAME/.local/share/bioinf-cli-env \
    && mkdir -p /home/$USERNAME/.local/log \
    && cp /home/$USERNAME/bioinf-cli-env/config.ini.template /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_OH_MY_ZSH=.*/INSTALL_OH_MY_ZSH=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_MODERN_TOOLS=.*/INSTALL_MODERN_TOOLS=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_MICROMAMBA=.*/INSTALL_MICROMAMBA=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_JOB_MONITORING=.*/INSTALL_JOB_MONITORING=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_PALETTE_SELECTOR=.*/INSTALL_PALETTE_SELECTOR=true/' /home/$USERNAME/bioinf-cli-env/config.ini \
    && sed -i 's/INSTALL_AZURE_OPENAI=.*/INSTALL_AZURE_OPENAI=false/' /home/$USERNAME/bioinf-cli-env/config.ini

# Install the environment
RUN ./install.sh --non-interactive --config config.ini

# Set up entrypoint initialization script
RUN echo '#!/bin/bash' > /home/$USERNAME/entrypoint.sh && \
    echo '# Source zsh config' >> /home/$USERNAME/entrypoint.sh && \
    echo 'source ~/.zshrc' >> /home/$USERNAME/entrypoint.sh && \
    echo '' >> /home/$USERNAME/entrypoint.sh && \
    echo '# Initialize micromamba' >> /home/$USERNAME/entrypoint.sh && \
    echo "eval \"\$(micromamba shell hook --shell=bash)\"" >> /home/$USERNAME/entrypoint.sh && \
    echo 'micromamba activate base' >> /home/$USERNAME/entrypoint.sh && \
    echo '' >> /home/$USERNAME/entrypoint.sh && \
    echo '# Execute the provided command or start zsh' >> /home/$USERNAME/entrypoint.sh && \
    echo 'if [ $# -eq 0 ]; then' >> /home/$USERNAME/entrypoint.sh && \
    echo '    exec zsh' >> /home/$USERNAME/entrypoint.sh && \
    echo 'else' >> /home/$USERNAME/entrypoint.sh && \
    echo '    exec "$@"' >> /home/$USERNAME/entrypoint.sh && \
    echo 'fi' >> /home/$USERNAME/entrypoint.sh && \
    chmod +x /home/$USERNAME/entrypoint.sh

# Set final working directory and entrypoint
WORKDIR /home/$USERNAME
ENTRYPOINT ["/home/biouser/entrypoint.sh"]