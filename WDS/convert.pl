#!/usr/bin/perl

#
# Tool for create a Stellarium Catalogue of Double Stars
#
# Copyright (C) 2026 Alexander Wolf
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
use Time::Piece;

#$HIPDAT		= "./hipprob.txt";	# WDS - HIP cross-id
$HIPDAT		= "./hipwds.dat";	# WDS - HIP cross-id
$DR3DAT		= "./wds_comp_dr3.txt";	# WDS - Gaia DR3 cross-id
$DR3HIP		= "./gaia-hip.dat";	# Gaia DR3 - HIP cross-id

$CROSSID	= "./extra_name.fab";	# Double Stars IDs
$RESULT		= "./wds.fab";		# WDS catalog for Stellarium

$HDR		= "./format_description.header";

$delimiter = "\t"; # delimiter for columns

%wdscat  = ();
%wdscmd  = ();
%wdshipf = ();
%wdships = ();
%gaiahip = ();

open(WDSHDR, "<:encoding(utf-8)", "$HDR");
@header = <WDSHDR>;
close WDSHDR;

open(WDSDR3, "<:encoding(utf-8)", "$DR3DAT");
@dr3data = <WDSDR3>;
close WDSDR3;

open(GH, "<:encoding(utf-8)", "$DR3HIP");
@dr3hip = <GH>;
close GH;

open(WDSHIP, "<:encoding(utf-8)", "$HIPDAT");
@hipdata = <WDSHIP>;
close WDSHIP;

open (FAB, ">:encoding(utf8)", "$RESULT");

$date = localtime;
$version = "v".$date->ymd("");

for($i=0; $i<scalar(@header);$i++) {
    $text = $header[$i];
    $text =~ s/\$version\$/$version/gi;
    print FAB $text;
}
print FAB "\n";

