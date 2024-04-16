#!/bin/bash

# Part 1: Generation of MLI images and geocoding

work_dir="$1"
rslc_dir="$2"
ref_date="$3"
rglks="$4"
azlks="$5"
dem_dir="$6"
dem_name="$7"

cd ${work_dir}

# create results directory
if [ -d "results" ];then rm -r results; fi
mkdir results
cd ${work_dir}/results

cp ${rslc_dir}/dates .

# generate multi-look intensity images using 2 range and 6 azimuth looks
# run_all allows to execute the command indicated in '   ' for each line of the indicated text file using the first word on the line as $1, the second as $2, etc)

cd ${work_dir}/results
cp ${rslc_dir}/dates .
if [ -e rmli ];then rm -r rmli; fi
mkdir rmli

while read line; do echo "$line $rglks $azlks" >> dates_mli; done < dates
run_all dates_mli 'multi_look ../rslc/$1.rslc ../rslc/$1.rslc.par rmli/$1.rmli rmli/$1.rmli.par $2 $3 - - 0.00001'
rm -f dates_mli

# generate average image (to be used for visualization)
ls rmli/*.rmli > rmli_list
range_samples=`cat rmli/${ref_date}.rmli.par   | grep "range_samples"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`
azimuth_lines=`cat rmli/${ref_date}.rmli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`
echo $range_samples
ave_image rmli_list $range_samples ave.rmli 1 $azimuth_lines 1 1 0 5
ras_dB ave.rmli $range_samples 1 0 1 1 -10. 10. gray.cm ave.rmli.bmp

# The geocoding reference geometry used is 20100210.rmli.par (you can check the scale_factor parameters in the SLC_par files)
grep scale_factor ../rslc/*.rslc.par  # --> are both 1.000 only for 20100210.rslc.par
echo "You can check the scale_factor parameters in the SLC_par"

#disdem_par inputs/DEM/Yibal.dem inputs/DEM/Yibal.dem_par

#cp ${dem_dir}/${dem_name}.dem inputs/
#cp ${dem_dir}/${dem_name}.dem_par inputs/

# generate geocoding lookup table, ls_map, incidence angle map
gc_map2 rmli/${ref_date}.rmli.par ${dem_dir}/${dem_name}.dem_par ${dem_dir}/${dem_name}.dem - - ${dem_name}.lt 1 1 ${dem_name}.ls_map ${dem_name}.ls_map_rdc ${dem_name}.inc - - - - - - - - - 3 8 0 - 1

# check accuracy / determine a refinement of the lookup table
pixel_area rmli/${ref_date}.rmli.par ${dem_dir}/${dem_name}.dem_par ${dem_dir}/${dem_name}.dem ${dem_name}.lt ${dem_name}.ls_map ${dem_name}.inc pix_sigma0 - 20 1.0
create_diff_par rmli/${ref_date}.rmli.par rmli/${ref_date}.rmli.par ${ref_date}.diff_par 1 0
#dis2pwr pix_sigma0 rmli/20100210.rmli 3000 3000
offset_pwr_trackingm pix_sigma0 rmli/${ref_date}.rmli ${ref_date}.diff_par ${ref_date}.offs ${ref_date}.ccp 512 512 - 2 0.1 64 64 - - - -
offset_fitm ${ref_date}.offs ${ref_date}.ccp ${ref_date}.diff_par - - 0.1 1

# refine lookup table
gc_map2 rmli/${ref_date}.rmli.par ${dem_dir}/${dem_name}.dem_par ${dem_dir}/${dem_name}.dem - - ${dem_name}.lt_fine 1 1 ${dem_name}.ls_map ${dem_name}.ls_map_rdc ${dem_name}.inc - - - - - - - - - 3 8 0 ${ref_date}.diff_par 1

# transform average backscatter image to map geometry
width=`cat ${dem_dir}/${dem_name}.dem_par | grep "width" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
nlines=`cat ${dem_dir}/${dem_name}.dem_par | grep "nlines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
geocode_back ave.rmli $range_samples ${dem_name}.lt_fine ${dem_name}.ave.rmli $width $nlines 5 0
vispwr.py ${dem_name}.ave.rmli $width 1 -22. 3.5 -u ${dem_name}.ave.rmli.bmp
#disras Yibal.ave.rmli.bmp

# transform DEM heights to MLI slant range geometry
geocode ${dem_name}.lt_fine ${dem_dir}/${dem_name}.dem $width ${ref_date}.hgt $range_samples $azimuth_lines 0 0
#disdt_pwr ${ref_date}.hgt ave.rmli $range_samples 1 0 10. 150. 1 terrain.cm - - 24

