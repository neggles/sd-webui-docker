#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=${REPO_DIR:-'/app/browser'}
IMAGES_DIR=${IMAGES_DIR:-'/output'}
BROWSER_PORT=${BROWSER_PORT-}

# make sure we're in the repo dir
cd ${REPO_DIR}

# fixed flags (needed for docker)
IIB_FLAGS='--host=0.0.0.0'

WEBUI_CONFIG_PATH=${WEBUI_CONFIG_PATH:-'/data/config/auto/config.json'}
if [[ ! -f ${WEBUI_CONFIG_PATH} ]]; then
    echo \
        "------------------------------------------------------------------------" \
        "  No config file found at ${WEBUI_CONFIG_PATH}, using default config.   " \
        "  !!! Defaults assume your webui output dir is mounted at /outputs !!!  " \
        "------------------------------------------------------------------------"
    WEBUI_CONFIG_PATH="/app/config.default.json"
fi

# if we have any args, and the first arg is not a flag, assume args are a command and exec it
if [[ $# -gt 0 ]] && [[ ! $1 =~ ^- ]]; then
    echo "Command detected (first arg is not a flag), will not start server!"
    echo "exec'ing command: $@"
    exec "$@"
fi

# make temp dir and set env (thumbnail storage)
mkdir -p /data/.cache/iib
export TMPDIR=/data/.cache/iib

# add port flag if set
if [[ -n ${BROWSER_PORT} ]]; then
    IIB_FLAGS="${IIB_FLAGS} --port=${BROWSER_PORT}"
fi

# check if the mounted /data volume has an IIB installation and pass the flag to use it
if [[ -d '/data/config/auto/extensions/sd-webui-infinite-image-browsing' ]]; then
    echo 'Found IIB installation in mounted /data volume, enabling DB sharing mode'
    IIB_FLAGS="${IIB_FLAGS} --sd_webui_dir=/data/config/auto"
fi

echo "Starting webui server with args: $@ --host=0.0.0.0"
exec python -u app.py --sd_webui_config=${WEBUI_CONFIG_PATH} "$@" ${IIB_FLAGS}
