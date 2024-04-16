#!/bin/bash

# Step 7: Estimation and subtraction of very long-range atmospheric component (in diff/diff1_???.diff)

work_dir="$1"
ref_date="$2"

cd ${work_dir}/results

# To avoid including deformation phase in it we mask the main (wide area) subsidence area.
# For this we use the spatial interpolation and filtering tools fill_gaps and fspf

# We first mask the deforming area
if [ -e diff1_dem_tab ];then rm -f diff1_dem_tab; fi
ls  diff/diff1_???.diff > diff1_tab
range_samples=`cat rmli/${ref_date}.rmli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`
while read line; do echo "$line ${range_samples} ${ref_date}" >> diff1_dem_tab; done < diff1_tab
run_all diff1_dem_tab 'poly_mask $1 $1.masked $2 poly1 1 0'

# We then interpolate the data and apply the spatial filtering.
run_all diff1_dem_tab 'fill_gaps $1.masked $2 $1.masked.interp 0 4 - 1 100 4 400'
run_all diff1_dem_tab 'rasdt_pwr $1.masked ave.rmli $2 1 0 1 1 -3.14 3.14 1 rmg.cm $1.masked.bmp'
run_all diff1_dem_tab 'rasdt_pwr $1.masked.interp ave.rmli $2 1 0 1 1 -3.14 3.14 1 rmg.cm $1.masked.interp.bmp'
#dis2ras diff/diff1_007.diff.masked.bmp diff/diff1_007.diff.masked.interp.bmp &
#eog diff/diff1_???.diff.masked.bmp &
#eog diff/diff1_???.diff.masked.interp.bmp &

# and apply the spatial filtering.
run_all diff1_dem_tab 'fspf $1.masked.interp $1.atm1 $2 2 250 1 rmli/$3.rmli.par'
run_all diff1_dem_tab 'rasdt_pwr $1.atm1 ave.rmli $2 1 0 1 1 -3.14 3.14 1 rmg.cm $1.atm1.bmp'
#eog diff/diff1_???.diff.atm1.bmp &
#xv -exp -4 diff/diff1_???.diff.atm1.bmp &
bash ../mymontage.sh "diff/diff1_???.diff.atm1.bmp"

# As for the linear trend we prefer to have an estimate per date for this we subtract the temporal average from all layers.

if [ -e atm1.list ];then rm -f atm1.list atm1_dem.list; fi
ls diff/diff1_???.diff.atm1 > atm1.list
ave_image atm1.list $range_samples diff/ave.atm1
while read line; do echo "$line ${range_samples}" >> atm1_dem.list; done < atm1.list
run_all atm1_dem.list 'lin_comb 2 $1 diff/ave.atm1 0.0 1. -1. $1.1 $2 1 0 1 1 1'

# rename the files
paste atm1.list dates > atm1_dates.list
run_all atm1_dates.list 'mv $1.1 diff/$2.atm1'

# remove files no longer used
/bin/rm diff/diff1_???.diff.masked diff/diff1_???.diff.masked.interp
/bin/rm diff/diff1_???.diff.atm1 diff/diff1_???.diff.atm1.bmp
/bin/rm atm1.list atm1_dem.list

run_all dates_dem 'rasdt_pwr diff/$1.atm1 ave.rmli $2 1 0 1 1 -3.14 3.14 1 rmg.cm diff/$1.atm1.bmp'
#eog diff/????????.atm1.bmp

# we subtract this atmospheric phase from the multi-reference differential interferograms
run_all bperp_file 'sub_phase diff/$2_$3.diff1.unw1 diff/$3.atm1 diff/$2_$3.diff_par diff/$2_$3.tmp 0 0 0'
run_all bperp_file 'sub_phase diff/$2_$3.tmp diff/$2.atm1 diff/$2_$3.diff_par diff/$2_$3.diff2.unw 0 1 0'
/bin/rm diff/2*tmp

