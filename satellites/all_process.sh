#!/bin/sh

urllist="./sources.url"

echo "[Step 1] Downloading files...\n"
while URL= read -r url; do
    if [ ! -z "$url" ]; then
        echo "Processing $url"
        curl -# --retry 3 --connect-timeout 720 -R -O $url
        sleep 5
    fi
done < "$urllist"

echo "[Step 2] Extract standard magnitudes...\n"
for f in ./*.zip; do
    echo "Processing $f"
    rm qs.mag
    unzip -o $f
done

echo "\n[Step 3] Create satellites.fab file for Stellarium...\n"

cp -f satellites.fab satellites.previous

./generate_satellites_data.pl

gzip -nc satellites.fab > satellites.dat

oldFileSize=$(stat -c%s "./satellites.previous")
newFileSize=$(stat -c%s "./satellites.fab")

echo "[Step 4] Clean up...\n"

rm -rf ./*.zip ./satellites.previous

if [ $oldFileSize != $newFileSize ]
then
    echo "Satellites data is changed!\n"
fi
