# Copyright (c) 2022 Can Aknesil

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

include("Utils.jl")
import NPZ
import Clustering as cl
import Statistics as st
import PyPlot as plt
import ProgressMeter as pm


# TODO: Remove leading zeros from traces when not using trigger.


sig_file = ARGS[1]

trigger_exists = false

if trigger_exists
    trace_folders = ARGS[2:end]
    trigger_files = map(f -> f * "/C3block00001.npy", trace_folders)
    trace_files   = map(f -> f * "/C4block00001.npy", trace_folders)
else
    trace_files = ARGS[2:end]
end

println("$(length(trace_files)) trace files")


# Parameters dependent to capturing configuration
TRIGGER_DOWN_THRESHOLD = -2.0 # FIX THIS
N_SAMPLES_BEFORE_STABLE_TRIGGER = 260
#PEAK_THRESHOLD = 0.14
PEAK_THRESHOLD = 0.18 # 0.14 is not enough for ac_byte-3
MIN_PEAK_DIFFERENCE = 700
PEAK_SIZE = 695 # must be big enough to skip the whole peak
FROM_PEAK_START_TO_PEAK_THRESHOLD = 600
FROM_PEAK_THRESHOLD_TO_PEAK_END = 400
SYNCHRONIZATION_ALLOWANCE = 100

N_CLUSTERS = 1
println("N_CLUSTERS: $N_CLUSTERS")



"Categorization with K-Means. data size: (n features, n sample)"
function categorize(data::Array{T, 2} where T, n_clusters)
    res = cl.kmeans(data, n_clusters)

    labels = cl.assignments(res)
    centers = res.centers
    counts = cl.counts(res)

    println("Cluster counts: ", counts)

    magnitude(v) = sqrt(sum(v .^ 2))
    println("Center magnitudes: ", mapslices(magnitude, centers, dims=1))

    distance(v1, v2) = sqrt(sum((v1 - v2) .^ 2))
    distances = zeros(typeof(centers[1]), n_clusters, n_clusters)
    for i = 1:(n_clusters-1)
        for j = 2:n_clusters
            distances[i, j] = distance(centers[:,i], centers[:,j])
        end
    end
    println("Center distances: ")
    display(distances); println()

    labels
end


"Synchronize x2 by taking x1 as reference."
function synchronize(x1::Array{T, 1}, x2::Array{T, 1}) where T
    corr = Utils.cross_correlate(x1, x2)

    # expected peak idx when x1 = x2: len(x2)
    # If x2 is located towards to right acc. to x1, max value in corr comes earlier.
    # => Offset is positive.
    # => Beginni1ng of x2 needs to be chopped.

    offset = length(x2) - findmax(corr)[2]
    if offset > 0
        x2 = vcat(x2[offset + 1:end], zeros(T, offset))
    elseif offset < 0
        offset *= -1
        x2 = vcat(zeros(T, offset), x2[1:end-offset])
    end

    x2
end


"data size: (n points, n traces)"
function synchronize(data::Array{T, 2} where T)
    reference_idx = 2
    reference = data[:,reference_idx]
    count = 0
    data = mapslices(data, dims=1) do tr
        tr = synchronize(reference, tr)
        count += 1
        print("\r$(floor(Int, count / size(data)[2] * 100)) % ")
        tr
    end
    println()
    data
end


function get_peaks(trace_file, trigger_file=nothing)
    println(trace_file)
    
    trace = NPZ.npzread(trace_file)
    #trace = trace[1:300070] # For development
    
    if !isnothing(trigger_file)
        trigger = NPZ.npzread(trigger_file)
        trigger_end = findfirst(x -> x < TRIGGER_DOWN_THRESHOLD,
                                trigger[N_SAMPLES_BEFORE_STABLE_TRIGGER + 1:end]) + N_SAMPLES_BEFORE_STABLE_TRIGGER
        trace = trace[1:trigger_end]
    else
        # TODO: Remove zeros at the end of trace for faster execution.
    end

    trace = vcat(zeros(eltype(trace), FROM_PEAK_START_TO_PEAK_THRESHOLD + SYNCHRONIZATION_ALLOWANCE + 1), trace)

    appr_peak_indices = Utils.peak_indices(trace, PEAK_THRESHOLD, MIN_PEAK_DIFFERENCE)
    println("Extracted $(length(appr_peak_indices)) peaks.")
    
    peaks = map(appr_peak_indices) do i
        from = i - FROM_PEAK_START_TO_PEAK_THRESHOLD - SYNCHRONIZATION_ALLOWANCE
        to = i + FROM_PEAK_THRESHOLD_TO_PEAK_END + SYNCHRONIZATION_ALLOWANCE - 1
        trace[from:to]
    end

    #peaks = map(tr -> tr / sum(abs.(tr)), peaks) # Normalize power (kind of)
    peaks = hcat(peaks...)
end


println("Loading traces and extracting peaks...")
if trigger_exists
    peaks = map(get_peaks, trace_files, trigger_files)
else
    peaks = map(get_peaks, trace_files)
end

peaks = hcat(peaks...)

if N_CLUSTERS > 1
    println("Categorizing...")
    labels = categorize(peaks, N_CLUSTERS)
else
    labels = ones(Int, size(peaks, 2))
end

peaks_per_class = map(1:N_CLUSTERS) do c
    peaks[:,findall(x -> x == c, labels)]
end
peaks = nothing

println("Synchronizing...")
peaks_per_class = map(synchronize, peaks_per_class)

signatures = map(peaks_per_class) do peaks
    sig = st.mean(peaks, dims=2)
    sig = sig[1 + SYNCHRONIZATION_ALLOWANCE:end - SYNCHRONIZATION_ALLOWANCE]
end

signatures_npy = permutedims(hcat(signatures...))
println("size(signatures_npy): $(size(signatures_npy))")
NPZ.npzwrite(sig_file, signatures_npy)

for s in signatures
    plt.figure()
    plt.plot(s)
end

plt.show()
println("Done.")


