#!/usr/bin/perl

#
# Tool for create a base_locations.txt and iso3166.tab files for Stellarium
#
# Copyright (C) 2013, 2021 Alexander Wolf
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

use utf8;

$SRC	= "./cities15000.txt";
$CODE	= "./admin1CodesASCII.txt";
$GEOS	= "./regions-geoscheme.tab";
$HDR	= "./base_locations.header";
$ADX	= "./base_locations.appendix";
$ETL	= "./base_locations.extraterrestrial";
$OUT	= "./base_locations.txt";
$ISOS	= "./countryInfo.txt";
$ISOO	= "./iso3166.tab";

open(ALL, "<:encoding(utf8)", "$SRC");
@allData = <ALL>;
close ALL;

open(BLH, "<:encoding(utf8)", "$HDR");
@header = <BLH>;
close BLH;

open(APX, "<:encoding(utf8)", "$ADX");
@appdx = <APX>;
close APX;

open(ETL, "<:encoding(utf8)", "$ETL");
@appet = <ETL>;
close ETL;

open(CC, "<:encoding(utf8)", "$CODE");
@code = <CC>;
close CC;

open(GS, "<:encoding(utf8)", "$GEOS");
@geosch = <GS>;
close GS;

open(ISOSC, "<:encoding(utf8)", "$ISOS");
@isocode = <ISOSC>;
close ISOSC;

%geo = ();
for ($i=0;$i<scalar(@code);$i++)
{
	@gc = split(/\t/, $code[$i]);
	$geo{$gc[0]} = $gc[2];
}

%geoscheme = ();
for ($i=0;$i<scalar(@geosch);$i++)
{
	if (substr($geosch[$i], 0, 1) eq '#') { next; }
	@gsm = split(/\t/, $geosch[$i]);
	@countries = split(/,/, $gsm[3]);
	for($j=0;$j<scalar(@countries);$j++)
	{
		$country = $countries[$j];
		if (length($country)==3) { chop($country); }
		$geoscheme{$country} = $gsm[0];
	}
}

open(ISOOC, ">:encoding(utf8)", "$ISOO");
print ISOOC "# ISO 3166 alpha-2 country codes\n#\n";
print ISOOC "# This file is licensed under a Creative Commons Attribution 4.0 License,\n";
print ISOOC "# see https://creativecommons.org/licenses/by/4.0/\n#\n";
print ISOOC "# This file contains a table of two-letter country codes.  Columns are\n";
print ISOOC "# separated by a single tab.  Lines beginning with '#' are comments.\n";
print ISOOC "# All text uses UTF-8 encoding.  The columns of the table are as follows:\n#\n";
print ISOOC "# 1.  ISO 3166-1 alpha-2 country code.\n";
print ISOOC "# 2.  The usual English name for the coded region,\n";
print ISOOC "#     chosen so that alphabetic sorting of subsets produces helpful lists.\n";
print ISOOC "#     This is not the same as the English name in the ISO 3166 tables.\n#\n";
print ISOOC "# See: http://download.geonames.org/export/dump/countryInfo.txt\n#\n";
for ($i=0;$i<scalar(@isocode);$i++)
{
	if (substr($isocode[$i], 0, 1) eq '#') { next; }
	@iso = split(/\t/, $isocode[$i]);
	print ISOOC $iso[0]."\t".$iso[4]."\n";
}
close ISOOC;

open(OUT, ">:encoding(utf8)", "$OUT");
for($i=0;$i<scalar(@header);$i++)
{
	print OUT $header[$i];
}
for($i=0;$i<scalar(@allData);$i++)
{
	@item = split(/\t/, $allData[$i]);
	$latn = $item[4]+0;
	$lonn = $item[5]+0;
	if ($latn>=0) { $lat = $latn."N"; } else { $lat = abs($latn)."S"; }
	if ($lonn>=0) { $lon = $lonn."E"; } else { $lon = abs($lonn)."W"; }
	if ($item[7] eq "PPLC") {
		$type = "C";
	} elsif ($item[7] eq "PPLA") {
		$type = "R";
	} else {
		$type = "N";
	}
	$population = $item[14]/1000;
	if ($population >= 1000)
	{
		$pollution = 9;
	} elsif ($population >= 500) {
		$pollution = 8;
	} elsif ($population >= 100) {
		$pollution = 7;
	} elsif ($population >= 50) {
		$pollution = 6;
	} elsif ($population >= 10) {
		$pollution = 5;
	} elsif ($population >= 5) {
		$pollution = 4;
	} else {
		$pollution = '';
	}
	$country = $item[8];
	if ($country eq 'RU') 
	{
		# Special case: Russia (Northern Asia / Eastern Europe)
		if ($lonn>=60) { $geodata = 11; } else { $geodata = 17; }
	} elsif ($country eq 'US') {
		# Special case: United States ( Polynesia / Northern America )
		if ($geo{$item[8].".".$item[10]} eq 'Hawaii') { $geodata = 24; } else { $geodata = '09'; }
	} else {
		$geodata = $geoscheme{$country};
	}
	if ($geodata eq '') 
	{ 
		$geodata = $country; 
		print $item[2]." (".$geo{$item[8].".".$item[10]}."): ".$country."\n";
	}
	#$country =~ tr/[A-Z]+/[a-z]/;
	#print OUT join("\t", $item[2], $geo{$item[8].".".$item[10]}, $country, $type, $population, $lat, $lon, $item[16], $pollution, $item[17], "", "")."\n";
	print OUT join("\t", $item[2], $geo{$item[8].".".$item[10]}, $geodata, $type, $population, $lat, $lon, $item[16], $pollution, $item[17])."\n";
}
for($i=0;$i<scalar(@appdx);$i++)
{
	@sitem = split(/\t/, $appdx[$i]);
	$lat = $sitem[5];
	$lon = $sitem[6];
	if ($lat =~ m/N/gi) {
		$latn =~ s/N//;
		$latn += 0;
	} else {
		$latn =~ s/S//;
		$latn += 0;
		$latn *= -1;
	}
	if ($lon =~ m/E/gi) {
		$lonn =~ s/E//;
		$lonn += 0;
	} else {
		$lonn =~ s/W//;
		$lonn += 0;
		$lonn *= -1;
	}

	$country = uc($sitem[2]);
	if ($country eq 'RU') 
	{
		# Special case: Russia (Northern Asia / Eastern Europe)
		if ($lonn>=60) { $geodata = 11; } else { $geodata = 17; }
	} elsif ($country eq 'US') {
		# Special case: United States ( Polynesia / Northern America )
		if ($sitem[1] eq 'Hawaii') { $geodata = 24; } else { $geodata = '09'; }
	} else {
		$geodata = $geoscheme{$country};
	}
	if ($geodata eq '') 
	{ 
		$geodata = $country; 
	}
	$sitem[2] = $geodata;
	print OUT join("\t", @sitem);
}
print OUT "#\n# extraterrestrial locations\n#\n";
for($i=0;$i<scalar(@appet);$i++)
{
	print OUT $appet[$i];
}

close OUT;
