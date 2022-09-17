#! /bin/csh -f

cd /lb13/abentley/scripts/archive

source /linuxapps/ncl/latest/nclenviron

setenv NCARG_COLORMAPS $NCARG_ROOT/lib/ncarg/colormaps:/lb13/abentley/colormaps

set LOG = /free1/abentley/logs/map_archive

ncl plot_mslp_jet.ncl >>& $LOG/mslp_jet.out &

ncl plot_irro_wind.ncl >>& $LOG/irro_wind.out &

ncl plot_dt_2pvu.ncl >>& $LOG/dt_2pvu.out &

ncl plot_rel_vort.ncl >>& $LOG/rel_vort.out &

ncl plot_700wind_pw.ncl >>& $LOG/700wind_pw.out &

ncl plot_IVT_conv.ncl >>& $LOG/IVT_conv.out &

ncl plot_6hprecip.ncl >>& $LOG/6hprecip.out &

ncl plot_500g_anom.ncl >>& $LOG/500g_anom.out &

ncl plot_pw_anom.ncl >>& $LOG/pw_anom.out &

ncl plot_850t_anom.ncl >>& $LOG/850t_anom.out &

ncl plot_925wind_anom.ncl >>& $LOG/925wind_anom.out &

ncl plot_mslp_anom.ncl >>& $LOG/mslp_anom.out &
