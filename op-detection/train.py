import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'
import numpy as np
import tensorflow as tf
import sys
import tensorflow_docs as tfdocs # For plotting
import tensorflow_docs.plots
from matplotlib import pyplot as plt
from functools import reduce
from pprint import pprint


traces_fname = sys.argv[1]
labels_fname = sys.argv[2]
model_folder = sys.argv[3]


trace_point_start = None
trace_point_end = None
n_classes = 256

validation_split = 0.3
batch_size = 64


# PREPARE DATA

traces = np.load(traces_fname, mmap_mode='r')
print("traces.shape:", traces.shape)
assert(len(traces.shape) == 2)

#traces = traces[:10000]
traces = traces[:,trace_point_start:trace_point_end]
input_size = traces.shape[-1]

labels = np.load(labels_fname)
print("labels.shape:", labels.shape)

print("Loading traces to memory...")
traces = np.array(traces)

perm = np.random.permutation(len(traces))
traces = traces[perm]
labels = labels[perm]

labels = tf.keras.utils.to_categorical(labels)


def create_mlp_model():
    model = tf.keras.models.Sequential([
        tf.keras.Input(shape=(input_size,)), # Conv1D expects 3D input shape batch_size + (steps, input_dim)
        tf.keras.layers.BatchNormalization(),

        tf.keras.layers.Dense(1024),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.ReLU(),

        tf.keras.layers.Dense(512),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.ReLU(),

        tf.keras.layers.Dense(256),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.ReLU(),
        
        tf.keras.layers.Dense(n_classes, activation='softmax')
    ])

    model.compile(
        #optimizer=tf.keras.optimizers.RMSprop(0.00008), # huanyu
        optimizer=tf.keras.optimizers.Nadam(0.01),
        loss='categorical_crossentropy',
        metrics=[
            'accuracy',
        ]
    )

    return model



model = create_mlp_model()
print(model.summary())

early_stopping_cb = tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=20, verbose=1, mode='max')
save_model_cb = tf.keras.callbacks.ModelCheckpoint(model_folder, verbose=1, save_best_only=True, monitor='val_accuracy')


history = model.fit(
    x=traces,
    y=labels,
    batch_size=batch_size,
    validation_split=validation_split,    
    epochs=5000,
    callbacks=[early_stopping_cb, save_model_cb],
)


# Plot history
plotter = tfdocs.plots.HistoryPlotter()
plotter.plot({'accuracy': history}, 'accuracy')

plt.savefig(model_folder + "_history_plot.svg")

acc_hist = history.history['accuracy']
val_acc_hist = history.history['val_accuracy']
np.save(model_folder + "_history_accuracy.npy", acc_hist)
np.save(model_folder + "_history_val_accuracy.npy", val_acc_hist)
print("Accuracy history: ", acc_hist)
print("Validation accuracy history: ", val_acc_hist)


#plt.show()


