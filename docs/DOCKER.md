# Testing with Docker

This guide explains how to test the bioinformatics CLI environment using Docker.

## Prerequisites

- [Docker](https://www.docker.com/get-started) installed on your system
- Git clone of this repository

## Building the Docker Image

To build the Docker image, run the following command from the repository root:

```bash
docker build -t bioinf-cli-env .
```

This builds an image named `bioinf-cli-env` with all the tooling preinstalled.

## Running the Docker Container

### Basic Usage

Run the container with an interactive shell:

```bash
docker run -it bioinf-cli-env
```

This will start a container with a ZSH shell and all the configured tools.

### Mount Local Files

To access your local files within the container, use volume mounting:

```bash
docker run -it -v /path/to/your/data:/home/biouser/data bioinf-cli-env
```

Replace `/path/to/your/data` with the absolute path to your data directory.

### Run Specific Commands

You can also run specific commands in the container:

```bash
docker run -it bioinf-cli-env micromamba env list
```

## Testing Components

### Testing Micromamba

Inside the container, verify that micromamba is correctly installed:

```bash
micromamba --version
micromamba env list
```

Test the bioinformatics environment:

```bash
micromamba activate base
python -c "import numpy; print(numpy.__version__)"
```

### Testing Job Monitoring

Simulate a job for monitoring:

```bash
# Start a long-running task in the background
sleep 300 &
job_pid=$!

# Monitor it
monitoring_job $job_pid "Test Job"
```

### Testing ZSH Configuration

Verify that the ZSH configuration is working correctly:

```bash
# Check Oh My Zsh installation
ls -la ~/.oh-my-zsh

# Check Powerlevel10k
echo $POWERLEVEL9K_MODE

# Test syntax highlighting
# Type a valid command and see if it gets highlighted
```

### Testing Workflow Monitoring

Inside the container, test workflow monitoring tools:

```bash
# Test Snakemake monitor
bash scripts/workflow_monitors/snakemake_monitor.sh --help

# Test Nextflow monitor
bash scripts/workflow_monitors/nextflow_monitor.sh --help

# Test WDL monitor
bash scripts/workflow_monitors/wdl_monitor.sh --help
```

## Customization Testing

You can test customizations by modifying the Docker image:

1. Create a new `Dockerfile.custom`:

   ```dockerfile
   FROM bioinf-cli-env

   USER biouser
   WORKDIR /home/biouser

   # Add your custom configurations
   COPY --chown=biouser:biouser custom_config.zsh /home/biouser/.custom_config.zsh
   RUN echo "source ~/.custom_config.zsh" >> ~/.zshrc
   ```

1. Build and run your custom image:

   ```bash
   docker build -t bioinf-cli-env-custom -f Dockerfile.custom .
   docker run -it bioinf-cli-env-custom
   ```

## Troubleshooting Docker Issues

### Container exits immediately

If the container exits immediately, run with an explicit command:

```bash
docker run -it bioinf-cli-env /bin/bash
```

### Permission issues with mounted volumes

If you encounter permission issues with mounted volumes, adjust the user ID:

```bash
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) \
    -t bioinf-cli-env .
```

### Networking issues

If you need to access network resources from within the container:

```bash
docker run -it --network=host bioinf-cli-env
```

## Using Docker for CI/CD

This Docker image can be used for continuous integration testing. Example GitHub
Actions workflow:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container: 
      image: bioinf-cli-env:latest
    steps:
      - name: Test micromamba
        run: micromamba --version
      - name: Test bioinformatics tools
        run: |
          micromamba activate base
          python -c "import numpy; print('Numpy works!')"
```

## Extending the Docker Image

To extend the Docker image for specific bioinformatics workflows:

1. Create a new Dockerfile:

   ```dockerfile
   FROM bioinf-cli-env

   USER root
   RUN apt-get update && apt-get install -y \
       additional-package1 \
       additional-package2 \
       && rm -rf /var/lib/apt/lists/*

   USER biouser
   RUN micromamba install -n base -c bioconda \
       additional-bioconda-package
   ```

1. Build your extended image:

   ```bash
   docker build -t my-bioinf-workflow -f Dockerfile.extended .
   ```
