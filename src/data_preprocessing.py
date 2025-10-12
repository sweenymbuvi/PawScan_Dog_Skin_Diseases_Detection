from tensorflow.keras.preprocessing.image import ImageDataGenerator # type: ignore
from collections import Counter
from .config import DATASET_PATH, IMG_SIZE, BATCH_SIZE, SEED

def create_data_generators(dataset_path=DATASET_PATH, img_size=IMG_SIZE, batch_size=BATCH_SIZE):
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=25,
        width_shift_range=0.15,
        height_shift_range=0.15,
        shear_range=0.15,
        zoom_range=0.15,
        horizontal_flip=True,
        brightness_range=[0.85, 1.15],
        channel_shift_range=0.08,
        fill_mode='nearest'
    )


    val_test_datagen = ImageDataGenerator(rescale=1./255)

    train_generator = train_datagen.flow_from_directory(
        dataset_path / "train",
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode='categorical',
        shuffle=True,
        seed=SEED
    )

    val_generator = val_test_datagen.flow_from_directory(
        dataset_path / "valid",
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode='categorical',
        shuffle=False
    )

    test_generator = val_test_datagen.flow_from_directory(
        dataset_path / "test",
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode='categorical',
        shuffle=False
    )

    print("\n✅ Data generators created successfully!")
    print(f"  Training samples: {train_generator.samples}")
    print(f"  Validation samples: {val_generator.samples}")
    print(f"  Test samples: {test_generator.samples}")
    print(f"  Class indices: {train_generator.class_indices}\n")

    return train_generator, val_generator, test_generator


def calculate_class_weights(train_generator):
    class_counts = Counter(train_generator.classes)
    total_samples = len(train_generator.classes)
    num_classes = len(train_generator.class_indices)

    class_weights = {
        class_idx: total_samples / (num_classes * count)
        for class_idx, count in class_counts.items()
    }

    print("Class weights for imbalanced dataset:")
    for class_name, class_idx in train_generator.class_indices.items():
        count = class_counts[class_idx]
        weight = class_weights[class_idx]
        print(f"  {class_name}: {weight:.2f}")

    return class_weights
