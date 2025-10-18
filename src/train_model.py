import os
import numpy as np
import datetime
import matplotlib.pyplot as plt
import tensorflow as tf
from tensorflow.keras.optimizers import Adam # type: ignore
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint, TensorBoard # type: ignore

# Import from src
from src.data_preprocessing import create_data_generators, calculate_class_weights
from src.model_architecture import create_mobilenet_model
from src.config import MODEL_SAVE_PATH, TENSORBOARD_LOG_DIR


# DATA PREPARATION

train_gen, val_gen, test_gen = create_data_generators()
class_weights = calculate_class_weights(train_gen)


# MODEL CREATION

model, base_model = create_mobilenet_model()

#  PHASE 1: Train with frozen MobileNetV2 base model

print("=" * 60)
print("PHASE 1: Training with frozen MobileNetV2 base model")
print("=" * 60)

initial_learning_rate = 0.001
model.compile(
    optimizer=Adam(learning_rate=initial_learning_rate),
    loss='categorical_crossentropy',
    metrics=[
        'accuracy',
        tf.keras.metrics.TopKCategoricalAccuracy(k=2, name='top_2_accuracy')
    ]
)
print("✅ Model compiled successfully!")

# TensorBoard setup
log_dir = TENSORBOARD_LOG_DIR / datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
tensorboard_callback = TensorBoard(log_dir=log_dir, histogram_freq=1)

# Callbacks for phase 1
callbacks_phase1 = [
    tensorboard_callback,
    EarlyStopping(
        monitor='val_accuracy',
        patience=12,
        restore_best_weights=True,
        verbose=1
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.4,
        patience=4,
        min_lr=1e-7,
        verbose=1
    ),
    ModelCheckpoint(
        os.path.join(MODEL_SAVE_PATH, "best_mobilenet_phase1.h5"),
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )
]

EPOCHS_PHASE1 = 20

# Train model (Phase 1)
history_phase1 = model.fit(
    train_gen,
    epochs=EPOCHS_PHASE1,
    validation_data=val_gen,
    class_weight=class_weights,
    callbacks=callbacks_phase1,
    verbose=1
)

print("✅ Phase 1 training completed!")


#  PHASE 1 RESULTS

