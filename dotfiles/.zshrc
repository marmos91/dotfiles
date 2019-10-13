# Environment
export DOTFILES_DIR="$HOME/.dotfiles"
. "$DOTFILES_DIR"/.env

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Theme preferences
ZSH_THEME="powerlevel9k/powerlevel9k"
POWERLEVEL9K_MODE='awesome-patched'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status node_version)
CASE_SENSITIVE="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# ZSH plugins
plugins=(
  git
  git-extras
  git-flow
  iterm2
  node
  zsh-syntax-highlighting 
  zsh-autosuggestions
)

# Source dotfiles
for DOTFILE in "$DOTFILES_DIR"/alias/.alias; do
  [ -f "$DOTFILE" ] && . "$DOTFILE"
done

if is-macos; then
  for DOTFILE in "$DOTFILES_DIR"/alias/.alias.macos; do
    [ -f "$DOTFILE" ] && . "$DOTFILE"
  done
fi

source $ZSH/oh-my-zsh.sh

. /usr/local/etc/profile.d/z.sh

nvm use --delete-prefix 12 --silent

test -e "${HOME}/.iterm2_shell_integration.zsh" && . "${HOME}/.iterm2_shell_integration.zsh"

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion