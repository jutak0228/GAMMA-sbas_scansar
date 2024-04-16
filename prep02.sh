#!/bin/bash

# Part 2: Prepare DEM and geocode reference

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
dem_name="$5"

cd input_prep

# multilook reference
multi_look_ScanSAR ${ref_date}.vv.SLC_tab ${ref_date}_${rlks}_${azlks}.vv.mli ${ref_date}_${rlks}_${azlks}.vv.mli.par ${rlks} ${azlks} 1
# estimate corber latitude and longitude
if [ -e SLC_corners.txt ]; then rm -f SLC_corners.txt; fi
SLC_corners ${ref_date}_${rlks}_${azlks}.vv.mli.par > SLC_corners.txt
# setting variable for clipping dem data
# -->
# lower left  corner longitude, latitude (deg.): 139.06  35.15
# upper right corner longitude, latitude (deg.): 140.29  36.06

lowleft_lat=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $8}' | tr -d [:space:]`
lowleft_lon=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $7}' | tr -d [:space:]`
uppright_lat=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $8}' | tr -d [:space:]`
uppright_lon=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $7}' | tr -d [:space:]`

# download filled SRTM1 using elevation module
eio clip -o ../input_files_orig/SRTM1_elevation.tif --bounds $lowleft_lon $lowleft_lat $uppright_lon $uppright_lat
# eio --product SRTM1 clip -o ../input_files_orig/SRTM1_elevation.tif --bounds 7.64 45.68 9.24 46.92

if [ -e ../DEM ];then rm -r ../DEM; fi
mkdir ../DEM
cd ../DEM

/bin/cp ../input_prep/${ref_date}_${rlks}_${azlks}.vv.mli .
/bin/cp ../input_prep/${ref_date}_${rlks}_${azlks}.vv.mli.par .

# convert the GeoTIFF DEM into Gamma Software format, including geoid to ellipsoid height reference conversion
dem_import ../input_files_orig/SRTM1_elevation.tif ${dem_name}.dem ${dem_name}.dem_par 0 1 $DIFF_HOME/scripts/egm96.dem $DIFF_HOME/scripts/egm96.dem_par 0

# visualize DEM as a shaded relief
#disdem_par ${dem_name}.dem ${dem_name}.dem_par

# --> not ideal but OK

# generate look-up table using gc_map2
gc_map2 ${ref_date}_${rlks}_${azlks}.vv.mli.par ${dem_name}.dem_par ${dem_name}.dem ${ref_date}_seg.dem_par ${ref_date}_seg.dem ${ref_date}.lt 2 2 ${ref_date}.ls_map - ${ref_date}.inc

ortho_width=`cat ${ref_date}_seg.dem_par | grep "width" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
ortho_nlines=`cat ${ref_date}_seg.dem_par | grep "nlines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`

# generating "simulated" backscatter image
pixel_area ${ref_date}_${rlks}_${azlks}.vv.mli.par ${ref_date}_seg.dem_par ${ref_date}_seg.dem ${ref_date}.lt ${ref_date}.ls_map ${ref_date}.inc ${ref_date}.sigma0 ${ref_date}.gamma0 20 0.01
#dis2pwr 20190809.gamma0 20190809_5_1.vv.mli 5323 5323

# calculate offset between gamma0 and multilooked image
create_diff_par ${ref_date}_${rlks}_${azlks}.vv.mli.par - ${ref_date}.diff_par 1 0
offset_pwrm ${ref_date}.gamma0 ${ref_date}_${rlks}_${azlks}.vv.mli ${ref_date}.diff_par ${ref_date}.offs ${ref_date}.snr 128 128 - 1 32 32 0.3
offset_fitm ${ref_date}.offs ${ref_date}.snr ${ref_date}.diff_par ${ref_date}.coffs - 0.3 1

# refine geocoding look-up table
gc_map_fine ${ref_date}.lt ${ortho_width} ${ref_date}.diff_par ${ref_date}.lt_fine 1

# calculate updated sigma0 and gamma0 maps
pixel_area ${ref_date}_${rlks}_${azlks}.vv.mli.par ${ref_date}_seg.dem_par ${ref_date}_seg.dem ${ref_date}.lt_fine ${ref_date}.ls_map ${ref_date}.inc ${ref_date}.sigma0 ${ref_date}.gamma0 20 0.01
#dis2pwr 20190809.gamma0 20190809_5_1.vv.mli 5323 5323

range_samples=`cat ${ref_date}_${rlks}_${azlks}.vv.mli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
azimuth_lines=`cat ${ref_date}_${rlks}_${azlks}.vv.mli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
range_pixel_spacing=`cat ${ref_date}_${rlks}_${azlks}.vv.mli.par   | grep "range_pixel_spacing"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

# calculate DEM in radar coordinates
geocode ${ref_date}.lt_fine ${ref_date}_seg.dem ${ortho_width} ${ref_date}.hgt ${range_samples} ${azimuth_lines}

# visualize
#dishgt ${ref_date}.hgt ${ref_date}_${rlks}_${azlks}.vv.mli 5323

# geocode image for visualization
geocode_back ${ref_date}_${rlks}_${azlks}.vv.mli ${range_samples} ${ref_date}.lt_fine ${ref_date}.geo ${ortho_width} ${ortho_nlines} 5 0 - - 3
vispwr.py ${ref_date}.geo ${ortho_width} -u ${ref_date}.geo.png -t
kml_map ${ref_date}.geo.png ${ref_date}_seg.dem_par ${ref_date}.geo.kml

cd ../
