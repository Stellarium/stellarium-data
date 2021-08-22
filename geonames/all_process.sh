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

./convert.pl

oldFileSize=$(stat -c%s "./base_locations.previous")
newFileSize=$(stat -c%s "./base_locations.txt")
if [ $oldFileSize != $newFileSize ]
then
    echo "base_locations.txt is changed!\n"
fi

rm -f ./base_locations.previous