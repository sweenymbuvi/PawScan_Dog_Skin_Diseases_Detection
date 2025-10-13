import os
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2 # type: ignore
from tensorflow.keras.layers import GlobalAveragePooling2D, BatchNormalization, Dropout, Dense # type: ignore
from tensorflow.keras.optimizers import Adam # type: ignore
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint # type: ignore
from .config import NUM_CLASSES, IMG_SIZE, MODEL_SAVE_PATH

def create_mobilenet_model(num_classes=NUM_CLASSES, img_size=IMG_SIZE):
    """Create MobileNetV2 model with custom classification head"""
    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(img_size, img_size, 3),
        alpha=1.0
    )
    base_model.trainable = False  # freeze backbone initially
    print(f"MobileNetV2 base model layers: {len(base_model.layers)}")

    inputs = tf.keras.Input(shape=(img_size, img_size, 3))
    x = base_model(inputs, training=False)
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dropout(0.2)(x)
    x = Dense(128, activation='relu', name='dense_1')(x)
    x = BatchNormalization()(x)
    x = Dropout(0.15)(x)
    x = Dense(64, activation='relu', name='dense_2')(x)
    x = Dropout(0.1)(x)

    outputs = Dense(num_classes, activation='softmax', name='predictions')(x)

    model = tf.keras.Model(inputs, outputs, name='MobileNetV2_DogSkin')
    return model, base_model



# Compile the model with optimized settings

def get_compiled_model():
    model, base_model = create_mobilenet_model()
    
    model.compile(
        optimizer=Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=[
            'accuracy',
            tf.keras.metrics.TopKCategoricalAccuracy(k=2, name='top_2_accuracy')
        ]
    )
    
    print("✅ Model compiled successfully!")
    return model, base_model


#Create callbacks function

def create_callbacks(model_save_path=MODEL_SAVE_PATH, phase="phase1"):
    """Create training callbacks optimized for MobileNet"""
    callbacks = [
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
            os.path.join(model_save_path, f'best_mobilenet_{phase}.h5'),
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]
    return callbacks


# Instantiate callbacks for Phase 1 training
callbacks = create_callbacks(MODEL_SAVE_PATH, "phase1")
print(f"✅ Callbacks created! (Model will be saved to: {MODEL_SAVE_PATH})")
