#!/bin/bash
REPO_URL="git@github.com:vinmh/dotfiles.git"
DOTFILES_DIR=$HOME/.dotfiles
SCRIPTS_DIR=$HOME/scripts
NVIM_CONFIG_DIR=$HOME/.config/nvim
VIMRC_PATH=$HOME/.vimrc
CURRENT_DATE=$(printf -v date '%(%Y-%m-%d)T' -1)

if [[ ! -d "$DOTFILES_DIR" ]] then
  echo "Cloning repo"
  git clone $REPO_URL $DOTFILES_DIR
elif cd $DOTFILES_DIR && ! git rev-parse --is-inside-work-tree; then
  rm -rf $DOTFILES_DIR
  echo "Cloning repo"
  git clone $REPO_URL $DOTFILES_DIR
fi

cp -r $SCRIPTS_DIR $DOTFILES_DIR
cp -r $NVIM_CONFIG_DIR $DOTFILES_DIR
cp $VIMRC_PATH $DOTFILES_DIR

cd $DOTFILES_DIR && \
  git add $DOTFILES_DIR/. && \
  git commit -m "Auto-update from $CURRENT_DATE" && \
  git push origin main
