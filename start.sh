#!/usr/bin/env bash

echo "Worker Initiated"

echo "Symlinking files from Network Volume"
rm -rf /workspace && \
  ln -s /runpod-volume /workspace

echo "Starting ComfyUI API"
source /workspace/venv/bin/activate
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
export PYTHONUNBUFFERED=true
export HF_HOME="/workspace"
cd /workspace/ComfyUI
python main.py --port 3000 > /workspace/logs/comfyui.log 2>&1 &
python custom_nodes/ComfyUI-Manager/cm-cli.py fix all &
python custom_nodes/ComfyUI-Manager/cm-cli.py show installed &
deactivate

echo "Starting RunPod Handler"
python3 -u /rp_handler.py
