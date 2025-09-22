#!/usr/bin/perl
#
# This is tool to convert discovery circumstances of minor planets from MPC format 
# into Stellarium's format
#
# Copyright (c) 2023 Alexander Wolf
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

open(ORIG, "<./NumberedMPs.txt");
@original = <ORIG>;
close ORIG;

$delimiter = "\t";

open(FAB, ">./discovery_circumstances.fab");
print FAB "#\n";
print FAB "# Discovery Circumstances: Numbered Minor Planets\n";
print FAB "#\n";
print FAB "# The official discovery circumstances for the numbered minor planets\n";
print FAB "# are maintained by the Minor Planet Center.\n";
print FAB "#\n";
print FAB "# Source: https://minorplanetcenter.net/iau/lists/NumberedMPs.html\n";
print FAB "#\n";
for($i=0; $i<scalar(@original); $i++)
{
    $text       = $original[$i];

    if ($text =~ m/\((\d+)\)/gi) { $number = $1; }
    $date       = substr($text, 44, 10);
    $date       =~ s/\s/-/gi;
    $discoverer = substr($text, 81);
    if ($discoverer =~ m/,/gi) 
    {
        @fio = split(", ", $discoverer);
        @names = ();
        for($j=0; $j<scalar(@fio); $j=$j+2) 
        {
            $initials = $fio[$j+1];
            $initials =~ s/\s+//gi;
            $initials =~ s/\r//gi;
            $initials =~ s/\n//gi;
            push @names, $initials." ".$fio[$j];
        }
        if (scalar(@names)>3) {
    	    $discoverer = $names[0]." et al.";
        } else {
            $discoverer = join(", ", @names);
        }
        $discoverer .= "\n";
    }

    # special case: Spacewatch at Kitt Peak
    if ($discoverer =~ m/Spacewatch/) { $discoverer = "Spacewatch at Kitt Peak\n"; }

    print FAB $number.$delimiter.$date.$delimiter.$discoverer;
}

close FAB;

