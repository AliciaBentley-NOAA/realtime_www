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

delall = 0
check_dne = 0
timeUnits = "hours since 1800-01-01 00:00:00"

datestr = systemfunc("date")
print("datestr: "+datestr)

quote = inttochar(34) 
cyyyy = stringtoint(systemfunc("date "+quote+"+%Y"+quote))
cmm = stringtoint(systemfunc("date "+quote+"+%m"+quote))
cdd = stringtoint(systemfunc("date "+quote+"+%d"+quote))
chh = stringtoint(systemfunc("date "+quote+"+%H"+quote))
cdate = cd_inv_calendar(cyyyy,cmm,cdd,chh,00,00,timeUnits,0)

bdate = cdate
bdate = bdate - 20*24
dateInformation = calendar_decode2(bdate,-5)
syyyy = dateInformation(:,0)			;;; start date in yyyy mm dd hh
smm = dateInformation(:,1)
sdd = dateInformation(:,2)
shh = dateInformation(:,3)

ldate = cdate
ldate = ldate - 24
dateInformation = calendar_decode2(ldate,-5)
eyyyy = dateInformation(:,0)			;;; start date in yyyy mm dd hh
emm = dateInformation(:,1)
edd = dateInformation(:,2)

sdate = cd_inv_calendar(syyyy,smm,sdd,00,00,00,timeUnits,0) ;;; Convert string values to integers to use cd_inv_calendar function
edate = cd_inv_calendar(eyyyy,emm,edd,00,00,00,timeUnits,0)

fdate = edate
fdate = fdate - 24

print(" ")
print("Delete time: "+ut_string(sdate,""))
print("Current time: "+ut_string(cdate,""))
;print("Fake time: "+ut_string(fdate,""))
print("Add time: "+ut_string(edate,""))


fdate_time = ut_string(fdate,"%y%N%D")
edate_time = ut_string(edate,"%y%N%D")
;print("fdate_time: "+fdate_time)
;print("edate_time: "+edate_time)
print(" ")

keep_time = ut_string(edate,"%y%N%D")
str_time = ut_string(sdate,"%y%N%D")
str_hr = ut_string(sdate,"%H")
dir_grib = "/free/abentley/realtime/grib/"




;copy = (/"00","06","12","18"/)  
;endcopy = dimsizes(copy)

;do x = 0,endcopy-1
;hourcopy = copy(x)
;print("Copying hour: "+hourcopy)	
;copyfrom = "GFS_"+fdate_time+"_"+hourcopy+"_000"
;copyto = "GFS_"+edate_time+"_"+hourcopy+"_000"
;print("copyfrom: "+dir_grib+copyfrom)
;print("copyto: "+dir_grib+copyto)
;system("'cp' "+dir_grib+copyfrom+" "+dir_grib+copyto)
;print(" ")
;end do





system("'cp' /nfs/nmc2/grib/gfs255_anl_"+keep_time+".grb2.tar "+dir_grib)
system("tar -xvf "+dir_grib+"gfs255_anl_"+keep_time+".grb2.tar -C "+dir_grib)
system("rm -f "+dir_grib+"*.grb2.tar")




folder = (/"00","06","12","18"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1
hour = folder(x)
print(" ")
print("Deleting hour: "+hour)	
filetodelete = "GFS_"+str_time+"_"+hour+"_000"
print("filetodelete: "+dir_grib+filetodelete)	
system("'rm' "+dir_grib+filetodelete)
end do





print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end