def plot_training_history(history, phase_name):
    """Plot training history"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))

    # Accuracy
    ax1.plot(history.history['accuracy'], label='Training Accuracy', linewidth=2)
    ax1.plot(history.history['val_accuracy'], label='Validation Accuracy', linewidth=2)
    ax1.set_title(f'{phase_name} - Model Accuracy')
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Accuracy')
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Loss
    ax2.plot(history.history['loss'], label='Training Loss', linewidth=2)
    ax2.plot(history.history['val_loss'], label='Validation Loss', linewidth=2)
    ax2.set_title(f'{phase_name} - Model Loss')
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Loss')
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()

    # Print best metrics
    best_val_acc = max(history.history['val_accuracy'])
    best_val_loss = min(history.history['val_loss'])
    print(f"🏆 Best validation accuracy: {best_val_acc:.4f}")
    print(f"📉 Best validation loss: {best_val_loss:.4f}")

plot_training_history(history_phase1, "Phase 1 - MobileNetV2")



#  PHASE 2: Fine-Tuning MobileNetV2 


print("=" * 60)
print("PHASE 2: Ultra-Gentle Fine-Tuning of MobileNetV2")
print("=" * 60)

# --- Baseline Performance Reference from Phase 1 ---
phase1_best_val_acc = max(history_phase1.history['val_accuracy'])
phase1_best_epoch = history_phase1.history['val_accuracy'].index(phase1_best_val_acc) + 1

print(f"📊 Baseline from Phase 1:")
print(f"   Best Validation Accuracy: {phase1_best_val_acc:.4f} (Epoch {phase1_best_epoch})")
print(f"   This is our minimum acceptable performance threshold\n")

# Optional confirmation
proceed = input("Proceed with ultra-gentle fine-tuning? (y/n): ").lower()
if proceed != 'y':
    print("\n✅ Skipping Phase 2 — using Phase 1 model as final.")
    import shutil
    shutil.copy(
        os.path.join(MODEL_SAVE_PATH, 'best_mobilenet_phase1.h5'),
        os.path.join(MODEL_SAVE_PATH, 'pawscan_final.h5')
    )
    print("   Saved as: pawscan_final.h5")
else:
    print("\n🔬 Starting ultra-gentle fine-tuning...")

   
    # STEP 1: VERY CONSERVATIVE LAYER UNFREEZING

    base_model.trainable = True
    total_layers = len(base_model.layers)
    unfreeze_percentage = 0.05  # Only 5% of layers
    fine_tune_at = int(total_layers * (1 - unfreeze_percentage))

    print(f"Total MobileNetV2 layers: {total_layers}")
    print(f"Freezing {fine_tune_at} layers ({(fine_tune_at/total_layers)*100:.1f}%)")
    print(f"Unfreezing {total_layers - fine_tune_at} layers ({unfreeze_percentage*100:.1f}%)\n")

    for layer in base_model.layers[:fine_tune_at]:
        layer.trainable = False

    trainable_params = np.sum([np.prod(v.shape) for v in model.trainable_weights])
    non_trainable_params = np.sum([np.prod(v.shape) for v in model.non_trainable_weights])
    total_params = trainable_params + non_trainable_params

    print(f"Trainable parameters: {trainable_params:,} ({(trainable_params/total_params)*100:.2f}%)")
    print(f"Frozen parameters: {non_trainable_params:,} ({(non_trainable_params/total_params)*100:.2f}%)")

  
    # STEP 2: ULTRA-LOW LEARNING RATE
   
    fine_tune_learning_rate = 1e-6  # 10x lower than before
    print(f"\nLearning rate set to {fine_tune_learning_rate} for minimal disruption.\n")

    model.compile(
        optimizer=Adam(learning_rate=fine_tune_learning_rate),
        loss='categorical_crossentropy',
        metrics=[
            'accuracy',
            tf.keras.metrics.TopKCategoricalAccuracy(k=2, name='top_2_accuracy')
        ]
    )

    
    # STEP 3: PROTECTIVE CALLBACKS
  
    callbacks_phase2 = [
        EarlyStopping(
            monitor='val_accuracy',
            patience=12,
            restore_best_weights=True,
            mode='max',
            baseline=phase1_best_val_acc,
            verbose=1
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.7,
            patience=5,
            min_lr=1e-9,
            verbose=1
        ),
        ModelCheckpoint(
            os.path.join(MODEL_SAVE_PATH, 'best_mobilenet_phase2.h5'),
            monitor='val_accuracy',
            save_best_only=True,
            mode='max',
            verbose=1
        )
    ]

    print("🛡️  EarlyStopping baseline set to Phase 1 best accuracy.")
    print("🧠  Gentle ReduceLROnPlateau for gradual adaptation.\n")

   
    # STEP 4: EXTENDED TRAINING CONFIGURATION
    
    EPOCHS_PHASE2 = 20
    TOTAL_EPOCHS = EPOCHS_PHASE1 + EPOCHS_PHASE2

    print(f"Training for {EPOCHS_PHASE2} fine-tuning epochs.")
    print(f"Total epochs including Phase 1: {TOTAL_EPOCHS}")
    print("=" * 60)

    history_phase2 = model.fit(
        train_gen,
        epochs=TOTAL_EPOCHS,
        initial_epoch=history_phase1.epoch[-1] + 1,
        validation_data=val_gen,
        class_weight=class_weights,
        callbacks=callbacks_phase2,
        verbose=1
    )

    print("✅ Phase 2 fine-tuning completed.\n")

   
    # STEP 5: PERFORMANCE COMPARISON
    
    phase2_best_val_acc = max(history_phase2.history['val_accuracy'])
    improvement = (phase2_best_val_acc - phase1_best_val_acc) * 100

    print(f"Phase 1 best val acc: {phase1_best_val_acc:.4f}")
    print(f"Phase 2 best val acc: {phase2_best_val_acc:.4f}")
    print(f"Change: {improvement:+.2f}%")

    if improvement < -0.5:
        print("❌ Phase 2 decreased performance. Reverting to Phase 1 model.")
        use_phase2 = False
    else:
        print("✅ Phase 2 maintained or improved performance.")
        use_phase2 = True

  
    # STEP 6: SELECT FINAL MODEL
 
    import shutil
    if use_phase2:
        final_source = 'best_mobilenet_phase2.h5'
        final_acc = phase2_best_val_acc
    else:
        final_source = 'best_mobilenet_phase1.h5'
        final_acc = phase1_best_val_acc

    shutil.copy(
        os.path.join(MODEL_SAVE_PATH, final_source),
        os.path.join(MODEL_SAVE_PATH, 'pawscan_final.h5')
    )
    print(f"💾 Final model: {final_source}")
    print(f"   Validation Accuracy: {final_acc:.4f}")
    print(f"   Saved as: pawscan_final.h5\n")


# STEP 7: COMBINE HISTORIES AND PLOT

def combine_histories(hist1, hist2):
    combined_history = {}
    for key in hist1.history.keys():
        combined_history[key] = hist1.history[key] + hist2.history[key]
    return combined_history

if 'history_phase2' in locals():
    combined_history_dict = combine_histories(history_phase1, history_phase2)
else:
    combined_history_dict = history_phase1.history

class CombinedHistory:
    def __init__(self, history_dict):
        self.history = history_dict

combined_history = CombinedHistory(combined_history_dict)

def plot_combined_history(combined_history, phase1_epochs):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))
    epochs = range(1, len(combined_history.history['accuracy']) + 1)

    # Accuracy
    ax1.plot(epochs, combined_history.history['accuracy'], 'b-', label='Training Accuracy', linewidth=2)
    ax1.plot(epochs, combined_history.history['val_accuracy'], 'r-', label='Validation Accuracy', linewidth=2)
    ax1.axvline(x=phase1_epochs, color='gray', linestyle='--', alpha=0.7, label='Fine-tuning starts')
    ax1.set_title('Complete Training History - Accuracy')
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Accuracy')
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Loss
    ax2.plot(epochs, combined_history.history['loss'], 'b-', label='Training Loss', linewidth=2)
    ax2.plot(epochs, combined_history.history['val_loss'], 'r-', label='Validation Loss', linewidth=2)
    ax2.axvline(x=phase1_epochs, color='gray', linestyle='--', alpha=0.7, label='Fine-tuning starts')
    ax2.set_title('Complete Training History - Loss')
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Loss')
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()

    print(f"\nFinal training accuracy: {combined_history.history['accuracy'][-1]:.4f}")
    print(f"Final validation accuracy: {combined_history.history['val_accuracy'][-1]:.4f}")
    print(f"Best validation accuracy: {max(combined_history.history['val_accuracy']):.4f}")

plot_combined_history(combined_history, EPOCHS_PHASE1)
print("\n✅ Phase 2 pipeline complete.")
