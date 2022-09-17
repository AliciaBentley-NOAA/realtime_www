; ===========================================
; Moving archive and plotting GFS forecast 
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

yyyymmdd = "20210426"
hh = "18"

system("'rm' gfs.t"+hh+"z*")

;---------------------------------------

do x = 0,192,6

                 if (x.lt.10) then
                      filefhr = "00"+x
                 else if ((x.lt.100).and.(x.gt.10)) then
                      filefhr = "0"+x
                 else if (x.gt.100) then
                      filefhr = x
                 end if 
                 end if
                 end if

system("wget https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs."+yyyymmdd+"/"+hh+"/atmos/gfs.t"+hh+"z.pgrb2.0p50.f"+filefhr)

end do     ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
