#!/bin/sh

urllist="./geonames.url"

echo "[Step 1] Downloading files...\n"
while URL= read -r url; do
    if [ ! -z "$url" ]; then
        echo "Processing $url"
        curl -# --retry 3 --connect-timeout 720 -R -O $url
        sleep 5
    fi
done < "$urllist"

echo "[Step 2] Extract TXT file...\n"
unzip -o '*.zip'

echo "[Step 3] Create base_locations.txt file for Stellarium...\n"

cp -f base_locations.txt base_locations.previous
cp -f iso3166.tab iso3166.previous

./convert.pl

oldFileSize=$(stat -c%s "./base_locations.previous")
newFileSize=$(stat -c%s "./base_locations.txt")
oldISOFileSize=$(stat -c%s "./iso3166.previous")
newISOFileSize=$(stat -c%s "./iso3166.tab")

echo "[Step 4] Removing temporary files...\n"

rm -f ./base_locations.previous ./iso3166.previous ./cities15000.zip

echo "[Step 5] Done!";

if [ $oldFileSize != $newFileSize ]
then
    echo "...The file base_locations.txt changed!"
fi
if [ $oldISOFileSize != $newISOFileSize ]
then
    echo "...The file iso3166.tab changed!"
fi
