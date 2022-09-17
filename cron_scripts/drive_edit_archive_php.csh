#! /bin/csh -f

cd /lb13/abentley/scripts/archive

source /linuxapps/ncl/latest/nclenviron

setenv NCARG_COLORMAPS $NCARG_ROOT/lib/ncarg/colormaps:/lb13/abentley/colormaps

set LOG = /free1/abentley/logs/map_archive

./edit_archive.csh >>& $LOG/edit_archive.out &

