R = 6371000.0
set title "Elevation error resulting from a flat-Earth assumption"
set xlabel "Distance from center (m)"
set ylabel "Vertical error (m)"
unset key

set output "plot_flat_earth_error.svg"
set terminal svg
plot [0:40000] sqrt(R*R + x*x) - R

set output
set terminal x11
