#!/usr/bin/perl

#
# Tool for create a Stellarium Catalogue of Variable Stars
#
# Copyright (C) 2013, 2019, 2025 Alexander Wolf
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

$SRC = "./gcvs-hip-gaia.dat";         # Source
$DST = "./gcvs.fab";                  # Destination
$HDR = "./format_description.header"; # Headers

$delimiter = "\t"; # delimiter for columns
$formatOutput = 0; # formatting output

open (HEADER, "<:encoding(utf8)", "$HDR");
@header = <HEADER>;
close HEADER;

open (FAB, ">:encoding(utf8)", "$DST");
open (DAT, "<:encoding(utf8)", "$SRC");

$date = localtime;
$version = "5.1-".$date->ymd("");

for($i=0; $i<scalar(@header);$i++) {
    $text = $header[$i];
    $text =~ s/\$version\$/$version/gi;
    print FAB $text;
}
print FAB "\n";

$stars = "";

while (<DAT>) {
    $rawstring = $_;
    $hipstr = substr($rawstring,0,20);
    $designationstr = substr($rawstring,29,9);
    $coordstr = substr($rawstring,41,10);
    $vclassstr = substr($rawstring,62,9);
    $maxmagstr = substr($rawstring,73,7);
    $ampflagstr = substr($rawstring,83,1);
    $min1magstr = substr($rawstring,84,6);
    $min2magstr = substr($rawstring,97,6);
    $flagstr = substr($rawstring,109,2);
    $epochstr = substr($rawstring,112,10);
    $periodstr = substr($rawstring,132,16);
    $mmstr = substr($rawstring,152,2);
    $sclassstr = substr($rawstring,158,16);

    $hipstr =~ s/(\s+)//gi;
    $designationstr =~ s/(\s+)/ /gi;
    $coordstr =~ s/(\s+)//gi;
    $vclassstr =~ s/(\s+)//gi;
    $maxmagstr =~ s/(\s+)//gi;
    $min1magstr =~ s/(\s+)//gi;
    $min2magstr =~ s/(\s+)//gi;
    $epochstr =~ s/(\s+)//gi;
    $periodstr =~ s/(\s+)//gi;
    $mmstr =~ s/(\s+)//gi;
    $sclassstr =~ s/(\s+)//gi;
    $flagstr =~ s/(\s+)//gi; 

    $designationstr =~ s/alf/α/;
    $designationstr =~ s/bet/β/;
    $designationstr =~ s/gam/γ/;
    $designationstr =~ s/del/δ/;
    $designationstr =~ s/eps/ε/;
    $designationstr =~ s/zet/ζ/;
    $designationstr =~ s/eta/η/;
    $designationstr =~ s/the/θ/;
    $designationstr =~ s/tet/θ/; # typo
    $designationstr =~ s/iot/ι/;
    $designationstr =~ s/kap/κ/;
    $designationstr =~ s/lam/λ/;
    $designationstr =~ s/mu./μ/;
    $designationstr =~ s/nu./ν/;
    $designationstr =~ s/xi./ξ/;
    $designationstr =~ s/omi/ο/;
    $designationstr =~ s/pi./π/;
    $designationstr =~ s/rho/ρ/;
    $designationstr =~ s/sig/σ/;
    $designationstr =~ s/tau/τ/;
    $designationstr =~ s/ups/υ/;
    $designationstr =~ s/phi/φ/;
    $designationstr =~ s/ksi/ξ/;
    $designationstr =~ s/khi/χ/;
    $designationstr =~ s/psi/ψ/;
    $designationstr =~ s/ome/ω/;
    $designationstr =~ s/V0/V/; # remove leading zero

    $ampflag = 0;
    if ($ampflagstr eq '(') {
	$ampflag = 1;
    }
    if ($ampflagstr eq '<') {
	$ampflag = 2;
    }
    if ($ampflagstr eq '>') {
	$ampflag = 3;
    }
    
    if ($formatOutput) {
        $hipstr 	= sprintf("%19d", $hipstr);
        $designationstr	= sprintf( "%9s", $designationstr);
        $vclassstr	= sprintf( "%9s", $vclassstr);
        $maxmagstr	= sprintf( "%5s", sprintf("%2.2f", $maxmagstr));
        $min1magstr	= sprintf( "%5s", $min1magstr);
        $min2magstr	= sprintf( "%5s", $min2magstr);
        $flagstr	= sprintf( "%2s", $flagstr);
        $epochstr	= sprintf("%10s", $epochstr);
        $periodstr	= sprintf("%12s", $periodstr);
        $mmstr		= sprintf( "%2s", $mmstr);
    }
    
    # skip variable stars without coordinates and synonyms
    if (length($coordstr)>0 && index($stars, "{".$hipstr."}")<0) {
	print FAB $hipstr.$delimiter.$designationstr.$delimiter.$vclassstr.$delimiter.$maxmagstr.$delimiter.$ampflag.$delimiter.$min1magstr.$delimiter.$min2magstr.$delimiter.$flagstr.$delimiter.$epochstr.$delimiter.$periodstr.$delimiter.$mmstr.$delimiter.$sclassstr."\n";
    }
    $stars .= "{".$hipstr."}";
}
close FAB;
close DAT;
