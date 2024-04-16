#!/bin/bash

# Step 3: Generation of differential interferograms, filtering and spatial unwrapping

work_dir="$1"
ref_date="$2"
rglks="$3"
azlks="$4"

cd ${work_dir}/results

# Generate the differential interferograms
if [ -d diff ];then rm -r diff; fi
mkdir diff

if [ -f bperp_file_tmp ];then rm bperp_file_tmp; fi
run_all.pl bperp_file 'echo $1 $2 $3 >> bperp_file_tmp'
 
if [ -f bperp_file_rgaz ];then rm bperp_file_rgaz; fi
while read line; do echo "$line $ref_date $rglks $azlks" >> bperp_file_rgaz; done < bperp_file_tmp

run_all bperp_file_rgaz 'create_offset ../rslc/$2.rslc.par ../rslc/$3.rslc.par diff/$2_$3.off 1 $5 $6 0' 
run_all bperp_file_rgaz 'phase_sim_orb ../rslc/$2.rslc.par ../rslc/$3.rslc.par diff/$2_$3.off $4.hgt diff/$2_$3.ph_sim ../rslc/$4.rslc.par'
run_all bperp_file_rgaz 'SLC_diff_intf ../rslc/$2.rslc ../rslc/$3.rslc ../rslc/$2.rslc.par ../rslc/$3.rslc.par diff/$2_$3.off diff/$2_$3.ph_sim diff/$2_$3.diff0 $5 $6 1 1'

range_samples=`cat rmli/${ref_date}.rmli.par   | grep "range_samples"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

if [ -f bperp_file_dem ];then rm bperp_file_dem; fi
while read line; do echo "$line $range_samples" >> bperp_file_dem; done < bperp_file_tmp
run_all bperp_file_dem 'rasmph_pwr diff/$2_$3.diff0 ave.rmli $4 1 0 1 1 rmg.cm diff/$2_$3.diff0.bmp 1. .35 24'

# --> phase includes:
#   - large deformation pattern in the center
#   - some occasional very local deformation patterns
#   - atmospheric phase
#   - sometimes something like an overall linear phase trend (may be orbital phase or atmospheric phase)
#   - maybe height dependent atmospheric phase (difficult to be judged as height differences are limited)

##########

# Filtering

# We apply a spectral filtering of diff0; this filter results in a smoothing of the phase in areas with intermediate to high coherence, but it does not affect much the noisy phase in low coherence areas.
# We iteratively apply it 3 times with a relatively low exponent 0.25
run_all bperp_file_dem 'adf diff/$2_$3.diff0 diff/$2_$3.diff0.adf1 diff/$2_$3.diff0.adf.cc $4 0.25 64 5 4'
run_all bperp_file_dem 'adf diff/$2_$3.diff0.adf1 diff/$2_$3.diff0.adf2 diff/$2_$3.diff0.adf.cc $4 0.25 32 5 2'
run_all bperp_file_dem 'adf diff/$2_$3.diff0.adf2 diff/$2_$3.diff0.adf3 diff/$2_$3.diff0.adf.cc $4 0.25 16 5 1'
/bin/rm diff/*.diff0.adf1 diff/*.diff0.adf2

run_all bperp_file_dem 'rasmph_pwr diff/$2_$3.diff0.adf3 ave.rmli $4 1 0 1 1 rmg.cm diff/$2_$3.diff0.adf3.bmp 1. .35 24'

##########

# Phase unwrapping

# Next we unwrap the filtered differential interferograms spatially.
# For the unwrapping we want to use a fast and robust procedure.
# We achieve this by multi-looking the complex differential interferograms.
# Then we filter and unwrap the multi-looked interferograms.
# The multi-looked unwrapped phase is then expanded to the initial 2x6 look geometry and used as model to unwrap the original complex differential interferogram.

# We do this unwrapping sequence in a small script (available in inputs)

run_all bperp_file '../mcf_sequence_with_multi_cpx diff/$2_$3.diff0.adf3 diff/$2_$3.off diff/$2_$3.diff0.adf3.unw 4 4 0.2'
run_all bperp_file_dem 'rasdt_pwr diff/$2_$3.diff0.adf3.unw ave.rmli $4 1 0 1 1 -6.28 6.28 1 rmg.cm diff/$2_$3.diff0.adf3.unw.bmp'

# --> reasonably well unwrapped

