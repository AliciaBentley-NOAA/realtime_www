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
load "~/ncl/lib/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
; ===========================================

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

timeUnits = "hours since 1800-01-01 00:00:00"

; ********************************************************
; Specify center lat/lon to use 
; ********************************************************
count = 0
totallines = 40
outfile = "/lb13/abentley/scripts/mapdisco/pvmetrics/pvmetric_values.csv"
lines := new((/totallines/),"string")

fileread = asciiread("/lb13/abentley/scripts/mapdisco/pvmetrics/hermine_12Z_2SEP2016.csv",(/totallines,6/),"float")

yyyy_arr := new(totallines,double,0)
mm_arr := new(totallines,double,0)
dd_arr := new(totallines,double,0)
hh_arr := new(totallines,double,0)
rlat_arr := new(totallines,float,0)
rlon_arr := new(totallines,float,0)

; ************************************************
; Specify the date and lat/lon (read in from file)
; ************************************************

do timestep = 0,totallines-1

number = timestep + 1

print("Obtaining data from line: "+number+" of "+totallines)

;print("Line "+number+": "+fileread(timestep))

yyyy = flt2dble(fileread(timestep,0))
mm = flt2dble(fileread(timestep,1))
dd = flt2dble(fileread(timestep,2))
hh = flt2dble(fileread(timestep,3))
rlat = fileread(timestep,4)
rlon = fileread(timestep,5)


yyyy_arr(timestep) = yyyy
mm_arr(timestep) = mm
dd_arr(timestep) = dd
hh_arr(timestep) = hh
rlat_arr(timestep) = rlat
rlon_arr(timestep) = rlon

end do    ; end timestep (aka: finding lat/lons to plot)

print(" ")
print("Lat/Lons successfully collected from file")

; ************************************************
; Obtain GFS analyses and forecasts
; ************************************************

datestr = systemfunc("date")
print("datestr: "+datestr)

quote = inttochar(34) 
cyyyy = stringtoint(systemfunc("date "+quote+"+%Y"+quote))
cmm = stringtoint(systemfunc("date "+quote+"+%m"+quote))
cdd = stringtoint(systemfunc("date "+quote+"+%d"+quote))
chh = stringtoint(systemfunc("date "+quote+"+%H"+quote))
cdate = cd_inv_calendar(cyyyy,cmm,cdd,chh,00,00,timeUnits,0)

bdate = cdate
bdate = bdate - 3*24
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

if chh .lt. 7 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,00,00,00,timeUnits,0) ;;; Convert string values to integers to use cd_inv_calendar function
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 00  ;;; choose forecast synoptic time (e.g. 00 will plot the forecast initialized at 00 UTC)
else if chh .ge. 7 .and. shh .lt. 16 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,06,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 06
else if chh .ge. 16 .and. shh .lt. 22 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 12
else if chh .ge. 22 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,18,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 18
end if
end if
end if
end if

fdate = edate + hr + 6

print(" ")
print("(Time now) "+ut_string(cdate,""))
print("sdate: "+ut_string(sdate,""))
print("edate: "+ut_string(edate,""))

total = 53

theta_all := new((/total,361,720/),"double")
absvort_all := new((/total,361,720/),"double")
pv_all := new((/total,9,361,720/),"double")
therm_all := new((/total,361,720/),"double")


;********************************************************************************************

dir_grib = "/free2/abentley/realtime/pvmetrics/"		  

  do tim = sdate,fdate,6
         tim@units = "hours since 1800-01-01 00:00:00"   ;define units for t (which is the time in 6 hour intervals)
    
         if(tim.eq.sdate) then
             print("Time = Start Date")
         end if
         
         ; Let's make a few date strings
         str_time = ut_string(tim,"%y%N%D")
         str_hr = ut_string(tim,"%H")
  
         ; Get the tar file and opens the grib files
         if(tim .le. edate) then
             if(str_hr .eq. "00") then
  	        	system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
  	        	system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if
  
             ;;; new... to read in files that don't start at 00 UTC
             if( (tim.eq.sdate) .and. (str_hr.ne."00")) then
                system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
  	            system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if  
         end if
      
          ;now that the filename should be in the proper directory, go ahead and add it 
          if(tim .le. edate) then
                filename = dir_grib+"GFS_"+str_time+"_"+str_hr+"_000.grb2"
          end if
  
          if(tim .eq. fdate) then
             print("Plotting from forecast grib files")
             delete(fhr)
             fhr  = (/0,6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192,198,204,210,216,222,228,234,240/)
             nfhr = dimsizes(fhr)
          else
             fhr = (/0/)
             nfhr = dimsizes(fhr)
          end if

 		  
          if (tim .gt. edate) then
          	 print("Plotting from last analysis!")
             do f = 0,nfhr-1
                 if (fhr(f).lt.10) then
                      filefhr = "00"+fhr(f)
                 else if ((fhr(f).lt.100).and.(fhr(f).gt.10)) then
                      filefhr = "0"+fhr(f)
                 else if (fhr(f).gt.100) then
                      filefhr = fhr(f)
                 end if 
                 end if
                 end if
                 filename = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+str_time+"_"+str_hr+"_"+filefhr+".grb2"
                 fhr_cur = fhr(f)
                 print("filename: "+filename)
                 a := addfile(filename,"r")
                 
                 ;******************************************************		  
		  
	lev_temp := (/85000/) ; Needs to be in Pa
  	t := a->TMP_P0_L100_GLL0({lev_temp},::-1,:)			
  	theta850 := t*((100000/85000)^(0.286))
  	copy_VarMeta(t,theta850) 
  			
  	lev_temp := (/92500/) ; Needs to be in Pa
  	t := a->TMP_P0_L100_GLL0({lev_temp},::-1,:)
  	theta925 := t*((100000/92500)^(0.286))
  	copy_VarMeta(t,theta925) 
  			
  	thetaavg = (theta850 + theta925)/2
  	copy_VarMeta(t,thetaavg)   			
  	theta_all(count,:,:) = thetaavg

