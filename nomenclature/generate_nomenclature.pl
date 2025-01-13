#!/usr/bin/perl
#
# This is tool to extract nomenclature data from the DBF files, which are 
# distributed on the web page https://planetarynames.wr.usgs.gov
#
# Please extract all DBF files from archives into this directory and run the tool.
#
# Copyright (c) 2017, 2018, 2019, 2023 Alexander Wolf
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
use DBI;
use DBD::XBase;

my @dbfiles;
my $dbf="./dbf/";

opendir(DIR, "$dbf") or die "can't open dir: $dbf";
while(defined(my $file = readdir(DIR))) {
    if ($file =~ /\.dbf$/) { push @dbfiles, $file; }
}

my @header;
#open(TMPL, "<:encoding(UTF-8)", "./header.tmpl");
open(TMPL, "<./header.tmpl");
@header = <TMPL>;
close TMPL;

# Some objects do not have DBF for nomenclature; let's use extra file for it
my @extra;
#open(TMPL, "<:encoding(UTF-8)", "./nomenclature.extra");
open(TMPL, "<./nomenclature.extra");
@extra = <TMPL>;
close TMPL;

#open(FAB, ">:encoding(UTF-8)", "./nomenclature.fab");
open(FAB, ">./nomenclature.fab");
for(my $j=0;$j<scalar(@header);$j++) {
    print FAB $header[$j];
}
print FAB "\n";

open(NOTE, ">./nomenclature.warning");
print NOTE "#\n# WARNING: the truncated origin statements\n#\n";

open(TYPO, ">./nomenclature.typo");
print TYPO "#\n# WARNING: probables typos and mistakes\n#\n";

my @dbfiless = sort @dbfiles;
for(my $i=0; $i<scalar(@dbfiless); $i++)
{
    my $fileName = $dbfiless[$i];
    my $planetName  = $fileName;
    $planetName =~ s/_nomenclature([\w]*).dbf//gi;
    my $pName   = substr($planetName, 0, 1);
    my $pNameLC = substr($planetName, 1);
    $pNameLC = lc $pNameLC;
    $pName .= $pNameLC;

    my $dbh = DBI->connect("DBI:XBase:./") or die $DBI::errstr;
    my $dbname = $dbf.$fileName;
    my $sth = $dbh->prepare("SELECT name, clean_name, diameter, center_lon, center_lat, code, link, type, origin FROM $dbname ORDER BY code ASC") or die $dbh->errstr;
    $sth->execute() or die $sth->errstr;
    
    while(my $arr = $sth->fetchrow_arrayref ) 
    {
	my $cbname = sprintf("%-12s", $pName);
	my $id = $arr->[6];
	$id =~ s/http\:\/\/planetarynames\.wr\.usgs\.gov\/Feature\///gi;
	my $pfid = sprintf("%5d", $id);
	my $latitude  = sprintf "%.6f", $arr->[4];
	my $longitude = sprintf "%.6f", $arr->[3];
	my @ntype = split(",",$arr->[7]);
	my $type = lc $ntype[0]; # context
	my $featureName = $arr->[0];
	my $origin = $arr->[8];
	$origin =~ s/\r\n/ /gi;
	my $message = $cbname."[".$pfid."] ".$origin."\n";
	if (length($origin)>=250) {
	    print NOTE $message;
	}
	if ($origin =~ /\w\s\/\w/ || $origin =~ /\s{2,}/ || $origin =~ /\s\,/ || $origin =~ /\s\./ || $origin =~ /\s\;/ || $origin =~ /fertilty/ || $origin =~ /Odinn/ 
	    || $origin =~ /chieftan/ || $origin =~ /lightening/ || $origin =~ /Scandanavian/ || $origin =~ /Launcelot/ || $origin =~ /Amour/ || $origin =~ /Price\sIgor/ 
	    || $origin =~ /western\sSiberia/ || $origin =~ /Jpanese/ || $origin =~ /Francios/) {
	    print TYPO $message;
	}
	# if ($featureName !~ m/\'/ && $featureName !~ m/\./) { $featureName = $arr->[1]; }
	print FAB "# TRANSLATORS: (".$pName."); ".$origin."\n";
	$origin =~ s/ \"/ “/g;
	$origin =~ s/\"/”/g;
	print FAB $pName."\t".$id."\t_(\"".$featureName."\",\"".$type."\")\t".$arr->[5]."\t".$latitude."\t".$longitude."\t".$arr->[2]."\t_(\"".$origin."\",\"origin\")\n";
    }
}

close NOTE;
close TYPO;

for(my $k=0;$k<scalar(@extra);$k++) {
    print FAB $extra[$k];
}
print FAB "\n";

close FAB;

