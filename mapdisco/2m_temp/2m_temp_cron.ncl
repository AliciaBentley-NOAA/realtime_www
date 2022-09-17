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
bdate = bdate - 14*24
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

if shh .gt. 1 .and. shh .lt. 7 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,00,00,00,timeUnits,0) ;;; Convert string values to integers to use cd_inv_calendar function
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 00  ;;; choose forecast synoptic time (e.g. 00 will plot the forecast initialized at 00 UTC)
else if shh .ge. 7 .and. shh .lt. 15 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,06,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 06
else if shh .ge. 15 .and. shh .lt. 20 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 12
else if shh .ge. 20 .or. shh .le. 1 then
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

folder = (/"southpac"/)  
;folder = (/"northamer","europe","pacific","atlantic"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)

fcast = "yes" 		        ;;; do you want to plot the 192 hour GFS forecast at the next synoptic time?	         	
  
fdate = edate + hr + 6
    
imgcount = 1			;;; this starts the image count at 1 (you can change this to any number you want
  				        ;;; but note it counts up by 1 at a time as you move 6h forward in time

name = "2m_temp"
dir_grib = "/free/abentley/realtime/grib/"	
dir_plot = "/free/abentley/realtime/"+name+"/grib/"	        
dir_out = "/lb11/abentley/www/realtime/images/"+domain+"/"+name+"/"

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
;  	        system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
;  	        system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if
  
             ;;; new... to read in files that don't start at 00 UTC
             if( (tim.eq.sdate) .and. (str_hr.ne."00")) then
;                system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
;  	            system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if  
          end if
      
          ;now that the filename should be in the proper directory, go ahead and add it
          ;check to make sure it exists too!
  
          if(tim .le. edate) then
                filename = dir_grib+"GFS_"+str_time+"_"+str_hr+"_000.grb2"
				if (isfilepresent(filename)) then
				    if (imgcount .gt. 1) then
;				        system("rm -f "+dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000")			
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
             delete(fhr)
             fhr  = (/0,6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192/)
             nfhr = dimsizes(fhr)
          else
             fhr = (/0/)
             nfhr = dimsizes(fhr)
          end if
  
          if(tim .gt. edate) then
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

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************
      	delete(a)
      	delete(mslp)
      	delete(u)
      	delete(v)
      	delete(temp)

  a = addfile(filename,"r")

  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01

  u = a->UGRD_P0_L103_GLL0(0,::-1,:)
  v = a->VGRD_P0_L103_GLL0(0,::-1,:)
  u = u * 1.94384449 
  v = v * 1.94384449 
  
  temp = a->TMP_P0_L103_GLL0(0,::-1,:)
  temp = temp - 273.15
  copy_VarCoords(u,temp)
  temp@units = "C"
;  printVarSummary(temp)
;  printMinMax(temp, True) 

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+"/"+name+"_"+imgcount)
gsn_define_colormap(wks,"tempprac")
;**********************************************

res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                              ; Turn on color fill
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 1
res@cnMinLevelValF = -50
res@cnMaxLevelValF = 50  
;res@cnFillColors = (/2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60/)
res@cnFillColors = (/2,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,53,54,55,56,57,58,59,60/)

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

res@gsnLeftString = "MSLP; 2-m temperature (0~F34~0~F~C line in white); 10-m wind"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightString = ut_string(tim,"")
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

res@mpGeophysicalLineThicknessF = 2.0
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey16"
res@mpNationalLineColor = "grey16"
res@mpUSStateLineColor = "grey16"

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
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/);tmres@tmXBMinorValues = (/-175,-170,-165,-160,-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-40,-35,-30,-25,-15,-10,-5,0,5,10,15,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,145,150,155,160,165,170,175/)
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
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
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
cnres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cnres@cnFillOn = False
cnres@cnLinesOn = True
cnres@cnLabelMasking = True
cnres@cnLineLabelsOn = False
cnres@cnLineThicknessF = 3
cnres@cnLineColor = "white"
cnres@cnLevelSelectionMode = "ExplicitLevels"
cnres@cnLevels = (/0/)
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 1
cnres@cnLineLabelDensityF = .77
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.018
cnres@cnSmoothingOn = True
cnres@cnSmoothingDistanceF = 0.00001

if domain .eq. "europe" then
cnres@cnLineThicknessF = 4
end if

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
cnres@cnLineDrawOrder ="Draw"
mres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, temp, res)          ; Plot filled contour map
other = gsn_csm_contour(wks, temp, cnres)
contours = gsn_csm_contour(wks, mslp, mres)
barbs = gsn_csm_vector(wks, u, v, bres)
plot = add_map_tickmarks(wks,plot,tmres)

