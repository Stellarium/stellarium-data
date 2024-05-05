#!/usr/bin/perl
#
# This is tool to extract standard magnitudes and radar cross-section (RCS) data from the various
# files, which are distributed on Make McCants' web page (https://mmccants.org), MMT-9 observatory 
# (http://mmt.favor2.info/satellites), and CelesTrack web page (https://celestrak.org)
#
# Copyright (c) 2024 Alexander Wolf
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

use strict;

# data
my $stdmagFile	= "./qs.mag";
my $RCSFile	= "./rcs";
my $MMTFile	= "./download";
my $SCFile	= "./satcat.txt";
# templates
my $headerFile	= "./header.tmpl";
# results
my $satDFile	= "./satellites.fab";

my %satellites	= ();
my $delimiter	= "\t";

my @header;
open(TMPL, "<$headerFile");
@header = <TMPL>;
close TMPL;

# read standard magnitudes from quickmag file (Mike McCants)
my @stdmagdata;
open(SMD, "<$stdmagFile");
@stdmagdata = <SMD>;
close SMD;

for(my $i=1; $i<scalar(@stdmagdata); $i++)
{
    my $data  = $stdmagdata[$i];
    my $NORAD = substr($data, 0, 5);
    my $magd  = substr($data, 33, 4);
    my $rcsd  = substr($data, 50, 5);
    $NORAD    = $NORAD+0;
    $magd     =~ s/\s+//gi;
    $rcsd     =~ s/\s+//gi;
    if ($NORAD!=99999)
    {
	$satellites{$NORAD} = $magd."::".$rcsd;
    }
}

# read radar cross-section (RCS) data from rcs file (Mike McCants)
my @rcsdata;
open(RCS, "<$RCSFile");
@rcsdata = <RCS>;
close RCS;

for(my $j=0; $j<scalar(@rcsdata); $j++)
{
    my $data  = $rcsdata[$j];
    my $NORAD = substr($data, 0, 5);
    my $rcsd  = substr($data, 5, 5);
    $NORAD =~ s/\s+//gi;
    $rcsd  =~ s/\s+//gi;
    if (exists $satellites{$NORAD})
    {
	my @val = split("::", $satellites{$NORAD});
	if ($val[1] eq '')
	{
	    $satellites{$NORAD} = $val[0]."::".$rcsd;
	}
    } else {
	$satellites{$NORAD} = "::".$rcsd;
    }
}

# read standard magnitudes from MMT-9
my @mmtdata;
open(MMT, "<$MMTFile");
@mmtdata = <MMT>;
close MMT;

for(my $i=0; $i<scalar(@mmtdata); $i++)
{
    my $data  = $mmtdata[$i];
    if (substr($data, 0, 1) eq '#') 
    { 
	next;
    }
    if ($data =~ m/^(NORAD|McCants)\s(\d+)\s\"(.+)\"\s\w+\s\d\s\d\s([\.\d]+)\s/)
    {
	my $NORAD = $2;
	my $mag   = $4;
	if (not exists $satellites{$NORAD})
	{
	    $satellites{$NORAD} = $mag."::";
	}
    }
}

# read radar cross section (RCS) from CelesTrack
my @scdata;
open(SCF, "<$SCFile");
@scdata = <SCF>;
close SCF;

for(my $i=0; $i<scalar(@scdata); $i++)
#for(my $i=0; $i<25; $i++)
{
    my $data  = $scdata[$i];
    my $NORAD = substr($data, 13, 5);
    my $rcsd  = substr($data, 119, 8);
    $NORAD    = $NORAD+0;
    $rcsd     =~ s/\s+//gi;
    $rcsd     =~ s/N\/A/-/gi;
    if ($rcsd ne '-' && $rcsd ne '')
    {
	if (exists $satellites{$NORAD})
	{
	    my @val = split("::", $satellites{$NORAD});
	    $satellites{$NORAD} = $val[0]."::".$rcsd;
	} else {
	    $satellites{$NORAD} = "::".$rcsd;
	}
    }
}

# write satellites.fab file (joint data)
open(FAB, ">$satDFile");
for(my $k=0; $k<scalar(@header); $k++) 
{
    print FAB $header[$k];
}
print FAB "\n";

foreach my $sat (sort { $a <=> $b } keys %satellites) 
{
    my $noradID = sprintf("%6d", $sat);
    my @dat = split("::", $satellites{$sat});
    my $magID   = ($dat[0] eq '') ? sprintf "%8s" , $dat[0] : sprintf "%8s" , (sprintf "%.4f", $dat[0]);
    my $rcsID   = ($dat[1] eq '') ? sprintf "%8s" , $dat[1] : sprintf "%8s" , (sprintf "%.4f", $dat[1]);
    if ($dat[0] ne '' || $dat[1] ne '')
    {
	print FAB $noradID.$delimiter.$magID.$delimiter.$rcsID."\n";
    }
}

close FAB;

