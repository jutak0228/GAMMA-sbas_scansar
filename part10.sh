#!/bin/bash

# Step 10: Geocoding and visualization of the result

work_dir="$1"
ref_date="$2"
dem_dir="$3"
dem_name="$4"

cd ${work_dir}/results

if [ -e geo ];then rm -r geo; fi
mkdir geo

#######

# transform binary results to map geometry
range_samples=`cat rmli/${ref_date}.rmli.par   | grep "range_samples"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

# average backscatter
width=`cat ${dem_dir}/${dem_name}.dem_par | grep "width" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
nlines=`cat ${dem_dir}/${dem_name}.dem_par | grep "nlines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
geocode_back ave.rmli $range_samples ${dem_name}.lt_fine geo/${dem_name}.ave.rmli $width $nlines 5 0

# deformation rate
geocode_back los_def_rate $range_samples ${dem_name}.lt_fine geo/${dem_name}.los_def_rate $width $nlines 1 0
/bin/cp colors.los_def_060.png geo

if [ -e dates_geoback ];then rm -f dates_geoback; fi
while read line; do echo "$line $dem_name $width $nlines $range_samples" >> dates_geoback; done < dates

# deformation time series
run_all dates_geoback 'geocode_back diff/$1.disp $5 $2.lt_fine geo/$2.$1.disp $3 $4 1 0'
/bin/cp colors.los_def_250.png geo

# atmospheric phase
run_all dates_geoback 'geocode_back diff/$1.atm $5 $2.lt_fine geo/$2.$1.atm $3 $4 1 0'

# phase standard deviation (quality measure)
geocode_back diff3.sigma_ts3 $range_samples ${dem_name}.lt_fine geo/${dem_name}.diff3.sigma_ts3 $width $nlines 3 0

#######

# generate bmp files
ras_dB geo/${dem_name}.ave.rmli $width 1 0 1 1 -10. 10. gray.cm geo/${dem_name}.ave.rmli.bmp
rasdt_pwr geo/${dem_name}.los_def_rate geo/${dem_name}.ave.rmli $width 1 0 1 1 -0.06 0.06 0 hls.cm geo/${dem_name}.los_def_rate.bmp 1. .35 24
rasdt_pwr geo/${dem_name}.diff3.sigma_ts3 geo/${dem_name}.ave.rmli $width 1 0 1 1 0.0 1.5 0 cc.cm geo/${dem_name}.diff3.sigma_ts3.bmp 1. .35 24

run_all dates_geoback 'rasdt_pwr geo/$2.$1.atm geo/$2.ave.rmli $3 1 0 1 1 -3.14 3.14 1 rmg.cm geo/$2.$1.atm.bmp 1. .35 24'
run_all dates_geoback 'rasdt_pwr geo/$2.$1.disp geo/$2.ave.rmli $3 1 0 1 1 -0.25 0.25 0 hls.cm geo/$2.$1.disp.bmp 1. .35 24'

# generate geotiff files (rasterfiles)
data2geotiff ${dem_dir}/${dem_name}.dem_par geo/${dem_name}.los_def_rate.bmp 0 geo/${dem_name}.los_def_rate.tif
# ...

# generate geotiff files (float values)
data2geotiff ${dem_dir}/${dem_name}.dem_par geo/${dem_name}.los_def_rate 2 geo/${dem_name}.los_def_rate.float.tif
# generate geotiff files (float values) for each disp_date
run_all dates_geoback 'data2geotiff ../DEM/$2.dem_par geo/$2.$1.disp 2 geo/$1.$2.float.tif'

# generate kmz files for visualization in Google Earth
visdt_pwr.py geo/${dem_name}.los_def_rate geo/${dem_name}.ave.rmli $width -0.06 0.06 -m hls.cm -u geo/${dem_name}.los_def_rate.png -t
kml_map geo/${dem_name}.los_def_rate.png ${dem_dir}/${dem_name}.dem_par geo/${dem_name}.los_def_rate.kml
zip geo/${dem_name}.los_def_rate.kmz geo/${dem_name}.los_def_rate.kml geo/${dem_name}.los_def_rate.png
# ...

# generate jpg "quick-looks (with color scale) of the atmospheric phase"
run_all dates_geoback 'visdt_pwr.py geo/$2.$1.atm geo/$2.ave.rmli $3 -c 6.28 -z 800 -d "atmospheric_path_delay_in_radian" -m rmg.cm -b -p geo/$2.$1.atm.jpg'
#eog geo/*atm.jpg

# a few of the results are available in the directory results

