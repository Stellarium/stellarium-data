#!/usr/bin/perl -w

#
# Tool for generate catalog of pulsars
#
# Copyright (C) 2012-2020 Alexander Wolf
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


#
# read psrcat.db from ATNF Pulsar Catalogue and convert to JSON
# URL: http://www.atnf.csiro.au/research/pulsar/psrcat/download.html
#
use Math::Trig;

$PSRCAT	= "./psrcat_tar/psrcat.db";
$JSON	= "./pulsars.json";
$NAMES	= "./propernames.lst";

$FORMAT = 2;

# Use tab char for reduce the file size
$tab1   = "\t";
$tab2   = $tab1.$tab1;
$tab3   = $tab2.$tab1;

open (PSRN, "<$NAMES");
@psrnames = <PSRN>;
close PSRN;

%psrname = ();
for ($i=0;$i<scalar(@psrnames);$i++) {
	$s = $psrnames[$i];
	chomp $s;
	($key,$value) = split('\|', $s);
	$psrname{$key} = $value;
}

open (PSRCAT, "<$PSRCAT");
@catalog = <PSRCAT>;
close PSRCAT;

$psrcat = "";
foreach $s (@catalog) {
	$psrcat .= $s;
}

$version = $catalog[0];
$version =~ m/CATALOGUE\s+([\d\.]+)/gi;
$CATVER = $1;
$CATVER =~ s/\s+//gi;

@cat = split("@\-\-\-",$psrcat);

open (JSON, ">$JSON");
print JSON "{\n";
print JSON $tab1."\"version\": \"".$FORMAT."\",\n";
print JSON $tab1."\"shortName\": \"A catalogue of pulsars, based on ATNF Pulsar Catalogue v".$CATVER."\",\n";
print JSON $tab1."\"originalCatalogURL\": \"http://www.atnf.csiro.au/research/pulsar/psrcat/\",\n";
print JSON $tab1."\"pulsars\":\n";
print JSON $tab1."{\n";

