#!/bin/bash

# Exit immediately on errors
set -e

function success () {
  echo -e "[ \033[00;32mOK\033[0m ] $1\n"
}

function fail () {
  echo -e "[\033[0;31mFAIL\033[0m] $1\n"
  exit 1
}

# Vars
ENV_FILE=/usr/local/etc/borg/.env
if [ ! -f "${ENV_FILE}" ]; then
  fail "Copy the .env.sample file to .env and fill out the empty variables"
fi

source .env

# Backup
borg create                                                   \
  --compression zlib,6                                        \
  --exclude-from '/usr/local/etc/borg/backup.excludes'        \
  --filter AME                                                \
  --show-rc                                                   \
  --stats                                                     \
  ::${BACKUP}                                                 \
  /Users/abendy                                               \
  /etc                                                        \
  /usr
success 'Backup complete'

# Prune
borg prune -v --list ${BORG_REPO} --prefix 'macos-' --keep-daily=14 --keep-weekly=4 --keep-monthly=6
success 'Prune complete'

# Sync to S3
borg with-lock ${BORG_REPO} aws s3 sync ${BORG_REPO} s3://${S3_BUCKET} --delete
success 'Sync complete'

exit 0;