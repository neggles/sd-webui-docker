# syntax=docker/dockerfile:1

# base image to use
ARG BASE_IMAGE=python:3.10-bookworm
# settings for apt and pip (inheritable by all images)
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_PRIORITY=critical
ARG PIP_PREFER_BINARY=1

# Build the base image.
FROM ${BASE_IMAGE} as browser

# Set shell
SHELL ["/bin/bash", "-ceuxo", "pipefail"]

# Inherit args from global
ARG DEBIAN_FRONTEND
ARG DEBIAN_PRIORITY
ARG PIP_PREFER_BINARY

# Silence pip root user warnings
ENV PIP_ROOT_USER_ACTION=ignore
ENV _PIP_LOCATIONS_NO_WARN_ON_MISMATCH=1

# create app/data directories
RUN mkdir -p /app/browser /data /output
# set workdir
WORKDIR /app/browser

# clone repo and clean up git dir (to reduce image size)
ARG BROWSER_REPO=https://github.com/zanllp/sd-webui-infinite-image-browsing.git
ARG BROWSER_REF=main
RUN git clone --depth=1 --single-branch --branch="${BROWSER_REF}" "${BROWSER_REPO}" /app/browser \
    && rm -fr /app/browser/.git

# install Python dependencies
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    python -m pip install -U pip setuptools wheel \
    && python -m pip install -r requirements.txt

# hotpatch the path to the sqlite db file so it's in /data
RUN sed -iE 's|iib\.db|/data/iib.sqlite|g' /app/browser/scripts/iib/db/datamodel.py \
    && grep -q '/data/iib.sqlite' /app/browser/scripts/iib/db/datamodel.py \
    || (echo "Failed to hotpatch the sqlite db path!" && exit 1)

# copy in entrypoint script and set permissions
COPY --chown=root:root entrypoint.sh /app/entrypoint.sh
RUN chmod 755 /app/entrypoint.sh

# copy in default config
COPY --chown=root:root config.json /app/config.default.json

# set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
CMD []
