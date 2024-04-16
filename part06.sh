#!/bin/bash

# Step 6: Checking of phase unwrapping consistency using mb with gamma = 0

work_dir="$1"
ref_date="$2"
rg_off="$3"
az_off="$4"

cd ${work_dir}/results

rm -f diff1.DIFF_tab
ls  diff/*.diff1.unw > diff1.DIFF_tab
mb diff1.DIFF_tab RMLI_tab itab - itab_ts diff/diff1 1 diff1.sigma_ts 1 - $rg_off $az_off 15 15 0.0 rmli/${ref_date}.rmli.par
# --> diff1.sigma_ts, diff1_006.diff ..., 20100513_20101229.diff1.unw_sim ...

# Potentially there are a few unwrapping inconsistencies that can be fixed using the simulated phase as model.

if [ -f bperp_file_unw ];then rm bperp_file_unw; fi
while read line; do echo "$line $rg_off $az_off" >> bperp_file_unw; done < bperp_file_dem

run_all bperp_file_unw 'unw_to_cpx diff/$2_$3.diff1.unw diff/$2_$3.diff1.unw.cpx $4'
run_all bperp_file_unw 'unw_model diff/$2_$3.diff1.unw.cpx diff/$2_$3.diff1.unw_sim diff/$2_$3.diff1.unw1 $4 $5 $6'
run_all bperp_file_unw '/bin/rm diff/$2_$3.diff1.unw.cpx diff/$2_$3.diff1.unw_sim'

# Here we rerun mb for diff/$2_$3.diff1.unw1 to check if the sigma values were reduced
ls diff/*.diff1.unw1 > diff1.DIFF_tab
mb diff1.DIFF_tab RMLI_tab itab - itab_ts diff/diff1 1 diff1.sigma_ts1 0 - $rg_off $az_off 15 15 0.0 rmli/${ref_date}.rmli.par

#dis2dt_pwr diff1.sigma_ts diff1.sigma_ts1 ave.rmli 3000 3000 1 0 0 0 0.0 1.5 0 cc.cm
# --> in the more noisy areas the values were reduce, so some improvement was achieved

# --> diff1.sigma_ts1 values are < 0.1 radian for high coherence areas and < 0.5 for most of the area except low coherence areas.
# --> We can use diff1.sigma_ts1 with a threshold of 0.5 to mask the less reliable areas.

# --> We accept diff/diff1_???.diff as time series that includes deformation, atm, height dependent atm, and noise

