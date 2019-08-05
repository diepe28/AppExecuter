#!/bin/bash

# https://github.com/andikleen/pmu-tools
#Simple script to upload a new version of HPCCG-RHT to Grid 5K and run them
#chmod +x executable, to give permission

#Example of use: ./myScriptAppExecuter.sh App-Executer g5k
#Example of use: ./myScriptAppExecuter.sh App-Executer cenat

#folder="$1"
#newFolder="$1"-Clean
#cluster="$2" #cenat | g5k

folder=App-Executer
newFolder=App-Executer-Clean
cluster=g5k

if [ $cluster == "cenat" ]
then
    cluster="dperez@cluster.cenat.ac.cr"
else
    cluster="dperez@access.grid5000.fr"
fi

echo Cluster http: $cluster

echo Folder Name: $folder $newFolder

cp -a $folder/ ./$newFolder
rm -rf $newFolder/.git
rm -rf $newFolder/.idea

tar -czvf $newFolder.tar.gz $newFolder
rm -r -f $newFolder
echo "zip file created"

#echo "Copying files to Nancy..."
#scp $newFolder.tar.gz dperez@access.grid5000.fr:nancy/public

if [ "$2" == "cenat" ]
then
    echo "Copying files to Kabre..."
    scp $newFolder.tar.gz $cluster:~/public/workspace
    echo "Files copied to Kabre Storage"
else
    #echo "Copying files to Lyon..."
    #scp $newFolder.tar.gz $cluster:lyon/public/workspace
    #scp reserve-prepare-nodes.sh $cluster:lyon/public/workspace
    #scp rel-exp-node.sh $cluster:lyon/public/workspace
    
    #echo "Copying files to Rennes..."
    #scp $newFolder.tar.gz $cluster:rennes/public/workspace
    #scp reserve-prepare-nodes.sh $cluster:rennes/public/workspace
    #scp rel-exp-node.sh $cluster:rennes/public/workspace
    
    #echo "Copying files to Sophia..."
    #scp $newFolder.tar.gz $cluster:sophia/public/workspace
    #scp reserve-prepare-nodes.sh $cluster:sophia/public/workspace
    #scp rel-exp-node.sh $cluster:sophia/public/workspace
    
    echo "Copying files to Nantes..."
    scp $newFolder.tar.gz $cluster:nantes/public/workspace
    scp reserve-prepare-nodes.sh $cluster:nantes/public/workspace
    scp rel-exp-node.sh $cluster:nantes/public/workspace
    
    echo "Copying files to Nancy..."
    scp $newFolder.tar.gz $cluster:nancy/public/workspace
    scp reserve-prepare-nodes.sh $cluster:nancy/public/workspace
    scp rel-exp-node.sh $cluster:nancy/public/workspace
    
    #echo "Copying files to Lille..."
    #scp $newFolder.tar.gz $cluster:lille/public/workspace
    #scp reserve-prepare-nodes.sh $cluster:lille/public/workspace
    #scp rel-exp-node.sh $cluster:lille/public/workspace
    
    echo "Files copied to Grid5K Storage"
fi    
echo "Removing zip file"
rm $newFolder.tar.gz
echo "Success!!"