;******************************************************		

  u925 = a->UGRD_P0_L100_GLL0({92500},::-1,:)
  v925 = a->VGRD_P0_L100_GLL0({92500},::-1,:)
  vort925 = uv2vrF_Wrap(u925,v925)

    lat2d = conform_dims(dimsizes(vort925), vort925&lat_0, 0)         ; degrees
    lat2d_deg = lat2d*(3.141592653/180)                  ; switch from degrees to radians
    absvort925 = vort925 + 2*(7.292*10^(-5))*sin(lat2d_deg)    ; absolute vorticity
    
  u850 = a->UGRD_P0_L100_GLL0({85000},::-1,:)
  v850 = a->VGRD_P0_L100_GLL0({85000},::-1,:)
  vort850 = uv2vrF_Wrap(u850,v850)
  absvort850 = vort850 + 2*(7.292*10^(-5))*sin(lat2d_deg)    ; absolute vorticity
  
  absvortavg = (absvort850 + absvort925)/2
  copy_VarMeta(vort925,absvortavg)   
  absvort_all(count,:,:) = absvortavg
	
;******************************************************		

  lev_pv  = (/20000,30000,40000,50000,60000,70000,80000,85000,92500/)
  upv = a->UGRD_P0_L100_GLL0({lev_pv},::-1,:)
  vpv = a->VGRD_P0_L100_GLL0({lev_pv},::-1,:)
  tpv = a->TMP_P0_L100_GLL0({lev_pv},::-1,:)

  lev_pv@units = "Pa"
  pv = PotVortIsobaric(lev_pv,upv,vpv,tpv,tpv&lat_0,1,0)
  pv = pv*(10^6)
  copy_VarCoords(upv,pv)
  pv_all(count,:,:,:) = pv
	
;******************************************************	  

    u1 = a->UGRD_P0_L100_GLL0({20000},::-1,:)
    v1 = a->VGRD_P0_L100_GLL0({20000},::-1,:)
    u2 = a->UGRD_P0_L100_GLL0({50000},::-1,:)
    v2 = a->VGRD_P0_L100_GLL0({50000},::-1,:)

    relvort200 = uv2vrG_Wrap(u1,v1) ; Calculate relative vorticity using spherical harmonics
    relvort500 = uv2vrG_Wrap(u2,v2)
    therm_vort = relvort200(:,:)-relvort500(:,:)
    therm_vort = therm_vort*(10^5)
    copy_VarCoords(u1,therm_vort)
    
    therm_all(count,:,:) = therm_vort
	
;******************************************************	   
              count = count + 1
              print("count: "+count)
              end do   

		  
		  else
		  print("From archived files!")	  
		  print("filename: "+filename)
		  
		    a := addfile(filename,"r")
		  
;******************************************************		  
		  
	lev_temp := (/85000/) ; Needs to be in Pa
  	t := a->TMP_P0_L100_GLL0({lev_temp},::-1,:)			
  	theta850 := t*((100000/85000)^(0.286))
  	copy_VarMeta(t,theta850) 
  			
  	lev_temp := (/92500/) ; Needs to be in Pa
  	t := a->TMP_P0_L100_GLL0({lev_temp},::-1,:)
  	theta925 := t*((100000/92500)^(0.286))
  	copy_VarMeta(t,theta925) 
  			
  	thetaavg = (theta850 + theta925)/2
  	copy_VarMeta(t,thetaavg)   			
  	theta_all(count,:,:) = thetaavg

