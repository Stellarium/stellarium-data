#!/usr/bin/perl
#
# This is tool to generate an assosicial list "old-style (Belyaev/Carusi ID) - 
# new-style (starting in 1995)" designations for periodic comets
#
# Data source: https://minorplanetcenter.net/iau/lists/PeriodicCodes.html
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

open(CODE, "<./PeriodicCodes.txt");
@codes = <CODE>;
close CODE;

$delimiter = "\t";

open(FAB, ">./periodic_comet_codes.fab");
print FAB "#\n";
print FAB "# Periodic Comet Numbers\n";
print FAB "#\n";
print FAB "# The assignment of periodic comet numbers is the responsibility of the Minor Planet Center.\n";
print FAB "# Association of designations: old-style (Belyaev/Carusi ID) - new-style (starting in 1995).\n";
print FAB "#\n";
print FAB "# Source: https://minorplanetcenter.net/iau/lists/PeriodicCodes.html\n";
print FAB "#\n";
for($i=0; $i<scalar(@codes); $i++)
{
    $text       = $codes[$i];

    if (substr($text, 0, 1) eq '#') { next; }

    $BelyaevID = substr($text, 0, 7);
    $BelyaevID =~ s/\s+//gi;
    $ModernID  = substr($text, 49);
    $ModernID  =~ s/\s+/ /gi;
    $ModernID  =~ s/\r/-/gi;
    $ModernID  =~ s/\n/-/gi;

    print FAB $BelyaevID.$delimiter.$ModernID."\n";
}

close FAB;

