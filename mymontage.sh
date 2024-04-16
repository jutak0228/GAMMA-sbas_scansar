#!/bin/bash
set -ef

file_rule="$1"

if [ `echo ${file_rule} | awk -F"?" '{print $1}'` != ${file_rule} ]; then
	echo "input file rule:"
	echo ${file_rule}
	filename_trunk=`echo "${file_rule}" | awk -F"?" '{print $1}'`
elif [ `echo ${file_rule} | awk -F"*" '{print $1}'` != ${file_rule} ]; then
	echo "input file rule:"
	echo ${file_rule}
	filename_trunk=`echo "${file_rule}" | awk -F"*" '{print $1}'`
else
	echo "Error!!!: include wildcard ? or * in the input characters!!!"
	exit
fi

montage -geometry +2+2 -tile +6 ${file_rule} ${filename_trunk}.all.jpg
echo "output jpg file:"
echo "${filename_trunk}.all.jpg"

