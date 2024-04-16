#!/bin/bash

##########################################################################
# [flags] 
##########################################################################
# preprocessing
# satellite(i.e. Sentinel-1) *.zip data, /OPOD/*.EOF files, and "*.tif" dem data into "input_files_orig" dir. 
prep_01a="off" 		 # [1-a] iws slc data extraction bf edit
prep_01b="off"		 # [1-b] iws slc data extraction af edit
prep_02="off"			 # [2] Prepare DEM and geocode reference
prep_03="off"		 	 # [3] coregister data
prep_04="off"			 # [4] Deramp the data, oversample the data in range direction, and remove margin
# sbas processing
part_01="off" 		 # [1] Generation of MLI images and geocoding
part_02="off"			 # [2] Selection of pairs for the multi-reference stack
part_03="off"		 	 # [3] Generation of differential interferograms, filtering and spatial unwrapping
# please check diff/*.diff0.adf3.bmp
part_04="off"			 # [4] Definition of a mask for the subsidence area
part_05="off"			 # [5] Estimation of linear phase ramps
part_06="off"			 # [6] Checking of phase unwrapping consistency using mb with gamma = 0 
part_07="off"			 # [7] Estimation and subtraction of very long-range atmospheric component
part_08="off"			 # [8] Update estimation and subtraction of atmospheric component
part_09="off"			 # [9] Rerun mb to get quality measure, mask low quality part of result and finalize the result 
part_10="off"			 # [10] Geocoding and visualization of the result
dem_aux="off"			 # [option] dem support file export (ls_map, incidence angle, local resolution, offnadir angle)

####################################################################################
# setting parameters
####################################################################################
work_dir="/home/jutak/data/tokyo_test/sbas_scansar"
rslc_dir="${work_dir}/rslc"
ref_date="20210209" # (temporally more or less in the centere of the considered period)
rglks_deramp="5"
azlks_deramp="1"
dem_dir="${work_dir}/DEM"
dem_name="tokyo"
rglks="13"
azlks="2"
thres_bperp="-" # threshold bperp ("[bperp_max]")
thres_days="-" # threshold days ("[delta_T_max]")
thres_nmax="3" # threshold nmax ("[delta_nmax]")
rg_off="1633"
az_off="1267"

####################################################################################
# ps-dsinsar process
####################################################################################
# preprocessing
if [ "${prep_01a}" = "on" ];then bash prep01a.sh ${work_dir} ${ref_date}; fi
if [ "${prep_01b}" = "on" ];then bash prep01b.sh ${work_dir} ${ref_date} ${rglks_deramp} ${azlks_deramp}; fi
if [ "${prep_02}" = "on" ];then bash prep02.sh ${work_dir} ${ref_date} ${rglks_deramp} ${azlks_deramp} ${dem_name}; fi
if [ "${prep_03}" = "on" ];then bash prep03.sh ${work_dir} ${ref_date} ${rglks_deramp} ${azlks_deramp}; fi
if [ "${prep_04}" = "on" ];then bash prep04.sh ${work_dir} ${ref_date} ${rglks_deramp} ${azlks_deramp}; fi
# sbas processing
if [ "${part_01}" = "on" ];then bash part01.sh ${work_dir} ${rslc_dir} ${ref_date} ${rglks} ${azlks} ${dem_dir} ${dem_name}; fi
if [ "${part_02}" = "on" ];then bash part02.sh ${work_dir} ${ref_date} ${thres_bperp} ${thres_days} ${thres_nmax}; fi
if [ "${part_03}" = "on" ];then bash part03.sh ${work_dir} ${ref_date} ${rglks} ${azlks}; fi
if [ "${part_04}" = "on" ];then bash part04.sh ${work_dir} ${ref_date}; fi
if [ "${part_05}" = "on" ];then bash part05.sh ${work_dir} ${ref_date} ${rg_off} ${az_off}; fi
if [ "${part_06}" = "on" ];then bash part06.sh ${work_dir} ${ref_date} ${rg_off} ${az_off}; fi
if [ "${part_07}" = "on" ];then bash part07.sh ${work_dir} ${ref_date}; fi
if [ "${part_08}" = "on" ];then bash part08.sh ${work_dir} ${ref_date} ${rg_off} ${az_off}; fi
if [ "${part_09}" = "on" ];then bash part09.sh ${work_dir} ${ref_date} ${rg_off} ${az_off}; fi
if [ "${part_10}" = "on" ];then bash part10.sh ${work_dir} ${ref_date} ${dem_dir} ${dem_name}; fi
if [ "${dem_aux}" = "on" ];then bash demaux.sh ${work_dir} ${ref_date} ${dem_dir} ${dem_name}; fi



