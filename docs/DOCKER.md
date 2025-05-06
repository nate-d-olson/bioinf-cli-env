# Testing with Docker

This guide explains how to test and troubleshoot the bioinformatics CLI environment using Docker.

## Prerequisites

- [Docker](https://www.docker.com/get-started) or compatible Docker alternative such as Colima (for macOS) installed on your system
- Clone of this repository

## Building the Docker Image

Run this command from the repository root:

```bash
docker build -t bioinf-cli-env .
```

This builds the Docker image `bioinf-cli-env` with all pre-installed tools.

## Running the Docker Container

### Basic Usage

Interactive shell within container:

```bash
docker run -it bioinf-cli-env
```

### Mounting Local Data

Mount local files within the Docker environment:

```bash
docker run -it -v /path/to/your/data:/home/biouser/data bioinf-cli-env
```

Replace `/path/to/your/data` accordingly.

### Running Specific Commands

Execute specific commands directly:

```bash
docker run -it bioinf-cli-env micromamba env list
```

## Testing Individual Components

### Micromamba Testing

Verify micromamba's installation:

```bash
micromamba --version
micromamba env list
```

Test the installed bioinformatics packages (excluding problematic ones noted in [troubleshooting](TROUBLESHOOTING.md)):

```bash
micromamba activate base
python -c "import numpy; print(numpy.__version__)"
```

### Job and Workflow Monitoring Testing

Simulate a monitoring scenario:

```bash
# Run a simple background job
sleep 300 &
monitoring_job $! "Test Job"
```

### ZSH Configuration

Check Oh My Zsh and Powerlevel10k setup:

```bash
ls -la ~/.oh-my-zsh
echo $POWERLEVEL9K_MODE
```

## Customizing and Extending Docker Image

Create your own Dockerfile for custom setups:

```dockerfile
FROM bioinf-cli-env

USER biouser
COPY custom_configs/ ~/custom_configs/
RUN echo "source ~/custom_configs/.zsh_customizations" >> ~/.zshrc
```

And build the derived container:

```bash
docker build -t bioinf-cli-env-custom -f Dockerfile.custom .
```

## Using Docker in CI/CD

Follow this example GitHub Actions workflow for container testing:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: bioinf-cli-env:latest
    steps:
      - name: Validate Micromamba
        run: micromamba --version
      - name: Check Python Environment
        run: |
          micromamba activate base
          python -c "import numpy; print(numpy.__version__)"
```

## Troubleshooting Docker Issues

### Container Immediately Exits

Explicit command invocation as follows:

```bash
docker run -it bioinf-cli-env /bin/bash
```

### Permission Errors With Mounted Volumes

Adjust permissions with user and group ID build arguments:

```bash
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) \
    -t bioinf-cli-env .
```

### Networking Issues

If you encounter network issues:

```bash
docker run -it --network=host bioinf-cli-env
```

## Debugging Recommendations

- Use Docker alternatives like Colima (macOS):

```bash
brew install colima colima start
```

- For advanced debugging locally, use `act` for testing GitHub workflows:

```bash
brew install act
act -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

## Extending Docker Container Functionality

To extend functionalities explicitly:

```dockerfile
FROM bioinf-cli-env

USER root
RUN apt-get update && apt-get install -y additional-package \
    && rm -rf /var/lib/apt/lists/*

USER biouser
RUN micromamba install -n base -c bioconda additional-bioconda-package
```

Then build:

```bash
docker build -t bioinf-cli-env-extended .
```

This structured guide enhances your Docker experience by clarifying and explicitly advising best practices for local and CI/CD scenarios.