#! /bin/csh -f

cd /free/abentley/realtime/prac

source /linuxapps/ncl/latest/nclenviron

set YYMMDDHH = `date +"%y%m%d%H"`
set LOGFIL = /free1/abentley/logs/download/${YYMMDDHH}.log
setenv NCARG_COLORMAPS $NCARG_ROOT/lib/ncarg/colormaps:/lb13/abentley/colormaps

ncl download_analysis.ncl >& $LOGFIL &



