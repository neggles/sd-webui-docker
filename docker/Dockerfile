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
FROM python:3.10.9-slim AS base

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
    libgoogle-perftools-dev \
    moreutils \
    nano \
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

# enable contrib and non-free repos
RUN --mount=type=cache,target=/var/cache/apt \
  sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list \
  && apt-get update

# PATH
ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64

# Install CUDNN
ARG CUDA_VERSION=12.0
ARG CUDNN_VERSION=8.8.0.121
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update \
  && apt-get -y install --no-install-recommends \
    libcudnn8=${CUDNN_VERSION}-1+cuda${CUDA_VERSION} \
    libcudnn8-dev=${CUDNN_VERSION}-1+cuda${CUDA_VERSION} \
  && apt-get clean

# Install PyTorch
ARG TORCH_VERSION=2.0.0+cu118
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu118
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install torch==${TORCH_VERSION} torchvision --extra-index-url ${TORCH_INDEX_URL}

FROM base AS webui

# set up some important environment variables
ARG PIP_PREFER_BINARY
ENV LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8

# CUDA-related
ENV CUDA_MODULE_LOADING=LAZY
ENV TORCH_CUDNN_V8_API_ENABLED=1
ENV USE_EXPERIMENTAL_CUDNN_V8_API=1
ENV TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics
ENV NVIDIA_REQUIRE_CUDA="cuda>=11.8 driver>=450"

# Where we should put everything
ENV ROOT_DIR=/stable-diffusion-webui

# Clone actual repo
ARG SD_WEBUI_REF=d7aec59c4eb02f723b3d55c6f927a42e97acd679
ARG SD_WEBUI_REPO=https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone ${SD_WEBUI_REPO} ${ROOT_DIR} \
  && cd ${ROOT_DIR} \
  && git reset --hard ${SD_WEBUI_REF}

# Install requirements
RUN --mount=type=cache,target=/root/.cache/pip \
  cd stable-diffusion-webui \
  && pip install -r requirements.txt

# Install xformers and triton
ARG XFORMERS_VERSION=0.0.17rc481
ARG TRITON_VERSION=2.0.0.post1
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install --no-deps --pre xformers==${XFORMERS_VERSION} triton==${TRITON_VERSION}

# Grab interrograte data
COPY --from=download /git ${ROOT_DIR}
RUN mkdir -p ${ROOT_DIR}/interrogate \
  && cp -rfv ${ROOT_DIR}/repositories/clip-interrogator/clip_interrogator/data ${ROOT_DIR}/interrogate

# Install requirements for CodeFormer
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r ${ROOT_DIR}/repositories/CodeFormer/requirements.txt

# Install GFPGAN, CLIP, OPENCLIP and pyngrok
ARG GFPGAN_PKG_REF=8d2447a2d918f8eba5a4a01463fd48e45126a379
ARG CLIP_PKG_REF=d50d76daa670286dd6cacf3bcd80b5e4823fc8e1
ARG OPENCLIP_PKG_REF=bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install pyngrok \
  "git+https://github.com/TencentARC/GFPGAN.git@${GFPGAN_PKG_REF}" \
  "git+https://github.com/openai/CLIP.git@${CLIP_PKG_REF}" \
  "git+https://github.com/mlfoundations/open_clip.git@${OPENCLIP_PKG_REF}"


# fix an issue in A1111
ENV LD_PRELOAD=libtcmalloc.so

# Reupdate the repo to target hash and install deps
ARG SD_WEBUI_REF
RUN --mount=type=cache,target=/root/.cache/pip \
  cd stable-diffusion-webui \
  && git fetch \
  && git reset --hard ${SD_WEBUI_REF} \
  && pip install -r requirements_versions.txt

# Install OpenCV
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -U opencv-python-headless

# Install moviepy and up-to-date tqdm
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install moviepy==1.0.3 tqdm>=4.65.0 imageio-ffmpeg

# Add the rest of the files
COPY . /docker

# Commit high treason
RUN sed -i 's/in_app_dir = .*/in_app_dir = True/g' /usr/local/lib/python3.10/site-packages/gradio/routes.py

# Set up the entrypoint
WORKDIR ${ROOT_DIR}
ENV CLI_ARGS=""
ENV DATA_DIR=/data
ENV WEBUI_PORT=7860

EXPOSE ${WEBUI_PORT}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD python -u webui.py --listen --port ${WEBUI_PORT} ${CLI_ARGS}

FROM base AS kohya

# New root dir
ENV ROOT_DIR=/kohya_ss
WORKDIR /

# set up some important environment variables
ARG PIP_PREFER_BINARY
ENV LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8

# CUDA-related
ENV CUDA_MODULE_LOADING=LAZY
ENV TORCH_CUDNN_V8_API_ENABLED=1
ENV USE_EXPERIMENTAL_CUDNN_V8_API=1
ENV TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics
ENV NVIDIA_REQUIRE_CUDA="cuda>=11.8 driver>=450"

# fix an issue with a dependency
ENV LD_PRELOAD=libtcmalloc.so

# PATHs
ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64

# Install xformers and triton
ARG XFORMERS_VERSION=0.0.17rc481
ARG TRITON_VERSION=2.0.0.post1
ARG BNB_VERSION=0.37.2
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install --no-deps --pre \
    xformers==${XFORMERS_VERSION} \
    triton==${TRITON_VERSION} \
    bitsandbytes==${BNB_VERSION}

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt apt-get update \
  && apt-get -y install --no-install-recommends \
    python3-tk \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1-mesa-glx \
    nano

# Clone the repo
ARG KOHYA_SS_REF=9c8c480f8e654eeb5a7d92c13b4ce04333840b0c
ARG KOHYA_SS_REPO=https://github.com/bmaltais/kohya_ss.git
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone ${KOHYA_SS_REPO} ${ROOT_DIR} \
  && cd ${ROOT_DIR} \
  && git reset --hard ${KOHYA_SS_REF}

# Install requirements
RUN --mount=type=cache,target=/root/.cache/pip \
  cd ${ROOT_DIR} \
  && git fetch \
  && git reset --hard ${KOHYA_SS_REF} \
  && pip install -r requirements.txt

# Install OpenCV
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -U opencv-python-headless tensorrt

# Add the rest of the files and replace the entrypoint
COPY . /docker
COPY ./entrypoint_kohya.sh /docker/entrypoint.sh

# war crime
RUN sed -i 's|interface.launch(|interface.launch(server_name="0.0.0.0", |' ${ROOT_DIR}/dreambooth_gui.py

# Set up the entrypoint
WORKDIR ${ROOT_DIR}
ENV CLI_ARGS=""
ENV DATA_DIR=/data
ENV KOHYA_PORT=7680

EXPOSE ${KOHYA_PORT}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD python -u kohya_gui.py --server_port ${KOHYA_PORT} ${CLI_ARGS}
