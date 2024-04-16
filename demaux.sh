#!/bin/bash

###################################################
### create support files from dem data
# (layover and shadow, incidence angle, local resolution, offnadir angle)
# unit of look vector is radian:
# lv_theta  (output) SAR look vector "elevation angle" at each map pixel
#              lv_theta: PI/2 -> up  -PI/2 -> down
# lv_phi    (output) SAR look vector orientation angle at each map pixel
#              lv_phi: 0 -> East  PI/2 -> North

work_dir="$1"
ref_date="$2"
dem_dir="$3"
dem_name="$4"

cd ${work_dir}/results

if [ -e demaux ];then rm -r demaux; fi
mkdir demaux
cd demaux

# ls_map,local incidence
gc_map2 ../rmli/${ref_date}.rmli.par ${dem_dir}/${dem_name}.dem_par ${dem_dir}/${dem_name}.dem - - - 1 1 ls_map - inc
data2geotiff ${dem_dir}/${dem_name}.dem_par ls_map 5 ls_map.tif 0
rm -rf ls_map
# convert degree
python ${work_dir}/rad2deg.py inc inc_deg
data2geotiff ${dem_dir}/${dem_name}.dem_par inc_deg 1 local_inc.tif 0
rm -rf inc inc_deg

# slope
dem_gradient ${dem_dir}/${dem_name}.dem_par ${dem_dir}/${dem_name}.dem theta phi mag 1
python ${work_dir}/deg_calc.py theta slope_grad
python ${work_dir}/rad2deg.py phi slope_ori
data2geotiff ${dem_dir}/${dem_name}.dem_par slope_grad 1 slope_grad.tif 0
data2geotiff ${dem_dir}/${dem_name}.dem_par slope_ori 1 slope_ori.tif 0
rm -rf slope_grad slope_ori theta phi mag

# look vector
look_vector ../rmli/${ref_date}.rmli.par - ${dem_dir}/${dem_name}.dem_par ${dem_dir}/${dem_name}.dem lv_theta lv_phi
data2geotiff ${dem_dir}/${dem_name}.dem_par lv_theta 2 lv_theta.tif 0
data2geotiff ${dem_dir}/${dem_name}.dem_par lv_phi 2 lv_phi.tif 0
rm -rf lv_theta lv_phi




