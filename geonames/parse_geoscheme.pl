#!/usr/bin/perl

#
# Tool for parse a regions-geoscheme.tab file for extraction of region names for translation
#
# Copyright (C) 2021 Alexander Wolf
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

$SRC	= "./regions-geoscheme.tab";
$TMPL	= "./translations_regions.tmpl";
$WIKI	= "./wiki.url";
$OUT	= "./translations_regions.h";

open(ALL, "<:encoding(utf8)", "$SRC");
@srcData = <ALL>;
close ALL;

open(WIKI, "<:encoding(utf8)", "$WIKI");
@wikiData = <WIKI>;
close WIKI;

%wikilink = ();
for($i=0;$i<scalar(@wikiData);$i++)
{
	@link = split(/;/, $wikiData[$i]);
	# data format: region name; link to wikipedia
	$wikilink{$link[0]} = $link[1];
}

open(TMPL, "<:encoding(utf8)", "$TMPL");
@tmpl = <TMPL>;
close TMPL;

open(OUT, ">:encoding(utf8)", "$OUT");
for($i=0;$i<scalar(@tmpl);$i++)
{
	if ($tmpl[$i] =~ m/LIST_OF_REGIONS/gi)
	{
		for($j=0;$j<scalar(@srcData);$j++)
		{
			$str = $srcData[$j];
			chop($str);
			if ($str !~ m/#/)
			{
				@item = split(/\t/, $str);
				$planet  = $item[1];
				$region  = $item[2];
				if ($planet eq 'Moon')
				{
					print OUT "\t\t// TRANSLATORS: Name of region on the ".$planet."\n";
					print OUT "\t\t// TRANSLATORS: See also 1961 U.S.G.S. Physical Map of the Moon: https://commons.wikimedia.org/wiki/File:1961_U.S.G.S._Physical_Map_of_the_Moon_(wall_map)_-_landmark_Lunar_map%5E_-_Geographicus_-_MoonPhysical-usgs-1961.jpg\n";
				} else {
					print OUT "\t\t// TRANSLATORS: Name of region on ".$planet."\n";
				}
				if ($planet eq 'Mars')
				{
					print OUT "\t\t// TRANSLATORS: See also MOLA global image showing boundaries of regional feature names: https://planetarynames.wr.usgs.gov/images/mola_regional_boundaries.pdf\n";
				}
				if (exists $wikilink{$region})
				{
					print OUT "\t\t// TRANSLATORS: ".$wikilink{$region};
				}
				print OUT "\t\tN_(\"".$region."\");\n";
			}
		}
	}
	else
	{
		print OUT $tmpl[$i];
	}
}
close OUT;