;==============================================
; Set Marker and Text Resources
;==============================================

tres = True
tres@gsLineDashPattern = 5
tres@gsLineThicknessF = 3
tres@gsLineColor = "grey12"

if domain .eq. "northamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-148.5,3.5,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-148,2,tres)
else if domain .eq. "pacific" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",117.7,-6.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",118.4,-8.8,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-85.0,-4,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-84,-6,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-45.0,23.2,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-44.7,21.7,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-121.5,-68.6,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-121.5,-69.5,tres)
end if 
end if
end if
end if
end if 

;********************************************

overlay(plot,other)
overlay(plot,contours)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert "+dir_plot+"/"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".png")
system ("'rm' "+dir_plot+"/"+name+"_*.png") 


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
      	delete(mslp)
      	delete(u)
      	delete(v)
      	delete(temp)
  end if
  
  delall = 1

  a = addfile(filename,"r")

  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01

  u = a->UGRD_P0_L103_GLL0(0,::-1,:)
  v = a->VGRD_P0_L103_GLL0(0,::-1,:)
  u = u * 1.94384449 
  v = v * 1.94384449 
  
  temp = a->TMP_P0_L103_GLL0(0,::-1,:)
  temp = temp - 273.15
  copy_VarCoords(u,temp)
  temp@units = "C"
;  printVarSummary(temp)
;  printMinMax(temp, True) 

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+"/"+name+"_"+imgcount)
gsn_define_colormap(wks,"tempprac")
;**********************************************

res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                              ; Turn on color fill
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 1
res@cnMinLevelValF = -50
res@cnMaxLevelValF = 50  
;res@cnFillColors = (/2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60/)
res@cnFillColors = (/2,52,51,50,49,48,47,46,45,44,43,42,41,40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,53,54,55,56,57,58,59,60/)

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

res@gsnLeftString = "MSLP; 2-m temperature (0~F34~0~F~C line in white); 10-m wind"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightString = "(Analysis) "+ut_string(tim,"")
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013
res@gsnLeftStringFontColor = "black"
res@gsnRightStringFontColor = "black"

; *********************************************

res@mpGeophysicalLineThicknessF = 2.0
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey16"
res@mpNationalLineColor = "grey16"
res@mpUSStateLineColor = "grey16"

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
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/);tmres@tmXBMinorValues = (/-175,-170,-165,-160,-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-40,-35,-30,-25,-15,-10,-5,0,5,10,15,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,145,150,155,160,165,170,175/)
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
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
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
cnres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cnres@cnFillOn = False
cnres@cnLinesOn = True
cnres@cnLabelMasking = True
cnres@cnLineLabelsOn = False
cnres@cnLineThicknessF = 3
cnres@cnLineColor = "white"
cnres@cnLevelSelectionMode = "ExplicitLevels"
cnres@cnLevels = (/0/)
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 1
cnres@cnLineLabelDensityF = .77
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.018
cnres@cnSmoothingOn = True
cnres@cnSmoothingDistanceF = 0.00001

if domain .eq. "europe" then
cnres@cnLineThicknessF = 4
end if

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
cnres@cnLineDrawOrder ="Draw"
mres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, temp, res)          ; Plot filled contour map
other = gsn_csm_contour(wks, temp, cnres)
contours = gsn_csm_contour(wks, mslp, mres)
barbs = gsn_csm_vector(wks, u, v, bres)
plot = add_map_tickmarks(wks,plot,tmres)

;==============================================
; Set Marker and Text Resources
;==============================================

tres = True
tres@gsLineDashPattern = 5
tres@gsLineThicknessF = 3
tres@gsLineColor = "grey12"

if domain .eq. "northamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-148.5,3.5,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-148,2,tres)
else if domain .eq. "pacific" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",117.7,-6.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",118.4,-8.8,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-85.0,-4,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-84,-6,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-45.0,23.2,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-44.7,21.7,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-121.5,-68.6,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-121.5,-69.5,tres)
end if 
end if
end if
end if
end if 

;********************************************

overlay(plot,other)
overlay(plot,contours)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert "+dir_plot+"/"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".png")
system ("'rm' "+dir_plot+"/"+name+"_*.png") 

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

;system("rm -f "+dir_grib+"GFS_*_000")	
system("rm -f "+dir_grib+"*.grb2.tar")

end do     ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end