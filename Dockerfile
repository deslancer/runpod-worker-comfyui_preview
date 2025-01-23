FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /

# Upgrade apt packages and install required dependencies
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
      python3-dev \
      python3-pip \
      fonts-dejavu-core \
      rsync \
      git \
      jq \
      moreutils \
      aria2 \
      wget \
      curl \
      libglib2.0-0 \
      libsm6 \
      libgl1 \
      libxrender1 \
      libxext6 \
      ffmpeg \
      libgoogle-perftools4 \
      libtcmalloc-minimal4 \
      procps \
      python3-opencv \
      build-essential \
      python3-venv && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean -y

# Set Python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Установка PyTorch отдельно
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Установка базовых зависимостей
RUN pip install --no-cache-dir \
    opencv-python-headless \
    pillow \
    transformers \
    safetensors \
    aiohttp \
    numpy
RUN pip install color-matcher
# Установка runpod и accelerate
RUN pip install --no-cache-dir requests runpod && \
    pip install --no-cache-dir git+https://github.com/huggingface/accelerate

# Add RunPod Handler and Docker container start script
COPY start.sh rp_handler.py ./

# Add validation schemas
COPY schemas /schemas

# Add workflows
COPY workflows /workflows

# Ensure proper permissions for mounted volume
RUN mkdir -p /runpod-volume && \
    chmod 777 /runpod-volume

# Start the container
RUN chmod +x /start.sh
ENTRYPOINT /start.sh