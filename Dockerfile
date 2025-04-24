# Bioinformatics CLI Environment Dockerfile
FROM ubuntu:24.04
# use bash (with pipefail) for all subsequent RUN commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

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
    jq \
    parallel \
    && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
ARG USERNAME=biouser
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# Copy the environment files
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/bioinf-cli-env

# Install the environment
RUN cd /home/$USERNAME/bioinf-cli-env && \
    ./install.sh < <(echo -e "y\ny\ny\nn\ny\n") && \
    echo "source ~/.zshrc" >> ~/.bashrc

# Default command
CMD ["zsh"]