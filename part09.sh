#!/bin/bash

# Step 9: Rerun mb to get quality measure, mask low quality part of result and finalize the result

work_dir="$1"
ref_date="$2"
rg_off="$3"
az_off="$4"

cd ${work_dir}/results

# here a small gamma value is used as we don't want to filter
ls diff/????????_????????.diff2.unw > diff2.DIFF_tab
mb diff2.DIFF_tab RMLI_tab itab - itab_ts diff/diff3 0 diff3.sigma_ts3 0 - $rg_off $az_off 15 15 0.5 rmli/${ref_date}.rmli.par

#disdt_pwr diff3.sigma_ts3 ave.rmli 3000 1 0 0.0 1.5 0 cc.cm 1. .35 24
# as a conservative quality threshold we use diff3.sigma_ts3 > 0.5 radian

range_samples=`cat rmli/${ref_date}.rmli.par   | grep "range_samples"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

replace_values diff3.sigma_ts3 0.5 0.0 diff3.sigma_ts3.masked $range_samples 1 2 0
#dis2dt_pwr diff3.sigma_ts3 diff3.sigma_ts3.masked ave.rmli $range_samples $range_samples 1 0 0 0 0.0 1.5 0 cc.cm 1. .35

# generate rasterfile with 0 values for masked area
rasdt_pwr diff3.sigma_ts3.masked - $range_samples 1 0 1 1 0. 1.5 1 cc.cm diff3.sigma_ts3.masked.bmp 1. .35 8
#eog diff3.sigma_ts3.masked.bmp

# mask the high noise areas in diff3_???.diff
ls diff/diff3_???.diff > TS_tab3
while read line; do echo "$line $range_samples" >> TS_dem_tab3; done < TS_tab3
run_all TS_dem_tab3 'mask_data $1 $2 $1.masked diff3.sigma_ts3.masked.bmp 0'

# --> binary result in MLI slant range geometry:  diff/diff3_???.diff.masked
# rename the files
paste TS_tab3 dates > TS_dates_tab3
run_all TS_dates_tab3 'mv $1.masked diff/$2.disp.phase'

# convert phase to displacement (such that subsidence has a negative sign)
run_all dates_dem_ref 'dispmap diff/$1.disp.phase - rmli/$3.rmli.par - diff/$1.disp 0 0'

# display total los deformation (first to last date in cm), in slant range geometry
#first_date=`head -n 1 dates`
last_date=`tail -n 1 dates`
rasdt_pwr diff/${last_date}.disp ave.rmli $range_samples 1 0 1 1 -0.25 0.25 0 hls.cm diff/${last_date}.disp.250.bmp 1. .35 24
vis_colormap_bar.py hls.cm colors.los_def_250.png -25.0 25.0 -l "los deformation [cm]" -h

# calculate average deformation rate
ls diff/????????.disp > disp.TS_tab
ts_rate disp.TS_tab RMLI_tab itab_ts - los_def_rate los_def_const los_def_sigma 0
rasdt_pwr los_def_rate ave.rmli $range_samples 1 0 1 1 -0.06 0.06 0 hls.cm los_def.060.bmp 1. .35 24
vis_colormap_bar.py hls.cm colors.los_def_060.png -6.0 6.0 -l "los deformation rate [cm/year]" -h

# visualization of time series using vu_disp2d (scaled for subsiding area) in MLI slant range geometry
#vu_disp2d disp.TS_tab RMLI_tab itab_ts los_def.060.bmp - 1. -0.25 0.05 displacement date 3 64 &

