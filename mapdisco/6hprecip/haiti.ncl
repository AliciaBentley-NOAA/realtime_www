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
bdate = bdate - 0*24
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

odate = cdate
odate = bdate - 24
odateInformation = calendar_decode2(odate,-5)
oyyyy = odateInformation(:,0)			;;; start date in yyyy mm dd hh
omm = odateInformation(:,1)
odd = odateInformation(:,2)
ohh = odateInformation(:,3)

olddate = cd_inv_calendar(oyyyy,omm,odd,00,00,00,timeUnits,0)
; Setting old_str_time in the analysis section every time imgcount = 1

if shh .lt. 7 then
     sdate = cd_inv_calendar(syyyy,smm,20,00,00,00,timeUnits,0) ;;; Convert string values to integers to use cd_inv_calendar function
     edate = cd_inv_calendar(eyyyy,emm,19,18,00,00,timeUnits,0)
     hr = 00  ;;; choose forecast synoptic time (e.g. 00 will plot the forecast initialized at 00 UTC)
else if shh .ge. 7 .and. shh .lt. 16 then
     sdate = cd_inv_calendar(syyyy,smm,20,06,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,19,18,00,00,timeUnits,0)
     hr = 06
else if shh .ge. 16 .and. shh .lt. 21 then
     sdate = cd_inv_calendar(syyyy,smm,20,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,19,18,00,00,timeUnits,0)
     hr = 12
else if shh .ge. 21 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,18,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 18
end if
end if
end if
end if

print("GFS Forecast: "+hr+"Z run")

;;; end date in yyyy mm dd hh (note end of analysis must ALWAYS end at 18 UTC)
;;; this is because grib files are packaged in .tar format which saves daily files
;;; (00,06,12,18) bundeling all the synoptic times in one file. This program
;;; bridges the gap if you are looking at a forecast other than starting at 00 UTC
;;; by filling in the missing dates with the forecast analysis grib files 

print("sdate: "+ut_string(sdate,""))
print("edate: "+ut_string(edate,""))

folder = (/"southeast"/)   
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)

fcast = "yes" 		        ;;; do you want to plot the 192 hour GFS forecast at the next synoptic time?	         	
  
fdate = edate + hr + 6
    
