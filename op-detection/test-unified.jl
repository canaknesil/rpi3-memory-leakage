
# Unified test for all bytes to generate unified plots to be
# presented.

import NNlib # for BSON.@load to work
import Flux
using NPZ
import BSON
import PyPlot as plt


function analysis(folder, byte, ax)
    println("Analysis for byte $byte")
    
    model_file = "$(folder)/model.bson"
    traces_fname = "$(folder)/ds_test-traces.npy"
    labels_fname = "$(folder)/ds_test-labels.npy"
    
    BSON.@load model_file model
    display(model); println()

    traces = npzread(traces_fname)
    labels = npzread(labels_fname)
    println("size(traces): $(size(traces))")
    println("size(labels): $(size(labels))")
    traces = permutedims(traces)
    
    
    scores = model(traces)
    n_classes = size(scores, 1)
    predictions = map(v -> findmax(v)[2] - 1, eachcol(scores))
    
    
    accuracy = sum(predictions .== labels) / length(predictions)
    println("Accuracy byte $byte: $accuracy")


    confusion_matrix = zeros(Int, n_classes, n_classes)
    for (lab, pred) in zip(labels, predictions)
        confusion_matrix[1 + lab, 1 + pred] += 1
    end
    

    history = BSON.load("$(folder)/model_history.bson")
    training_acc_list = history[:training_accuracy_list]
    validation_acc_list = history[:validation_accuracy_list]

    ax.plot(training_acc_list)
    ax.plot(validation_acc_list)
    ax.set_title("Byte $byte")
    ax.set_xlabel("Epoch")
    if byte == 0
        ax.legend(["Training acc.", "Validation acc."])
    end
end


ds = "/mnt/data/sca/raspberry-sca-traces/ac-rand_byte-"

fig, axs = plt.subplots(2, 2)
map(n -> analysis("$(ds)$(n)", n, axs[div(n, 2) + 1, n % 2 + 1]), 0:3)

plt.show()