print "Fetch and parse Gaia DR3 - HIP cross-id list...\n";
for($i=0;$i<scalar(@dr3hip);$i++)
{
	$cxm = $dr3hip[$i];
	if (substr($wdsd, 0, 1) eq '#') { next; }

	($dr3,$hip) = split("|", $cxm);
	$hip	=~ s/\s+//gi;
	$dr3	=~ s/\s+//gi;
	
	if (!exists($gaiahip{$dr3})) {
		$gaiahip{$dr3} = $hip;
	}
}
print "DONE!\n\n";
print "Fetch and parse HIP cross-id catalog...\n";
for($i=0;$i<scalar(@hipdata);$i++)
{
	$wdsd = $hipdata[$i];
	if (substr($wdsd, 0, 1) eq '#') { next; }

#	$hip	= substr($wdsd, 3, 6);
#	$hip	=~ s/\s+//gi;
#	$wds	= substr($wdsd,10,10);
#	$wds	=~ s/\s+//gi;
	$hip	= substr($wdsd, 35, 6);
	$hip	=~ s/\s+//gi;
	$wds	= substr($wdsd,201,10);
	$wds	=~ s/\s+//gi;
	
	if (!exists($wdshipf{$wds})) {
		$wdshipf{$wds} = $hip;
	} elsif (!exists($wdships{$wds})) {
		$wdships{$wds} = $hip;
	}
}
print "DONE!\n\n";
print "Fetch and parse WDS catalog + Gaia DR3 cross-id data...\n";
for($i=0;$i<scalar(@dr3data);$i++)
{
	$wdsd = $dr3data[$i];
	if (substr($wdsd, 0, 1) eq '#') { next; }

	$wds	= substr($wdsd,  0, 10);
	$wds	=~ s/\s+//gi;
	$disc	= substr($wdsd, 10,  7);
	$disc	=~ s/\s+/ /gi;
	$year	= substr($wdsd, 28,  4);
	$year	=~ s/\s+//gi;
	$pa	= substr($wdsd, 38,  6);
	$pa	=~ s/\s+//gi;
	$sep	= substr($wdsd, 46,  7);
	$sep	=~ s/\s+//gi;
	$dr3	= substr($wdsd,138);
	$dr3	=~ s/\s+//gi;
	$dr3	+= 0;
	
	$data = $wds.$delimiter.$year.$delimiter.$pa.$delimiter.$sep;
	
	$hipf = $wdshipf{$wds} + 0;
	$hips = $wdships{$wds} + 0;
	if ($dr3 > 0) {
		$hip  = $gaiahip{$dr3} + 0;
		# HIP has priority
		if ($hip > 0) {
			$starId = $hip;
		} elsif ($hips > 0) {
			$starId = $hips;
		} elsif ($hipf > 0) {
			$starId = $hipf;
		} else {
			$starId = $dr3;
		}
		if (!exists($wdscat{$starId})) {
			$wdscat{$starId} = $starId.$delimiter.$data;
		}
		if (!exists($wdscmd{$starId})) {
			$wdscmd{$starId} = $disc;
		}
	} else {
		if ($hips > 0) {
			$starId = $hips;
		} elsif ($hipf > 0) {
			$starId = $hipf;
		} else {
			$starId = 0;
		}
		
		if ($starId > 0) {
			if (!exists($wdscat{$starId})) {
				$wdscat{$starId} = $starId.$delimiter.$data;
			}
			if (!exists($wdscmd{$starId})) {
				$wdscmd{$starId} = $disc;
			}
		}
	}
}
print "DONE!\n\n";
print "Let's make a list of designations for double stars!\n";
open(CROSS, ">:encoding(utf8)", "$CROSSID");
$jdx = 0;
foreach my $id (sort { $a <=> $b } keys %wdscmd)
{
	$name = $wdscmd{$id};
	$idx = length($id);
	$hips = "";
	for($j=0;$j<(19-$idx);$j++) { $hips .= " "; }

	$len = 3;
	if ($name =~ /STTA/ || $name =~ /STFA/ || $name =~ /STFB/) { $len = 4; }

	$dsd = substr($name, 0, $len);
	$dsd =~ s/\s+//g;
	$num = substr($name, $len);
	$num =~ s/\s+//g;
	# Replace modern designation by obsolete designation
	# according to Burnham's Celestial Handbook and The Cambridge Double Star Atlas
	# for backward compatibility with old atlases (few designations only at the moment)
	$dsd =~ s/STFA/Σ_I/g;
	$dsd =~ s/STFB/Σ_II/g;
	$dsd =~ s/STF/Σ/g;
	$dsd =~ s/BUP/β_pm/g;
	$dsd =~ s/BU/β/g;
	$dsd =~ s/STTA/ΟΣΣ/g;
	$dsd =~ s/STT/ΟΣ/g;
	$dsd =~ s/DUN/Δ/g;
	$dsd =~ s/SEE/λ/g;
	#$dsd =~ s/DAW/δ/g;
	$dsd =~ s/FIN/φ/g;
	#$dsd =~ s/RMK/Rmk/g;
	#$dsd =~ s/SHJ/Sh/g;
	#$dsd =~ s/COU/Cou/g;
	#$dsd =~ s/HDO/HdO/g;
	#$dsd =~ s/LAL/Lal/g;
	#$dsd =~ s/RST/Rst/g;
	#$dsd =~ s/KNT/Knott/g;
	#$dsd =~ s/STN/Stone/g;
	#$dsd =~ s/HWE/Howe/g;
	#$dsd =~ s/BSO/BrsO/g;
	#$dsd =~ s/GLI/Gli/g;
	#$dsd =~ s/MLO/MlbO/g;
	#$dsd =~ s/CPO/CapO/g;
	#$dsd =~ s/COO/CorO/g;
	#$dsd =~ s/SLR/Slr/g;
	#$dsd =~ s/MLR/Mlr/g;
	#$dsd =~ s/ARG/Arg/g;
	#$dsd =~ s/DJU/Dju/g;
	#$dsd =~ s/DON/Don/g;
	#$dsd =~ s/DOO/Doo/g;
	#$dsd =~ s/GLE/Gale/g;
	#$dsd =~ s/HLD/Hld/g;
	#$dsd =~ s/HRG/Hrg/g;
	#$dsd =~ s/KUI/Kui/g;
	#$dsd =~ s/ROE/Roe/g;
	#$dsd =~ s/SEI/Sei/g;
	#$dsd =~ s/SMY/Smyth/g;
	#$dsd =~ s/VOU/Vou/g;
	#$dsd =~ s/WEB/Webb/g;
	#$dsd =~ s/WNC/Wnc/g;
	if (length($dsd)==2)
	{
		#$dsd =~ s/JD/Jc/g;
		#$dsd =~ s/HO/Ho/g;
		#$dsd =~ s/ES/Es/g;
		#$dsd =~ s/HU/Hu/g;
		#$dsd =~ s/AC/AC/g;
		#$dsd =~ s/AG/AG/g;
		#$dsd =~ s/KU/Ku/g;
		#$dsd =~ s/PZ/Pz/g;
		#$dsd =~ s/SE/Se/g;
		#$dsd =~ s/DA/Dawes/g;
		#$dsd =~ s/HJ/h/g;
		$dsd =~ s/HN/H_N/g;
		#$dsd =~ s/H1/H_I/g;
		#$dsd =~ s/H2/H_II/g;
		#$dsd =~ s/H3/H_III/g;
		#$dsd =~ s/H4/H_IV/g;
		#$dsd =~ s/H5/H_V/g;
		#$dsd =~ s/H6/H_VI/g;
		$dsd =~ s/H1/H_1/g;
		$dsd =~ s/H2/H_2/g;
		$dsd =~ s/H3/H_3/g;
		$dsd =~ s/H4/H_4/g;
		$dsd =~ s/H5/H_5/g;
		$dsd =~ s/H6/H_6/g;
	}
	$dsname = $dsd."_".$num;
	print CROSS $hips.$id."|".$dsname.$appdx."\n";
	$jdx++;
}
close CROSS;
print "DONE!\n";
print "-- The list has ".$jdx." entries\n\n";
print "Let's make a WDS catalog for Stellarium!\n";
$idx = 0;
foreach my $id (sort {$a <=> $b} keys %wdscat) 
{
    print FAB $wdscat{$id}."\n";
    $idx++;
}
print "DONE!\n\nWDS catalog for Stellarium has been created!\n";
print "-- Catalog has ".$idx." entries\n\n";

close FAB;
