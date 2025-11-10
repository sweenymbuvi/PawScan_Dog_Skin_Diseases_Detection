import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from typing import List
import tensorflow as tf
import numpy as np
from .utils import preprocess_image_bytes

app = FastAPI(title="PawScan ML API")


from pathlib import Path
from src.config import MODEL_SAVE_PATH
MODEL_PATH = os.environ.get("MODEL_PATH", str(Path(MODEL_SAVE_PATH) / "pawscan_final.h5"))
LABELS_PATH = os.environ.get("LABELS_PATH", str(Path(MODEL_SAVE_PATH) / "labels.txt"))

# Load model and labels once at startup
model = tf.keras.models.load_model(MODEL_PATH)
with open(LABELS_PATH, "r") as f:
    LABELS = [l.strip() for l in f.readlines() if l.strip()]

def predict_image_bytes(image_bytes):
    x = preprocess_image_bytes(image_bytes, target_size=(224,224))
    preds = model.predict(x)  # shape (1, num_classes)
    preds = preds[0]  # numpy array
    idx = int(np.argmax(preds))
    return {"disease": LABELS[idx], "confidence": float(preds[idx]), "all": [float(p) for p in preds]}

@app.post("/analyze_files")
async def analyze_files(files: List[UploadFile] = File(...)):
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")

    per_image_predictions = []
    for f in files:
        content = await f.read()
        pred = predict_image_bytes(content)
        per_image_predictions.append(pred)

    # Aggregation: majority vote + avg confidence for winning class
    counts = {}
    for p in per_image_predictions:
        counts[p["disease"]] = counts.get(p["disease"], 0) + 1

    final_disease = max(counts.items(), key=lambda x: (x[1], x[0]))[0]
    confidences = [p["confidence"] for p in per_image_predictions if p["disease"]==final_disease]
    avg_conf = float(sum(confidences)/len(confidences)) if confidences else 0.0

    if avg_conf >= 0.85:
        severity = "severe"
    elif avg_conf >= 0.6:
        severity = "moderate"
    else:
        severity = "mild"

    description = f"Likely {final_disease} detected aggregated over {len(files)} images."
    recommendations = [
        "Keep the area clean",
        "Book a vet appointment",
        "Avoid applying unverified home remedies"
    ]

    return {
        "disease": final_disease,
        "confidence": round(avg_conf * 100, 2),
        "severity": severity,
        "description": description,
        "recommendations": recommendations,
        "per_image_predictions": per_image_predictions
    }
