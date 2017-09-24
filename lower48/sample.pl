#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';
use IPC::Run qw(run);


my $lat0 = 25.0;
my $lat1 = 50.0;
my $lon0 = -125.0;
my $lon1 = -66.0;
my $r    = 0.1;


my $N_lat = int (($lat1 - $lat0) / (2. * $r) + 0.5);
my $N_lon = int (($lon1 - $lon0) / (2. * $r) + 0.5);

say "# lat lon Nways";

for my $ilat (0..$N_lat-1)
{
    my $lat = $lat0 + $ilat * 2. * $r;
    for my $ilon (0..$N_lon-1)
    {
        my $lon = $lon0 + $ilon * 2. * $r;

        my $in = '';
        my $out;
        my $err;
        run [ './query_center_countonly.sh', $lat, $lon, $r ], \$in, \$out, \$err;

        my ($Nways) = $out =~ /"ways": ([0-9]+)/;
        say "$lat $lon $Nways";
    }
}
