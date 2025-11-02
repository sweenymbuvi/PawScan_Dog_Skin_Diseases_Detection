
from pathlib import Path

# Project Paths
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATASET_PATH = PROJECT_ROOT / "data" / "dataset"
MODEL_SAVE_PATH = PROJECT_ROOT / "models"
MODEL_SAVE_PATH.mkdir(parents=True, exist_ok=True)

# TensorBoard logs folder
TENSORBOARD_LOG_DIR = PROJECT_ROOT / "logs"
TENSORBOARD_LOG_DIR.mkdir(parents=True, exist_ok=True)

# Training Configuration 
IMG_SIZE = 224
BATCH_SIZE = 16
NUM_CLASSES = 6  
SEED = 42

# Training Hyperparameters
INITIAL_LR = 0.001
PATIENCE_EARLY_STOP = 12
PATIENCE_REDUCE_LR = 4
MIN_LR = 1e-7

print(f"✅ Config loaded successfully from: {__file__}")
print(f"  PROJECT_ROOT: {PROJECT_ROOT}")
print(f"  DATASET_PATH: {DATASET_PATH}")
print(f"  MODEL_SAVE_PATH: {MODEL_SAVE_PATH}")
