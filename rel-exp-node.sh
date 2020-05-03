#!/bin/bash

# https://github.com/andikleen/pmu-tools
#chmod +x executable, to give permission

#Adding ssh key of frontend
echo Adding frontend ssh key to known_hosts
ssh-keyscan -H frontend >> ~/.ssh/known_hosts

# Exporting variables
export LLVM_BUILD_PATH=/home/diego/workspace/clang+llvm-3.5.2
export FLIPIT_PATH=/home/diego/workspace/FlipIt-master

#only required if you want to use FlipIt as a library with other code
export LD_LIBRARY_PATH=/home/diego/workspace/FlipIt-master/lib:$

#not required, but can make your fingers happy in you do not use the comp$
PATH=$PATH:/home/diego/workspace/clang+llvm-3.5.2/bin
export PATH

cd /home/diego/workspace

echo Located at
pwd

skipExecution=false

### Running not replicated HPCCG ######################################
if [ "$1" == "0" ] || [ "$1" = "4" ] || [ "$1" = "8" ]
then
	echo Running not replicated HPCCG
fi

### Running wang approach #############################################
if [ "$1" == "1" ] || [ "$1" = "5" ] || [ "$1" = "9" ]
then
	echo Running wang approach
fi

### Running wang approach with var grouping ############################
if [ "$1" == "2" ] || [ "$1" = "6" ] || [ "$1" = "10" ]
then
	echo Running wang approach with var grouping
fi

### Running wang approach with just volatiles ##########################
if [ "$1" == "3" ] || [ "$1" = "7" ] || [ "$1" = "11" ]
then
	echo Running wang approach with just volatiles
fi

# Uncompress the tar.gz files
echo Uncompressing repositories files
tar xf App-Executer-Clean.tar.gz
tar xf HPCCG-RHT-Clean.tar.gz

echo Printing all folders
ls

# Make HPCCG and all its targets
echo Making HPCCG and all its targets
cd HPCCG-RHT-Clean/

errorLevel=''

### Executables with all kinds of errors #######################################
if [ "$1" == "0" ] || [ "$1" = "1" ] || [ "$1" = "2" ]|| [ "$1" = "3" ]
then
	echo All kinds of errors are enabled
	#errorLevel=$1'_MPI_allErrors'
	#errorLevel=$1'_NOPdcDrt_allErrors'
	#errorLevel=$1'_NOMPI_allErrors'
	errorLevel=$1'_allErrors'
	skipExecution=true
fi

### Executables with arithmetic errors and control errors ######################
if [ "$1" == "4" ] || [ "$1" = "5" ] || [ "$1" = "6" ]|| [ "$1" = "7" ]
then
	echo Arithmetic and control operations errors are enabled
	mv config.py ./configAll.py
	mv configAC.py ./config.py
	#errorLevel=$1'_MPI_arithmetic_control'
	#errorLevel=$1'_NOPdcDrt_arithmetic_control'
	#errorLevel=$1'_NOMPI_arithmetic_control'
	errorLevel=$1'_arithmetic_control'
fi

### Executables with only arithmetic errors #####################################
if [ "$1" == "8" ] || [ "$1" = "9" ] || [ "$1" = "10" ]|| [ "$1" = "11" ]
then
	echo Only arithmetic errors are enabled
	mv config.py ./configAll.py
	mv configA.py ./config.py
	#errorLevel=$1'_MPI_arithmetic'
	#errorLevel=$1'_NOPdcDrt_arithmetic'
	#errorLevel=$1'_NOMPI_arithmetic'
	errorLevel=$1'_arithmetic'
fi

make cleanBinaries
# Make wang executable and its log
# Moving HPCCG executables and logfiles to app-executer folder
make clean && make Wang && ../FlipIt-master/scripts/binary2ascii.py ddot.cpp.LLVM.bin #&& ../FlipIt-master/scripts/binary2ascii.py RHT.cpp.LLVM.bin
mv ddot.cpp.LLVM.txt ddot-$errorLevel-Wang.LLVM.txt
#mv RHT.cpp.LLVM.txt RHT-$errorLevel-Wang.LLVM.txt
cp Wang ../App-Executer-Clean/
cp ddot-$errorLevel-Wang.LLVM.txt ../App-Executer-Clean/
#cp RHT-$errorLevel-Wang.LLVM.txt ../App-Executer-Clean/

