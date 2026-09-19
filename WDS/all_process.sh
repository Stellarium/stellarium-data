#!/bin/sh

echo "[Step 3] Create WDS catalog for Stellarium..."

cp -f wds.fab wds.previous
./convert.pl
gzip -nc wds.fab > wds.cat
gzip -nc extra_name.fab > extra_name.cat

oldFileSize=$(stat -c%s "./wds.previous")
newFileSize=$(stat -c%s "./wds.fab")

echo "[Step 4] Clean up..."

rm ./*.previous

if [ $oldFileSize != $newFileSize ]
then
    echo "-- WDS Catalogue Updated!\n"
fi