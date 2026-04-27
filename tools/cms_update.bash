#!/usr/bin/env bash
set -euo pipefail

CMS_DIR=$1
BRANCH=${2:-master}
INIT=${3:-cbqz-site}

cd "$CMS_DIR"
CMS_FILES_USER=$( stat -c '%U' README.md )
sudo -u "$CMS_FILES_USER" git pull origin "$BRANCH"
/etc/init.d/$INIT graceful
