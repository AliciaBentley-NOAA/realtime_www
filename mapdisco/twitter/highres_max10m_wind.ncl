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

if shh .lt. 7 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,00,00,00,timeUnits,0) ;;; Convert string values to integers to use cd_inv_calendar function
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 00  ;;; choose forecast synoptic time (e.g. 00 will plot the forecast initialized at 00 UTC)
else if shh .ge. 7 .and. shh .lt. 15 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,06,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 06
else if shh .ge. 15 .and. shh .lt. 19 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 12
else if shh .ge. 19 then
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

folder = (/"haiti"/)  
;folder = (/"northamer"/) 
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)

fcast = "yes" 		        ;;; do you want to plot the 192 hour GFS forecast at the next synoptic time?	         	
  
fdate = edate + hr + 6
    
imgcount = 1			;;; this starts the image count at 1 (you can change this to any number you want
  				        ;;; but note it counts up by 1 at a time as you move 6h forward in time

name = "10m_wind_max"
dir_grib = "/free/abentley/twitter/grib/"		        
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
				    if (imgcount .gt. 3) then
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
             fhr  = (/0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57,60,63,66,69,72,75,78,81,84/)
             nfhr = dimsizes(fhr)
          else
             fhr = (/0/)
             nfhr = dimsizes(fhr)
          end if
  
          if(tim .gt. edate) then
             do f = 0,nfhr-1
                 if (fhr(f).lt.10) then
                      filefhr = "0"+fhr(f)
                 else if (fhr(f).gt.10) then
                      filefhr = fhr(f)
                 end if 
                 end if
  print("ftp://ftp.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.2016100612/gfs.t12z.sfluxgrbf"+filefhr+".grib2")
  
  system("'rm' gfs.t12z.sfluxgrbf*.grib2")
  system("wget ftp://ftp.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.2016100612/gfs.t12z.sfluxgrbf"+filefhr+".grib2")

                 filename = dir_grib+"gfs.t12z.sfluxgrbf"+filefhr+".grib2"
                 fhr_cur = fhr(f)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

  a = addfile(filename,"r")
  
  	u10m := a->UGRD_P0_L103_GGA0(::-1,:)
  	v10m := a->VGRD_P0_L103_GGA0(::-1,:)
  	
  	printVarSummary(u10m)
  	
  	speedms := ((u10m^2)+(v10m^2))^0.5
	copy_VarCoords(u10m,speedms)  	
	speedmph := (speedms*2.23694) ; convert from m/s to mph
	copy_VarCoords(speedms,speedmph)
	check := new((/2,1536,3072/),"float")
	
if fhr(f) .eq. 0 then
	plotmax = speedmph
	print("New Max: "+plotmax(30,30))

else if fhr(f) .ge. 3 then
	check(0,:,:) = plotmax
	check(1,:,:) = speedmph
	plotmax = dim_max_n(check,0)
	copy_VarCoords(plotmax,speedmph)
	
	print("Checking max...")
	print("Old max: "+check(0,30,30))
	print("Is this higher?: "+check(1,30,30))
	print("New max: "+plotmax(30,30))

end if
end if
  
print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_grib+name+"_"+imgcount)
gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
;**********************************************
res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                              ; Turn on color fill
;res@cnFillMode = "RasterFill"
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 5
res@cnMinLevelValF = 0
res@cnMaxLevelValF = 100
;res@cnFillColors = (/0,21,32,36,42,47,58,66,74,90,110,120,130,138,154,162,170,186,192,196,199/)
res@cnFillColors = (/0,21,31,35,42,47,55,62,71,80,90,110,120,130,138,154,162,170,186,192,196,199,1/)

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

res@gsnLeftString = "Maximum 10-meter wind speed (mph) from 13-km GFS"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
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

res@mpGeophysicalLineThicknessF = 4.5
res@mpNationalLineThicknessF = 4.5
res@mpUSStateLineThicknessF = 4.5
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "black"
res@mpNationalLineColor = "black"
res@mpUSStateLineColor = "black"

