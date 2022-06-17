#!/bin/bash
#################################################################################
:<<DESCRIPTION
DITESH POOJARI
sh /home/Ditesh/md5sumDemo.sh "DIRECTORY" "FLAG"				#
FLAGS:																			#
i:to create checksum files for the directory									#
c:to check the integrity using the checksum									#
IF:overriding the checksum file if already exist	
DESCRIPTION				
#################################################################################
##set -euox pipefail

###trap "" SIGINT
E_DIR_NOMATCH=80
E_BAD_DBFILE=81
tm=`date +%Y-%m-%d`
dbfile=FILE_RECORD_$tm.md5
l_red="\e[0;0;1;31m"
ldefault="\e[0m"
l_normal_green="\e[0;0;1;32m"
l_UIGreen="\e[4;3;1;32m"
l_yellow="\e[0;0;1;33m"
l_blue="\e[0;0;1;34m"
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
echo -e "${l_normal_green}CREATING CHECKSUM FOR ALL FILES in $idir${default}"
echo
if [ ! -r $dbfile ]
then 
echo -e "${l_normal_green}SETTING dbfile, \e[4;3;1;32m$idir/$dbfile.\e[0m"
setup_db $idir
else
echo -e "${l_red}$idir/$dbfile ALREADY EXIST\nEmptying the file....\e[0m"
cat /dev/null>$dbfile
setup_db $idir
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
	echo -e "\e[0;0;0;32mSAVED MD5CHECKSUM FOR $a${default}"
elif [ -d  "$a"  -a "$a" != "cygdrive" ]
then 
	echo -e "${l_blue}$a IS DIRECTORY${default}"
	echo -e "${l_yellow}ENTERING INTO THE DIRECTORY:$a...${default}"
	init $a
	pwd=`pwd`
	echo -e "${l_UIGreen}DONE FOR FILES in $pwd${default}"
	cd ..
elif [ ! -d "$a" ];then
		echo -e "\e[0;0;0;31m$a is not txt/sh/sql/dll/sql${default}"
	

fi
##sleep 2
done
chmod 400 $dbfile
}
check_db()
{

cdir=$1
cd $cdir
dbfile=`ls -tr FILE_RECORD_*.md5|tail -n 1`
if [ ! -r $dbfile ]
then
echo -e "\e[5;0;1;31mUNABLE TO READ CHECKSUM DB FILE(${dbfile}) in $cdir${default}"
else
start_check $dbfile
fi
for a in `ls $cdir`;
do 
	if [ -d  "$a" -a "$a" != "cygdrive"  ]
	then 
		
		echo -e "${l_yellow}Entering $a...${default}"
		cd $a
		dbfile=`ls -tr FILE_RECORD_*.md5|tail -n 1`
		if [ ! -r $dbfile ]
		then
			echo -e "${l_red}UNABLE TO READ CHECKSUM DB FILE(${dbfile}) in $a${default}"
			cd ..
		else
			echo -e "${l_yellow}Found ${dbfile} ${default}"
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
echo -e "${l_UIGreen}RUNNING FILE INTEGRITY CHECK ON $dir${default}"
while read record[n]
do
dir_checked="${record[0]}"
if [ $n -eq 0 ]
then
	if [ "$dir_checked" != "$dir" ]
	then 
		echo -e "{$l_red}DIRECTORIES DO NOT MATCH UP!${default}"
		exit $E_DIR_NOMATCH
	else 
		echo -e "${l_blue}Directory mentioned in file ${file} matched with PWD.${default}"
	fi
fi
if [ "$n" -gt 0 ]
then

	filename[n]=$( echo ${record[$n]}|awk '{print $2}' )
	
	checksum[n]=$( md5sum "${filename[n]}" )
	if [ "${record[n]}" = "${checksum[n]}" ]
	then 
		echo -e "${l_normal_green}${filename[n]} unchanged.${default}"
	elif [ "`basename $filename[n]`" != "$dbfile" ]
	then
		echo -e "${l_red}${filename[n]} :CHECKSUM ERROR!${default}"
	fi
							
fi
let "n+=1"
done<$file
}
:<<COMMENTED
msg()
{
	echo -e "\e[0;0;0;32m \n*****nohup sh /home/Ditesh/md5sumDemo.sh -d\"DIRECTORY\"-i(to createchecksum file) -c(to check the integrity of the file against the checksum generated earlier)\"\"***** \nFLAGS:\ni:to create checksum files for the directory\nc:to check the integrity using the checksum\nif:overriding the checksum file if already exist\n\n			OR\n\nfor current directory\n*****nohup sh /home/Ditesh/md5sumDemo.sh \"FLAGS\"  *****\nFLAGS:\ni:to create checksum files for the directory\nc:to check the integrity using the checksum\nif:overriding the checksum file if already exist\n\n		OR\n\nwith no inputs default values(directory=pwd and flags=i)\n*****nohup sh /home/Ditesh/md5sumDemo.sh &*****\e[0m"
exit 1
}
COMMENTED
echo -e "Input: $0\n ARG:$#"
if [ $# -eq 0 ]
then
	touch /home/Ditesh/md5logs_$tm.log
	exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
	directory=`pwd`
	init $directory
else
touch /home/Ditesh/md5logs_$tm.log
while getopts d:i:c o
do
	case $o in 
	d)directory=$OPTARG;;
	i)create=true;;
	c)checkdb=true;;
	[?])echo -e "${l_blue}Usage:$0 [-d] [directory Path] [-i] flag to create checksum files for the directory or [-c] to check the integrity using the checksum created earlier${default}"|tee /home/Ditesh/md5logs_$tm.log
	exit 1;;
	esac
	if test -z $directory
	then
		directory=`pwd`
	elif test -d $directory
	then
		echo -e "${l_red}Invalid  Directory:\"$directory\"\nExiting Script...${default}">>/home/Ditesh/md5logs_$tm.log
		exit 1
	fi
	
	if [ $create ]
	then
		exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		`find $directory -type f -name "FILE_RECORD_*.md5" -exec rm -rf {} \;` 
		init $directory
	elif [ $checkdb ]
	then 
		exec 1>>/home/Ditesh/md5logs_$tm.log 2>&1
		check_db $directory
	fi
done
fi

sed -ni '/md5sumDemo3.sh/!{p};/md5sumDemo3.sh/{n;p}' $dbfile
echo -e "\e[0;3;1;38m****************************************THE END**********************************************\e[0m"



