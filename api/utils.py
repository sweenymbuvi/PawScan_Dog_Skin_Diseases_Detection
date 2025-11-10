from PIL import Image
import io
import numpy as np

def preprocess_image_bytes(image_bytes, target_size=(224,224)):
    """Return a numpy array shaped (1, H, W, C) normalized 0-1."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize(target_size)
    arr = np.asarray(img).astype("float32") / 255.0
    arr = np.expand_dims(arr, axis=0)
    return arr
