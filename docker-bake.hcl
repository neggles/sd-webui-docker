# docker-bake.hcl for stable-diffusion-webui
group "default" {
  targets = ["auto-latest", "auto-edge", "vlad-latest"]
}

variable "IMAGE_REGISTRY" {
  default = "ghcr.io"
}

variable "IMAGE_NAME" {
  default = "neggles/sd-webui-docker"
}

variable "AUTO_LATEST_REF" {
  default = "origin/master"
}

variable "AUTO_EDGE_REF" {
  default = "origin/dev"
}

variable "VLAD_LATEST_REF" {
  default = "origin/master"
}

variable "KOHYA_SS_REF" {
  default = "63657088f4c35a376dd8a936f53e9b9a3b4b1168"
}

variable "KOHYA_EDGE_REF" {
  default = "ad76b1cddfae460372262cb44043701fe1aec96e"
}

variable "CUDA_VERSION" {
  default = "12.1"
}

variable "TORCH_VERSION" {
  default = "2.0.1+cu118"
}

variable "TORCH_INDEX" {
  default = "https://download.pytorch.org/whl/cu118"
}

# docker-metadata-action will populate this in GitHub Actions
target "docker-metadata-action" {}

# Shared amongst all containers
target "common" {
  context = "./docker"
  args = {
    CUDA_REPO_URL = "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64"
    CUDA_REPO_KEY = "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/3bf863cc.pub"
    CUDA_VERSION  = CUDA_VERSION
    CUDA_RELEASE  = "${regex_replace(CUDA_VERSION, "\\.", "-")}"

    TORCH_INDEX      = TORCH_INDEX
    TORCH_VERSION    = TORCH_VERSION
    CUDNN_VERSION    = "8.9.3.28-1"
    XFORMERS_VERSION = "0.0.21"
    BNB_VERSION      = "0.41.1"
    TRITON_VERSION   = "2.0.0.post1"
    LION_VERSION     = "0.0.7"
  }
  platforms = ["linux/amd64"]

}

# Base image with cuda, python, torch, and other dependencies
target "base" {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.base"
  target     = "base"
  args = {
    CUDA_REPO_URL = "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64"
    CUDA_REPO_KEY = "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/3bf863cc.pub"
    CUDA_VERSION  = CUDA_VERSION
    CUDA_RELEASE  = "${regex_replace(CUDA_VERSION, "\\.", "-")}"

    TORCH_INDEX   = TORCH_INDEX
    TORCH_VERSION = TORCH_VERSION
  }
}

# AUTOMATIC1111 on latest git commit
target "auto-edge" {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.auto"
  target     = "webui"
  contexts = {
    base = "target:base"
  }
  args = {
    SD_WEBUI_VARIANT = "edge"
    SD_WEBUI_REPO    = "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
    SD_WEBUI_REF     = AUTO_EDGE_REF
    REQFILE_NAME     = "requirements_versions.txt"

    TRITON_VERSION   = "2.1.0"
    XFORMERS_VERSION = "0.0.21"

    STABLE_DIFFUSION_REF    = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
    STABLE_DIFFUSION_XL_REF = "45c443b316737a4ab6e40413d7794a7f5657c19f"
    TAMING_TRANSFORMERS_REF = "24268930bf1dce879235a7fddd0b2355b84d7ea6"
    K_DIFFUSION_REF         = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c"
    CODEFORMER_REF          = "c5b4593074ba6214284d6acd5f1719b6c5d739af"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"

    CLIP_INTERROGATOR_REF = "08546eae22d825a23f30669e10025098bb4f9dde"
    GFPGAN_PKG_REF        = "8d2447a2d918f8eba5a4a01463fd48e45126a379"
    CLIP_PKG_REF          = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF      = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}


# AUTOMATIC1111 on latest known-good commit
target "auto-latest" {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.auto"
  target     = "webui"
  contexts = {
    base = "target:base"
  }
  args = {
    SD_WEBUI_VARIANT = "latest"
    SD_WEBUI_REPO    = "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
    SD_WEBUI_REF     = AUTO_LATEST_REF
    REQFILE_NAME     = "requirements_versions.txt"

    STABLE_DIFFUSION_REF    = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
    STABLE_DIFFUSION_XL_REF = "45c443b316737a4ab6e40413d7794a7f5657c19f"
    TAMING_TRANSFORMERS_REF = "24268930bf1dce879235a7fddd0b2355b84d7ea6"
    K_DIFFUSION_REF         = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c"
    CODEFORMER_REF          = "c5b4593074ba6214284d6acd5f1719b6c5d739af"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"

    CLIP_INTERROGATOR_REF = "08546eae22d825a23f30669e10025098bb4f9dde"
    GFPGAN_PKG_REF        = "8d2447a2d918f8eba5a4a01463fd48e45126a379"
    CLIP_PKG_REF          = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF      = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}

# vladmandic/automatic on latest git commit
target "vlad-latest" {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.vlad"
  target     = "vlad"
  contexts = {
    base = "target:base"
  }
  args = {
    SD_WEBUI_VARIANT = "vlad"
    SD_WEBUI_REPO    = "https://github.com/vladmandic/automatic.git"
    SD_WEBUI_REF     = VLAD_LATEST_REF
    REQFILE_NAME     = "requirements.txt"

    TRITON_VERSION   = "2.1.0"
    XFORMERS_VERSION = "0.0.21"

    STABLE_DIFFUSION_REF    = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
    STABLE_DIFFUSION_XL_REF = "45c443b316737a4ab6e40413d7794a7f5657c19f"
    TAMING_TRANSFORMERS_REF = "24268930bf1dce879235a7fddd0b2355b84d7ea6"
    K_DIFFUSION_REF         = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c"
    CODEFORMER_REF          = "c5b4593074ba6214284d6acd5f1719b6c5d739af"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"

    CLIP_PKG_REF = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
  }
}

# bmaltais/kohya_ss training repo
target "kohya-latest" {
  inherits   = ["common", "docker-metadata-action"]
  context    = "./kohya"
  dockerfile = "Dockerfile.kohya"
  target     = "kohya"
  contexts = {
    base = "target:base"
  }
  args = {
    KOHYA_SS_REPO = "https://github.com/bmaltais/kohya_ss.git"
    KOHYA_SS_REF  = KOHYA_SS_REF
  }
}

# bmaltais/kohya_ss training repo
target "kohya-edge" {
  inherits   = ["common", "docker-metadata-action"]
  context    = "./kohya"
  dockerfile = "Dockerfile.kohya"
  target     = "kohya"
  contexts = {
    base = "target:base"
  }
  args = {
    KOHYA_SS_REPO = "https://github.com/neggles/kohya_ss.git"
    KOHYA_SS_REF  = KOHYA_EDGE_REF
  }
}
