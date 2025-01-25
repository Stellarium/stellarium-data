#!/bin/sh

url_gcvs="http://www.sai.msu.su/gcvs/gcvs/gcvs5/gcvs5.txt"
#url_remarks="http://www.sai.msu.su/gcvs/gcvs/gcvs5/remark.txt"

rm ./*.txt

echo "[Step 1] Downloading data..."

echo "-- processing GCVS 5.1 catalog ($url_gcvs)";
curl -# --retry 3 --connect-timeout 720 -R -O $url_gcvs
sleep 5

#echo "-- processing remarks for GCVS 5.1 ($url_remarks)";
#curl -# --retry 3 --connect-timeout 720 -R -O $url_remarks
#sleep 5

echo "[Step 2] Fetch HIP/Gaia3 ID's..."
./get-identifiers.pl

echo "[Step 3] Create GCVS catalog for Stellarium..."

cp -f gcvs.fab gcvs.previous
./convert.pl
gzip -nc gcvs.fab > gcvs.cat

oldFileSize=$(stat -c%s "./gcvs.previous")
newFileSize=$(stat -c%s "./gcvs.fab")

echo "[Step 4] Clean up..."

rm ./*.previous

if [ $oldFileSize != $newFileSize ]
then
    echo "-- GCVS Catalogue Updated!\n"
fi