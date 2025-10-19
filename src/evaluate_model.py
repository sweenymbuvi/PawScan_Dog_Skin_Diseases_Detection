import os
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix
from pathlib import Path

from src.data_preprocessing import create_data_generators
from src.config import MODEL_SAVE_PATH


print("="*60)
print("📊 MOBILENETV2 MODEL EVALUATION ON TEST SET")
print("="*60)


# 1. Load test data generator
train_gen, val_gen, test_gen = create_data_generators()


# 2. Load the best saved model
best_model_path = os.path.join(MODEL_SAVE_PATH, "pawscan_final.h5")
best_model = tf.keras.models.load_model(best_model_path)
print(f"✅ Loaded model from: {best_model_path}")


# 3. Make predictions
print("\n🔍 Making predictions on test set...")
test_gen.reset()
test_predictions = best_model.predict(test_gen, verbose=1)
predicted_classes = np.argmax(test_predictions, axis=1)

# True labels
true_classes = test_gen.classes
class_names = list(test_gen.class_indices.keys())


# 4. Classification report
print("\n📑 Classification Report:")
print(classification_report(true_classes, predicted_classes, target_names=class_names))


# 5. Confusion Matrix
cm = confusion_matrix(true_classes, predicted_classes)

def plot_confusion_matrix(cm, class_names):
    """Plot confusion matrix with better styling"""
    plt.figure(figsize=(10, 8))
    sns.heatmap(
        cm, annot=True, fmt='d', cmap='Blues',
        xticklabels=class_names, yticklabels=class_names,
        cbar_kws={'label': 'Count'}
    )
    plt.title('Confusion Matrix - MobileNetV2 Dog Skin Disease Classification', fontsize=14, pad=20)
    plt.ylabel('True Label', fontsize=12)
    plt.xlabel('Predicted Label', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    plt.tight_layout()
    plt.show()

plot_confusion_matrix(cm, class_names)


# 6. Per-class Performance Analysis
def analyze_per_class_performance(cm, class_names):
    """Analyze per-class performance"""
    print("\n📈 Per-class Performance Analysis:")
    print("-" * 60)

    overall_accuracy = np.trace(cm) / np.sum(cm)
    print(f"Overall Accuracy: {overall_accuracy:.3f}")
    print("-" * 60)

    for i, class_name in enumerate(class_names):
        tp = cm[i, i]
        fp = np.sum(cm[:, i]) - tp
        fn = np.sum(cm[i, :]) - tp
        tn = np.sum(cm) - tp - fp - fn

        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

        print(f"{class_name}:")
        print(f"  Precision: {precision:.3f}")
        print(f"  Recall: {recall:.3f}")
        print(f"  F1-Score: {f1:.3f}")
        print(f"  Support: {np.sum(cm[i, :])}")
        print()

analyze_per_class_performance(cm, class_names)
