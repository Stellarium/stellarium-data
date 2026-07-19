#!/usr/bin/perl

#
# Tool for create a Stellarium Catalogue of Variable Stars
#
# Copyright (C) 2013, 2015, 2019, 2025 Alexander Wolf
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


use LWP::UserAgent;

$GCVS   = "./gcvs5.txt"; 	# GCVS
$HIPV	= "./gcvs-hip-gaia.dat";
$LOGF	= "./log.txt";
$fpart 	= "https://simbad.u-strasbg.fr/simbad/sim-basic?Ident=";
$lpart 	= "&submit=SIMBAD+search";

$pausec  = 5; # pause in seconds between chunks of requests
$pausep  = 1; # pause in seconds between requests of pages

$ua = LWP::UserAgent->new(keep_alive=>1, timeout=>180);

$ua->agent("Opera/9.80 (X11; Linux i686; U; ru) Presto/2.9.168 Version/11.50");

$i = 0;
$record = 0;
$process = 0;
$err = 0;

open (LOG, ">$LOGF");
open (OUT, ">$HIPV");
open (GV, "$GCVS");
while (<GV>) {
    $i++;
    $rawstring = $_;

    if ($rawstring =~ m/^(\d+)\s+/) { $record++; }

    $designation = substr($rawstring,8,9);
    $designation =~ s/[ ]{1,}/+/gi;

    $URL = $fpart.$designation.$lpart;

    $request = HTTP::Request->new('GET', $URL);
    $responce = $ua->request($request);
    $content = $responce->content;

    $content =~ m/>HIP<\/A> (\d+)/gi;
    $hipn = $1;
    $d = "H";

    if(length($hipn)==0) {
	$content =~ m/>Gaia<\/A> DR3 (\d+)/gi;
	$d = "G";
	$hipn = $1;
    }
    chomp($hipn);

    $len = length($hipn);
    if ($len>0) {
	$process++;
	$hip = sprintf("%21d", $hipn);
	$s = "+";
	print OUT $hip."|".$rawstring;
    } else {
	$s = "!";
	$err++;
    }

    print LOG sprintf("%12s",$designation)." ".$d."".sprintf("%21d", $hipn)." ".sprintf("%2d", $len)." ".$s." [".$URL."]\n";
    LOG->flush();

    if ($i==10) {
	$i = 0;
	sleep $pausec;
	print LOG ":------------------------------------: ".$err."\n";
	$err = 0;
	OUT->flush();
    } else {
	sleep $pausep;
    }
}
close GV;
close OUT;
close LOG;

$percent = sprintf("%3.2f", 100.0*($process/$record));
print "\nProcessed ".$percent."% of CGVS 5.1 (".$process."/".$record." stars)\n";