# Make wang var grouping executable and its log
make clean && make WangVG && ../FlipIt-master/scripts/binary2ascii.py ddot.cpp.LLVM.bin #&& ../FlipIt-master/scripts/binary2ascii.py RHT.cpp.LLVM.bin
mv ddot.cpp.LLVM.txt ddot-$errorLevel-WangVG.LLVM.txt
#mv RHT.cpp.LLVM.txt RHT-$errorLevel-WangVG.LLVM.txt
cp WangVG ../App-Executer-Clean/
cp ddot-$errorLevel-WangVG.LLVM.txt ../App-Executer-Clean/
#cp RHT-$errorLevel-WangVG.LLVM.txt ../App-Executer-Clean/

# Make wang just volatiles executable and its log
make clean && make WangJV && ../FlipIt-master/scripts/binary2ascii.py ddot.cpp.LLVM.bin #&& ../FlipIt-master/scripts/binary2ascii.py RHT.cpp.LLVM.bin
mv ddot.cpp.LLVM.txt ddot-$errorLevel-WangJV.LLVM.txt
#mv RHT.cpp.LLVM.txt RHT-$errorLevel-WangJV.LLVM.txt
cp WangJV ../App-Executer-Clean/
cp ddot-$errorLevel-WangJV.LLVM.txt ../App-Executer-Clean/
#cp RHT-$errorLevel-WangJV.LLVM.txt ../App-Executer-Clean/


# Make app executable and all subfolders
echo Making app executable and all subfolders
cd ../App-Executer-Clean/
make

# Copy executable to respective folder
echo Copy executable to respective folder
myPass="Password2018..."

#########################################
if [ "$1" == "0" ] || [ "$1" = "4" ] || [ "$1" = "8" ]
then
	if [ "$skipExecution" = false ] ; then
		mkdir output
		cp Wang output/
		cp ddot-$errorLevel-Wang.LLVM.txt output/ddot-$errorLevel-notReplicated.LLVM.txt
		#cp RHT-$errorLevel-Wang.LLVM.txt output/RHT-$errorLevel-notReplicated.LLVM.txt
		cp app-executer output/

		# Run not replicated version and copy output to frondend
		echo Running not replicated exe
		cd output/
		./app-executer ../Settings/settings_NotReplicated.ini > finalOutput.txt
		cd ..
		folderName=$errorLevel'_runNotReplicated.tar.gz'
		tar -czvf $folderName output/
		sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
	fi
fi

#########################################
if [ "$1" == "1" ] || [ "$1" = "5" ] || [ "$1" = "9" ]
then
	if [ "$skipExecution" = false ] ; then
		mkdir output
		cp Wang output/
		cp ddot-$errorLevel-Wang.LLVM.txt output/
		#cp RHT-$errorLevel-Wang.LLVM.txt output/
		cp app-executer output/

		# Run Wang approach, and copy output to frontend
		echo Running wang approach
		cd output/
		./app-executer ../Settings/settings_Wang.ini > finalOutput.txt
		cd ..
		folderName=$errorLevel'_runWang.tar.gz'
		tar -czvf $folderName output/
		sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
	fi
fi

#########################################
if [ "$1" == "2" ] || [ "$1" = "6" ] || [ "$1" = "10" ]
then
	if [ "$skipExecution" = false ] ; then
		mkdir output
		cp WangVG output/
		cp ddot-$errorLevel-WangVG.LLVM.txt output/
		#cp RHT-$errorLevel-WangVG.LLVM.txt output/
		cp app-executer output/
		# Run Wang Var Grouping approach, and copy output to frontend

		echo Running wang approach with var grouping
		cd output/
		./app-executer ../Settings/settings_Wang_VG.ini > finalOutput.txt
		cd ..
		folderName=$errorLevel'_runWangVG.tar.gz'
		tar -czvf $folderName output/
		sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
	fi
fi

#########################################
if [ "$1" == "3" ] || [ "$1" = "7" ] || [ "$1" = "11" ]
then
	if [ "$skipExecution" = false ] ; then
		mkdir output
		cp WangJV output/
		cp ddot-$errorLevel-WangJV.LLVM.txt output/
		#cp RHT-$errorLevel-WangJV.LLVM.txt output/
		cp app-executer output/

		# Run Wang Just Volatiles approach, and copy output to frontend
		echo Running wang approach with just volatiles
		cd output/
		./app-executer ../Settings/settings_Wang_JV.ini > finalOutput.txt
		cd ..
		folderName=$errorLevel'_runWangJV.tar.gz'
		tar -czvf $folderName output/
		sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
	fi
fi

exit
