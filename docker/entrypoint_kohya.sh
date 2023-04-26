#!/usr/bin/env bash
set -Eeuo pipefail

# Set up our directory mapping table
repo_root=${ROOT_DIR:-'/kohya_ss'}
data_dir=${DATA_DIR:-'/data'}
declare -A path_map

path_map["${repo_root}/models/Stable-diffusion"]="${data_dir}/StableDiffusion"
path_map["${repo_root}/models/VAE"]="${data_dir}/VAE"
path_map["${repo_root}/models/deepbooru"]="${data_dir}/Deepdanbooru"


# add pip cache path to path_map
if [[ -d ${HOME} ]]; then
    echo "Using ${HOME}/.cache for pip cache"
    path_map["${HOME}/.cache"]="${data_dir}/.cache"
else
    echo "Warning: No home directory found, using /tmp/.cache for pip cache"
    path_map["/tmp/.cache"]="${data_dir}/.cache"
fi

# add other paths to path_map
path_map["${repo_root}/embeddings"]="${data_dir}/embeddings"

if [[ -d "${data_dir}/config/kohya" ]]; then
    config_dir="${data_dir}/config/kohya"
else
    config_dir="${data_dir}/kohya"
fi

path_map["${repo_root}/extensions"]="${config_dir}/extensions"
path_map["${repo_root}/.vscode"]="${config_dir}/.vscode"


### Execution begins here ###

# create path maps and symlink them
for tgt_path in "${!path_map[@]}"; do
    echo -n "link ${tgt_path#"/${repo_root}"}"
    # get source path and create it if it doesn't exist
    src_path="${path_map[${tgt_path}]}"
    [[ -d ${src_path} ]] || mkdir -vp "${src_path}" 2>&1 > /dev/null

    # ensure target parent directory exists
    tgt_parent="$(dirname "${tgt_path}")"
    [[ -d ${tgt_parent} ]] || mkdir -vp "${tgt_parent}" 2>&1 > /dev/null

    # clean out target directory and symlink it to source path
    rm -rf "${tgt_path}"
    ln -sT "${src_path}" "${tgt_path}"
    echo " -> ${src_path} (directory)"
done

# Set git config so it won't warn
git config --global pull.ff only

# make sure CUDA libs etc. are in path
if [[ ! -z "${CUDA_HOME:-}" ]]; then
    ln -s "${CUDA_HOME}" /usr/local/cuda || true # this may or may not already exist
    export PATH="${CUDA_HOME}/bin:${PATH}"
    export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
fi

# Run startup script if it exists
if [ -f "${config_dir}/startup.sh" ]; then
    pushd "${repo_root}" > /dev/null
    echo "Running startup script..."
    # shellcheck source=/dev/null
    . "${config_dir}/startup.sh"
    popd > /dev/null
fi

if [[ $1 == 'python' ]]; then
    # Run the python script
    exec python "${repo_root}/kohya_gui.py"
fi

exec "$@"
