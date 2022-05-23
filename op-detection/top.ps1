
# I run each command one by one manualy.


$src = "/home/canaknesil/Desktop/work/raspberry-sca/op-detection"


julia $src/create-signature.jl signature.npy (l traces | Get-Random -Count 180)

0..1999 |
  foreach {"$_".padleft(5, '0')} |
  foreach {echo $_; julia $src/extract.jl signature.npy "traces/F2block$($_).npy" "traces_processed/$_" }

julia $src/create-dataset.jl ds ./traces_processed/*

julia $src/correlation-analysis.jl ./ds_train-traces.npy ./ds_train-labels.npy

python $src/train.py ./ds_train-traces.npy ./ds_train-labels.npy model

python $src/test.py  ./ds_test-traces.npy ./ds_test-labels.npy model


