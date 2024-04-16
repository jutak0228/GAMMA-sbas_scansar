#!/bin/bash

# Part 4: Deramp the data, oversample the data in range direction, and crop the area of interest

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

if [ -e rslc ];then rm -r rslc; fi

cd rslc_prep

mkdir ../rslc
cp dates ../rslc/dates

# deramp all scenes based on the reference scene, this is required for the point selection using "mk_sp_all" / "sp_stat"
# Notice that S1_deramp_TOPS_slave checks if the deramping phase ramp for the reference already exists;
# if not the reference it is generated.
# S1_deramp_TOPS_slave also generates the mosaic SLC
while read line; do echo "$line $ref_date $rlks $azlks" >> dates_rev; done < dates
run_all.pl dates_rev 'S1_deramp_TOPS_slave $1_rslc_tab $1 $2_rslc_tab $3 $4 1'
rm -f dates_rev

# oversample by factor 2 in range
run_all.pl dates 'SLC_ovr $1.rslc.deramp $1.rslc.deramp.par $1.rslc.deramp.ovr $1.rslc.deramp.ovr.par 2.0 1.0 1 9'

# remove margin (15 pix of MLI) and copy data

range_samples=`cat ${ref_date}.rmli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
azimuth_lines=`cat ${ref_date}.rmli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`

rg_off=$((15*rlks))
ss_width=$(((range_samples-30)*rlks*2)) # because of the factor 2.0 is from oversamled value in range
az_off=$((15*azlks))
ss_height=$(((azimuth_lines-30)*azlks*1)) # because of the factor 1.0 is from oversampled value in azimuth

echo 'margin_params="'`echo ${rg_off} ${ss_width} ${az_off} ${ss_height}`'"' >> margin_param.txt
source margin_param.txt

while read line; do echo "$line $margin_params" >> dates_margin; done < dates
run_all.pl dates_margin 'SLC_copy $1.rslc.deramp.ovr $1.rslc.deramp.ovr.par ../rslc/$1.rslc ../rslc/$1.rslc.par - - $2 $3 $4 $5'
rm -f dates_margin

# remove intermediate data
#run_all.pl dates 'rm -f $1.slc $1.slc.par $1.rslc $1.rslc.par $1_rslc $1_rslc.par $1_rslc.tops_par $1_rslc_tab'
rm -f *.lt *.sim_unw *.rslc.deramp *.rslc.deramp.par *.rslc.deramp.ovr *.rslc.deramp.ovr.par

