#!/usr/bin/env bash
# Idempotent setup for the tensorflow-yolo repo.
#
# The project targets Python 2.7 + TensorFlow 1.x (see README and the
# `python2.7` branch). The repo uses Python-2-only modules (ConfigParser,
# Queue) and TF 1.x graph APIs, so we provision an isolated Python 2.7
# environment via Miniconda rather than touching the system interpreter.
set -euo pipefail

MINICONDA_DIR="$HOME/miniconda3"
ENV_NAME="yolo"
ENV_PY="$MINICONDA_DIR/envs/$ENV_NAME/bin/python"
ENV_PIP="$MINICONDA_DIR/envs/$ENV_NAME/bin/pip"

# 1. Install Miniconda if it is not already present.
if [ ! -x "$MINICONDA_DIR/bin/conda" ]; then
  installer="$(mktemp --suffix=.sh)"
  curl -fsSL -o "$installer" \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash "$installer" -b -p "$MINICONDA_DIR"
  rm -f "$installer"
fi
CONDA="$MINICONDA_DIR/bin/conda"

# 2. Create the Python 2.7 environment (conda-forge avoids the Anaconda
#    default-channel Terms-of-Service prompt and still ships python 2.7).
if [ ! -x "$ENV_PY" ]; then
  "$CONDA" create -y -n "$ENV_NAME" -c conda-forge --override-channels python=2.7
fi

# 3. Install pinned dependencies. Versions are chosen because they are the
#    newest releases that still publish CPython 2.7 wheels and are mutually
#    compatible with TensorFlow 1.15. Re-running is a no-op once satisfied.
"$ENV_PIP" install \
  "tensorflow==1.15.0" \
  "grpcio==1.24.3" \
  "h5py==2.10.0" \
  "numpy==1.16.6" \
  "protobuf==3.17.3" \
  "wrapt==1.12.1" \
  "gast==0.2.2" \
  "scipy==1.2.3" \
  "opencv-python-headless==4.1.2.30" \
  --only-binary=grpcio,h5py,numpy,protobuf,scipy,opencv-python-headless

# 4. Auto-activate the env in interactive shells so the README commands
#    (`python demo.py`, `python tools/train.py ...`) resolve to Python 2.7.
if ! grep -q "conda activate $ENV_NAME" "$HOME/.bashrc" 2>/dev/null; then
  "$CONDA" init bash >/dev/null
  echo "conda activate $ENV_NAME" >> "$HOME/.bashrc"
fi

"$ENV_PY" - <<'PY'
import tensorflow as tf, cv2, numpy
print("yolo env ready: tensorflow %s, opencv %s, numpy %s"
      % (tf.__version__, cv2.__version__, numpy.__version__))
PY
