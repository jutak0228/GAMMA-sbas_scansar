#!/bin/bash

# Part 3: Coregister data

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

if [ -e rslc_prep ];then rm -r rslc_prep; fi
mkdir rslc_prep
cd rslc_prep

# copy burst slc to new folder
cp ../input_prep/dates .
cp ../input_prep/*.vv.slc.iw? .
cp ../input_prep/*.vv.slc.iw?.par .
cp ../input_prep/*.vv.slc.iw?.tops_par .

while read line
do
#	date_time=`echo $slc | awk -F"." '{print $1}'`
	mv ${line}.vv.slc.iw? ${line}_vv.slc
	mv ${line}.vv.slc.iw?.par ${line}_vv.slc.par
	mv ${line}.vv.slc.iw?.tops_par ${line}_vv.slc.tops_par
done < dates
#run_all.pl dates 'cp ../input_prep/$1.vv.slc.iw2 ./$1_vv.slc'
#run_all.pl dates 'cp ../input_prep/$1.vv.slc.iw2.par ./$1_vv.slc.par'
#run_all.pl dates 'cp ../input_prep/$1.vv.slc.iw2.tops_par ./$1_vv.slc.tops_par'

# prepare SLC_tab files
run_all.pl dates 'echo "$1_vv.slc $1_vv.slc.par $1_vv.slc.tops_par" > $1_vv.SLC_tab'

# set 20190809 scene as reference
cp ${ref_date}_vv.slc ${ref_date}_rslc
cp ${ref_date}_vv.slc.par ${ref_date}_rslc.par
cp ${ref_date}_vv.slc.tops_par ${ref_date}_rslc.tops_par

# prepare RSLC_tab files
run_all.pl dates 'echo "$1_rslc $1_rslc.par $1_rslc.tops_par" > $1_rslc_tab'

### make dates_coreg_1 and dates_coreg_2 ###

# get row number of reference date in dates file
row_num=`cat dates | wc -l`
ref_num=`grep -e ${ref_date} -n dates | sed -e 's/:.*//g'`
ref_num_bf=`expr $ref_num - 1`
ref_num_af=`expr $ref_num + 1`

# prepare dates for coregistration
# [1] neighbor slaves
rm -f dates_coreg_1
ref_date_bf=`head -n $ref_num_bf dates | tail -n 1`
echo "$ref_date_bf $ref_date $rlks $azlks" > dates_coreg_1
ref_date_af=`head -n $ref_num_af dates | tail -n 1`
echo "$ref_date_af $ref_date $rlks $azlks" >> dates_coreg_1

# [2] all other slaves

rm -f dates_coreg_2
ref_date_bf_col=`head -n $ref_num_bf dates` # dates list before reference date
ref_num_af_num=`expr $row_num - $ref_num` # subtract the number of dates before reference date from total dates 
ref_date_af_col=`tail -n $ref_num_af_num dates` # dates list after reference date

for line in $ref_date_bf_col; do echo $line >> dates_bf; done
for line in $ref_date_af_col; do echo $line >> dates_af; done
sort -r dates_bf >> dates_bfr
sort -r dates_af >> dates_afr

sed -e '1d' dates_af > dates_af1 # delete first row and this column can be the first col
sed -e '$d' dates_af > dates_af2 # delete last row and this column can be the second col
sed -e '1d' dates_bfr > dates_bfr1 # delete first row and this column can be the first col
sed -e '$d' dates_bfr > dates_bfr2 # delete last row and this column can be the second col

awk 1 dates_af1 dates_bfr1 > dates_col1
awk 1 dates_af2 dates_bfr2 > dates_col2
paste dates_col1 dates_col2 > dates_coreg_2tmp

while read line; do echo "$line $ref_date $rlks $azlks" >> dates_coreg_2; done < dates_coreg_2tmp
rm -f dates_af dates_af1 dates_af2 dates_afr dates_bf dates_bfr dates_bfr1 dates_bfr2 dates_col1 dates_col2 dates_coreg_2tmp

### coregistration by using dates_coreg_1 and dates_coreg_2 ###

# coregister neighbor slaves with reference
run_all.pl dates_coreg_1 'ScanSAR_coreg.py $2_rslc_tab $2 $1_vv.SLC_tab $1 $1_rslc_tab ../DEM/$2.hgt $3 $4'

# coregister other slaves with reference, using neighbor slave
run_all.pl dates_coreg_2 'ScanSAR_coreg.py $3_rslc_tab $3 $1_vv.SLC_tab $1 $1_rslc_tab ../DEM/$3.hgt $4 $5 --RSLC3_tab $2_rslc_tab --RSLC3_ID $2'

# remove burst SLCs
#run_all.pl dates 'rm -f $1_vv.slc $1_vv.slc.par $1_vv.slc.tops_par $1_vv.SLC_tab'

cd ../


