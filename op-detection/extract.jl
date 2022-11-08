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
import Statistics as st
import PyPlot as plt
import ProgressMeter as pm
import Peaks


sig_file = ARGS[1]
trace_file = ARGS[2]
dest_pre = ARGS[3]

trigger_exists = false

if trigger_exists
    trigger_file = ARGS[4]
end


TRIGGER_DOWN_THRESHOLD = -2.0 # FIX THIS
N_SAMPLES_BEFORE_STABLE_TRIGGER = 260

#CORRELATION_THRESHOLDS = [0.6, 0.6] # Baremetal
#CORRELATION_THRESHOLDS = [0.45, 0.45] # OS
CORRELATION_THRESHOLDS = [0.38]

MIN_PEAK_DIFFERENCE = 650 # Largest peak in corr will be selected in a group of peaks with less than this difference in between.


trace = NPZ.npzread(trace_file)
println("trace size: ", size(trace))
    
if trigger_exists
    trigger = NPZ.npzread(trigger_file)
    trigger_end = findfirst(x -> x < TRIGGER_DOWN_THRESHOLD,
                            trigger[N_SAMPLES_BEFORE_STABLE_TRIGGER + 1:end]) + N_SAMPLES_BEFORE_STABLE_TRIGGER
    trace = trace[1:trigger_end]
else
    # TODO: Remove zeros at the end of trace.
end
println("trace size after chopping: ", size(trace))

signatures = permutedims(NPZ.npzread(sig_file))
println("signatures size: ", size(signatures))

#trace = trace[1:300070] # For development


println("Calculating cross correlations for $(size(signatures)[2]) signatures...")
corr = mapslices(sig -> Utils.cross_correlate(trace, sig), signatures, dims=1)

# for (i, c) in enumerate(eachcol(corr))
#     NPZ.npzwrite("$(dest_pre)_peak_correlation_$(i).npy", c)
# end

# plt.figure()
# plt.plot(corr[:,1])
# plt.show()


peak_indices = map(eachcol(corr), CORRELATION_THRESHOLDS) do c, th
    Utils.peak_indices(c, th, MIN_PEAK_DIFFERENCE)
end

peaks = map(peak_indices, eachcol(signatures)) do indices, sig
    res = map(indices) do idx
        x = idx - length(sig) + 1
        y = idx
        T = eltype(trace)
        if y > length(trace)
            vcat(trace[x:end], zeros(T, y - length(trace)))
        elseif x < 1
            vcat(zeros(T, 1 - x), trace[1:y])
        else
            trace[x:y]
        end
    end
    hcat(res...)
end

println("Number of extracted peaks: ", map(x -> size(x)[2], peaks))

for (i, pks) in enumerate(peaks)
    NPZ.npzwrite("$(dest_pre)_peaks_$(i).npy", permutedims(pks))
end


# for c = eachcol(corr), indices = peak_indices
#     plt.figure()
#     plt.plot(c)
#     plt.vlines(indices, -1, 1, "red")
# end
# plt.show()



