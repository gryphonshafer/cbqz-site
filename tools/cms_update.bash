#!/usr/bin/env bash
set -euo pipefail

CMS_DIR=$1
BRANCH=${2:-master}
SERVICE=${3:-cbqz-site.service}

cd "$CMS_DIR"
CMS_FILES_USER=$( stat -c '%U' README.md )
sudo -u "$CMS_FILES_USER" git pull origin "$BRANCH"
systemctl restart "$SERVICE"
