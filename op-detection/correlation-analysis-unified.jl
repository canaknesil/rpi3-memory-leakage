
# Analysis for all 4 bytes to be presented in a unified way.

include("Utils.jl")
import .Utils: hamming_weight as hw
using NPZ
import PyPlot as plt
import Statistics as s


function diff_analysis(f1, f2, name, traces, labels)
    tr1 = traces[f1.(labels), :]
    tr2 = traces[f2.(labels), :]
    tt = Utils.ttest(tr1, tr2)
    s1 = size(tr1, 1)
    s2 = size(tr2, 1)
    println("T-test for $name: max of abs $(maximum(abs.(tt))), group sizes ($s1, $s2)")
    
    tt, s1, s2
end


function analysis(ds, byte, axs)
    traces_fname = "$(ds)traces.npy"
    labels_fname = "$(ds)labels.npy"

    traces = npzread(traces_fname)
    labels = npzread(labels_fname)
    println("size(traces): $(size(traces))")
    println("size(labels): $(size(labels))")

    if byte == 0
        trace_av = s.mean(traces, dims=1)'
        trace_std = s.std(traces, dims=1)'
        
        axs[1].plot(trace_av)
        axs[1].plot(trace_std)
        axs[1].legend(["Average trace", "Standard deviation"])
    end
    
    tt, s1, s2 = diff_analysis(c -> hw(c) < 4,
                               c -> hw(c) > 4, "byte $byte - 'HW < 4' vs. 'HW > 4'", traces, labels)
    axs[2].plot(tt, label="byte $byte")
    

    max_t_values = []
    for i = 0:6
        for j = i+1:7
            val1 = 1 << i
            val2 = 1 << j
            tt, s1, s2 = diff_analysis(c -> c == val1,
                                       c -> c == val2, "byte $byte - '$val1' vs. '$val2'", traces, labels)
            push!(max_t_values, maximum(abs.(tt)))
            if i == 2 && j == 3
                axs[3].plot(tt, label="byte $byte")
            end
        end
    end
    return max_t_values
end


fig, axs = plt.subplots(3, 1)


#ds = "/mnt/data/sca/raspberry-sca-traces/ac-rand_byte-"
ds = "/mnt/data/sca/raspberry-sca-traces/ac_byte-"

t_vals = map(n -> analysis("$(ds)$(n)/ds_train-", n, axs), 0:3)

t_vals_mean = s.mean(t_vals)
t_vals_std = s.std(t_vals)

println("HW 1 byte mean:")
n = 1
for i = 0:6
    for j = i+1:7
        println("$i vs. $j - $(t_vals_mean[n]) ($(t_vals_std[n]))")
        global n += 1
    end
end

t_vals_flat = vcat(t_vals...)
t_vals_mean_overall = s.mean(t_vals_flat)
t_vals_std_overall = s.std(t_vals_flat)
println("HW 1 all mean - $(t_vals_mean_overall) ($(t_vals_std_overall))")


axs[1].set_title("Average trace for byte 0")
axs[2].set_title("'HW < 4' vs. 'HW > 4'")
axs[2].legend()
axs[3].set_title("Value 4 vs. Value 8")
axs[3].legend()


plt.figure()
plt.boxplot(t_vals, labels=["byte 0", "byte 1", " byte 2", "byte 3"])
plt.ylabel("max. |t-value|")
plt.title("T-test for HW = 1")
plt.ylim(bottom=0)


plt.show()
