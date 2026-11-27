#!/bin/bash
# Sync machine-level dotfiles (~/scripts, ~/.vimrc) into ~/.dotfiles and push.
#
# nvim is NOT copied here anymore: ~/.config/nvim is a symlink into
# ~/.dotfiles/nvim, so the repo IS the live config — edit it in place and
# commit from the repo (or run this script, which commits everything).
set -e
REPO_URL="git@github.com:vinmh/dotfiles.git"
DOTFILES_DIR=$HOME/.dotfiles
SCRIPTS_DIR=$HOME/scripts
VIMRC_PATH=$HOME/.vimrc
CURRENT_DATE=$(date +"%Y-%m-%d")

if [[ ! -d "$DOTFILES_DIR" ]] then
  echo "Cloning repo"
  git clone $REPO_URL $DOTFILES_DIR
elif cd $DOTFILES_DIR && ! git rev-parse --is-inside-work-tree; then
  rm -rf $DOTFILES_DIR
  echo "Cloning repo"
  git clone $REPO_URL $DOTFILES_DIR
fi

cp -r $SCRIPTS_DIR $DOTFILES_DIR
cp $VIMRC_PATH $DOTFILES_DIR

cd $DOTFILES_DIR && \
  git add -A && \
  git commit -m "Auto-update from $CURRENT_DATE" || \
  echo "nothing to commit"
git push origin main