;******************************************************		

  u925 = a->UGRD_P0_L100_GLL0({92500},::-1,:)
  v925 = a->VGRD_P0_L100_GLL0({92500},::-1,:)
  vort925 = uv2vrF_Wrap(u925,v925)

    lat2d = conform_dims(dimsizes(vort925), vort925&lat_0, 0)         ; degrees
    lat2d_deg = lat2d*(3.141592653/180)                  ; switch from degrees to radians
    absvort925 = vort925 + 2*(7.292*10^(-5))*sin(lat2d_deg)    ; absolute vorticity
    
  u850 = a->UGRD_P0_L100_GLL0({85000},::-1,:)
  v850 = a->VGRD_P0_L100_GLL0({85000},::-1,:)
  vort850 = uv2vrF_Wrap(u850,v850)
  absvort850 = vort850 + 2*(7.292*10^(-5))*sin(lat2d_deg)    ; absolute vorticity
  
  absvortavg = (absvort850 + absvort925)/2
  copy_VarMeta(vort925,absvortavg)   
  absvort_all(count,:,:) = absvortavg
	
;******************************************************		

  lev_pv  = (/20000,30000,40000,50000,60000,70000,80000,85000,92500/)
  upv = a->UGRD_P0_L100_GLL0({lev_pv},::-1,:)
  vpv = a->VGRD_P0_L100_GLL0({lev_pv},::-1,:)
  tpv = a->TMP_P0_L100_GLL0({lev_pv},::-1,:)

  lev_pv@units = "Pa"
  pv = PotVortIsobaric(lev_pv,upv,vpv,tpv,tpv&lat_0,1,0)
  pv = pv*(10^6)
  copy_VarCoords(upv,pv)
  pv_all(count,:,:,:) = pv
	
;******************************************************	  

    u1 = a->UGRD_P0_L100_GLL0({20000},::-1,:)
    v1 = a->VGRD_P0_L100_GLL0({20000},::-1,:)
    u2 = a->UGRD_P0_L100_GLL0({50000},::-1,:)
    v2 = a->VGRD_P0_L100_GLL0({50000},::-1,:)

    relvort200 = uv2vrG_Wrap(u1,v1) ; Calculate relative vorticity using spherical harmonics
    relvort500 = uv2vrG_Wrap(u2,v2)
    therm_vort = relvort200(:,:)-relvort500(:,:)
    therm_vort = therm_vort*(10^5)
    copy_VarCoords(u1,therm_vort)
    
    therm_all(count,:,:) = therm_vort
	
;******************************************************	 
		  count = count + 1		  
		  print("count: "+count)
		  end if ; tim .gt. edate
		  

	
	end do
		

			if (isfilepresent("/free2/abentley/realtime/pvmetrics/theta.nc") .eq. True) then
			    system("'rm' /free2/abentley/realtime/pvmetrics/theta.nc")	
			end if
		ncdf_clusters = addfile("/free2/abentley/realtime/pvmetrics/theta.nc" ,"c")
		ncdf_clusters->theta = theta_all  

			if (isfilepresent("/free2/abentley/realtime/pvmetrics/absvort.nc") .eq. True) then
			    system("'rm' /free2/abentley/realtime/pvmetrics/absvort.nc")	
			end if
		ncdf_clusters = addfile("/free2/abentley/realtime/pvmetrics/absvort.nc" ,"c")
		ncdf_clusters->absvort = absvort_all  

			if (isfilepresent("/free2/abentley/realtime/pvmetrics/pv.nc") .eq. True) then
			    system("'rm' /free2/abentley/realtime/pvmetrics/pv.nc")	
			end if
		ncdf_clusters = addfile("/free2/abentley/realtime/pvmetrics/pv.nc" ,"c")
		ncdf_clusters->pv = pv_all  

			if (isfilepresent("/free2/abentley/realtime/pvmetrics/therm_vort.nc") .eq. True) then
			    system("'rm' /free2/abentley/realtime/pvmetrics/therm_vort.nc")	
			end if
		ncdf_clusters = addfile("/free2/abentley/realtime/pvmetrics/therm_vort.nc" ,"c")
		ncdf_clusters->therm_vort = therm_all  

exit


sdate = cd_inv_calendar(yyyy_arr(0),mm_arr(0),dd_arr(0),hh_arr(0),00,00,timeUnits,0)
















    ; Load Raw Data
   
    u = u_file->u({time(tm)},{925},{opt@lat_min:opt@lat_max},{opt@lon_min:opt@lon_max})
    v = v_file->v({time(tm)},{925},{opt@lat_min:opt@lat_max},{opt@lon_min:opt@lon_max})

    ;print("Data loaded")

    ; Calculate vorticity
 
    vort= uv2vrF_Wrap(u, v)
 
    delete(u)
    delete(v)

    ;print("Vorticity Calculated")

    ; Compute absolute vorticity





    ;;;;;;;;;; make a 2d latitude grid

    lat2d = conform_dims(dimsizes(vort), vort&lat, 0)         ; degrees

    lat2d_deg = lat2d*(3.141592653/180)                  ; switch from degrees to radians
    
    absvort = vort + 2*(7.292*10^(-5))*sin(lat2d_deg)    ; absolute vorticity

    out_p->$opt@out_var$({time(tm)},:,:) = (/absvort/)





system("rm -f "+dir_grib+"GFS_*_000")
system("rm -f "+dir_grib+"*.grb2.tar")

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end