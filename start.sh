#!/usr/bin/env bash

echo "Worker Initiated"

echo "Symlinking files from Network Volume"
rm -rf /workspace && \
  ln -s /runpod-volume /workspace

# Активируем виртуальное окружение
source /workspace/venv/bin/activate

# Устанавливаем зависимости для нод если они еще не установлены
if [ -d "/workspace/ComfyUI/custom_nodes/ComfyUI-SUPIR" ]; then
    echo "Installing SUPIR dependencies"
    pip install -r /workspace/ComfyUI/custom_nodes/ComfyUI-SUPIR/requirements.txt
fi

if [ -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Impact-Pack" ]; then
    echo "Installing Impact-Pack dependencies"
    pip install -r /workspace/ComfyUI/custom_nodes/ComfyUI-Impact-Pack/requirements.txt
fi

# Проверяем и устанавливаем права доступа
echo "Setting correct permissions"
chown -R root:root /workspace/ComfyUI/custom_nodes
chmod -R 755 /workspace/ComfyUI/custom_nodes

# Настройка переменных окружения
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
export PYTHONUNBUFFERED=true
export HF_HOME="/workspace"
export PYTHONPATH="${PYTHONPATH}:/workspace/ComfyUI/custom_nodes"

cd /workspace/ComfyUI

# Очистка кэша Python перед запуском
find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true

echo "Starting ComfyUI API"
python main.py --port 3000 > /workspace/logs/comfyui.log 2>&1 &

deactivate

echo "Starting RunPod Handler"
python3 -u /rp_handler.py