#!/bin/bash

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd input_prep

# write acquisition dates to text file "dates"

if [ -e dates ];then rm -f dates; fi
if [ -e tmp0 ];then rm -f tmp0; fi

cd ${work_dir}/input_files_orig
for zip_file in `ls -F *.zip`
do
	file_tm=`echo $zip_file | awk -F"T" '{print $1}'`
	fileID=`echo $file_tm | awk -F"_" '{print $1$2$3"_"$6}'`
	date=`echo $fileID | awk -F"_" '{print $2}'`
	echo ${date} >> ${work_dir}/input_prep/tmp_dates
	echo ${ref_date} >> ${work_dir}/input_prep/tmp0
done

cd ${work_dir}/input_prep
sort tmp_dates | uniq >> dates
rm tmp_dates

# create OPOD directory and donwload orbit aux data from ESA website
# sentineleof: Tool to download Sentinel 1 precise/restituted orbit files (.EOF files) for processing SLCs
if [ -e "../input_files_orig/OPOD" ];then rm -r ../input_files_orig/OPOD; fi
mkdir -p "../input_files_orig/OPOD"
run_all.pl dates 'eof -p ../input_files_orig --save-dir ../input_files_orig/OPOD'

#for i in `cat dates | wc -l`; do echo ${ref_date} >> tmp0; done
paste dates tmp0 > dates_tmp0

# import selected bursts from each acquisition
run_all.pl dates 'ls ../input_files_orig/*$1*.zip > $1.zipfile_list'
run_all.pl dates_tmp0 'S1_import_SLC_from_zipfiles $1.zipfile_list $2.burst_number_table vv 0 0 ../input_files_orig/OPOD 1 1'

# generate low-resolution images for checking
rlks_low=$((rlks*4))
azlks_low=$((azlks*4))
while read line; do echo "$line $rlks_low $azlks_low" >> dates_mli; done < dates
run_all.pl dates_mli 'multi_look_ScanSAR $1.vv.SLC_tab $1.vv.mli $1.vv.mli.par $2 $3 1'
rm -f dates_mli

# the MLI data have various range sizes. So we extract
# the samples from the MLI_par and write it as second col into the textfile dates
rm -f tmp1
run_all.pl dates 'get_value $1.vv.mli.par range_samples >> tmp1'
paste dates tmp1 > dates_tmp1

# write BMP for each MLI
run_all.pl dates_tmp1 'raspwr $1.vv.mli $2'
rm -f dates_tmp0 dates_tmp1 tmp1

# plot baselines
make_tab dates SLC_tab '$1.vv.mli $1.vv.mli.par'
base_calc SLC_tab ${ref_date}.vv.mli.par baselines.txt itab 0 1

# -->
# we keep 20190809 as the reference

# remove temporary files
rm -rf tmp_data_dir

cd ../
