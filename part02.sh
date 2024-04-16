#!/bin/bash

# Step 2: Selection of pairs for the multi-reference stack

work_dir="$1"
ref_date="$2"
thres_bperp="$3"
thres_days="$4"
thres_nmax="$5"

cd ${work_dir}/results

# Generate SLC_tab
if [ -e SLC_tab ];then /bin/rm SLC_tab; fi
run_all dates 'echo ../rslc/$1.rslc ../rslc/$1.rslc.par >> SLC_tab'

# check baselines relative to the first scene
if [ -e bperp_single_reference ];then /bin/rm bperp_single_reference itab; fi
first_date=`head -n 1 dates`
base_calc SLC_tab ../rslc/${first_date}.rslc.par bperp_single_reference itab 0 1

if [ -e bperp_file ];then /bin/rm bperp_file; fi
base_calc SLC_tab ../rslc/${ref_date}.rslc.par bperp_file itab 1 1 - $thres_bperp - $thres_days $thres_nmax

echo "Please adjust and change thres_days if poorly connected"
echo "--> add connections to these groups with longer baselines using a longer maximum baseline"
