# syntax=docker/dockerfile:1

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_PRIORITY=critical
ARG PIP_PREFER_BINARY=1

FROM alpine/git:2.36.2 as download

# Get bash, set shell
RUN apk add --no-cache bash
SHELL [ "/bin/bash", "-ceuxo", "pipefail" ]

# This isn't strictly necessary as it's set upstream, but it's here for clarity
WORKDIR /git

# Add clone script
COPY --chown=root:root --chmod=0755 ./clone.sh /clone.sh

# Clone repositories
ARG TAMING_TRANSFORMERS_REF=24268930bf1dce879235a7fddd0b2355b84d7ea6
RUN mkdir -p taming-transformers && \
  /clone.sh taming-transformers "https://github.com/CompVis/taming-transformers.git" "${TAMING_TRANSFORMERS_REF}" \
  && cd taming-transformers \
  && rm -fr data assets **/*.ipynb

ARG STABLE_DIFFUSION_REF=47b6b607fdd31875c9279cd2f4f16b92e4ea958e
RUN mkdir -p stable-diffusion-stability-ai && \
  /clone.sh stable-diffusion-stability-ai "https://github.com/Stability-AI/stablediffusion.git" "${STABLE_DIFFUSION_REF}" \
  && cd stable-diffusion-stability-ai \
  && rm -fr ./assets ./data/**/*.png ./data/**/*.jpg ./data/**/*.gif

ARG CODEFORMER_REF=c5b4593074ba6214284d6acd5f1719b6c5d739af
RUN mkdir -p CodeFormer && \
  /clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git ${CODEFORMER_REF} \
  && cd CodeFormer \
  && rm -fr data assets **/*.ipynb

ARG BLIP_REF=48211a1594f1321b00f14c9f7a5b4813144b2fb9
RUN /clone.sh BLIP https://github.com/salesforce/BLIP.git ${BLIP_REF}

ARG K_DIFFUSION_REF=5b3af030dd83e0297272d861c19477735d0317ec
RUN /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git ${K_DIFFUSION_REF}

ARG CLIP_INTERROGATOR_REF=08546eae22d825a23f30669e10025098bb4f9dde
RUN /clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator ${CLIP_INTERROGATOR_REF}

# Copy interrogate data to where webui will expect it to be
RUN rm -fr /git/interrogate \
  && cp -r /git/repositories/clip-interrogator/clip_interrogator/data /git/interrogate

# Build the main image
FROM python:3.10.9-slim AS app

# Set shell
SHELL ["/bin/bash", "-ceuxo", "pipefail"]

ARG DEBIAN_FRONTEND
ARG DEBIAN_PRIORITY
ARG PIP_PREFER_BINARY

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt apt-get update \
  && apt-get -y install --no-install-recommends \
    apt-transport-https \
    apt-utils \
    build-essential \
    ca-certificates \
    curl \
    fonts-dejavu-core \
    git \
    gnupg2 \
    jq \
    moreutils \
    pkg-config \
    rsync \
    unzip \
    wget \
  && apt-get clean

# Get nVidia repo key and add to apt sources
ARG CUDA_REPO_URL=https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/3bf863cc.pub \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/cuda.gpg \
  && echo "deb ${CUDA_REPO_URL} /" >/etc/apt/sources.list.d/cuda.list

# Install CUDNN
ARG CUDA_VERSION=12.0
ARG CUDNN_VERSION=8.8.0.121
RUN --mount=type=cache,target=/var/cache/apt apt-get update \
  && apt-get -y install --no-install-recommends \
    libcudnn8=${CUDNN_VERSION}-1+cuda${CUDA_VERSION} \
    libcudnn8-dev=${CUDNN_VERSION}-1+cuda${CUDA_VERSION} \
  && apt-get clean

# Install PyTorch
ARG TORCH_VERSION=1.13.1+cu117
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu117
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install torch==${TORCH_VERSION} torchvision --extra-index-url ${TORCH_INDEX_URL}

# Clone actual repo
ARG SD_WEBUI_REF=d7aec59c4eb02f723b3d55c6f927a42e97acd679
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git \
  && cd stable-diffusion-webui \
  && git reset --hard d7aec59c4eb02f723b3d55c6f927a42e97acd679

# Install requirements
RUN --mount=type=cache,target=/root/.cache/pip \
  cd stable-diffusion-webui \
  && pip install -r requirements.txt

# Install xformers and triton
ARG XFORMERS_VERSION=0.0.17.dev465
ARG TRITON_VERSION=2.0.0a2
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install xformers==${XFORMERS_VERSION} triton==${TRITON_VERSION}

ENV ROOT=/stable-diffusion-webui

# Grab interrograte data
COPY --from=download /git ${ROOT}
RUN mkdir -p ${ROOT}/interrogate \
  && cp -rfv ${ROOT}/repositories/clip-interrogator/clip_interrogator/data ${ROOT}/interrogate

# Install requirements for CodeFormer
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r ${ROOT}/repositories/CodeFormer/requirements.txt

# Install GFPGAN, CLIP, OPENCLIP and pyngrok
ARG GFPGAN_PKG_REF=8d2447a2d918f8eba5a4a01463fd48e45126a379
ARG CLIP_PKG_REF=d50d76daa670286dd6cacf3bcd80b5e4823fc8e1
ARG OPENCLIP_PKG_REF=bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install pyngrok \
  "git+https://github.com/TencentARC/GFPGAN.git@${GFPGAN_PKG_REF}" \
  "git+https://github.com/openai/CLIP.git@${CLIP_PKG_REF}" \
  "git+https://github.com/mlfoundations/open_clip.git@${OPENCLIP_PKG_REF}"

# TODO: either remove if fixed in A1111 (unlikely) or move to the top with other apt stuff
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get -y update && \
  apt-get -y install libgoogle-perftools-dev \
  && apt-get clean
ENV LD_PRELOAD=libtcmalloc.so

# Clone the AUTOMATIC1111 repo and install deps
ARG SHA=0cc0ee1bcb4c24a8c9715f66cede06601bfc00c8
RUN --mount=type=cache,target=/root/.cache/pip \
  cd stable-diffusion-webui \
  && git fetch \
  && git reset --hard ${SHA} \
  && pip install -r requirements_versions.txt

# Install OpenCV
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -U opencv-python-headless

# Install moviepy and up-to-date tqdm
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install moviepy==1.0.3 tqdm==4.65.0 imageio-ffmpeg

# Add the rest of the files
COPY . /docker

# Commit high treason
RUN python3 /docker/info.py ${ROOT}/modules/ui.py \
  && sed -i 's/in_app_dir = .*/in_app_dir = True/g' /usr/local/lib/python3.10/site-packages/gradio/routes.py

# Set up the entrypoint
WORKDIR ${ROOT}
ENV CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD python -u webui.py --listen --port 7860 ${CLI_ARGS}
