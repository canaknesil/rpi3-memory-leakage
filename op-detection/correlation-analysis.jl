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
import .Utils: hamming_weight as hw
using NPZ
import PyPlot as plt
import Statistics as s


traces_fname = ARGS[1]
labels_fname = ARGS[2]


traces = npzread(traces_fname)
labels = npzread(labels_fname)
println("size(traces): $(size(traces))")
println("size(labels): $(size(labels))")


function diff_analysis(f1, f2, name)
    tr1 = traces[f1.(labels), :]
    tr2 = traces[f2.(labels), :]
    tt = Utils.ttest(tr1, tr2)
    s1 = size(tr1, 1)
    s2 = size(tr2, 1)
    println("T-test for $name: max $(maximum(tt)), min $(minimum(tt)), group sizes ($s1, $s2)")
    
    tt, s1, s2
end


trace_av = s.mean(traces, dims=1)'
trace_std = s.std(traces, dims=1)'

fig, axs = plt.subplots(3, 1)

axs[1].plot(trace_av)
axs[1].plot(trace_std)
axs[1].legend(["Average trace", "Standard deviation"])
axs[1].set_title("Average trace")

name = "'HW < 4' vs. 'HW > 4'"
tt, s1, s2 = diff_analysis(c -> hw(c) < 4,
                           c -> hw(c) > 4, name)
axs[2].set_title("$name ($s1, $s2)")
axs[2].plot(tt)


for i = 0:6
    for j = i+1:7
        val1 = 1 << i
        val2 = 1 << j
        local name = "'$val1' vs. '$val2'"
        tt, s1, s2 = diff_analysis(c -> c == val1,
                                   c -> c == val2, name)
        axs[3].plot(tt, label="$name ($s1, $s2)")
    end
end
axs[3].set_title("HW 1 with different values")
#axs[3].legend()


plt.show()
