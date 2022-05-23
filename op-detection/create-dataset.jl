using NPZ
import Random as r


ds_name = ARGS[1]
traces_fnames = ARGS[2:end]
println("Number of trace files: $(length(traces_fnames))")


n_leading_peaks = 0
array_size = 2048 # Double the array size for single signature for both ldr and str.
n_classes = 256
classes = UInt8(0):UInt8(255)

@assert array_size % n_classes == 0
class_size = div(array_size, n_classes) # Per file

test_split = 0.2


function create_ds(trace_fname)
    traces = npzread(trace_fname)
    println(trace_fname)
    println("size(traces): $(size(traces))")
    @assert ndims(traces) == 2

    n_expected_peaks = array_size + n_leading_peaks
    traces = traces[1 + n_leading_peaks:end, :]

    extra = size(traces, 1) - array_size
    if extra > 0
        traces = traces[1:end - extra, :]
    elseif extra < 0
        extra *= -1
        filling = zeros(eltype(traces), extra, size(traces, 2))
        for i in 1:extra
            filling[i,:] = traces[end,:]
        end
        traces = vcat(traces, filling)
    end
    @assert size(traces, 1) == array_size

    labels = map(c->fill(c, class_size), classes)
    labels = vcat(labels...)

    traces, labels
end
        

traces = []
labels = []
for f in traces_fnames
    tr, lab = create_ds(f)
    push!(traces, tr)
    push!(labels, lab)
end

println("Concatenating...")
traces = vcat(traces...)
labels = vcat(labels...)

#println("Total traces size:", size(traces))
#println("Total labals size:", size(labels))

println("Shuffling...")
perm = r.randperm(size(traces, 1))
traces = traces[perm,:]
labels = labels[perm]

println("Splitting test dataset...")
train_size = floor(Int, size(traces, 1) * (1 - test_split))
test_traces = traces[1 + train_size:end,:]
test_labels = labels[1 + train_size:end]
traces = traces[1:train_size,:]
labels = labels[1:train_size]

#println("Train traces size:", size(traces))
#println("Train labals size:", size(labels))
#println("Test traces size:", size(test_traces))
#println("Test labals size:", size(test_labels))

println("Saving...")
npzwrite("$(ds_name)_train-traces.npy", traces)
npzwrite("$(ds_name)_train-labels.npy", labels)
npzwrite("$(ds_name)_test-traces.npy", test_traces)
npzwrite("$(ds_name)_test-labels.npy", test_labels)


