import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'
import numpy as np
import tensorflow as tf
import sys
from matplotlib import pyplot as plt


traces_fname = sys.argv[1]
labels_fname = sys.argv[2]
model_file = sys.argv[3]


def reshape_traces_acc_to_model(traces, model):
    if len(traces.shape) == 2 and len(model.input_shape) == 3:
        traces = traces.reshape((*traces.shape, 1))
    if len(traces.shape) == 3 and len(model.input_shape) == 2:
        traces = traces.reshape(traces.shape[:2])
    return traces


def get_n_classes(model):
    return model.output_shape[-1]


def analysis(traces, labels, model):
    n_classes = get_n_classes(model)
        
    scores = model.predict(traces)
    predictions = np.argmax(scores, 1)
    
    accuracy = np.count_nonzero(predictions == labels) / len(predictions)
    print("Score analysis accuracy:", accuracy)
    
    confusion_matrix = tf.math.confusion_matrix(labels, predictions)
    print("Confusion matrix (rows: real labels, cols: predictions)")
    print(confusion_matrix)
    plt.figure()
    plt.imshow(confusion_matrix)


traces = np.load(traces_fname)
labels = np.load(labels_fname)
print("traces.shape:", traces.shape)
print("labels.shape:", labels.shape)

model = tf.keras.models.load_model(model_file)
model.summary()

traces = reshape_traces_acc_to_model(traces, model)    

analysis(traces, labels, model)
plt.show()

