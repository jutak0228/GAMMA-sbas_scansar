#!/bin/bash

# Step 8: Update estimation and subtraction of atmospheric component

work_dir="$1"
ref_date="$2"
rg_off="$3"
az_off="$4"

cd ${work_dir}/results
source bef_aft_dates.txt

# To get smoothed time series through the observations we rerun mb for diff/$2_$3.diff2.unw with temporal smoothing (i.e. gamma > 1.0 to have a high price for non-zero curvatures)

if [ -e diff2.DIFF_tab ];then rm -f diff2.DIFF_tab; fi
ls diff/*.diff2.unw > diff2.DIFF_tab

mb diff2.DIFF_tab RMLI_tab itab - itab_ts diff/diff2 0 diff2.sigma_ts2 0 - $rg_off $az_off 15 15 10.0 rmli/${ref_date}.rmli.par
if [ -e TS_tab ];then rm -f TS_tab; fi
ls diff/diff2_???.diff > TS_tab

# visualization with a scaling suited for more stable areas a scaling factor is applied in the plots to convert the phase to a LOS displacement in meter
#before_date=`head -n 1 dates`
#after_date=`tail -n 1 dates`
#vu_disp2d TS_tab RMLI_tab itab_ts diff/${first_date}_${last_date}.diff0.adf3.unw.bmp - -1.8785e-2 -0.025 0.025 displacement date 2 128 &

# visualization with a scaling suited for subsiding area a scaling factor is applied in the plots to convert the phase to a LOS displacement in meter
#vu_disp2d TS_tab RMLI_tab itab_ts diff/${first_date}_${last_date}.diff0.adf3.unw.bmp - -1.8785e-2 -0.25 0.05 displacement date 2 128 &

######

# The deviation of the un-smoothed time series to the smoothed time series contains noise, as well as atmospheric phase (as well as displacement phase from significantly non-uniform motion).

# We estimate and update to the atmospheric phase based on the difference between the smoothed and un-smoothed time series
mb diff2.DIFF_tab RMLI_tab itab - itab_ts diff/diff2.000 0 diff2.sigma_ts2 0 - $rg_off $az_off 15 15  0.0 rmli/${ref_date}.rmli.par
mb diff2.DIFF_tab RMLI_tab itab - itab_ts diff/diff2.010 0 diff2.sigma_ts2 0 - $rg_off $az_off 15 15 10.0 rmli/${ref_date}.rmli.par
ls diff/diff2.000_???.diff > TS_tab.000
ls diff/diff2.010_???.diff > TS_tab.010
paste TS_tab.000 TS_tab.010 > TS_tab
if [ -e TS_fl_tab ];then rm -f TS_fl_tab; fi
while read line; do echo "$line $before_date $after_date" >> TS_fl_tab; done < TS_tab
run_all TS_fl_tab 'sub_phase $1 $2 diff/$3_$4.diff_par $1.1 0 0 0'

range_samples=`cat rmli/${ref_date}.rmli.par   | grep "range_samples"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

if [ -e atm2.list ];then rm -f atm2.list; fi
ls diff/diff2.000_???.diff.1 > atm2.list
ave_image atm2.list $range_samples diff/ave.atm2
#disdt_pwr diff/ave.atm2 ave.rmli $range_samples 1 0 -3.14 3.14 1 rmg.cm 1. .35 24
#disdt_pwr diff/diff2.000_002.diff.1 ave.rmli $range_samples 1 0 -3.14 3.14 1 rmg.cm 1. .35 24

if [ -e atm2_dem.list ];then rm -f atm2_dem.list; fi
while read line; do echo "$line ${range_samples}" >> atm2_dem.list; done < atm2.list
run_all atm2_dem.list 'lin_comb 2 $1 diff/ave.atm2 0.0 1. -1. $1.1 $2 1 0 1 1 1'

# rename the files
if [ -e atm2_dates.list ];then rm -f atm2_dates.list; fi
paste atm2.list dates > atm2_dates.list
run_all atm2_dates.list 'mv $1.1 diff/$2.atm2.tmp'

# apply a spatial filtering (smaller window is used here)
if [ -e dates_dem_ref ];then rm -f dates_dem_ref; fi
while read line; do echo "$line $ref_date" >> dates_dem_ref; done < dates_dem
run_all dates_dem_ref 'fspf diff/$1.atm2.tmp diff/$1.atm2 $2 2 35 1 rmli/$3.rmli.par'
run_all dates_dem 'rasdt_pwr diff/$1.atm2 ave.rmli $2 1 0 1 1 -3.14 3.14 1 rmg.cm diff/$1.atm2.bmp 1. .35 24'
#eog diff/????????.atm2.bmp
#xv -exp -4 diff/????????.atm2.bmp
bash ../mymontage.sh "diff/????????.atm2.bmp"
# --> a minor update of the atmospheric phase

run_all dates_dem 'lin_comb 2 diff/$1.atm1 diff/$1.atm2 0.0 1.0 1.0 diff/$1.atm $2 1 0 1 1 1'

# remove some files:
/bin/rm diff/diff2.010_???.diff diff/diff2.000_???.diff

######

# subtract diff/????????.atm from diff/$2_$3.diff1.unw1
run_all bperp_file 'sub_phase diff/$2_$3.diff1.unw1 diff/$3.atm diff/$2_$3.diff_par diff/$2_$3.tmp 0 0 0'
run_all bperp_file 'sub_phase diff/$2_$3.tmp        diff/$2.atm diff/$2_$3.diff_par diff/$2_$3.diff2.unw 0 1 0'
/bin/rm diff/2*tmp