; *********************************************
res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 5.
res@mpGridLonSpacingF = 5.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey29"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,5)
tmres@tmYRValues = ispan(-80,80,5)
tmres@tmXBValues = ispan(-180,179,5)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = (/-175,-170,-165,-160,-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,145,150,155,160,165,170,175/)


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

if domain .eq. "haiti"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 20
res@mpLambertParallel1F = 10
res@mpLambertMeridianF = -80
res@mpLimitMode = "LatLon"
res@mpMinLatF = 22
res@mpMaxLatF = 36
res@mpMinLonF = -89
res@mpMaxLonF = -71
end if

; *************************************************************

cnres = True

cnres@gsnFrame = False                                        
cnres@gsnDraw = False

cnres@gsnLeftString = " "
cnres@gsnRightString = " "

cnres@cnFillMode = "AreaFill"
cnres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cnres@cnFillOn = False
cnres@cnLinesOn = True
cnres@cnLabelMasking = True
cnres@cnLineThicknessF = 4                    ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 3
cnres@cnMinLevelValF = 90
cnres@cnMaxLevelValF = 420  
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = 1.1
;cnres@cnSmoothingOn = True
;cnres@cnSmoothingDistanceF = 0.009
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008

; *************************************************************

tres = True

tres@gsnFrame = False                                        
tres@gsnDraw = False

tres@cnFillMode = "AreaFill"
tres@gsnLeftString = " "
tres@gsnRightString = " "
tres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
tres@cnFillOn = False
tres@cnLinesOn = True
tres@cnLabelMasking = True
tres@cnLineThicknessF = 4
tres@cnLineColor = "red"
tres@cnLineLabelFontColor = "red"
tres@cnLevelSelectionMode = "ManualLevels"
tres@cnLevelSpacingF = 4
tres@cnMinLevelValF = -72
tres@cnMaxLevelValF = 36
tres@cnLineLabelsOn = True
tres@cnLineLabelAngleF = 0.0
tres@cnLineLabelInterval = 2
tres@cnLineLabelDensityF = 1.0
tres@cnLineLabelBackgroundColor = -1
tres@cnLineLabelFontHeightF = 0.008
tres@cnLineDashPattern = 5
tres@gsnAddCyclic =  True

; *************************************************************


    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey22"
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
cnres@cnLineDrawOrder ="Draw"
tres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, plotmax, res)          ; Plot filled contour map
;contours = gsn_csm_contour(wks, g, cnres)
;barbs = gsn_csm_vector(wks, u, v, bres)
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
tres@gsLineColor = "grey29"

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
else if domain .eq. "haiti" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01    
    mytext = gsn_add_text(wks,plot,"Alicia M. Bentley",-88.8,22.6,tres)
    mytext2 = gsn_add_text(wks,plot,"www.AliciaMBentley.com",-88.79,22.2,tres)
end if
end if 
end if
end if
end if
end if 

;********************************************

;overlay(plot,contours)
;overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert "+dir_grib+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' "+dir_grib+name+"_*.png") 

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
      	delete(u)
      	delete(v)
      	delete(g)
  end if

  delall = 1
  a := addfile(filename,"r")
  
  lev = (/85000/)

print("loading data")
;Compute the equivalent temperature in the 1000-850 hPa layer.
           t850 := a->TMP_P0_L100_GLL0({85000:100000},::-1,:)
           rh850 := a->RH_P0_L100_GLL0({85000:100000},::-1,:)
           pres := a->lv_ISBL0({85000:100000})
           phpa := pres
           phpa := pres/100
           q850 := t850
           q850 := mixhum_ptrh(conform(t850,phpa,0),t850,rh850,1)
           t_e := t850
           t_e=t850+(2.6e6/1004)*q850

;Compute the max theta-e in the 1000-850 hPa layer.
           theta_e_all := t_e*(1000/conform(t_e,phpa,0))^0.286
           theta_e := theta_e_all(0,:,:)
 ;          printMinMax(theta_e,True)


  u := a->UGRD_P0_L100_GLL0({lev},::-1,:)
  v := a->VGRD_P0_L100_GLL0({lev},::-1,:)
  u = u * 1.94384449 
  v = v * 1.94384449 

  g := a->HGT_P0_L100_GLL0({lev},::-1,:) 
  g = g/10
  
  copy_VarCoords(g,theta_e)
 
