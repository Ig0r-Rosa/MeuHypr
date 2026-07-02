#!/usr/bin/env bash
# Ambiente Vulkan/NVIDIA para jogos Proton no Hyprland (notebook híbrido).
# Remove vars do compositor que quebram vkCreateDevice em alguns títulos (ex.: Enshrouded).

unset WLR_DRM_DEVICES
unset GBM_BACKEND

export __NV_PRIME_RENDER_OFFLOAD=1
export __VK_LAYER_NV_optimus=NVIDIA_only
export DISABLE_LSFG=1
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

exec "$@"
