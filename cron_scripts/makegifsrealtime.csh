#! /bin/csh -f

cd /lb13/abentley/scripts/mapdisco

source /linuxapps/ncl/latest/nclenviron

setenv NCARG_COLORMAPS $NCARG_ROOT/lib/ncarg/colormaps:/lb13/abentley/colormaps

ncl makegifs/standard_gif.ncl &

ncl makegifs/severe_gif.ncl &

ncl makegifs/subtrop_gif.ncl &

ncl makegifs/std_anom_gif.ncl &



