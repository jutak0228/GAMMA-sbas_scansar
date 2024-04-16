#!/bin/bash

# Part 1: S1 IWS SLC Data extraction

work_dir="$1"
ref_date="$2"

# for now, we use the following date as reference: 
# ex) >>> 20190809 (temporally more or less in the centere of the considered period)

if [ -e input_prep ];then rm -r input_prep; fi
mkdir input_prep
cd input_prep

ref_zip=`ls ${work_dir}/input_files_orig | grep "${ref_date}"`
S1_extract_png ${work_dir}/input_files_orig/${ref_zip}

# ex) --> IW2, bursts 1-6
S1_BURST_tab_from_zipfile.py 1 --zip_ref ${work_dir}/input_files_orig/${ref_zip}
ref_header=`echo ${ref_zip} | sed 's/\.[^\.]*$//'`
cp ${ref_header}.burst_number_table ${ref_date}.burst_number_table

echo "please edit your reference busrt file as below...
zipfile:              S1A_IW_SLC__1SDV_20190809T053522_20190809T053549_028488_033855_23C3.zip
iw2_number_of_bursts: 6
iw2_first_burst:      796.808209
iw2_last_burst:       801.808209"

nedit ${ref_date}.burst_number_table &

#vi ${ref_date}.burst_number_table

cd ../