%psrnameslist = ();
for ($i=0;$i<scalar(@cat)-1;$i++) {
	@lines = split("\n", $cat[$i]);
	$period = 0;
	$pderivative = 0;
	$bperiod = 0;
	$parallax = 0;
	$dmeasure = 0;
	$frequency = 0;
	$pfrequency = 0;
	$eccentricity = 0;
	$w50 = 0;
	$s400 = 0;
	$s600 = 0;
	$s1400 = 0;
	$distance = 0;
	$outRA = "";
	$outDE = "";
	$pmRA = "";
	$pmDE = "";
	$elat = "";
	$elong = "";
	$flag = 0;
	$notes = "";
	$glitch = 0;
	$psrbname = "";
	for ($j=0;$j<scalar(@lines);$j++) {
		if ($lines[$j] =~ /^PSRB(\s+)B([\d]{4})([\+\-]{1})([\d]{2,4})([\w]{0,1})(\s+)/) {
			$psrbname = "PSR B".$2.$3.$4.$5;
		}

		if ($lines[$j] =~ /^PSRJ(\s+)J([\d]{4})([\+\-]{1})([\d]{2,4})([\w]{0,1})(\s+)/) {
			$name = $2.$3.$4.$5;
			$flag = 1;
		}

		if ($lines[$j] =~ /^ELONG(\s+)([\d\.]+)/) {
			$elong = $2;
		}

		if ($lines[$j] =~ /^ELAT(\s+)([\d\-\+\.]+)/) {
			$elat = $2;
		}

		if ($lines[$j] =~ /^RAJ(\s+)([\d\-\+\:\.]+)/) {
			$secf = 0;
			($hour,$min,$sec) = split(":",$2);
			$min += 0;
			if ($min!=int($min)) { $secf = $min-int($min); $secf *= 60; $min = int($min); }
			if ($min<10) { $min = "0".$min; }
			$sec += $secf;
			if ($sec<10) { $sec = "0".$sec; }
			$outRA = $hour."h".$min."m".$sec."s";
		}

		if ($lines[$j] =~ /^DECJ(\s+)([\d\-\+\:\.]+)/) {
			$secf = 0;
			($deg,$min,$sec) = split(":",$2);
			$min += 0;
			if ($min!=int($min)) { $secf = $min-int($min); $secf *= 60; $min = int($min); }
			if ($min<10) { $min = "0".$min; }
			$sec += $secf;
			if ($sec<10) { $sec = "0".$sec; }
			$outDE = $deg."d".$min."m".$sec."s";
		}
		
		if ($lines[$j] =~ /^PMRA(\s+)([\-\+\d\.]+)\s+/) {
			$pmRA = $2 + 0.0;
		}
		
		if ($lines[$j] =~ /^PMDEC(\s+)([\-\+\d\.]+)\s+/) {
			$pmDE = $2 + 0.0;
		}

		if ($lines[$j] =~ /^P0(\s+)([\d\.]+)/) {
			$period = $2;
		}

		if ($lines[$j] =~ /^P1(\s+)([\d\.\-E]+)/) {
			$pderivative = $2;
		}

		if ($lines[$j] =~ /^PB(\s+)([\d\.]+)/) {
			$bperiod = $2;
		}

		if ($lines[$j] =~ /^F0(\s+)([\d\.]+)/) {
			$frequency = $2;
		}

		if ($lines[$j] =~ /^F1(\s+)([\d\.\-E]+)/) {
			$pfrequency = $2;
		}

		if ($lines[$j] =~ /^W50(\s+)([\d\.]+)/) {
			$w50 = $2 + 0.0;
		}

		if ($lines[$j] =~ /^S400(\s+)([\d\.]+)/) {
			$s400 = $2 + 0.0;
		}

		if ($lines[$j] =~ /^S600(\s+)([\d\.]+)/) {
			$s600 = $2 + 0.0;
		}

		if ($lines[$j] =~ /^S1400(\s+)([\d\.]+)/) {
			$s1400 = $2 + 0.0;
		}

		if ($lines[$j] =~ /^PX(\s+)([\d\.]+)/) {
			$parallax = $2 + 0.0;
		}

		if ($lines[$j] =~ /^DM(\s+)([\d\.]+)/) {
			$dmeasure = $2;
		}

		if ($lines[$j] =~ /^DIST_DM1(\s+)([\d\.\+\-]+)/) {
			$distance = $2;
			$distance =~ s/\+//gi;
		}

		if ($lines[$j] =~ /^ECC(\s+)([\d\.\-E]+)/) {
			$eccentricity = $2;
		}

		if ($lines[$j] =~ /^TYPE(\s+)([\w\,]+)/)
		{
			$notes = $2;
		}

		if ($lines[$j] =~ /^NGLT(\s+)([\d]+)/)
		{
			$glitch = $2;
		}
	}

	if (exists($psrnameslist{$name})) {
		next;
	} else {
		$psrnameslist{$name} = 1;
	}

	$jname = "J".$name;
	$out  = $tab2."\"PSR ".$jname."\":\n";
	$out .= $tab2."{\n";
	if (exists $psrname{$jname}) {
		$out .= $tab3."\"name\": \"".$psrname{$jname}."\",\n";
	}
	if ($psrbname ne '') {
		$out .= $tab3."\"bdesignation\": \"".$psrbname."\",\n";
	}
	if ($parallax > 0) {
		$out .= $tab3."\"parallax\": ".$parallax.",\n";
	}
	if ($distance > 0) {
		$out .= $tab3."\"distance\": ".$distance.",\n";
	}
	if ($period > 0) {
		$out .= $tab3."\"period\": ".$period.",\n";
	}
	if ($bperiod > 0) {
		$out .= $tab3."\"bperiod\": ".$bperiod.",\n";
	}
	if ($eccentricity > 0) {
		$out .= $tab3."\"eccentricity\": ".$eccentricity.",\n";
	}
	if ($pderivative != 0) {
		$out .= $tab3."\"pderivative\": ".$pderivative.",\n";
	}
	if ($dmeasure > 0) {
		$out .= $tab3."\"dmeasure\": ".$dmeasure.",\n";
	}
	if ($frequency > 0) {
		$out .= $tab3."\"frequency\": ".$frequency.",\n";
	}
	if ($pfrequency != 0) {
		$out .= $tab3."\"pfrequency\": ".$pfrequency.",\n";
	}
	if ($w50 > 0) {
		$out .= $tab3."\"w50\": ".$w50.",\n";
	}
	if ($s400 > 0) {
		$out .= $tab3."\"s400\": ".$s400.",\n";
	}
	if ($s600 > 0) {
		$out .= $tab3."\"s600\": ".$s600.",\n";
	}
	if ($s1400 > 0) {
		$out .= $tab3."\"s1400\": ".$s1400.",\n";
	}
	if ($glitch > 0) {
		$out .= $tab3."\"glitch\": ".$glitch.",\n";
	}
	if ($notes ne '')
	{
		$out .= $tab3."\"notes\": \"".$notes."\",\n";
	}
	if (($outRA ne '') && ($outDE ne ''))
	{
		if ($pmRA ne '') {
			$out .= $tab3."\"pmRA\": ".$pmRA.",\n";
		}
		if ($pmDE ne '') {
			$out .= $tab3."\"pmDE\": ".$pmDE.",\n";
		}
		$out .= $tab3."\"RA\": \"".$outRA."\",\n";
		$out .= $tab3."\"DE\": \"".$outDE."\"\n";
	} 
	elsif (($elat ne '') && ($elong ne ''))
	{
		$coseps = 0.91748213149438;
		$sineps = 0.39777699580108;
		$deg2rad = pi / 180.0; # deg2rad
		$sdec   = sin($elat * $deg2rad) * $coseps + cos($elat * $deg2rad) * $sineps * sin($elong * $deg2rad);
		$dec    = asin($sdec); # in radians
		$cos_ra = ( cos($elong * $deg2rad) * cos($elat * $deg2rad) / cos($dec) );
		$sin_ra = ( sin($dec) * $coseps - sin($elat * $deg2rad) ) / (cos($dec) * $sineps);
		$ra     = atan2($sin_ra, $cos_ra); # in radians
		if ($ra < 0.0) {
			$ra = 2 * pi + $ra;
		} elsif ($ra > 2 * pi) {
			$ra = $ra - 2 * pi;
		}
		$RA = $ra / (2.0 * pi); # by dividing by 2PI of radians you obtain number of turns
		$Dec = $dec / (2.0 * pi); # by dividing by 2PI of radians you obtain number of turns
		$rahh = $RA * 24.0;
		$ramm = ($rahh - int($rahh)) * 60.0;
		$rasec = ($ramm - int($ramm)) * 60.0;
		$raisec = ($rasec * 10000.0 + 0.5) / 10000;
		if ($raisec == 60) {
			$rasec = 0.0;
			$ramm = $ramm + 1;
			if ($ramm == 60) {
				$ramm = 0;
				$rahh = $rahh + 1;
				if ($rahh == 24) {
					$rahh = 0;
				}
			}
		}
		$outRA = sprintf("%02dh%02dm%05.3fs",$rahh, $ramm, $rasec);
		if ($Dec < 0.0) {
			$sign = -1;
		} else {
			$sign = 1;
		}
		$dd = $Dec * 360.;
		$mm = abs($dd - int($dd)) * 60.;
		$sec = ($mm - int($mm)) * 60.0;
		$isec = ($sec * 1000.0 + 0.5) / 1000;
		if ($isec == 60){
			$sec = 0.;
			if ($sign == 1) {
				$mm = $mm + 1;
			} else {
				$mm = $mm - 1;
			}
			if ($mm == 60) {
				$mm = 0;
				if ($sign == 1) {
					$dd = $dd + 1;
				} else {
					$dd = $dd - 1;
				}
			}
		}
		if ($pmRA ne '') {
			$out .= $tab3."\"pmRA\": ".$pmRA.",\n";
		}
		if ($pmDE ne '') {
			$out .= $tab3."\"pmDE\": ".$pmDE.",\n";
		}
		$outDE = sprintf("%02dd%02dm%05.3fs",$dd,$mm,$sec);
		$out .= $tab3."\"RA\": \"".$outRA."\",\n";
		$out .= $tab3."\"DE\": \"".$outDE."\"\n";
	}
	$out .= $tab2."}";
	if ($i<scalar(@cat)-2) {
		$out .= ",";
	}
	if (($outRA ne '') && ($outDE ne '') || (($elat ne '') && ($elong ne '')) && ($flag == 1)) {
		print JSON $out."\n";
	}
}

print JSON $tab1."}\n}\n";

close JSON;
