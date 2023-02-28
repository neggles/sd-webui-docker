#!/bin/bash
set -exuo pipefail

repo_dir=${1:?"repo_dir is required"}
repo_url=${2:?"repo_url is required"}
repo_ref=${3:?"repo_ref is required"}

repo_path="/git/repositories/${repo_dir}"

# make dir
mkdir -p "${repo_path}"

# go into dir
pushd "${repo_path}" >/dev/null

# clone repo, reusing existing files if possible
git init .
git remote add origin "${repo_url}"
git fetch --depth 1 origin "${repo_ref}"
git reset --hard FETCH_HEAD

# clean up git dir
rm -fr .git

# restore old CWD just to be safe
popd >/dev/null
