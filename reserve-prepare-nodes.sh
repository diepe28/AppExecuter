#!/bin/bash

# https://github.com/andikleen/pmu-tools
#chmod +x executable, to give permission

#It assumes the .tar.gz files of AppExecuter and HPCCG are uploaded
#ssh dperez@access.grid5000.fr

#This must be executed before calling the executable
#myCluster='paravance' #rennes
#myCluster='suno' #sophia
#myCluster='chiclet' #lille
myCluster='ecotype' #nantes
#myCluster='grisou' #nancy
numNodes=12
#oardel 168442 #to delete a job
#oarsub -I -t deploy -l {"cluster='$myCluster'"}/nodes=1,walltime=1
#oarsub -I -l {"cluster='suno'"}/nodes=1,walltime=1
#oarsub -r "2019-08-05 19:00:00" -t deploy -l {"cluster='$myCluster'"}/nodes=$numNodes,walltime=12:00

#oarwalltime 168460 +0:30 
#oarsub -C 168460

#Deploy my image to all your nodes (as root)
echo Deploying image to all nodes
kadeploy3 -f $OAR_FILE_NODES -a myUbuntu.env -k

echo All nodes have been deployed
mapfile -t myNodes < <( cat $OAR_FILE_NODES )

echo Copying everything and executing scripts
var=$((${#myNodes[@]} / $numNodes))
param=0
for i in ${!myNodes[@]}; do
  index=$(($i%$var))
  if [ $index -eq 0 ]; then
    echo Node $i: ${myNodes[$i]}
    scp HPCCG-RHT-Clean.tar.gz root@${myNodes[$i]}:/home/diego/workspace/
    scp App-Executer-Clean.tar.gz root@${myNodes[$i]}:/home/diego/workspace/
    scp rel-exp-node.sh root@${myNodes[$i]}:/home/diego/workspace/
    ssh -n -f root@${myNodes[$i]} "sh -c 'cd /home/diego/workspace/; nohup ./rel-exp-node.sh $param > /dev/null 2>&1 &'"
    param=$(($param + 1))
  fi
done

#ssh -n -f root@${myNodes[1]} "sh -c 'cd /home/diego/workspace/; nohup ./rel-exp-node.sh 1 > /dev/null 2>&1 &'"
#ssh root@${myNodes[0]}
#oarstat #all jobs active

#7pm - 9am (no limit, best to do in this interval)

echo Done ordering script execution
exit

# These are just helpful commands to have, but they are not executed because of the recent "exit" command
# Renaming everything to proper folder names
mv runNotReplicated_allErrors.tar.gz 0-runNotReplicated_allErrors.tar.gz 
mv runNotReplicated_arithmetic_control.tar.gz 1-runNotReplicated_arithmetic_control.tar.gz
mv runNotReplicated_arithmetic.tar.gz 2-runNotReplicated_arithmetic.tar.gz 

mv runWang_allErrors.tar.gz 3-runWang_allErrors.tar.gz
mv runWang_arithmetic_control.tar.gz 4-runWang_arithmetic_control.tar.gz
mv runWang_arithmetic.tar.gz 5-runWang_arithmetic.tar.gz

mv runWangVG_allErrors.tar.gz 6-runWangVG_allErrors.tar.gz
mv runWangVG_arithmetic_control.tar.gz 7-runWangVG_arithmetic_control.tar.gz
mv runWangVG_arithmetic.tar.gz 8-runWangVG_arithmetic.tar.gz

mv runWangJV_allErrors.tar.gz 9-runWangJV_allErrors.tar.gz
mv runWangJV_arithmetic_control.tar.gz 10-runWangJV_arithmetic_control.tar.gz
mv runWangJV_arithmetic.tar.gz 11-runWangJV_arithmetic.tar.gz

# Compressing into a single tar.gz
tar -czvf reliability-results.tar.gz *-run*.tar.gz

# Executed from my machine
#scp dperez@access.grid5000.fr:nantes/public/workspace/reliability-results.tar.gz ./
#scp -r dperez@access.grid5000.fr:nantes/public/workspace/someDir ./
tar xf reliability-results.tar.gz 

# Extracting and preparing to copy to excel file

cp 0-runNotReplicated_allErrors/runNotReplicated/finalOutput.log 0-runNotReplicated_allErrors/
cp 1-runNotReplicated_arithmetic_control/runNotReplicated/finalOutput.log 1-runNotReplicated_arithmetic_control/
cp 2-runNotReplicated_arithmetic/runNotReplicated/finalOutput.log 2-runNotReplicated_arithmetic/

cp 3-runWang_allErrors/runWang/finalOutput.log 3-runWang_allErrors/
cp 4-runWang_arithmetic_control/runWang/finalOutput.log 4-runWang_arithmetic_control/
cp 5-runWang_arithmetic/runWang/finalOutput.log 5-runWang_arithmetic/

cp 6-runWangVG_allErrors/runWangVG/finalOutput.log 6-runWangVG_allErrors/
cp 7-runWangVG_arithmetic_control/runWangVG/finalOutput.log 7-runWangVG_arithmetic_control/
cp 8-runWangVG_arithmetic/runWangVG/finalOutput.log 8-runWangVG_arithmetic/

cp 9-runWangJV_allErrors/runWangJV/finalOutput.log 9-runWangJV_allErrors/
cp 10-runWangJV_arithmetic_control/runWangJV/finalOutput.log 10-runWangJV_arithmetic_control/
cp 11-runWangJV_arithmetic/runWangJV/finalOutput.log 11-runWangJV_arithmetic/



