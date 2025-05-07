# PROJECT BACKGROUND & DEVELOPMENT NOTES

## Introduction & Goals

The primary goal was to build a robust, consistent, and productivity-focused command-line interface (CLI) tailored for bioinformaticians across macOS, Ubuntu, and SLURM clusters. Essential tools include Zsh configurations, enhanced productivity utilities (Micromamba, Docker, Git, AWS CLI, Azure OpenAI integration), and intuitive, visual, and easy-to-navigate environments.

## Historical Context & Brainstorming Insights

The initial brainstorming phase identified detailed user requirements:
- Cross-platform compatibility (macOS, Ubuntu, SLURM)
- Enhanced CLI productivity (Micromamba, Docker, Git, ripgrep, fd-find, bat, exa, fzf, zoxide)
- Workflow monitoring (Snakemake, Nextflow, WDL/Cromwell)
- Enhanced shells using Zsh, Powerlevel10k, plugins (autosuggestions, syntax highlighting)
- Tools for Azure OpenAI-based CLI querying

## Technical Decisions & Alternatives

A comparative review between frameworks:

- **Oh My Zsh**: Selected for its widespread adoption, powerful features, and ease of setup.
- **Powerlevel10k Theme**: Chosen for its highly customizable and visually appealing interface.
- **Zinit**: Considered but ultimately not chosen due to complexity and less community uptake compared to Oh My Zsh.

## Implementation Overview

### Repository Configuration
- Detailed directory structure defined clearly.
- Git integration adopted early with strategic `.gitignore` policies for maintaining security and cleanliness.

### Installation and Configuration
- Interactive `install.sh` script developed for idempotent installation and user-configurable options.
- Environment variables and Micromamba setups managed carefully within structured YAML files for reproducibility.
- Linked essential dotfiles (.zshrc, .p10k.zsh, .tmux.conf) through scripts and symbolic links.

### Tool Integration
- Docker explicitly documented with alternative setups using Colima for macOS.
- Azure OpenAI integrated for terminal LLM querying.
- Git integrated extensively with aliases and completion scripts.

## Known Issues & Ongoing Refinements

- **Micromamba Environment Issues**:
  - Dependencies like `dipcall` and `truvari` explicitly excluded due to known compatibility and dependency issues (clearly documented in `USER_GUIDE.md` and `TROUBLESHOOTING.md`).

- **Docker & CI/CD Adjustments**:
  - Colima successfully implemented on macOS to replace Docker Desktop.
  - Adjustments made to local CI/CD environments (use of `act`, avoidance of `sudo` prompts).

- **CI/CD Docker Configurations**:
  - Resolved Docker image issues, explicitly documented debugging strategies for local and cloud setups.

## Recommendations for Continued Enhancements

### VS Code Integration
- Develop Remote-SSH integration capabilities for automated cross-platform development.
- Create preconfigured debug and task runners specifically for Snakemake and Nextflow pipelines.

### Expanded LLM CLI Support
- Enhance Azure-based OpenAI CLI integration for real-time query assistance and intelligent pipeline scaffolding.
- Use interactive chat features for config editing directly from the CLI to streamline user adjustments.

### Job Monitoring Enhancements
- Build a lightweight, multi-host tracking UI to aggregate job statistics and resource usage.
- Introduce historical analytics using lightweight databases (SQLite, InfluxDB) for improved pipeline performance.

## Final Notes on Consolidation
This document integrates key decisions, setups, and documented issues from extensive brainstorming sessions, technical evaluations, and direct user feedback. Future documentation should stay concise and explicitly linked to actionable tasks and improvements to maintain clarity and ease of use across development cycles.