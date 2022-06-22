#!/bin/bash
#################################################################################
#DITESH POOJARI
#sh /home/Ditesh/md5sumDemo.sh "DIRECTORY" "FLAG"				#
#FLAGS:																			#
#i:to create checksum files for the directory									#
#c:to check the integrity using the checksum									#
#IF:overriding the checksum file if already exist								#	
#################################################################################
##set -euox pipefail

trap "" SIGINT
E_DIR_NOMATCH=80
E_BAD_DBFILE=81
tm=`date +%Y-%m-%d`
dbfile=FILE_RECORD_$tm.md5
echo -e "$(basename $0.sh)"
rm -f ls /home/Ditesh/md5logs_`date +%Y-%m-`$(( `date +%d` -3 ))* 2>/dev/null
if [ -e /home/Ditesh/md5logs_$tm.log ]
then
/dev/null>/home/Ditesh/md5logs_$tm.log
fi
init()
{

cd $1
idir=`pwd`
echo -e "\e[4;3;1;32mCREATING CHECKSUM FOR ALL FILES in $idir\e[0m"
echo
if [ ! -r $dbfile ]
then 
echo -e "\e[5;0;1;32mSETTING dbfile, \e[4;3;1;32m$idir/$dbfile.\e[0m"
setup_db $idir
else
echo -e "\e[5;0;1;32m$idir/$dbfile ALREADY EXIST\e[0m"
fi
echo
##check_db $idir

}

setup_db()
{
sdir=$1
echo $dbfile
echo "$sdir" > $dbfile

for a in `ls $sdir`;
do

echo;
if [ ! -d "$a" ] &&  ls $a|egrep -q "*\.(txt|sh|sql|dll|sql)" 
then
	md5sum "$a" >> $dbfile
	echo -e "\e[0;0;0;32mSAVED MD5CHECKSUM FOR $a\e[0m"
elif [ -d  "$a"  -a "$a" != "cygdrive" ]
then 
	echo -e "\e[0;0;0;31m$a IS DIRECTORY\e[0m"
	echo -e "\e[0;0;3;33mENTERING INTO THE DIRECTORY:$a...\e[0m"
	init $a
	pwd=`pwd`
	echo -e "\e[4;3;1;32mDONE FOR FILES in $pwd\e[0m"
	cd ..
elif [ ! -d "$a" ];then
		echo -e "\e[0;0;0;31m$a is not txt/sh/sql/dll/sql\e[0m"
	

fi
##sleep 2
done
chmod 400 $dbfile
}
check_db()
{

cdir=$1
cd $cdir
if [ ! -r $dbfile ]
then
echo -e "\e[5;0;1;31mUNABLE TO READ CHECKSUM DB FILE in $cdir\e[0m"
else
start_check $dbfile
fi
for a in `ls $cdir`;
do 
	if [ -d  "$a" -a "$a" != "cygdrive"  ]
	then 
		echo -e "\e[0;0;0;33mEntering $a...\e[0m"
		cd $a
		
		if [ ! -r $dbfile ]
		then
			echo -e "\e[5;0;1;31mUNABLE TO READ CHECKSUM DB FILE in $a\e[0m"
			cd ..
		else
			start_check $dbfile
			cd ..
	
		fi
	fi
done
}
start_check()
{
local n=0
local filename
local checksum
file=$1
dir=`pwd`
echo -e "\e[4;3;1;32mRUNNING FILE INTEGRITY CHECK ON $dir\e[0m"
while read record[n]
do
dir_checked="${record[0]}"
if [ "$dir_checked" != "$dir" ]
then 
echo -e "\e[5;0;1;31mDIRECTORIES DO NOT MATCH UP!\e[0m"
exit $E_DIR_NOMATCH
fi
if [ "$n" -gt 0 ]
then

	filename[n]=$( echo ${record[$n]}|awk '{print $2}' )
	
	checksum[n]=$( md5sum "${filename[n]}" )
	if [ "${record[n]}" = "${checksum[n]}" ]
	then 
	echo -e "\e[5;0;1;32m${filename[n]} unchanged.\e[0m"
	elif [ "`basename $filename[n]`" != "$dbfile" ]
	then
	echo -e "\e[5;0;1;31m${filename[n]} :CHECKSUM ERROR!\e[0m"
	fi
							
fi
let "n+=1"
done<$file
}
msg()
{
echo -e "\e[0;0;0;32m \n*****nohup sh /home/Ditesh/md5sumDemo.sh \"DIRECTORY\" \"FLAGS\"***** \nFLAGS:\ni:to create checksum files for the directory\nc:to check the integrity using the checksum\nif:overriding the checksum file if already exist\n\n			OR\n\nfor current directory\n*****nohup sh /home/Ditesh/md5sumDemo.sh \"FLAGS\"  *****\nFLAGS:\ni:to create checksum files for the directory\nc:to check the integrity using the checksum\nif:overriding the checksum file if already exist\n\n		OR\n\nwith no inputs default values(directory=pwd and flags=i)\n*****nohup sh /home/Ditesh/md5sumDemo.sh &*****\e[0m"
exit 1
}
echo -e "Input: $0\n ARG:$#"
if [ $# -eq 0 ]
then
	exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
	directory=`pwd`
	init $directory
elif [ $# -eq 1 ]
then
	exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
	directory=`pwd`
	runcheckdb=$1
	if [[ `echo -e $runcheckdb|awk '{print toupper($0)}'` = 'C' ]] 
	then
		exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		check_db $directory
	elif [[ `echo -e $runcheckdb|awk '{print toupper($0)}'` = 'I' ]] 
	then
		exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		init $directory
	elif [[ `echo -e $runcheckdb|awk '{print toupper($0)}'` = 'IF' ]] 
	then
		exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		`find $directory -type f -name "FILE_RECORD_*.md5" -exec rm -rf {} \;` 
		init $directory
	fi
elif [ $# -eq 2 ]
then
exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
	directory=$1
	runcheckdb=$2
	if [[ `echo -e $runcheckdb|awk '{print toupper($0)}'` = 'C' ]] 
	then
	exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		check_db $directory
	elif [[ `echo -e $runcheckdb|awk '{print toupper($0)}'` = 'I' ]] 
	then
	exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		init $directory
	elif [[ `echo -e $runcheckdb|awk '{print toupper($0)}'` = 'IF' ]] 
	then
	exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		`find $directory -type f -name "FILE_RECORD_*.md5" -exec rm -rf {} \;` 
		init $directory
	fi
elif [ $# -gt 2 ]
then
	msg
fi
sed -ni '/md5sumDemo.sh/!{p};/md5sumDemo.sh/{n;p}' $dbfile
echo -e "\e[0;3;1;38m****************************************THE END**********************************************\e[0m"

