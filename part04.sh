#!/bin/bash

# Step 4: Definition of a mask for the subsidence area

work_dir="$1"
ref_date="$2"

cd ${work_dir}/results

# Determine a mask to be used for subsidence area in the center (to assure that the linear trend and the atmospheric phase are estimated outside this area.)

eog bperp_file.png

echo "Please consider before and after id are connected"
echo -n INPUT BEFORE DATE ID:
read before_date_id
echo -n INPUT AFTER DATE ID:
read after_date_id
before_date=`sed -n ${before_date_id}p bperp_single_reference | awk -F" " '{print $3}'` 
after_date=`sed -n ${after_date_id}p bperp_single_reference | awk -F" " '{print $3}'` 

rm -f bef_aft_dates.txt
echo "### before and after date information" >> bef_aft_dates.txt
echo "### before date information" >> bef_aft_dates.txt
echo before_date=${before_date} >> bef_aft_dates.txt
echo before_date_id=${ref_date_id} >> bef_aft_dates.txt
echo "### after date information" >> bef_aft_dates.txt
echo after_date=${after_date} >> bef_aft_dates.txt
echo after_date_id=${after_date_id} >> bef_aft_dates.txt

#first_date=`head -n 1 dates`
#last_date=`tail -n 1 dates`
polyras diff/${before_date}_${after_date}.diff0.adf3.bmp > poly1

# to be fully consistent with the results provided you may prefer to use the poly1 file provide in inputs

#/bin/cp inputs/poly1 .

# apply mask
range_samples=`cat rmli/${ref_date}.rmli.par   | grep "range_samples"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

poly_mask diff/${before_date}_${after_date}.diff0.adf3.unw diff/${before_date}_${after_date}.diff0.adf3.unw.masked $range_samples poly1 1 0
rasdt_pwr diff/${before_date}_${after_date}.diff0.adf3.unw.masked ave.rmli $range_samples 1 0 1 1 -6.28 6.28 1 rmg.cm diff/${before_date}_${after_date}.diff0.adf3.unw.masked.bmp

#eog diff/20070805_20101229.diff0.adf3.unw.masked.bmp

