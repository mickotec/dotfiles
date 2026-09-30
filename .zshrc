# ==============================================================================
# Omarchy & System Environment
# ==============================================================================
# Omarchy environment (OMARCHY_PATH + PATH)
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Increase FUNCNEST limit
export FUNCNEST=1000


# Anthropic / Claude Config
export CLAUDE_CONFIG_DIR="$HOME/.claude-omniroute"
export ANTHROPIC_BASE_URL="http://localhost:20128"
export ANTHROPIC_AUTH_TOKEN="sk-5f68f8afce66b320-84e7c9-6e416857"
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="mereb-ai"
export CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1
export GSK_RENDERER=ngl

# Source Omarchy environment, aliases, and functions (Zsh compatible)
_omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"
if [[ -d "$_omarchy_path" ]]; then
    [[ -r "$_omarchy_path/default/bash/envs" ]] && source "$_omarchy_path/default/bash/envs"
    [[ -r "$_omarchy_path/default/bash/aliases" ]] && source "$_omarchy_path/default/bash/aliases"
    [[ -r "$_omarchy_path/default/bash/functions" ]] && source "$_omarchy_path/default/bash/functions"
fi

# Shell integrations (mise, zoxide, try)
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

if command -v try &>/dev/null; then
    try() {
        unset -f try
        eval "$(SHELL=/bin/zsh command try init ~/Work/tries)"
        try "$@"
    }
fi


# ==============================================================================
# Aliases
# ==============================================================================
alias c='clear'
alias k='kubectl'
alias ll='eza -lah --icons --git --group-directories-first'
alias tree='eza --tree --icons'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgs='kubectl get services'
alias susp='systemctl suspend'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias omarchy-time-machine=~/.config/omarchy/plugins/jankeesvw.time-machine/bin/omarchy-time-machine

# ==============================================================================
# Zsh History Settings
# ==============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write timestamp to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded
setopt HIST_IGNORE_SPACE         # Don't record entries starting with a space
setopt HIST_VERIFY               # Don't execute immediately upon history expansion
setopt SHARE_HISTORY             # Share history between sessions

# ==============================================================================
# Completion System & Drop-down Menu with Descriptions
# ==============================================================================
fpath=("$HOME/.zsh/completions" $fpath)

zmodload zsh/complist
autoload -Uz compinit
compinit -d "$HOME/.zcompdump"

# Native drop-down menu with arrow key selection (double TAB triggers menu)
setopt AUTO_MENU                # Show menu on second tab press
unsetopt MENU_COMPLETE          # Do not automatically insert first menu item on first tab
zstyle ':completion:*' menu select=2
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- No matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Menu navigation keybindings
bindkey -M menuselect '^[[Z' reverse-menu-complete   # Shift-Tab moves backward
bindkey -M menuselect '\r' .accept-line              # Enter accepts selection

# ==============================================================================
# FZF Key Bindings & Completion
# ==============================================================================
if command -v fzf &>/dev/null; then
    [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
    [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
fi

# ==============================================================================
# fzf-tab: Rich Interactive Dropdown Menu with Fuzzy Search & Descriptions
# ==============================================================================
if [[ -f "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
    source "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"

    # Dropdown menu styling
    zstyle ':fzf-tab:*' fzf-flags \
        --height=45% \
        --layout=reverse \
        --border=rounded \
        --info=inline \
        --cycle \
        --bind=tab:down,btab:up

    # Group switching with ',' and '.'
    zstyle ':fzf-tab:*' switch-group ',' '.'

    # File and directory previews when navigating paths
    zstyle ':fzf-tab:complete:*:*' fzf-preview '
        if [[ -d $realpath ]]; then
            eza -lah --icons --color=always $realpath 2>/dev/null || ls -la $realpath
        elif [[ -f $realpath ]]; then
            bat --style=plain --color=always --line-range :25 $realpath 2>/dev/null || head -n 25 $realpath
        fi
    '
fi

# ==============================================================
# Tool Completions
# ==============================================================
# Kubectl completion for alias k
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
    compdef __start_kubectl k
fi

# Omarchy command completion
if command -v omarchy &>/dev/null; then
    _omarchy() {
        local bin_dir="${OMARCHY_PATH:-/usr/share/omarchy}/bin"
        [[ -d "$bin_dir" ]] || bin_dir="/usr/bin"

        local prefix="omarchy"
        local i
        for (( i = 2; i < CURRENT; i++ )); do
            local part="${words[i]}"
            [[ -z "$part" || "$part" == -* ]] && continue
            prefix+="-${part}"
        done

        local -A seen
        local -a candidates

        if (( CURRENT == 2 )); then
            candidates+=( "commands:List all commands" )
        fi

        if [[ "${words[2]}" == "commands" && CURRENT -ge 3 ]]; then
            _values "options" \
                "--all[Include commands explicitly marked hidden]" \
                "--json[Machine-readable command list]" \
                "--markdown[Markdown formatted list]" \
                "--check[Validate command metadata and routes]"
            return
        fi

        local f basename rest next
        for f in "$bin_dir/${prefix}"-*(N*); do
            [[ -f "$f" && -x "$f" ]] || continue
            basename="${f##*/}"
            rest="${basename#"${prefix}"-}"
            next="${rest%%-*}"
            if [[ -n "$next" && -z "${seen[$next]}" ]]; then
                seen[$next]=1
                candidates+=( "$next" )
            fi
        done

        _describe "omarchy command" candidates
    }
    compdef _omarchy omarchy
fi

# VirtualBox / VBoxManage completion
if command -v vboxmanage &>/dev/null || command -v VBoxManage &>/dev/null; then
    compdef _virtualbox vboxmanage VBoxManage VBoxHeadless vboxheadless 2>/dev/null
fi

# Azure CLI completion
if command -v az &>/dev/null; then
    compdef _az az 2>/dev/null
fi

# ==============================================================================
# Starship Prompt
# ==============================================================================
if command -v starship &>/dev/null; then
    trap - DEBUG 2>/dev/null
    unfunction starship_preexec starship_precmd starship_preexec_all 2>/dev/null
    eval "$(starship init zsh)"
fi

# ==============================================================================
# Plugins: Autosuggestions & Syntax Highlighting
# ==============================================================================
# Fish-like autosuggestions as you type
if [[ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Real-time syntax highlighting (must be loaded last)
if [[ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Fix Home/End keys printing '~'
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
