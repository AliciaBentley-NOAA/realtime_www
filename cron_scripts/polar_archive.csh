#! /bin/csh -f

cd /lb13/abentley/scripts/mapdisco

source /linuxapps/ncl/latest/nclenviron

setenv NCARG_COLORMAPS $NCARG_ROOT/lib/ncarg/colormaps:/lb13/abentley/colormaps

set LOG = /free1/abentley/logs/polar_archive

ncl mslp_jet/NH_archive_mslp_jet.ncl >>& $LOG/mslp_jet.out &

ncl irro_wind/NH_archive_irro_wind.ncl >>& $LOG/irro_wind.out &

ncl dt_2pvu/NH_archive_dt_2pvu.ncl >>& $LOG/dt_2pvu.out &

ncl rel_vort/NH_archive_rel_vort.ncl >>& $LOG/rel_vort.out &

ncl 700wind_pw/NH_archive_700wind_pw.ncl >>& $LOG/700wind_pw.out &

ncl IVT_conv/NH_archive_IVT_conv.ncl >>& $LOG/IVT_conv.out &

ncl 850_thetae/NH_archive_850_thetae.ncl >>& $LOG/850_thetae.out &

ncl cape_shear/NH_archive_cape_shear.ncl >>& $LOG/cape_shear.out &

ncl 6hprecip/NH_archive_6hprecip.ncl >>& $LOG/6precip.out &

ncl coupling/NH_archive_coupling.ncl >>& $LOG/coupling.out &

ncl 350K_isen/NH_archive_350K_isen.ncl >>& $LOG/350K_isen.out &

ncl 330K_isen/NH_archive_330K_isen.ncl >>& $LOG/330K_isen.out &

ncl 310K_isen/NH_archive_310K_isen.ncl >>& $LOG/310K_isen.out &

ncl 250wind_anom/NH_archive_250wind_anom.ncl >>& $LOG/250wind_anom.out &

ncl 250v_anom/NH_archive_250v_anom.ncl >>& $LOG/250v_anom.out &

ncl 500g_anom/NH_archive_500g_anom.ncl >>& $LOG/500g_anom.out &

ncl pw_anom/NH_archive_pw_anom.ncl >>& $LOG/pw_anom.out &

ncl 850t_anom/NH_archive_850t_anom.ncl >>& $LOG/850t_anom.out &

ncl 925wind_anom/NH_archive_925wind_anom.ncl >>& $LOG/925wind_anom.out &

ncl mslp_anom/NH_archive_mslp_anom.ncl >>& $LOG/mslp_anom.out &
