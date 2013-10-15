#!/bin/bash
# CRONTAB to run WARC repository generator
 
# CPR : Jd Daniel :: Ehime-ken
# MOD : 2013-10-08 @ 09:22:55

# INP : $1 System type (rhel|deb)
# INP : $2 Maria/Mysql User
# INP : $3 Maria/Mysql Pass
# INP : $4 Maria/Mysql DB.Table 

# REQ : DB supports EVEN runtimes only atm

set -e

# capture the runtime factors an address' from a database.table
query=$(mysql -u$2 -p$3 -sN -e "SELECT runtime, address FROM $4")

# assemble into an array with runtime factor leading address
array=( $( for i in $query ; do echo $i ; done ) ) #arr
outfile=$$-$RANDOM-data.nfo # gen random outfile, avoiding script name overlapping AKA: Condt 1

clear; #set -x # debug

[ ! -d 'trackers' ] && mkdir 'trackers' # !is_dir(trackers), mkdir trackers

for (( i=0 ; i<${#array[@]} ; i++ )); do # iterate array parts

	# use only ODD parts of the array, we will use address' out 
	# of sequence, poss integrety issue if some dumb ass inputs
	# incorrectly on setup, poss fake assoc arrays? Fix later..
	[ $((($i-1) % 2)) -eq 0 ] && continue 

	# set current tracker file
	tracker="trackers/${array[$i-1]}.stamp"

	sequence=$((24/${array[$i]})) # iteration amount until goal is met

	declare -i base=0 # declare base enumerator

	for i in $(seq 1 $sequence); do # use runtime as range()

		base=$(($base + $sequence))

		# cannot touch -t $(date +"%Y%m%d2400") {file} only 00:00 tmk
	    [ $base -eq 24 ] && mill=0 || mill=$base

		n=`printf %02d $mill`  		# pad items with leading 0

		# if file doesn't exist set tracker time to current time
		[ ! -f $tracker ] && touch -t $(date +"%Y%m%d$n%M") ${tracker}

		# +'%-' will elmitnate leading zeros
		if [ $i -eq $(date -r ${tracker} +%-H) ]; then 

			n=`printf %02d $(($mill+$sequence))`

			# set tracker forward to next runtime
			touch -t $(date +"%Y%m%d$n%M") ${tracker}

			echo "${array[$i-1]}....\n" 		# echo that we did something, anything....
			echo "${array[$i-1]}" >> $outfile 	# append this address to file for scraper 
		else
			echo -e "Doesn't exist: $(date -r ${tracker} +%-H) / $((24/$i)) \t ${tracker}" # got nothin'
		fi


	done
done

# test if file exists and run
[ -f $outfile ] && bash git-scrape.sh $1 $outfile