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
numNodes=8

#oarsub -I -t deploy -l {"cluster='$myCluster'"}/nodes=1,walltime=1
#oarsub -I -l {"cluster='suno'"}/nodes=1,walltime=1

# Request numNodes-nodes at the myClusters cluster 
#oarsub -r "2020-06-05 19:00:00" -t deploy -l {"cluster='$myCluster'"}/nodes=$numNodes,walltime=24:00

# Extend time on a job
#oarwalltime 199549 +0:30 

# Connect to job
#oarsub -C 199549

#Delete a job
#oardel 199549

#Deploy my image to all your nodes (as root)
echo Deploying image to all nodes
kadeploy3 -f $OAR_FILE_NODES -a myUbuntu.env -k

echo All nodes have been deployed
mapfile -t myNodes < <( cat $OAR_FILE_NODES )

echo Copying everything and executing scripts
var=$((${#myNodes[@]} / $numNodes))
# starts at 4 because we are no longer running all errors executions
param=4 
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
# Compressing into a single tar.gz
currentDate=$(date +%A%d%B)
tar -czvf $currentDate'_reliability-results.tar.gz' *_run*.tar.gz


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



