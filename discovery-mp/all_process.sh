#!/bin/sh

#url="https://minorplanetcenter.net/iau/lists/NumberedMPs.txt.gz"
url="https://minorplanetcenter.net/iau/lists/NumberedMPs.txt"

echo "[Step 1] Downloading Discovery Circumstances...\n"

echo "Processing $url"
curl -# --retry 3 --connect-timeout 720 -R -O $url
sleep 5

#echo "[Step 2] Extract text...\n"
#gzip -d ./*.gz

echo "[Step 3] Create Discovery Circumstances for Stellarium...\n"

cp -f discovery_circumstances.fab discovery_circumstances.previous

./generate_discovery_circumstances.pl

gzip -nc discovery_circumstances.fab > discovery_circumstances.dat

oldFileSize=$(stat -c%s "./discovery_circumstances.previous")
newFileSize=$(stat -c%s "./discovery_circumstances.fab")

echo "[Step 4] Clean up...\n"

rm ./*.txt ./*.previous

if [ $oldFileSize != $newFileSize ]
then
    echo "Discovery Circumstances is changed!\n"
fi