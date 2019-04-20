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
rm HPCCG-RHT-Clean/ -rf
rm App-Executer-Clean/ -rf
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
	errorLevel='_allErrors'
fi

### Executables with arithmetic errors and control errors ######################
if [ "$1" == "4" ] || [ "$1" = "5" ] || [ "$1" = "6" ]|| [ "$1" = "7" ]
then
	echo Arithmetic and control operations errors are enabled
	mv config.py ./configAll.py
	mv configAC.py ./config.py
	errorLevel='_arithmetic_control'
fi

### Executables with only arithmetic errors #####################################
if [ "$1" == "8" ] || [ "$1" = "9" ] || [ "$1" = "10" ]|| [ "$1" = "11" ]
then
	echo Only arithmetic errors are enabled	
	mv config.py ./configAll.py
	mv configA.py ./config.py
	errorLevel='_arithmetic'
fi

make cleanExes && make clean && make Wang && make clean && make WangVG && make clean && make WangJV && make clean
	
cp Wang ../App-Executer-Clean/Wang
cp WangVG ../App-Executer-Clean/WangVG
cp WangJV ../App-Executer-Clean/WangJV

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
	mkdir runNotReplicated
	cp Wang runNotReplicated/
	cp app-executer runNotReplicated/

	# Run not replicated version and copy output to frondend
	echo Running not replicated exe
	cd runNotReplicated/
	./app-executer ../Settings/settings_NotReplicated.ini > finalOutput.log
	cd ..
	folderName=runNotReplicated$errorLevel.tar.gz
	tar -czvf $folderName runNotReplicated/
	sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
fi    

#########################################
if [ "$1" == "1" ] || [ "$1" = "5" ] || [ "$1" = "9" ]
then
	mkdir runWang
	cp Wang runWang/
	cp app-executer runWang/

	# Run Wang approach, and copy output to frontend
	echo Running wang approach 
	cd runWang/
	./app-executer ../Settings/settings_Wang.ini > finalOutput.log
	cd ..
	folderName=runWang$errorLevel.tar.gz
	tar -czvf $folderName runWang/
	sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
fi    

#########################################
if [ "$1" == "2" ] || [ "$1" = "6" ] || [ "$1" = "10" ]
then
	mkdir runWangVG
	cp WangVG runWangVG/
	cp app-executer runWangVG/

	# Run Wang Var Grouping approach, and copy output to frontend
	echo Running wang approach with var grouping 
	cd runWangVG/
	./app-executer ../Settings/settings_Wang_VG.ini > finalOutput.log
	cd ..
	folderName=runWangVG$errorLevel.tar.gz
	tar -czvf $folderName runWangVG/
	sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
fi    

#########################################
if [ "$1" == "3" ] || [ "$1" = "7" ] || [ "$1" = "11" ]
then
	mkdir runWangJV
	cp WangJV runWangJV/
	cp app-executer runWangJV/

	# Run Wang Just Volatiles approach, and copy output to frontend
	echo Running wang approach with just volatiles
	cd runWangJV/
	./app-executer ../Settings/settings_Wang_JV.ini > finalOutput.log
	cd ..
	folderName=runWangJV$errorLevel.tar.gz
	tar -czvf $folderName runWangJV/
	sshpass -p $myPass scp $folderName dperez@frontend:/home/dperez/public/workspace/
fi    

exit

