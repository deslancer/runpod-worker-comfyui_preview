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

# Start the first command in the background and capture its PID
python main.py --port 3000 > /workspace/logs/comfyui.log 2>&1 &
pid1=$!

# Start the second command in the background and capture its PID
python custom_nodes/ComfyUI-Manager/cm-cli.py fix all &
pid2=$!

# Wait for both background jobs to finish before proceeding
wait $pid1
wait $pid2

# Now run the third command after both background jobs are done
python custom_nodes/ComfyUI-Manager/cm-cli.py show installed

deactivate

echo "Starting RunPod Handler"
python3 -u /rp_handler.py
