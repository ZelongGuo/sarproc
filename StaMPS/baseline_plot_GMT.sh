#!/bin/bash


gmt begin aaa tif
gmt set MAP_GRID_PEN_PRIMARY 0.3p,grey60,-
gmt set FORMAT_DATE_MAP=-o
# s p: primary and seconderay scale, Y:year, o:month
gmt basemap -R2017-10-15T/2020-12-15T/-150/150 -Bsxa1Y+l'Time' -Bpxa2of1og5o -Bya30f10g30+l'Perpendicular baseline (m)' -BSWrt
gmt plot GMT_T072A.txt -W1p,gray50
gmt plot GMT_T072A_sup.txt -W1.5p,gray50
gmt plot GMT_T072A_sup.txt -W0.7p,DARKTURQUOISE
gmt plot GMT_T072A.txt -Sc0.2c -Gsienna1 -W1p 
# reference point
gmt plot -Sc0.2c -Ggreen -W1p << EOF
2019-03-06T 0
EOF

gmt end show
