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

ldate = cdate
ldate = ldate - 24
dateInformation = calendar_decode2(ldate,-5)
lyyyy = dateInformation(:,0)                    ;;; start date in yyyy mm dd hh
lmm = dateInformation(:,1)
ldd = dateInformation(:,2)

bdate = cdate
bdate = bdate - 20*24
dateInformation = calendar_decode2(bdate,-5)
syyyy = dateInformation(:,0)			;;; start date in yyyy mm dd hh
smm = dateInformation(:,1)
sdd = dateInformation(:,2)
shh = dateInformation(:,3)
sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,timeUnits,0)

print(" ")
print("Delete time: "+ut_string(sdate,""))
print(" ")
print("Current time: "+ut_string(cdate,""))
print(" ")

;-------------------------------------------------

if (chh .gt. 4) .and. (chh .le. 10) then
     ehh = 00
     edate = cd_inv_calendar(cyyyy,cmm,cdd,ehh,00,00,timeUnits,0)
     hr = 06
     mdate = cd_inv_calendar(cyyyy,cmm,cdd,hr,00,00,timeUnits,0)
else if (chh .gt. 10) .and. (chh .le. 16) then
     ehh = 06
     edate = cd_inv_calendar(cyyyy,cmm,cdd,ehh,00,00,timeUnits,0)
     hr = 12
     mdate = cd_inv_calendar(cyyyy,cmm,cdd,hr,00,00,timeUnits,0)
else if (chh .gt. 16) .and. (chh .le. 23) then							; Last date should be 22
     ehh = 12
     edate = cd_inv_calendar(cyyyy,cmm,cdd,ehh,00,00,timeUnits,0)
     hr = 18
     mdate = cd_inv_calendar(cyyyy,cmm,cdd,hr,00,00,timeUnits,0)
else if (chh .ge. 0) .and. (chh .le. 4) then
     ehh = 18
     edate = cd_inv_calendar(lyyyy,lmm,ldd,ehh,00,00,timeUnits,0)
     hr = 00
     mdate = cd_inv_calendar(cyyyy,cmm,cdd,hr,00,00,timeUnits,0)
end if
end if
end if
end if

print("GFS model run: "+ut_string(mdate,""))
print("Time to save:  "+ut_string(edate,""))
print(" ")

get_time = ut_string(edate,"%Y%N%D%H")
print("get_time: "+get_time)
save_date = ut_string(edate,"%y%N%D")
print("save_date: "+save_date)
save_hh = ut_string(edate,"%H")
print("save_hh: "+save_hh)


dir_in = "http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs."+get_time+"/"

  system("'rm' GFS_"+save_date+"_"+save_hh+"_000")
  system("wget "+dir_in+"gfs.t"+save_hh+"z.pgrb2.0p50.anl")
  print(" ")
  print("Successfully downloaded gfs.t"+save_hh+"z.pgrb2.0p50.anl")
  system("'mv' gfs.t"+save_hh+"z.pgrb2.0p50.anl GFS_"+save_date+"_"+save_hh+"_000")
  print("Successfully moved to GFS_"+save_date+"_"+save_hh+"_000")
  print(" ")
  
;-----------------------------------------------------

delete_date = ut_string(sdate,"%y%N%D")
print("delete_date: "+delete_date)
  
folder = (/"00","06","12","18"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1
	hour = folder(x)
	print(" ")
	print("Deleting hour: "+hour)	
	filetodelete = "GFS_"+delete_date+"_"+hour+"_000"
	print("filetodelete: "+filetodelete)	
	system("'rm' "+filetodelete)
end do  
  
  

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end