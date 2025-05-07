# Bioinformatics CLI Development Scratch Space

## Issue Tracking and Resolution

### High Priority Issues

#### 1. Script Execution and 'sudo' Requirements
- **Problem:** Scripts unnecessarily requiring sudo.
- **Solution:** 
  - Implement permission checks and user-space installations.
  - Provide alternative installation instructions clearly.
- **Status:**
  - [x] Reviewed all scripts for unnecessary `sudo`.
  - [x] Modified `install.sh` explicitly handling user-space fallbacks.

#### 2. Azure CLI ('az') Dependency
- **Problem:** Missing automated checks or instructions for Azure CLI dependency.
- **Solution:**
  - Include explicit checks for Azure CLI installation.
  - Provide robust fallback instructions for manual installations.
- **Status:**
  - [x] Enhanced checks for Azure CLI at the start of `setup_llm.sh`.
  - [x] Added clear user instructions for manual installations.

#### 3. Shell Standardization
- **Problem:** Lack of clarity on shell usage in scripts (zsh vs. bash).
- **Solution:** Standardize on bash for universal compatibility.
- **Status:**
  - [x] Updated script headers explicitly to use bash.
- **Next Actions:**
  - [ ] Conduct comprehensive tests across macOS, Ubuntu, and SLURM clusters.

### Suggested Enhancements

#### 1. Termite (Terminal UI Generator)
- **Evaluation:** Investigate usability and integration potential.
- **Next Actions:**
  - [ ] Explore Termite integration examples.
  - [ ] Determine potential command-line productivity boosts.

#### 2. Enhanced Azure OpenAI CLI Integration
- **Evaluation:** Utilize provided Azure OpenAI endpoint for robust CLI interactions.
- **Next Actions:**
  - [ ] Develop Python scripts for enhanced LLM interactions at CLI.
  - [ ] Integrate and test provided scripts in diverse environments.

## Branch Management
- `fix/sudo-permissions` – Completed improvements for user-space installation handling.
- `fix/azure-cli-dependency` – Completed robust checks and manual instructions addition.
- `standardize-shell` – Completed header updates; testing remains.

## Review Schedule
- Weekly reviews to assess progress, next scheduled for next Friday.