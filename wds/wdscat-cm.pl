#!/usr/bin/perl

# http://cdsxmatch.u-strasbg.fr
# V/137D/XHIP x B/wds/wds (by position; radius 3 arcsec)

$HIPWDSDAT	= "./hipwds.dat";
$CROSSID	= "./names.fab";
$RESULT		= "./wds_hip_part.dat";

$del	= "\t";

%wdscat  = ();
%wdscmd  = ();

open(WDSD, "<$HIPWDSDAT");
@wdsdata = <WDSD>;
close WDSD;

print "Fetch and parse HIP-WDS cross-match catalog...\n";
for($i=0;$i<scalar(@wdsdata);$i++)
{
	$wdsd = $wdsdata[$i];
	if (substr($wdsd, 0, 1) eq '#') { next; }

	$hip	= substr($wdsd, 35, 6);
	$hip	=~ s/\s+//gi;
	$wds	= substr($wdsd,201,10);
	$wds	=~ s/\s+//gi;
	$disc	= substr($wdsd,212, 7);
	$year	= substr($wdsd,231, 4);
	$year	=~ s/\s+//gi;
	$pa	= substr($wdsd,240, 3);
	$pa	=~ s/\s+//gi;
	$sep	= substr($wdsd,250, 5);
	$sep	=~ s/\s+//gi;
	
	$data = $wds.$del.$year.$del.$pa.$del.$sep;
	if (!exists($wdscat{$hip})) {
		$wdscat{$hip} = $data;
	}
	$wdscmd{$disc} = $hip;
}

print "DONE!\n\n";
print "Let's make a list of designations for double stars!\n";
open(CROSS, ">$CROSSID");
foreach my $name (sort { $wdscmd{$a} <=> $wdscmd{$b} } keys %wdscmd)
{
	$hip = $wdscmd{$name};
	$idx = length($hip);
	$hips = "";
	for($j=0;$j<(6-$idx);$j++) { $hips .= " "; }

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
	print CROSS $hips.$hip."|".$dsname.$appdx."\n";
}
close CROSS;
print "DONE!\n\n";
print "Let's make a WDS catalog for Stellarium!\n";
open(WDS, ">$RESULT");
print WDS "# HIP, WDS designation, year of observation, position angle, separation\n";
foreach my $hip (sort {$a <=> $b} keys %wdscat) 
{
	print WDS $hip.$del.$wdscat{$hip}."\n";
}
print "DONE!\n\nWDS catalog for Stellarium has been created!\n";

close WDS;

