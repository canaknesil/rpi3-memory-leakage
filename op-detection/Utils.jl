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

module Utils

import Statistics as st
import ProgressMeter as pm
import Peaks
import HypothesisTests as ht


function cross_correlate(x::AbstractVector{T}, y::AbstractVector{T}; print_progress=false) where T
    @assert length(x) >= length(y)

    result_size = length(x) + length(y) - 1
    x = vcat(zeros(T, length(y) - 1),
             x,
             zeros(T, length(y) - 1))
    result = zeros(T, result_size)

    if print_progress
        prog = pm.Progress(result_size)
    end

    for i = 1:result_size
        a = x[i:i + length(y) - 1]
        result[i] = st.cor(a, y)
        if print_progress
            pm.next!(prog)
        end
    end

    result
end


"""
min_peak_difference: Largest peak in correlation is selected in a group of peaks with less than this difference in between.
"""
function peak_indices(vec::AbstractVector, threshold, min_peak_difference)
    pairs = collect(zip(Peaks.findmaxima(vec)...)) # pair: (idx, value)
    pairs = filter(p -> p[2] > threshold, pairs)

    if isempty(pairs)
        return []
    end

    # Group pairs with close indices
    groups = []
    group = [pairs[1]]
    last_idx = pairs[1][1]
    for pair in pairs[2:end]
        d = pair[1] - last_idx
        last_idx = pair[1]
        if d < min_peak_difference
            push!(group, pair)
        else
            push!(groups, group)
            group = [pair]
        end
    end
    push!(groups, group)
    
    # Keep only biggest peak in each group
    pairs = map(groups) do group
        idx = findmax(p -> p[2], group)[2]
        group[idx]
    end
    
    indices = map(p -> p[1], pairs)
end


ttest(x::AbstractVector, y::AbstractVector) = ht.EqualVarianceTTest(x, y).t

function ttest(x::AbstractMatrix, y::AbstractMatrix, dim=2)
    @assert size(x, dim) == size(y, dim)
    map(ttest, eachslice(x, dims=dim), eachslice(y, dims=dim))
end


function hamming_weight(n::Unsigned)
    hw = 0
    while n != 0
        hw += n % 2
        n >>= 1
    end
    hw
end


end # module
