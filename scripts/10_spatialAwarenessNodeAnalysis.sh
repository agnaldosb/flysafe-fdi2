#!/bin/bash

# -----------------------------------------------------------------------------
# Perform spatial awareness individual nodes rx analysis of each
# simulation and put in an individual file to each node
#
# Attention: The spatial awareness analysis start by performing this script
#
# Jun 13, 2023
#
# Run from inside flysafe traces folder
#			 (e.g. ns3.34/flysafe_traces# ./_spatialAwarenessNodeAnalysis.sh)
# -----------------------------------------------------------------------------

#[ ! -d flysafe_global_traces ] && mkdir flysafe_global_traces # create folder, if no exists

#folder="flysafe_global_traces" # define the name of the folder to global traces
IPFile="neighborhood_rx_analysis_gnuplot_192.168.1.*"
find . -name $IPFile  > _traceRxFiles # get nodes files from all simulations
#IPFileGlobal="global_localization_error_rx_statistics_192.168.1."$i".txt"
#echo -e "dateTime\tavgAvgError\tstdDevAvgError\tavgAvgMin\tstdDevAvgMin\tavgAvgMax\tstdDevAvgMax" >> $folder"/"$IPFileGlobal # insert a header line in global file

cat _traceRxFiles | while read line # get each file of one specific node
do
	echo $line
	dateTime=${line:2:13}
	fileLength=${#line} # get line length
	# get nodeNumber
	if [ $fileLength == "64" ]; then
		nodeNumber=${line:59:1}
	else
		if [ $fileLength == "65" ]; then
			nodeNumber=${line:59:2}
		else
			nodeNumber=${line:59:3}
		fi
	fi
	awareFile="./"$dateTime"/spatial_awareness_192.168.1."$nodeNumber".txt"
	noAwareFile="./"$dateTime"/spatial_no_awareness_192.168.1."$nodeNumber".txt"
	nodeFile="./"$dateTime"/spatial_awareness_rx_analysis_192.168.1."$nodeNumber".txt"

	# Insert header line in each file
	echo -e "startTime\tendTime\tduration\tawareness"	>> $awareFile # put the head line in the file
	echo -e "startTime\tendTime\tduration\tawareness"	>> $noAwareFile # put the head line in the file
	echo -e "startTime\tendTime\tduration\tawareness"	>> $nodeFile # put the head line in the file

	startTime=0
	fileLine=$(sed '2q;d' $line) # get data line from file (2nd line)
	endTime=$(echo $fileLine | cut -d ' ' -f 1)
	aware=$(echo $fileLine | cut -d ' ' -f 5)
	if [ "$aware" == 0 ]; then
		aware=1
	else
		aware=0
	fi
	nLines=$(wc -l < $line) # get number of lines in the file
	for i in $(seq 3 $nLines)
	do
	 	linei=$(sed $i'q;d' $line)
		lTime=$(echo $linei | cut -d ' ' -f 1)
		lError=$(echo $linei | cut -d ' ' -f 5)
		if [ "$lError" == 0 ]; then
			lError=1
		else
			lError=0
		fi
		if [ "$lError" == "$aware" ]; then
			endTime=$lTime
		else
			endTime=$lTime
			#duration=$(($endTime-$startTime))
			duration=$(bc <<< "$endTime-$startTime")
			# save all to the analysis to a node file
			echo -e $startTime"\t"$endTime"\t"$duration"\t"$aware >> $nodeFile

			# save infos from aware or no_aware analysis to specific files
			if [ "$aware" == 0 ]; then
				echo -e $startTime"\t"$endTime"\t"$duration"\t"$aware >> $noAwareFile
			else
				echo -e $startTime"\t"$endTime"\t"$duration"\t"$aware >> $awareFile
			fi
			startTime=$endTime
			aware=$lError
		fi
		if [ "$i" == "$nLines" ]; then
			endTime=$lTime
			duration=$(bc <<< "$endTime-$startTime")
			echo -e $startTime"\t"$endTime"\t"$duration"\t"$aware >> $nodeFile
			
			# save infos from aware or no_aware analysis to specific files
			if [ "$aware" == 0 ]; then
				echo -e $startTime"\t"$endTime"\t"$duration"\t"$aware >> $noAwareFile
			else
				echo -e $startTime"\t"$endTime"\t"$duration"\t"$aware >> $awareFile
			fi
		fi
	done
done	
[ -e _traceRxFiles ] && rm _traceRxFiles # remove temporary file
