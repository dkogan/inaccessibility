#!/usr/bin/perl
use strict;
use warnings;

use feature ':5.10';
use autodie;

use JSON;
use PDL;
use PDL::NiceSlice;
my $pi = 3.14159265359;


# here I read the json that comes in from the overpass query and massage it to
# be acceptable to the solver. The input comes from query.sh. I follow each way,
# making sure it contains points sampled at least $point_spacing_min apart. I
# map each lat/lon pair to a plane tangent to the earth (modeled as a sphere) in
# the center of the query rectangle. The earth is neither flat nor a sphere, but
# this is good enough for what I'm trying to do.
#
# The output is a list of points to feed to the voronoi solver. The output
# filename is points_lat0_lon0_lat1_lon1.dat



# The earth-centered coordinate system has
#   x points out from lon = 0          (greenwich)
#   y points out from lon = +90degrees (mongolia)
#   z points up to the north pole
my $Rearth                = 6371000.0; # meters
my $point_spacing_min     = 100.0;     # meters


my $infile = shift;
die "Input json must appear on the commandline"         unless defined $infile;
die "Existing json file must appear on the commandline" unless -e $infile;

my @corners = $infile =~ /(-?[0-9]+(?:\.[0-9]+)?)/g;
die "Input file must be query_lat0_lon0_lat1_lon1.osm" unless @corners == 4;

# I transform my points to a 2d plane tangent to my Earth sphere (good enough)
# at the center of the query rectangle. This coordinate system has
#   x pointing East,  as observed by a viewer at this location
#   y pointing North, as observed by a viewer at this location
#   z pointing up,    as observed by a viewer at this location

my @latlon_center = get_center_latlon(@corners);
my $v_center      = v_from_latlon(@latlon_center);
my $p_center      = $v_center * $Rearth;
my $R             = PDL::cat( east_at_latlon (@latlon_center),
                              north_at_latlon(@latlon_center),
                              $v_center )->transpose;

open OUT, '>', "points_" . join('_', @corners) .".dat";

# I write out the min/max coordinates of the corners, mapped to my plane.
# Adjacent corners won't actually have the lat/lon, but it's close enough for my
# purposes
say OUT join(' ', PDL::list(PDL::rint(map_latlon( $corners[0], $corners[1] ))));
say OUT join(' ', PDL::list(PDL::rint(map_latlon( $corners[2], $corners[3] ))));




# slurp input. Assuming it's not too large
my $osm = decode_json(`cat $infile`);
my %nodes;
for my $elem (@{$osm->{elements}})
{
    if($elem->{type} eq 'node')
    {
        $nodes{$elem->{id}} = $elem;
    }
    elsif($elem->{type} eq 'way')
    {
        my $p_last;

        for my $nodeid(@{$elem->{nodes}})
        {
            sub accept_point
            {
                my $p = shift;

                # boost voronoi computation thing wants integer input, so I'm
                # rounding to the nearest meter. This is close enough
                say OUT join(' ', $p->rint->list);
            }



            die "Way $elem->{id} references not-yet-seen node $nodeid"
              unless exists $nodes{$nodeid};

            my $p = map_latlon($nodes{$nodeid}{lat}, $nodes{$nodeid}{lon});

            if( defined $p_last )
            {
                my $diff_from_prev = $p - $p_last;
                my $dsq_from_prev  = inner($diff_from_prev, $diff_from_prev);
                if( $dsq_from_prev > $point_spacing_min * $point_spacing_min )
                {
                    my $toprint = $p_last->glue(1,$p);
                    my $d_from_prev = sqrt($dsq_from_prev);
                    $diff_from_prev /= $d_from_prev;

                    while( $d_from_prev > $point_spacing_min )
                    {
                        $p_last += $diff_from_prev * $point_spacing_min;
                        accept_point($p_last);

                        $d_from_prev -= $point_spacing_min;
                    }
                }
            }

            accept_point($p);
            $p_last = $p;
        }
    }
}







sub get_center_latlon
{
    my ($lat0, $lon0, $lat1, $lon1) = @_;


    # I have 4 unit vectors (the corners). I want to find the vector that's
    # their "average" using some metric. Let's minimize the sum angle:
    #  E = -sum( inner(v, v_i) ) constrained to inner(v,v) = 1
    # Lagrange multipliers: L = -sum( inner(v, v_i) ) - l*(inner(v,v) - 1)
    #
    #  dL/dv = 0 = -sum(v_i) - 2*l*v -> v = k * sum(v_i) ->
    #       -> v is the normalized average v_i
    my $v =
      v_from_latlon( $lat0, $lon0 ) +
      v_from_latlon( $lat0, $lon1 ) +
      v_from_latlon( $lat1, $lon0 ) +
      v_from_latlon( $lat1, $lon1 );

    $v /= sqrt(inner($v,$v));

    return latlon_from_v($v);
}

sub latlon_from_v
{
    my $v = shift;

    my $lat = asin($v->((2)));
    my $clat = cos($lat);
    my $lon = atan2( $v->((1)) / $clat, $v->((0)) / $clat);

    return ($lat * 180.0/$pi, $lon * 180.0/$pi);
}

sub v_from_latlon
{
    my ($lat, $lon) = @_;

    my $clon = cos($lon * $pi / 180.0);
    my $slon = sin($lon * $pi / 180.0);
    my $clat = cos($lat * $pi / 180.0);
    my $slat = sin($lat * $pi / 180.0);
    return pdl( $clon*$clat, $slon*$clat, $slat);
}

sub north_at_latlon
{
    my ($lat, $lon) = @_;

    my $clon = cos($lon * $pi / 180.0);
    my $slon = sin($lon * $pi / 180.0);
    my $clat = cos($lat * $pi / 180.0);
    my $slat = sin($lat * $pi / 180.0);

    return pdl( -$clon*$slat, -$slon*$slat, $clat );
}

sub east_at_latlon
{
    my ($lat, $lon) = @_;

    my $clon = cos($lon * $pi / 180.0);
    my $slon = sin($lon * $pi / 180.0);
    my $clat = cos($lat * $pi / 180.0);
    my $slat = sin($lat * $pi / 180.0);

    return pdl( -$slon, $clon, 0);
}

sub map_latlon
{
    # input is ($lat,$lon)

    my $p = $Rearth * v_from_latlon(@_);

    my $p_mapped = ($p - $p_center) x $R;

    # locally the surface is flat-enough, and I just take the (E,N)
    # tuple, and ignore the height (deviation from flat)
    return $p_mapped->(0:1);
}
