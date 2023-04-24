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
ARG TAMING_TRANSFORMERS_REF
RUN mkdir -p taming-transformers && \
  /clone.sh taming-transformers "https://github.com/CompVis/taming-transformers.git" "${TAMING_TRANSFORMERS_REF}" \
  && cd taming-transformers \
  && rm -fr data assets **/*.ipynb

ARG STABLE_DIFFUSION_REF
RUN mkdir -p stable-diffusion-stability-ai && \
  /clone.sh stable-diffusion-stability-ai "https://github.com/Stability-AI/stablediffusion.git" "${STABLE_DIFFUSION_REF}" \
  && cd stable-diffusion-stability-ai \
  && rm -fr ./assets ./data/**/*.png ./data/**/*.jpg ./data/**/*.gif

ARG CODEFORMER_REF
RUN mkdir -p CodeFormer && \
  /clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git ${CODEFORMER_REF} \
  && cd CodeFormer \
  && rm -fr data assets **/*.ipynb

ARG BLIP_REF
RUN /clone.sh BLIP https://github.com/salesforce/BLIP.git ${BLIP_REF}

ARG K_DIFFUSION_REF
RUN /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git ${K_DIFFUSION_REF}

ARG CLIP_INTERROGATOR_REF
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
ARG CUDA_REPO_URL
ARG CUDA_REPO_KEY
RUN curl -fsSL ${CUDA_REPO_KEY} \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/cuda.gpg \
  && echo "deb ${CUDA_REPO_URL} /" >/etc/apt/sources.list.d/cuda.list

# enable contrib and non-free repos
RUN --mount=type=cache,target=/var/cache/apt \
  sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list \
  && apt-get update

# add nVidia repo apt pin to prevent kernel driver installation
COPY cuda-repo-pin /etc/apt/preferences.d/cuda-repo-pin

# PATH
ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64

# Install CUDNN
ARG CUDA_VERSION
ARG CUDNN_VERSION
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update \
  && apt-get -y install --no-install-recommends \
    libcudnn8=${CUDNN_VERSION}*cuda${CUDA_VERSION} \
    libcudnn8-dev=${CUDNN_VERSION}*cuda${CUDA_VERSION} \
  && apt-get clean

# Install other CUDA libraries
ARG CUDA_RELEASE
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update \
  && apt-get -y install --no-install-recommends \
    cuda-libraries-${CUDA_RELEASE} \
  && apt-get clean

# # Install TensorRT. This doesn't work on Debian yet so it's disabled for now.
# ARG TENSORRT_VERSION=8.6.0.12-1
# RUN --mount=type=cache,target=/var/cache/apt \
#   apt-get update \
#   && apt-get -y install --no-install-recommends \
#     tensorrt=${TENSORRT_VERSION}'*' \
#   && apt-get clean

# Install PyTorch
ARG TORCH_VERSION
ARG TORCH_INDEX
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install torch==${TORCH_VERSION} torchvision --extra-index-url ${TORCH_INDEX}

FROM base AS webui

# set up some important environment variables
ARG PIP_PREFER_BINARY
ARG SD_WEBUI_VARIANT
ENV LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8
ENV SD_WEBUI_VARIANT=${SD_WEBUI_VARIANT}

# CUDA-related
ENV CUDA_LAUNCH_BLOCKING=0
ENV CUDA_CACHE_DISABLE=0
ENV CUDA_AUTO_BOOST=1
ENV CUDA_MODULE_LOADING=LAZY
ENV CUDA_DEVICE_DEFAULT_PERSISTING_L2_CACHE_PERCENTAGE_LIMIT=0
ENV NUMEXPR_MAX_THREADS=16
ENV SAFETENSORS_FAST_GPU=1
ENV TORCH_CUDNN_V8_API_ENABLED=1
ENV TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics
ENV NVIDIA_REQUIRE_CUDA="cuda>=11.8 driver>=450"

# Where we should put everything
ENV ROOT_DIR=/stable-diffusion-webui

# Clone actual repo
ARG SD_WEBUI_REF
ARG SD_WEBUI_REPO
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone ${SD_WEBUI_REPO} ${ROOT_DIR} \
  && cd ${ROOT_DIR} \
  && git reset --hard ${SD_WEBUI_REF}

# Install requirements
ARG REQFILE_NAME
RUN --mount=type=cache,target=/root/.cache/pip \
  cd stable-diffusion-webui \
  && pip install -r ${REQFILE_NAME}

# Install xformers and triton
ARG XFORMERS_VERSION
ARG TRITON_VERSION
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
ARG GFPGAN_PKG_REF
ARG CLIP_PKG_REF
ARG OPENCLIP_PKG_REF
RUN pip install pyngrok \
  "git+https://github.com/TencentARC/GFPGAN.git@${GFPGAN_PKG_REF}" \
  "git+https://github.com/openai/CLIP.git@${CLIP_PKG_REF}" \
  "git+https://github.com/mlfoundations/open_clip.git@${OPENCLIP_PKG_REF}"

# fix an issue in A1111
ENV LD_PRELOAD=libtcmalloc.so

# Reupdate the repo to target hash and install deps
RUN --mount=type=cache,target=/root/.cache/pip \
  cd stable-diffusion-webui \
  && git fetch \
  && git reset --hard ${SD_WEBUI_REF} \
  && pip install -r ${REQFILE_NAME}

# Install OpenCV and scikit-learn
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -U opencv-python-headless scikit-learn lora

# Install moviepy and up-to-date tqdm
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install 'moviepy==1.0.3' 'tqdm>=4.65.0' 'imageio-ffmpeg'

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
ENV CUDA_LAUNCH_BLOCKING=0
ENV CUDA_CACHE_DISABLE=0
ENV CUDA_AUTO_BOOST=1
ENV CUDA_MODULE_LOADING=LAZY
ENV CUDA_DEVICE_DEFAULT_PERSISTING_L2_CACHE_PERCENTAGE_LIMIT=0
ENV NUMEXPR_MAX_THREADS=16
ENV SAFETENSORS_FAST_GPU=1
ENV TORCH_CUDNN_V8_API_ENABLED=1
ENV TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics
ENV NVIDIA_REQUIRE_CUDA=cuda>=11.8 driver>=450

# fix an issue with a dependency
ENV LD_PRELOAD=libtcmalloc.so

# PATHs
ENV PATH=$PATH:/usr/local/cuda/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64

# Install xformers and triton
ARG XFORMERS_VERSION
ARG TRITON_VERSION
ARG BNB_VERSION
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
ARG KOHYA_SS_REF
ARG KOHYA_SS_REPO
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
ENV KOHYA_PORT=7681
ENV KOHYA_SCRIPT=kohya_gui.py

EXPOSE ${KOHYA_PORT}
ENTRYPOINT [ "/docker/entrypoint.sh" ]
CMD python -u "${KOHYA_SCRIPT}" --server_port "${KOHYA_PORT}" --listen 0.0.0.0 ${CLI_ARGS}
