# docker-bake.hcl for stable-diffusion-webui
group "default" {
  targets = ["local"]
}

variable "IMAGE_REGISTRY" {
  default = "ghcr.io"
}

variable "IMAGE_NAMESPACE" {
  default = "neggles/sd-webui-docker"
}

variable "AUTO_LATEST_REF" {
  default = "master"
}

variable "AUTO_EDGE_REF" {
  default = "dev"
}

variable "CUDA_VERSION" {
  default = "12.1"
}

variable "TORCH_PACKAGE" {
  default = "torch==2.2.0"
}

variable "TORCH_INDEX" {
  default = "https://pypi.org/simple"
}

# convert a CUDA version number into a shortname (e.g. 11.2.1 -> cu112)
function cudaName {
  params = [version]
  result = regex_replace(version, "^(\\d+)\\.(\\d).*", "cu$1$2")
}

# convert a CUDA version number into a release number (e.g. 11.2.1 -> 11-2)
function cudaRelease {
  params = [version]
  result = regex_replace(version, "^(\\d+)\\.(\\d).*", "$1-$2")
}

# torch version to torch name
function torchName {
  params = [version]
  # this is cursed, but if i try to do torch$1$20 it will interpret "$2 0" as $20
  result = join("", [regex_replace(version, "^(\\d+)\\.(\\d+)\\.(\\d+).*", "torch$1$2"), "0"])
}
# torch version to torch name
function torchSpec {
  params = [version]
  result = regex_replace(version, "^(\\d+)\\.(\\d+)\\.(\\d+).*", "torch==$1.$2.$3")
}

# build a tag for an image from this repo
function repoImage {
  params          = [imageTag]
  variadic_params = extraVals
  result = join(":", [
    join("/", [IMAGE_REGISTRY, IMAGE_NAMESPACE]),
    join("-", concat([imageTag], extraVals))
  ])
}
# sub-image, REGISTRY/NAMESPACE/subimagename:
function subImage {
  params          = [subImageName, imageTag]
  variadic_params = extraVals
  result = join(":", [
    join("/", [IMAGE_REGISTRY, IMAGE_NAMESPACE, subImageName]),
    join("-", concat([imageTag], extraVals))
  ])
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
    TORCH_PACKAGE    = TORCH_PACKAGE
    CUDNN_VERSION    = "8.9.3.28-1"
    XFORMERS_PACKAGE = "xformers>=0.0.23.post1"
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
    TORCH_PACKAGE = TORCH_PACKAGE
  }
}

# AUTOMATIC1111 on master
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
    K_DIFFUSION_REF         = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"
    SD_WEBUI_ASSETS_REF     = "6f7db241d2f8ba7457bac5ca9753331f0c266917"

    CLIP_PKG_REF     = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}

# AUTOMATIC1111 on dev
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

    STABLE_DIFFUSION_REF    = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
    STABLE_DIFFUSION_XL_REF = "45c443b316737a4ab6e40413d7794a7f5657c19f"
    K_DIFFUSION_REF         = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c"
    BLIP_REF                = "48211a1594f1321b00f14c9f7a5b4813144b2fb9"
    SD_WEBUI_ASSETS_REF     = "6f7db241d2f8ba7457bac5ca9753331f0c266917"

    CLIP_PKG_REF     = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1"
    OPENCLIP_PKG_REF = "bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b"
  }
}

target "local" {
  inherits = ["auto-latest"]
  target   = "webui"
  tags = [
    repoImage(cudaName("12.1.1"), torchName("2.2.0")),
    repoImage("latest"),
  ]
  args = {}
}

target "local-dev" {
  inherits = ["auto-edge"]
  target   = "webui"
  tags = [
    repoImage("edge", cudaName("12.1.1"), torchName("2.2.0")),
    repoImage("edge"),
  ]
  args = {}
}

target "browser" {
  inherits   = ["common", "docker-metadata-action"]
  context    = "./browser"
  dockerfile = "Dockerfile"
  target     = "browser"
  tags = [
    subImage("browser", "latest"),
  ]
}
