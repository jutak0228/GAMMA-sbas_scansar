#!/bin/bash

# Step 5: Estimation of linear phase ramps

work_dir="$1"
ref_date="$2"
rg_off="$3"
az_off="$4"

cd ${work_dir}/results
source bef_aft_dates.txt

## Estimate 2-D quadratic polynomial model phase function from an unwrapped differential interferogram
## and subtract quadratic model phase function from a differential interferogram

#first_date=`head -n 1 dates`
#last_date=`tail -n 1 dates`
if [ -e bperp_file_fl ];then rm bperp_file_fl; fi
while read line; do echo "$line $before_date $after_date" >> bperp_file_fl; done < bperp_file_tmp

run_all bperp_file 'create_diff_par diff/$2_$3.off  diff/$2_$3.off diff/$2_$3.diff_par 0 0'
run_all bperp_file_fl 'quad_fit diff/$2_$3.diff0.adf3.unw diff/$2_$3.diff_par 5 5 diff/$4_$5.diff0.adf3.unw.masked.bmp - 3 diff/$2_$3.atm_linear'
run_all bperp_file 'quad_sub diff/$2_$3.diff0.adf3.unw diff/$2_$3.diff_par diff/$2_$3.diff1.unw 0 0'
run_all bperp_file_dem 'rasdt_pwr diff/$2_$3.diff1.unw ave.rmli $4 1 0 1 1 -6.28 6.28 1 rmg.cm diff/$2_$3.diff1.unw.bmp'

############

# Based on the linear ramps of the pairs, linear ramps for the individual dates can be determined using mb with gamma = 0.0:

# Generate RMLI_tab
/bin/rm RMLI_tab
run_all dates 'echo rmli/$1.rmli rmli/$1.rmli.par >> RMLI_tab'

range_samples=`cat rmli/${ref_date}.rmli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

/bin/rm atm_linear.DIFF_tab atm_linear.sigma_ts itab_ts
ls diff/????????_????????.atm_linear > atm_linear.DIFF_tab
mb atm_linear.DIFF_tab RMLI_tab itab - itab_ts diff/atm_linear0 0 atm_linear.sigma_ts 0 - $rg_off $az_off 15 15 0.0 rmli/${ref_date}.rmli.par
#disdt_pwr atm_linear.sigma_ts ave.rmli $range_samples 1 0 0.0 1.5 0 cc.cm &
# --> the atm_linear.sigma_ts are all very small < 0.01 radian, indicating excellent consistency between the redundant ramp estimations

# --> ramps for individual dates: diff/atm_linear_006.diff
#disdt_pwr diff/atm_linear0_006.diff ave.rmli 3000 1 0 -3.14 3.14 1 rmg.cm &
# --> the values of the first layer are 0.0 and then they correspond to the difference of the ramp of layer i minus the ramp of the first layer

# --> we subtract the temporal average of the ramps to get a ramp estimate for each specific date

/bin/rm atm_linear0.list
ls diff/atm_linear0_???.diff >  atm_linear0.list
ave_image atm_linear0.list $range_samples diff/ave.atm_linear0
#disdt_pwr diff/ave.atm_linear0 ave.rmli $range_samples 1 0 -3.14 3.14 1 rmg.cm &

/bin/rm atm_linear0_dem.list
while read line; do echo "$line $range_samples" >> atm_linear0_dem.list; done < atm_linear0.list

run_all atm_linear0_dem.list 'lin_comb 2 $1 diff/ave.atm_linear0 0.0 1. -1. $1.1 $2 1 0 1 1 1'

# rename these to "date".atm_linear
/bin/rm atm_linear0_dates.list
paste atm_linear0.list dates > atm_linear0_dates.list
run_all atm_linear0_dates.list 'mv $1.1 diff/$2.atm_linear'

# here we remove the ramp estimates for the multi-reference pairs,
# the diff/atm_linear0_???.diff files and diff/ave.atm_linear0

/bin/rm diff/????????_????????.atm_linear
/bin/rm diff/atm_linear0_???.diff
/bin/rm diff/ave.atm_linear0 atm_linear0.list

/bin/rm dates_dem
while read line; do echo "$line $range_samples" >> dates_dem; done < dates

run_all dates_dem 'rasdt_pwr diff/$1.atm_linear ave.rmli $2 1 0 1 1 -3.14 3.14 1 rmg.cm diff/$1.atm_linear.bmp'

