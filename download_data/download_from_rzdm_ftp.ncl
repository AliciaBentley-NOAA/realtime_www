; ===========================================
; Plot composited PV on isentropic surfaces
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "~/ncl/lib/tTick.ncl"
load "~/ncl/lib/ut_string.ncl"
load "~/ncl/lib/latlon.ncl"
load "~/ncl/lib/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
; ===========================================

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

timeUnits = "hours since 1800-01-01 00:00:00"

do day = 24,23,1

do hour = 0,18,6

edate = cd_inv_calendar(2022,8,day,hour,00,00,timeUnits,0)

print("Time to save:  "+ut_string(edate,""))
print(" ")

get_time = ut_string(edate,"%Y%N%D")
print("get_time: "+get_time)
save_date = ut_string(edate,"%y%N%D")
print("save_date: "+save_date)
save_hh = ut_string(edate,"%H")
print("save_hh: "+save_hh)

dir_in = "https://ftp.emc.ncep.noaa.gov/users/abentley/"
print("dir_in"+dir_in)

system("'rm' GFS_"+save_date+"_"+save_hh+"_000")
system("wget --no-check-certificate "+dir_in+"gfs."+get_time+".t"+save_hh+"z.pgrb2.0p50.anl")
print(" ")
print("Successfully downloaded gfs."+get_time+".t"+save_hh+"z.pgrb2.0p50.anl")
system("'mv' gfs."+get_time+".t"+save_hh+"z.pgrb2.0p50.anl GFS_"+save_date+"_"+save_hh+"_000")
print("Successfully moved to GFS_"+save_date+"_"+save_hh+"_000")
print(" ")

end do ; hour
end do; day

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
