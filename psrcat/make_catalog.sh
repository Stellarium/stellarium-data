#!/bin/sh

catalog=psrcat_tar
archive=psrcat_pkg.tar.gz

currentCatalogSize=$(stat -c%s "./pulsars.json")

echo "[Step 1] Downloading file...\n"
curl -# --retry 3 --connect-timeout 720 -R -O https://www.atnf.csiro.au/research/pulsar/psrcat/downloads/psrcat_pkg.tar.gz
sleep 5
echo "[Step 2] Extract files...\n"
tar -zxvf $archive
echo "[Step 3] Parse catalog and generate JSON...\n"
./psrcat2json.pl
echo "[Step 4] Remove unused data...\n";
rm -rf $catalog
rm -f $archive
echo "[Step 5] Validate catalog...\n";
#jsonlint-py3 -v ./pulsars.json
jsonlint -v ./pulsars.json

updatedCatalogSize=$(stat -c%s "./pulsars.json")

if [ $currentCatalogSize != $updatedCatalogSize ]
then
    echo "\n\n[***] Catalog is changed!\n"
fi