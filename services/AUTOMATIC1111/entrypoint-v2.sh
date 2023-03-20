#!/usr/bin/env bash
set -Eeuo pipefail

# Set up our directory mapping table
repo_root=${ROOT:-'/stable-diffusion-webui'}
data_dir=${DATA_DIR:-'/data'}
declare -A path_map

path_map["${repo_root}/models/Stable-diffusion"]="${data_dir}/StableDiffusion"
path_map["${repo_root}/models/VAE"]="${data_dir}/VAE"
path_map["${repo_root}/models/Codeformer"]="${data_dir}/Codeformer"
path_map["${repo_root}/models/GFPGAN"]="${data_dir}/GFPGAN"
path_map["${repo_root}/models/ESRGAN"]="${data_dir}/ESRGAN"
path_map["${repo_root}/models/BSRGAN"]="${data_dir}/BSRGAN"
path_map["${repo_root}/models/RealESRGAN"]="${data_dir}/RealESRGAN"
path_map["${repo_root}/models/SwinIR"]="${data_dir}/SwinIR"
path_map["${repo_root}/models/ScuNET"]="${data_dir}/ScuNET"
path_map["${repo_root}/models/LDSR"]="${data_dir}/LDSR"
path_map["${repo_root}/models/hypernetworks"]="${data_dir}/Hypernetworks"
path_map["${repo_root}/models/torch_deepdanbooru"]="${data_dir}/Deepdanbooru"
path_map["${repo_root}/models/BLIP"]="${data_dir}/BLIP"
path_map["${repo_root}/models/midas"]="${data_dir}/MiDaS"
path_map["${repo_root}/models/Lora"]="${data_dir}/Lora"

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
path_map["${repo_root}/extensions"]="${data_dir}/config/auto/extensions"
path_map["${repo_root}/scripts"]="${data_dir}/config/auto/scripts"

# create path maps and symlink them
for to_path in "${!path_map[@]}"; do
    # get source path and create it if it doesn't exist
    from_path="${path_map[${to_path}]}"
    [ -d "${from_path}" ] || mkdir -vp "${from_path}"

    # clean out target directory and symlink it to source path
    rm -rf "${to_path}"
    ln -sT "${from_path}" "${to_path}"
    echo "Linked $(basename "${from_path}") to $(basename "${to_path}")"
done

# Map config and script files to their target locations
declare -A file_map
# add files to file_map
file_map["${repo_root}/config.json"]="${data_dir}/config/auto/config.json"
file_map["${repo_root}/ui-config.json"]="${data_dir}/config/auto/ui-config.json"
file_map["${repo_root}/user.css"]="${data_dir}/config/auto/user.css"

# copy default config.json if there isn't one
if [ ! -f "${data_dir}/config/auto/config.json" ]; then
    cp -n "${repo_root}/config.json" "${data_dir}/config/auto/config.json"
fi

# create empty ui-config.json if none provided
if [ ! -f "${data_dir}/config/auto/ui-config.json" ]; then
    echo '{}' > "${data_dir}/config/auto/ui-config.json"
fi

# create empty user.css if none provided
if [ ! -f "${data_dir}/config/auto/user.css" ]; then
    echo '' > "${data_dir}/config/auto/user.css"
fi

# merge system config.json with default config.json
jq '. * input' "${data_dir}/config/auto/config.json" "${repo_root}/config.json" \
    | sponge "${data_dir}/config/auto/config.json"

# symlink files
for to_path in "${!file_map[@]}"; do
    # get source path and create it if it doesn't exist (which it should, but just in case)
    from_path="${file_map[${to_path}]}"
    [ -f "${from_path}" ] || touch "${from_path}"

    # clean out target if it exists and symlink to source path
    rm -f "${to_path}"
    ln -sT "${from_path}" "${to_path}"
    echo "Linked $(basename "${from_path}") to $(basename "${to_path}")"
done

cp -vrfTs "${data_dir}/config/auto/scripts/" "${repo_root}/scripts/"

# Run startup script if it exists
if [ -f "${data_dir}/config/auto/startup.sh" ]; then
    pushd "${repo_root}" > /dev/null
    echo "Running startup script..."
    . "${data_dir}/config/auto/startup.sh"
    popd > /dev/null
fi

if [[ "$1" == 'python' ]]; then
    # Run the python script
    exec python "${repo_root}/app.py"
fi

exec "$@"