imgcount = 1			;;; this starts the image count at 1 (you can change this to any number you want
  				        ;;; but note it counts up by 1 at a time as you move 6h forward in time

name = "6hprecip"
dir_grib = "/free2/abentley/realtime/"+name+"/archive/"		        
dir_out = "/lb11/abentley/www/test/images/"


if x .gt. 0 then
delete(fhr)
delete(fhr_cur)
delete(nfhr)
end if

;*****************************************************

if(fcast.eq."yes") then
  print("Will plot analysis first then forecast")

  do tim = sdate,fdate,6
         tim@units = "hours since 1800-01-01 00:00:00"   ;define units for t (which is the time in 6 hour intervals)
    
         if(tim.eq.sdate) then
             print("Time = Start Date")
         end if
         
         ; Let's make a few date strings
         str_time = ut_string(tim,"%y%N%D")
         str_hr = ut_string(tim,"%H")
         
         baddate1 = cd_inv_calendar(2016,4,14,0,00,00,timeUnits,0)
         baddate2 = cd_inv_calendar(2016,4,14,6,00,00,timeUnits,0)
         baddate3 = cd_inv_calendar(2016,4,14,12,00,00,timeUnits,0)
         baddate4 = cd_inv_calendar(2016,4,14,18,00,00,timeUnits,0)
         
         if (tim.eq.baddate1) .or. (tim.eq.baddate2) .or. (tim.eq.baddate3) .or. (tim.eq.baddate4) then
         	print("Got in here! It's gonna fail!")
         	system("'cp' /free2/abentley/realtime/GFS_"+str_time+"_"+str_hr+"_000 "+dir_grib+".")
         	print("Correct file moved to right folder!")
         end if	
  
         if (domain .eq. "NH") .and. (imgcount .eq. 1) then
         		cstr_time = ut_string(cdate,"%y%N%D")
         		print("cstr_time: "+cstr_time+" str_hr: "+str_hr)
             system("'cp' /nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+cstr_time+"_"+str_hr+"_006 /bosartlab_rit/abentley/data/precip/.")
             	ddate = cdate
				ddate = ddate - 28*24
				dateInformation2 = calendar_decode2(ddate,-5)
				pyyyy = dateInformation2(:,0)			;;; start date in yyyy mm dd hh
				pmm = dateInformation2(:,1)
				pdd = dateInformation2(:,2)
				phh = dateInformation2(:,3)
				pdate = cd_inv_calendar(pyyyy,pmm,pdd,00,00,00,timeUnits,0)
;				print("pdate: "+ut_string(pdate,""))
				pstr_time = ut_string(pdate,"%y%N%D")
         		pstr_hr = ut_string(pdate,"%H")
         		print("pstr_time: "+pstr_time+" pstr_hr: "+pstr_hr)      		
         			if (isfilepresent("/bosartlab_rit/abentley/data/precip/GFS_"+pstr_time+"_"+pstr_hr+"_006") .eq. True) then
         				print("File to remove is present!")	
		         	    system("'rm' /bosartlab_rit/abentley/data/precip/GFS_"+pstr_time+"_"+pstr_hr+"_006")	
         			end if
         end if
  
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
          ;check to make sure it exists too!
  
          if(tim .le. edate) then
                filename = dir_grib+"GFS_"+str_time+"_"+str_hr+"_000.grb2"
				if (isfilepresent(filename)) then
				    if (imgcount .gt. 35) then
				        system("rm -f "+dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000")			
				    end if
				else
				  	filename = dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000.grb2"
				  	print("File does not exist. Using last file that did...")
				    print("filename: "+filename)
				    check_dne = 1
                end if
                dne_time = ut_string(tim,"%y%N%D")
			    dne_hr = ut_string(tim,"%H")
          end if
  
          if(tim .eq. fdate) then
             print("Plotting from forecast grib files")
             ; HERE NEEDS A DELETE fhr????
;             delete(fhr)
             fhr  := (/6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192/)
             nfhr = dimsizes(fhr)
          else
             fhr = (/0/)
             nfhr = dimsizes(fhr)
          end if
  
          if(tim .gt. edate) then
             do f = 0,nfhr-2
                 if (fhr(f).lt.10) then
                      filefhr = "00"+fhr(f)
                 else if ((fhr(f).lt.100).and.(fhr(f).gt.10)) then
                      filefhr = "0"+fhr(f)
                 else if (fhr(f).gt.100) then
                      filefhr = fhr(f)
                 end if 
                 end if
                 end if
                 
                 if (fhr(f+1).lt.10) then
                      filefhr3 = "00"+fhr(f+1)
                 else if ((fhr(f+1).lt.100).and.(fhr(f+1).gt.10)) then
                      filefhr3 = "0"+fhr(f+1)
                 else if (fhr(f+1).gt.100) then
                      filefhr3 = fhr(f+1)
                 end if 
                 end if
                 end if
                 filename = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+str_time+"_"+str_hr+"_"+filefhr+".grb2"
                 fhr_cur = fhr(f)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************
;      	delete(a)
;      	delete(b)
;      	delete(mslp)      	
;      	delete(t)
;      	delete(u)
;      	delete(v)
;      	delete(precip)

  a = addfile(filename,"r")

  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01


  lev_temp = (/85000/) ; Needs to be in Pa
  t = a->TMP_P0_L100_GLL0({lev_temp},::-1,:)
  t = t - 273.15
  
  u = a->UGRD_P0_L103_GLL0(0,::-1,:)
  v = a->VGRD_P0_L103_GLL0(0,::-1,:)
  u = u * 1.94384449 
  v = v * 1.94384449 
  
  if imgcount .eq. 1 then
    old_str_time = str_time
  end if 
  
  if str_hr .eq. "00" then
     precip_hr = "18"
     pfcst_time = old_str_time
  else if str_hr .eq. "06" then
     precip_hr = "00"
     pfcst_time = str_time
  else if str_hr .eq. "12" then
     precip_hr = "06"
     pfcst_time = str_time
  else if str_hr .eq. "18" then
     precip_hr = "12"
     pfcst_time = str_time
  end if
  end if 
  end if 
  end if 
  
  old_str_time = str_time
  
  print("fhr(f): "+fhr(f))
  
if fhr(f) .eq. 6 then
  print("/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr+".grb2")
  print("/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr3+".grb2")
  filename2 = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr+".grb2"
  filename3 = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr3+".grb2"
  b = addfile(filename2,"r") 
  c = addfile(filename3,"r")  
  precip = b->APCP_P8_L1_GLL0_acc(::-1,:)
  precip2 = b->APCP_P8_L1_GLL0_acc(::-1,:)
  precip2 = 0
  precip = precip * .0393701  ; convert from mm to inches
  precip2 = precip2 * .0393701  ; convert from mm to inches

else if fhr(f) .ge. 12 then
  print("/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr+".grb2")
  print("/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr3+".grb2")
  filename2 = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr+".grb2"
  filename3 = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+pfcst_time+"_"+str_hr+"_"+filefhr3+".grb2"
  b = addfile(filename2,"r") 
  c = addfile(filename3,"r")  
  precip = total_precip
  precip2 = c->APCP_P8_L1_GLL0_acc6h(::-1,:)
  precip2 = precip2 * .0393701  ; convert from mm to inches
 
else
  print("/bosartlab_rit/abentley/data/precip/GFS_"+pfcst_time+"_"+precip_hr+"_006.grb2")
  filename2 = "/bosartlab_rit/abentley/data/precip/GFS_"+pfcst_time+"_"+precip_hr+"_006.grb2"
  b = addfile(filename2,"r")  
  precip = b->APCP_P8_L1_GLL0_acc(::-1,:)

end if
end if

;printVarSummary(precip)
  
;  printMinMax(t,True)

  do d=0,2
    t=smth9(t,.5,.25,True)
  end do
  
; tot_precip = new((/2,361,720/),"float")
 
; tot_precip(0,:,:) = precip
; tot_precip(1,:,:) = precip2
;  total_precip = dim_avg_n_Wrap(tot_precip,0)
 
 total_precip = precip + precip2
 copy_VarCoords(precip2,total_precip)
 
 
;  do d=0,1
;    total_precip=smth9(total_precip,.5,-.25,True)
;  end do

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,"/free2/abentley/realtime/"+name+"/archive/"+name+"_"+imgcount)
gsn_define_colormap(wks,"precip")
;gsn_reverse_colormap(wks)
;**********************************************

res = True

res@gsnFrame = False                                    ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                     ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                      ; Turn on color fill
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLinesOn = False                               ; Turn off contour lines
;res@cnLevelSpacingF = 1                            ; Shading interval
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLevels = (/.10,.25,.50,.75,1.0,1.25,1.5,1.75,2.0,2.5,3.0,4.0,5.0,6.0,8.0,12.0,15.0/)
;res@cnLevels = (/5.0,10.0,15.0,20.0,30.0,40.0,50.0,60.0,70.0,80.0,100.0,120.0,140.0,160.0,200.0,240.0,280.0,320.0/)
res@cnFillColors = (/-1,7,8,9,10,11,12,13,14,15,16,17,18,19,20,22,23,24/)

;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                   ; Outline the color bar 
res@lbTopMarginF = .3

;**********************************************

res@tiMainString = " "
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = .02
res@tiXAxisFontHeightF = .015

res@gsnLeftString = "Accum. precip. (inches) since 0600 UTC 20 Jun 2017"
res@gsnLeftStringOrthogonalPosF = .0075
res@gsnLeftStringFontHeightF = .009
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013

  curdate = tim + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

  if (fhr_cur .gt. 0) then
     res@gsnRightString = "("+fhr_cur+" h fcst) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "red"
     res@gsnRightStringFontColor = "red"
  else
     res@gsnRightString = "(Analysis) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  end if
; *********************************************

res@mpGeophysicalLineThicknessF = 7.0
res@mpNationalLineThicknessF = 7.0
res@mpUSStateLineThicknessF = 5.0
res@mpOutlineSpecifiers = (/"Canada : Provinces","United States : States"/)

res@mpGeophysicalLineColor = "black"
res@mpNationalLineColor = "black"
res@mpUSStateLineColor = "black"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 5.
res@mpGridLonSpacingF = 5.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey28"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,5)
tmres@tmYRValues = ispan(-80,80,5)
tmres@tmXBValues = ispan(-180,179,10)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = ispan(-180,179,5)
; *************************************************************

if domain .eq. "northamer"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
res@mpLambertMeridianF = -100
res@mpLimitMode = "LatLon"
res@mpMinLatF = 8
res@mpMaxLatF = 69
res@mpMinLonF = -151
res@mpMaxLonF = -49
end if


if domain .eq. "pacific"
res@mpProjection = "LambertConformal"
  westlon = 118.
  eastlon = -118.
  centerlon = 180. ; to use this effectively remember its the the distance of lon between west and east divided by 2
  if(westlon.gt.eastlon)then
    useflip = True
    westlon = westlon
    eastlon = eastlon+360.
    if (centerlon.lt.0)then
      centerlon = centerlon+360.
    end if
  end if
res@mpLambertParallel2F = 28
res@mpLambertParallel1F = 7
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = centerlon
res@mpLimitMode = "LatLon"
res@mpMinLatF = -15
res@mpMaxLatF = 71
res@mpMinLonF = westlon
res@mpMaxLonF = eastlon
end if



if domain .eq. "atlantic"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = -20
res@mpLimitMode = "LatLon"
res@mpMinLatF = 6
res@mpMaxLatF = 71
res@mpMinLonF = -90
res@mpMaxLonF = 30
end if


if domain .eq. "europe"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 20
res@mpLambertParallel1F = 11
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = 0
res@mpLimitMode = "LatLon"
res@mpMinLatF = 25
res@mpMaxLatF = 72
res@mpMinLonF = -46
res@mpMaxLonF = 46
end if

if domain .eq. "southamer"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -70
res@mpMaxLatF = 8
res@mpMinLonF = -122
res@mpMaxLonF = 12
end if

if domain .eq. "eastcoast"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 15
res@mpLambertParallel1F = 10
res@mpLambertMeridianF = -130
res@mpLimitMode = "LatLon"
res@mpMinLatF = 28
res@mpMaxLatF = 58
res@mpMinLonF = -150
res@mpMaxLonF = -110
end if

if domain .eq. "southeast"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 15
res@mpLambertParallel1F = 10
res@mpLambertMeridianF = -85
res@mpLimitMode = "LatLon"
res@mpMinLatF = 15
res@mpMaxLatF = 50
res@mpMinLonF = -110
res@mpMaxLonF = -60
end if

; *************************************************************

thres = True

thres@gsnFrame = False                                        
thres@gsnDraw = False

thres@gsnLeftString = " "
thres@gsnRightString = " "
thres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
thres@cnFillOn = False
thres@cnLinesOn = True
thres@cnLabelMasking = True
thres@cnLineThicknessF = 5
thres@cnLineColor = "red"
thres@cnLineLabelFontColor = "red"
thres@cnLevelSelectionMode = "ManualLevels"
thres@cnLevelSpacingF = 5
thres@cnMinLevelValF = 5
thres@cnMaxLevelValF = 60 
thres@cnLineLabelAngleF = 0.0
thres@cnLineLabelInterval = 3
thres@cnLineLabelDensityF = .90
thres@cnLineLabelBackgroundColor = -1
thres@cnLineLabelFontHeightF = 0.008
thres@cnLineDashPattern = 5
thres@gsnAddCyclic =  True


; *************************************************************


th2res = True

th2res@gsnFrame = False                                        
th2res@gsnDraw = False

th2res@gsnLeftString = " "
th2res@gsnRightString = " "
th2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
th2res@cnFillOn = False
th2res@cnLinesOn = True
th2res@cnLabelMasking = True
th2res@cnLineThicknessF = 5
th2res@cnLineColor = "blue"
th2res@cnLineLabelFontColor = "blue"
th2res@cnLevelSelectionMode = "ManualLevels"
th2res@cnLevelSpacingF = 5
th2res@cnMinLevelValF = -60
th2res@cnMaxLevelValF = 0 
th2res@cnLineLabelAngleF = 0.0
th2res@cnLineLabelInterval = 3
th2res@cnLineLabelDensityF = .90
th2res@cnLineLabelBackgroundColor = -1
th2res@cnLineLabelFontHeightF = 0.008
th2res@cnLineDashPattern = 5
th2res@gsnAddCyclic =  True


; *************************************************************

mres = True

mres@gsnFrame = False                                        
mres@gsnDraw = False

mres@gsnLeftString = " "
mres@gsnRightString = " "

mres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
mres@cnFillOn = False
mres@cnLineLabelsOn = True
mres@cnLinesOn = True
mres@cnLabelMasking = True
mres@cnLineThicknessF = 4                    ; Changes thickness of contours
mres@cnLevelSelectionMode = "ManualLevels"
mres@cnLevelSpacingF = 4
mres@cnMinLevelValF = 800
mres@cnMaxLevelValF = 1200  
mres@cnLineLabelAngleF = 0.0
mres@cnLineLabelInterval = 2
mres@cnLineLabelDensityF = 1.4
;mres@cnSmoothingOn = True
;mres@cnSmoothingDistanceF = 0.009
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

; *************************************************************

    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey23"
    bres@vcWindBarbCalmCircleSizeF = 0
    bres@vcWindBarbLineThicknessF = 3.0
    bres@vcRefAnnoOn = False
    bres@vcRefLengthF = 0.0242
    bres@vcRefMagnitudeF = 10.0
    bres@vcRefAnnoString2On = False
    bres@vcRefAnnoOrthogonalPosF = -1.08
    bres@vcMinDistanceF = 0.025
    bres@vcWindBarbTickLengthF = 0.37
    bres@vcWindBarbTickSpacingF = 0.130
    bres@vcWindBarbTickAngleF = 55.0
    bres@gsnFrame = False
    bres@gsnAddCyclic =  True


; *************************************************************
res@mpFillOn = False
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
thres@cnLineDrawOrder ="Draw"
th2res@cnLineDrawOrder ="Draw"
mres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, total_precip, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, mslp, mres)
other = gsn_csm_contour(wks, t, thres)
other2 = gsn_csm_contour(wks, t, th2res)
barbs = gsn_csm_vector(wks, u, v, bres)
plot = add_map_tickmarks(wks,plot,tmres)

;==============================================
; Set Marker and Text Resources
;==============================================

tres = True
tres@txFontHeightF = 0.018
tres@txJust = "CenterLeft"
tres@gsLineDashPattern = 5
;tres@txFontThicknessF = 10
tres@gsLineThicknessF = 3
tres@gsLineColor = "grey12"

if domain .eq. "northamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-148.5,3.5,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-148,2,tres)
else if domain .eq. "pacific" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",117.7,-6.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",118.4,-8.8,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-85.0,-4,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-84,-6,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-45.0,23.2,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-44.7,21.7,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-121.5,-68.6,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-121.5,-69.5,tres)
else if domain .eq. "eastcoast" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01    
    mytext = gsn_add_text(wks,plot,"Alicia M. Bentley",-149.75,28.55,tres)
    mytext2 = gsn_add_text(wks,plot,"www.AliciaMBentley.com",-149.7,27.8,tres)
end if 
end if 
end if
end if
end if
end if 

;********************************************

;overlay(plot,other)
;overlay(plot,other2)
;overlay(plot,contours)
;overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert /free2/abentley/realtime/"+name+"/archive/"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' /free2/abentley/realtime/"+name+"/archive/"+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

                 imgcount = imgcount + 1
             end do

          else
             if(tim .eq. sdate) then
                 print("Plotting from archived grib files")
             end if

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************
   if delall .eq. 1 then
      	delete(a)
      	delete(b)
      	delete(mslp)      	
      	delete(t)
      	delete(u)
      	delete(v)
      	delete(precip)
  end if

  delall = 1
  a = addfile(filename,"r")

  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01


  lev_temp = (/85000/) ; Needs to be in Pa
  t = a->TMP_P0_L100_GLL0({lev_temp},::-1,:)
  t = t - 273.15
  
  u = a->UGRD_P0_L103_GLL0(0,::-1,:)
  v = a->VGRD_P0_L103_GLL0(0,::-1,:)
  u = u * 1.94384449 
  v = v * 1.94384449 
  
  if (imgcount .eq. 1) then
  	old_str_time = ut_string(olddate,"%y%N%D")
  	print("First image of new domain! Setting old_str_time again!")
  end if 
  
  if str_hr .eq. "00" then
     precip_hr = "18"
     pfcst_time = old_str_time
  else if str_hr .eq. "06" then
     precip_hr = "00"
     pfcst_time = str_time
  else if str_hr .eq. "12" then
     precip_hr = "06"
     pfcst_time = str_time
  else if str_hr .eq. "18" then
     precip_hr = "12"
     pfcst_time = str_time
  end if
  end if 
  end if 
  end if 
  
  old_str_time = str_time
  
  print("/bosartlab_rit/abentley/data/precip/GFS_"+pfcst_time+"_"+precip_hr+"_006.grb2")
  filename2 = "/bosartlab_rit/abentley/data/precip/GFS_"+pfcst_time+"_"+precip_hr+"_006.grb2"
  b = addfile(filename2,"r")  
  precip = b->APCP_P8_L1_GLL0_acc(::-1,:)
;  precip = precip * .0393701  ; convert from mm to inches
  
;  printMinMax(t,True)

  do d=0,2
    t=smth9(t,.5,.25,True)
  end do

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,"/free2/abentley/realtime/"+name+"/"+name+"_"+imgcount)
gsn_define_colormap(wks,"precip")
;gsn_reverse_colormap(wks)
;**********************************************

res = True

res@gsnFrame = False                                    ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                     ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                      ; Turn on color fill
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLinesOn = False                               ; Turn off contour lines
;res@cnLevelSpacingF = 1                            ; Shading interval
res@cnLevelSelectionMode = "ExplicitLevels"
;res@cnLevels = (/.01,.10,.25,.50,.75,1.0,1.25,1.5,1.75,2.0,2.5,3.0,4.0,5.0,6.0,7.0,8.0,9.0/)
res@cnLevels = (/.25,2.5,5.0,10.0,15.0,20.0,30.0,40.0,50.0,60.0,70.0,80.0,100.0,120.0,140.0,160.0,180.0,200.0/)
res@cnFillColors = (/-1,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24/)

;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                   ; Outline the color bar 
res@lbTopMarginF = .3

;**********************************************

res@tiMainString = " "
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = .02
res@tiXAxisFontHeightF = .015

res@gsnLeftString = "Accum. precip. (mm) since 1200 UTC 2 Oct 2016"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013

res@gsnRightString = "(Analysis) "+ut_string(tim,"")
res@gsnLeftStringFontColor = "black"
res@gsnRightStringFontColor = "black"


; *********************************************

res@mpGeophysicalLineThicknessF = 2.0
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey28"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
tmres@tmXBValues = ispan(-180,179,40)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = ispan(-180,179,5)
; *************************************************************

if domain .eq. "northamer"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
res@mpLambertMeridianF = -100
res@mpLimitMode = "LatLon"
res@mpMinLatF = 8
res@mpMaxLatF = 69
res@mpMinLonF = -151
res@mpMaxLonF = -49
end if


if domain .eq. "pacific"
res@mpProjection = "LambertConformal"
  westlon = 118.
  eastlon = -118.
  centerlon = 180. ; to use this effectively remember its the the distance of lon between west and east divided by 2
  if(westlon.gt.eastlon)then
    useflip = True
    westlon = westlon
    eastlon = eastlon+360.
    if (centerlon.lt.0)then
      centerlon = centerlon+360.
    end if
  end if
res@mpLambertParallel2F = 28
res@mpLambertParallel1F = 7
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = centerlon
res@mpLimitMode = "LatLon"
res@mpMinLatF = -15
res@mpMaxLatF = 71
res@mpMinLonF = westlon
res@mpMaxLonF = eastlon
end if



if domain .eq. "atlantic"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = -20
res@mpLimitMode = "LatLon"
res@mpMinLatF = 6
res@mpMaxLatF = 71
res@mpMinLonF = -90
res@mpMaxLonF = 30
end if


if domain .eq. "europe"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 20
res@mpLambertParallel1F = 11
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = 0
res@mpLimitMode = "LatLon"
res@mpMinLatF = 25
res@mpMaxLatF = 72
res@mpMinLonF = -46
res@mpMaxLonF = 46
end if

if domain .eq. "southamer"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -70
res@mpMaxLatF = 8
res@mpMinLonF = -122
res@mpMaxLonF = 12
end if

if domain .eq. "eastcoast"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 20
res@mpLambertParallel1F = 10
res@mpLambertMeridianF = -80
res@mpLimitMode = "LatLon"
res@mpMinLatF = 8
res@mpMaxLatF = 56
res@mpMinLonF = -101
res@mpMaxLonF = -49
end if

; *************************************************************

thres = True

thres@gsnFrame = False                                        
thres@gsnDraw = False

thres@gsnLeftString = " "
thres@gsnRightString = " "
thres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
thres@cnFillOn = False
thres@cnLinesOn = True
thres@cnLabelMasking = True
thres@cnLineThicknessF = 5
thres@cnLineColor = "red"
thres@cnLineLabelFontColor = "red"
thres@cnLevelSelectionMode = "ManualLevels"
thres@cnLevelSpacingF = 5
thres@cnMinLevelValF = 5
thres@cnMaxLevelValF = 60 
thres@cnLineLabelAngleF = 0.0
thres@cnLineLabelInterval = 3
thres@cnLineLabelDensityF = .90
thres@cnLineLabelBackgroundColor = -1
thres@cnLineLabelFontHeightF = 0.008
thres@cnLineDashPattern = 5
thres@gsnAddCyclic =  True


; *************************************************************


th2res = True

th2res@gsnFrame = False                                        
th2res@gsnDraw = False

th2res@gsnLeftString = " "
th2res@gsnRightString = " "
th2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
th2res@cnFillOn = False
th2res@cnLinesOn = True
th2res@cnLabelMasking = True
th2res@cnLineThicknessF = 5
th2res@cnLineColor = "blue"
th2res@cnLineLabelFontColor = "blue"
th2res@cnLevelSelectionMode = "ManualLevels"
th2res@cnLevelSpacingF = 5
th2res@cnMinLevelValF = -60
th2res@cnMaxLevelValF = 0 
th2res@cnLineLabelAngleF = 0.0
th2res@cnLineLabelInterval = 3
th2res@cnLineLabelDensityF = .90
th2res@cnLineLabelBackgroundColor = -1
th2res@cnLineLabelFontHeightF = 0.008
th2res@cnLineDashPattern = 5
th2res@gsnAddCyclic =  True


; *************************************************************

mres = True

mres@gsnFrame = False                                        
mres@gsnDraw = False

mres@gsnLeftString = " "
mres@gsnRightString = " "

mres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
mres@cnFillOn = False
mres@cnLineLabelsOn = True
mres@cnLinesOn = True
mres@cnLabelMasking = True
mres@cnLineThicknessF = 4                    ; Changes thickness of contours
mres@cnLevelSelectionMode = "ManualLevels"
mres@cnLevelSpacingF = 4
mres@cnMinLevelValF = 800
mres@cnMaxLevelValF = 1200  
mres@cnLineLabelAngleF = 0.0
mres@cnLineLabelInterval = 2
mres@cnLineLabelDensityF = 1.4
;mres@cnSmoothingOn = True
;mres@cnSmoothingDistanceF = 0.009
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

; *************************************************************

    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey23"
    bres@vcWindBarbCalmCircleSizeF = 0
    bres@vcWindBarbLineThicknessF = 3.0
    bres@vcRefAnnoOn = False
    bres@vcRefLengthF = 0.0242
    bres@vcRefMagnitudeF = 10.0
    bres@vcRefAnnoString2On = False
    bres@vcRefAnnoOrthogonalPosF = -1.08
    bres@vcMinDistanceF = 0.025
    bres@vcWindBarbTickLengthF = 0.37
    bres@vcWindBarbTickSpacingF = 0.130
    bres@vcWindBarbTickAngleF = 55.0
    bres@gsnFrame = False
    bres@gsnAddCyclic =  True


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
thres@cnLineDrawOrder ="Draw"
th2res@cnLineDrawOrder ="Draw"
mres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, precip, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, mslp, mres)
other = gsn_csm_contour(wks, t, thres)
other2 = gsn_csm_contour(wks, t, th2res)
barbs = gsn_csm_vector(wks, u, v, bres)
plot = add_map_tickmarks(wks,plot,tmres)

;==============================================
; Set Marker and Text Resources
;==============================================

tres = True
tres@txFontHeightF = 0.018
tres@txJust = "CenterLeft"
tres@gsLineDashPattern = 5
;tres@txFontThicknessF = 10
tres@gsLineThicknessF = 3
tres@gsLineColor = "grey12"

if domain .eq. "northamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-148.5,3.5,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-148,2,tres)
else if domain .eq. "pacific" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",117.7,-6.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",118.4,-8.8,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-85.0,-4,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-84,-6,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-45.0,23.2,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-44.7,21.7,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"Alicia M. Bentley",-121.5,-68.6,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-121.5,-69.5,tres)
end if       
end if
end if
end if
end if 

;********************************************

overlay(plot,other)
overlay(plot,other2)
overlay(plot,contours)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert /free2/abentley/realtime/"+name+"/"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' /free2/abentley/realtime/"+name+"/"+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

             imgcount = imgcount + 1
          end if

          ; remove the grb2 file to save space
          if(tim .le. edate) then
             system("rm -f "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar") ; now remove the tar file (only have to do this once)
          end if
    end do

else
    print("Just the analysis")
    print("But I'll handle that later!")   ;maybe can always do the forecast and then just make it plot one time and quit
end if

system("rm -f "+dir_grib+"GFS_*_000")
system("rm -f "+dir_grib+"*.grb2.tar")

end do ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end