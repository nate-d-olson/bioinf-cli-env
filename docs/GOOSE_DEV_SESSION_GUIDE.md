# 🦢 Goose Development Session Guide

This Markdown contains crucial file paths, notes, and extensions recommended for efficiently interacting with Goose in future development sessions for your bioinformatics CLI environment project.

---

## 🗂 Project Files Overview

### 📖 Project Introduction
- **File:** `README.md`
- **Usage Note:** Provides clear overview, quick start, and project introduction.

### 🛠 Main Installation & Setup Scripts

- **Initial Installation Script:**
  - `install.sh`
- **Micromamba Environment Setup:**
  - `scripts/setup_micromamba.sh` (restored from stable commit `9a778c3`)
- **CLI Tools Setup:**
  - `scripts/setup_tools.sh`
- **Shell Environment (Oh My Zsh and Powerlevel10k):**
  - `scripts/setup_omz.sh`

**Usage Note:** Essential scripts are used for environment setup and maintenance tasks. Ensure they are intact, permission-executable (`chmod +x filename.sh`) and contain latest stable changes.

### ⚙️ Configuration and Environment

- **Bioinformatics Micromamba Environment:**
  - `config/micromamba-config.yaml`
- **General Project Configuration:**
  - `config.ini` (or related custom variant)

**Usage Note:** Update these to match environment or dependencies needed.

### 📑 Documentation Files

- **User Guide:**
  - `docs/USER_GUIDE.md`: Instructions on using the bioinformatics CLI environment
- **Developer Guide:**
  - `docs/DEVELOPER_GUIDE.md`: Guidelines on extending or modifying scripts
- **Customization Guide:**
  - `docs/CUSTOMIZATION.md`: Customizing environments, tools, aliases, etc.
- **Troubleshooting Guide:**
  - `docs/TROUBLESHOOTING.md`: Common errors and their detailed solutions
- **Docker Usage:**
  - `docs/DOCKER.md`: Documentation about Docker image building, management

### 🐳 Containerization Files

- **Dockerfile:**
  - `Dockerfile`: Container build process for Docker environment and CI/CD use

**Usage Note:** Regularly validate and rebuild image to ensure CI/CD and local consistency.

### 📋 Optional Reference Files

- **Brainstorming and Notes:**
  - `ref_docs/*`: Contains informal brainstorming, notes, and early ideas

**Note:** Useful for historical context or project rationale.

---

## 🚦 Goose CLI Command to Start Sessions

Use this recommended Goose CLI command to ensure optimal productivity and context awareness:

```bash
goose start --project bioinf-cli-env \
            --load README.md \
            --load .github/workflows/ci.yml \
            --load install.sh \
            --load scripts/setup_micromamba.sh \
            --load scripts/setup_tools.sh \
            --load scripts/setup_omz.sh \
            --load config/micromamba-config.yaml \
            --load config.ini \
            --load Dockerfile \
            --load docs/*.md \
            --load ref_docs/*.md
```

---

## 📦 Recommended Goose Extensions

### ✅ Already-Enabled Recommended Extensions:
- `developer`: Direct code execution
- `memory`: Session memory management
- `computercontroller`: Automation and filesystem control
- `tutorial`: Getting started & tutorials

### ➕ Suggested Additional Extensions:

Currently, your extensions seem robust. However, as ongoing development becomes advanced, consider adding:
- **`github-copilot` extension** (if available): AI-enhanced coding recommendations, efficiency in script modifications
- **Database interaction extensions** (e.g., `sqlite`, `postgres`) if project moves toward data persistence or monitoring needs

Installation via Goose CLI:
```bash
goose install-extension github-copilot
```

---

## ✅ Pre-Session Checklist
- [ ] All relevant files provided via Goose CLI `--load`
- [ ] Verify project scripts executable: (`chmod +x [filename].sh`)
- [ ] Dockerfile and CI/CD (Github workflow file) are updated.

---

🚀 You're now ready for productive and highly-contextualized Goose development sessions! Keep this guide handy for referencing paths, documentation files, and best session setups.