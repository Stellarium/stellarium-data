#!/bin/sh

urllist="../nomenclature.url"
sdir="./source"
dbf="./dbf/"
mkdir -p $sdir
mkdir -p $dbf

echo "[Step 1] Downloading files...\n"
cd "$sdir/"
while URL= read -r url; do
    if [ ! -z "$url" ]; then
        echo "Processing $url"
        curl -# --retry 3 --connect-timeout 720 -R -O $url
        sleep 5
    fi
done < "$urllist"

cd ..
echo "[Step 2] Extract DBF files...\n"
for f in "$sdir"/*; do
    echo "Processing $f"
    unzip -o $f '*.dbf' -d $dbf
done

echo "[Step 3] Create nomenclature files for Stellarium...\n"

cp -f nomenclature.fab nomenclature.previous
cp -f nomenclature-origins.fab nomenclature-origins.previous

./generate_nomenclature.pl

gzip -nc nomenclature.fab > nomenclature.dat
gzip -nc nomenclature-origins.fab > nomenclature-origins.dat

oldFileSize=$(stat -c%s "./nomenclature.previous")
newFileSize=$(stat -c%s "./nomenclature.fab")

echo "[Step 3] Clean up...\n"

rm -rf $sdir $dbf ./nomenclature.previous ./nomenclature-origins.previous

if [ $oldFileSize != $newFileSize ]
then
    echo "Nomenclature is changed!\n"
fi