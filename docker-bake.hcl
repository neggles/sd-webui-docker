# docker-bake.hcl for stable-diffusion-webui
group "default" {
  targets = ["auto-stable"]
}

variable "IMAGE_REGISTRY" {
  default = "ghcr.io"
}

variable "IMAGE_NAME" {
  default = "neggles/sd-webui-docker"
}

variable "AUTO_STABLE_REF" {
  default = "a9fed7c364061ae6efb37f797b6b522cb3cf7aa2"
}

variable "AUTO_LATEST_REF" {
  default = "origin/master"
}

variable "VLAD_LATEST_REF" {
  default = "origin/master"
}

variable "KOHYA_SS_REF" {
  default = "63657088f4c35a376dd8a936f53e9b9a3b4b1168"
}

variable "KOHYA_EDGE_REF" {
  default = "a39d082e35abe814070bb83086c7bb685bc08d5d"
}

variable "CUDA_VERSION" {
  default = "12.0"
}

variable "TORCH_VERSION" {
  default = "2.0.0+cu118"
}

variable "TORCH_INDEX" {
  default = "https://download.pytorch.org/whl/cu118"
}

# docker-metadata-action will populate this in GitHub Actions
target "docker-metadata-action" {}

# Shared amongst all containers
target "common" {
  inherits   = ["docker-metadata-action"]
  dockerfile = "Dockerfile"
  context    = "./docker"
  args = {
    CUDA_REPO_URL = "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64"
    CUDA_REPO_KEY = "https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/3bf863cc.pub"
    CUDA_VERSION  = CUDA_VERSION
    CUDA_RELEASE  = "${regex_replace(CUDA_VERSION, "\\.", "-")}"

    TORCH_INDEX      = TORCH_INDEX
    TORCH_VERSION    = TORCH_VERSION
    CUDNN_VERSION    = "8.8.1.3-1"
    XFORMERS_VERSION = "0.0.17"
    BNB_VERSION      = "0.38.1"
    TRITON_VERSION   = "2.0.0.post1"
  }
  platforms = ["linux/amd64"]

}

# AUTOMATIC1111 on latest git commit
target "auto-latest" {
  inherits = ["common"]
  target   = "webui"
  args = {
    SD_WEBUI_VARIANT = "latest"
    SD_WEBUI_REPO    = "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
    SD_WEBUI_REF     = AUTO_LATEST_REF
    REQFILE_NAME     = "requirements_versions.txt"

    STABLE_DIFFUSION_REF    = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
    TAMING_TRANSFORMERS_REF = "24268930bf1dce879235a7fddd0b2355b84d7ea6"
    K_DIFFUSION_REF         = "5b3af030dd83e0297272d861c19477735d0317ec"
    CODEFORMER_REF          = "c5b4593074ba6214284d6acd5f1719b6c5d739af"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"

    CLIP_INTERROGATOR_REF = "08546eae22d825a23f30669e10025098bb4f9dde"
    GFPGAN_PKG_REF        = "8d2447a2d918f8eba5a4a01463fd48e45126a379"
    CLIP_PKG_REF          = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF      = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}

# AUTOMATIC1111 on stable/pre-Gradio upgrade git commit
target "auto-stable" {
  inherits = ["common"]
  target   = "webui"
  args = {
    SD_WEBUI_VARIANT = "stable"
    SD_WEBUI_REPO    = "https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
    SD_WEBUI_REF     = AUTO_STABLE_REF
    REQFILE_NAME     = "requirements_versions.txt"

    STABLE_DIFFUSION_REF    = "47b6b607fdd31875c9279cd2f4f16b92e4ea958e"
    TAMING_TRANSFORMERS_REF = "24268930bf1dce879235a7fddd0b2355b84d7ea6"
    K_DIFFUSION_REF         = "5b3af030dd83e0297272d861c19477735d0317ec"
    CODEFORMER_REF          = "c5b4593074ba6214284d6acd5f1719b6c5d739af"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"

    CLIP_INTERROGATOR_REF = "08546eae22d825a23f30669e10025098bb4f9dde"
    GFPGAN_PKG_REF        = "8d2447a2d918f8eba5a4a01463fd48e45126a379"
    CLIP_PKG_REF          = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF      = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}

# vladmandic/automatic on latest git commit
target "vlad" {
  inherits = ["common"]
  target   = "webui"
  args = {
    SD_WEBUI_VARIANT = "vlad"
    SD_WEBUI_REPO    = "https://github.com/vladmandic/automatic.git"
    SD_WEBUI_REF     = VLAD_LATEST_REF
    REQFILE_NAME     = "requirements.txt"

    STABLE_DIFFUSION_REF    = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
    TAMING_TRANSFORMERS_REF = "3ba01b241669f5ade541ce990f7650a3b8f65318"
    K_DIFFUSION_REF         = "b43db16749d51055f813255eea2fdf1def801919"
    CODEFORMER_REF          = "c5b4593074ba6214284d6acd5f1719b6c5d739af"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"

    CLIP_INTERROGATOR_REF = "08546eae22d825a23f30669e10025098bb4f9dde"
    GFPGAN_PKG_REF        = "8d2447a2d918f8eba5a4a01463fd48e45126a379"
    CLIP_PKG_REF          = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF      = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}

# bmaltais/kohya_ss training repo
target "kohya" {
  inherits = ["common"]
  target   = "kohya"
  args = {
    KOHYA_SS_REPO = "https://github.com/bmaltais/kohya_ss.git"
    KOHYA_SS_REF  = KOHYA_SS_REF
  }
}

# bmaltais/kohya_ss training repo
target "kohya-edge" {
  inherits = ["common"]
  target   = "kohya"
  args = {
    KOHYA_SS_REPO = "https://github.com/neggles/kohya_ss.git"
    KOHYA_SS_REF  = KOHYA_EDGE_REF
  }
}
