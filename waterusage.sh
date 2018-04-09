#!/bin/sh
#
# usage: waterusage MeterID [start-year [end-year]]
#
# depends on gnuplot
#
set -a

usage() {
	echo usage: $0 MeterID [start-year [end-year]] 1>&2
	exit 1;
}

### command line options
METERID=$1
STARTYEAR=$2
ENDYEAR=$3

if [ -z "$METERID" ]; then usage; fi

CURRENTYEAR=`date +%Y`

# start year defaults to current year
if [ -z "$STARTYEAR" ]; then
	STARTYEAR=$CURRENTYEAR
	ENDYEAR=$CURRENTYEAR
fi

# end year defaults to start year
if [ -z "$ENDYEAR" ]; then
	ENDYEAR=$STARTYEAR
fi

if [ $STARTYEAR -gt $ENDYEAR ]; then usage;fi
if [ $STARTYEAR -gt $CURRENTYEAR ]; then usage; fi
if [ $ENDYEAR -gt $CURRENTYEAR ]; then ENDYEAR=$CURRENTYEAR; fi

# more date arg checking?

### end command line options processing

fileprefix=waterusage-${METERID}-${STARTYEAR}-${ENDYEAR} 	# ./waterusage-Meter-Year-Year

htmlfile=$fileprefix.html	# just for debugging
datafile=$fileprefix.data
gpfile=$fileprefix.gnuplot
pngfile=$fileprefix.png

# comment out this line if you want persistent data.  leave it alone if you don't like little turds lying around.
trap "rm -f $htmlfile $datafile $gpfile" 0 1 2 3 15

# use this line unless debugging
curl -s 'https://secure.a2gov.org/WaterConsumption/DownloadData.aspx?meterID='${METERID}'&startDate=1%2F1%2F'${STARTYEAR}'&endDate=12%2F31%2F'${ENDYEAR}  | tee $htmlfile |

# for debugging, curl is too slow, so (1) manually curl into, say, foo.html, (2) uncomment the next line, and (3) comment out the curl line above
#cat foo.html |

sed -e 1,4d -e /tr/d -e /table/d -e 's;</td><td>;,;g' -e 's/.*<td>//' -e 's;.</td>.*;;' | awk -F, -v METERID=$METERID -v STARTYEAR=$STARTYEAR -v ENDYEAR=$ENDYEAR -v datafile=$datafile -v gpfile=$gpfile -v pngfile=$pngfile -v minmeter=999999999999 '
{
	# date meter CCF Gal

	if (split($1, date, "/") != 3) {
		print
		abort()				# somebody has to fix the ahem parser
	}
	m = date[1]
	y = date[3]

	if (meter[m y] < $2)
		meter[m y] = $2			# largest meter reading for the month

	# record the min meter reading for later cleanup
	if ($2 < minmeter) {
		minmeter = $2
	}
	
	# figure out the first and last month/year for the output loop
	if (y > finalyear) {
		finalyear = y
		if (m > finalmonth)
			finalmonth = m
	}
}

END {
	# there might be months with no reading, so meter[ ] will show 0.  set them to the previous month meter.
	# make sure the first month is not zero for this to work
	if (meter[1 STARTYEAR] == 0)
		meter[1 STARTYEAR] = minmeter

	# gnuplot file
	print "set term png size 640, 480" > gpfile
	print "set output \"" pngfile "\"" > gpfile	
	print "set xdata time" > gpfile
	print "set timefmt \"%m/%Y\"" > gpfile
	print "set format x \"%m/%y\"" > gpfile
	print "set key off" > gpfile
	print "set title \"" METERID " Water Usage in Cubic Feet\"" > gpfile
	print "plot \"" datafile "\" using 1:2" > gpfile


	# data file
	print 2 "/" STARTYEAR, 0 > datafile			# set xzeroaxis in gnuplot is not working for me, so this a workaround

	prevreading = minmeter
	for (y = STARTYEAR; y <= ENDYEAR; y++) {
		for (m = 1; m <= 12; m++) {
			if (meter[m y] == 0)	# no readings this month.  really should interpolate the zero months
				meter[m y] = prevreading

			print m "/" y, meter[m y] - prevreading > datafile	# subtract prev month meter reading from this month meter reading
			prevreading = meter[m y]

			if (y == finalyear && m == finalmonth)
				exit(0)	
		}
	}
}
'

gnuplot $gpfile
open $pngfile
