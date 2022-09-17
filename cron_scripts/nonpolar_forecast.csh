#! /bin/csh -f

cd /lb13/abentley/scripts/mapdisco

source /linuxapps/ncl/latest/nclenviron

setenv NCARG_COLORMAPS $NCARG_ROOT/lib/ncarg/colormaps:/lb13/abentley/colormaps

set LOG = /free1/abentley/logs/nonpolar_forecast

ncl mslp_jet/new_mslp_jet_cron.ncl >>& $LOG/mslp_jet.out &

ncl irro_wind/new_irro_wind_cron.ncl >>& $LOG/irro_wind.out &

ncl dt_2pvu/new_dt_2pvu_cron.ncl >>& $LOG/dt_2pvu.out &

ncl rel_vort/new_rel_vort_cron.ncl >>& $LOG/rel_vort.out &

ncl 700wind_pw/new_700wind_pw_cron.ncl >>& $LOG/700wind_pw.out &

ncl IVT_conv/new_IVT_conv_cron.ncl >>& $LOG/IVT_conv.out &

ncl 850_thetae/new_850_thetae_cron.ncl >>& $LOG/850_thetae.out &

ncl cape_shear/new_cape_shear_cron.ncl >>& $LOG/cape_shear.out &

ncl 6hprecip/new_6hprecip_cron.ncl >>& $LOG/6hprecip.out &

ncl coupling/new_coupling_cron.ncl >>& $LOG/coupling.out &

ncl 350K_isen/new_350K_isen_cron.ncl >>& $LOG/350K_isen.out &

ncl 330K_isen/new_330K_isen_cron.ncl >>& $LOG/330K_isen.out &

ncl 310K_isen/new_310K_isen_cron.ncl >>& $LOG/310K_isen.out &

ncl 250wind_anom/new_250wind_anom_cron.ncl >>& $LOG/250wind_anom.out &

ncl 250v_anom/new_250v_anom_cron.ncl >>& $LOG/250v_anom.out &

ncl 500g_anom/new_500g_anom_cron.ncl >>& $LOG/500g_anom.out &

ncl pw_anom/new_pw_anom_cron.ncl >>& $LOG/pw_anom.out &

ncl 850t_anom/new_850t_anom_cron.ncl >>& $LOG/850t_anom.out &

ncl 925wind_anom/new_925wind_anom_cron.ncl >>& $LOG/925wind_anom.out &

ncl mslp_anom/new_mslp_anom_cron.ncl >>& $LOG/mslp_anom.out &