;  t := a->TMP_P0_L100_GLL0({lev},::-1,:)
;  t = t - 273.15
;  copy_VarCoords(g,t)

;do d=0,3
;t=smth9(t,.5,.25,True)
;end do

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,"/free2/abentley/realtime/"+name+"/"+name+"_"+imgcount)
gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
;**********************************************
res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                              ; Turn on color fill
;res@cnFillMode = "RasterFill"
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 6
res@cnMinLevelValF = 250
res@cnMaxLevelValF = 370
;res@cnFillColors = (/0,21,32,36,42,47,58,66,74,90,110,120,130,138,154,162,170,186,192,196,199/)
res@cnFillColors = (/0,21,31,35,42,47,55,62,71,80,90,110,120,130,138,154,162,170,186,192,196,199/)

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

res@gsnLeftString = "850-hPa theta-e, heights, and wind"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013

res@gsnRightString = "(Analysis) "+ut_string(tim,"")
res@gsnLeftStringFontColor = "black"
res@gsnRightStringFontColor = "black"

; *********************************************

res@mpGeophysicalLineThicknessF = 4.5
res@mpNationalLineThicknessF = 4.5
res@mpUSStateLineThicknessF = 4.5
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "navyblue"
res@mpNationalLineColor = "navyblue"
res@mpUSStateLineColor = "navyblue"

; *********************************************
res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey29"
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

tmres@tmYRMinorValues = (/5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = (/-175,-170,-165,-160,-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,145,150,155,160,165,170,175/)

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

; *************************************************************


cnres = True

cnres@gsnFrame = False                                        
cnres@gsnDraw = False

cnres@gsnLeftString = " "
cnres@gsnRightString = " "

cnres@cnFillMode = "AreaFill"
cnres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cnres@cnFillOn = False
cnres@cnLinesOn = True
cnres@cnLabelMasking = True
cnres@cnLineThicknessF = 4                    ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 3
cnres@cnMinLevelValF = 90
cnres@cnMaxLevelValF = 420  
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = 1.1
;cnres@cnSmoothingOn = True
;cnres@cnSmoothingDistanceF = 0.009
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008

; *************************************************************

tres = True

tres@gsnFrame = False                                        
tres@gsnDraw = False

tres@cnFillMode = "AreaFill"
tres@gsnLeftString = " "
tres@gsnRightString = " "
tres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
tres@cnFillOn = False
tres@cnLinesOn = True
tres@cnLabelMasking = True
tres@cnLineThicknessF = 4
tres@cnLineColor = "red"
tres@cnLineLabelFontColor = "red"
tres@cnLevelSelectionMode = "ManualLevels"
tres@cnLevelSpacingF = 4
tres@cnMinLevelValF = -72
tres@cnMaxLevelValF = 36
tres@cnLineLabelsOn = True
tres@cnLineLabelAngleF = 0.0
tres@cnLineLabelInterval = 2
tres@cnLineLabelDensityF = 1.0
tres@cnLineLabelBackgroundColor = -1
tres@cnLineLabelFontHeightF = 0.008
tres@cnLineDashPattern = 5
tres@gsnAddCyclic =  True

; *************************************************************


    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey22"
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
cnres@cnLineDrawOrder ="Draw"
tres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, plotmaxgust, res)          ; Plot filled contour map
;contours = gsn_csm_contour(wks, g, cnres)
;barbs = gsn_csm_vector(wks, u, v, bres)
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
tres@gsLineColor = "grey29"

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

;overlay(plot,contours)
;overlay(plot,barbs)

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

system("rm -f "+dir_grib+"gfs.t12z.sfluxgrbf"+filefhr+".grib2")
system("rm -f "+dir_grib+"*.grb2.tar")

end do ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end