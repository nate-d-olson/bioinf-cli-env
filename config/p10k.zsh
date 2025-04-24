# Generated p10k.zsh configuration file
# To customize the prompt, run `p10k configure` or edit this file.

# Prompt elements
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon                 # OS identifier
  dir                     # Current directory
  vcs                     # Git status
  prompt_char             # Prompt symbol
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # Exit code of the last command
  command_execution_time  # Duration of the last command
  background_jobs         # Presence of background jobs
  direnv                  # direnv status
  virtualenv              # Python virtual environment
  anaconda                # conda/micromamba environment
  aws                     # AWS profile
  time                    # Current time
)

# Basic settings
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_ICON_PADDING=moderate

# Directory settings
typeset -g POWERLEVEL9K_DIR_BACKGROUND=4
typeset -g POWERLEVEL9K_DIR_FOREGROUND=0
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3

# VCS settings
typeset -g POWERLEVEL9K_VCS_GIT_ICON='%fon %F{178}\uf1d3 '
typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=0
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=3
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=0
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=1
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=0

# Anaconda/micromamba environment display
typeset -g POWERLEVEL9K_ANACONDA_BACKGROUND=6
typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=0
typeset -g POWERLEVEL9K_PYTHON_ICON=🐍
typeset -g POWERLEVEL9K_ANACONDA_SHOW_ON_COMMAND='python|pip|ipython|jupyter|conda|mamba|micromamba'

# Command execution time
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=5
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=0
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'

# AWS profile
typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|terraform|pulumi|serverless'
typeset -g POWERLEVEL9K_AWS_BACKGROUND=208
typeset -g POWERLEVEL9K_AWS_FOREGROUND=0

# Status indicators
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=1
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=7

# Instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
