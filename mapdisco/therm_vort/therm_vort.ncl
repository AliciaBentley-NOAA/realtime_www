; ===========================================
; Plot composited PV on isentropic surfaces
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "/home/carl/nclscripts/lib/tTick.ncl"
load "/home/carl/nclscripts/lib/ut_string.ncl"
load "/home/abentley/ncl/lib/latlon.ncl"
load "/home/kgriffin/ncl_lib/shea_util.ncl"
; ===========================================

; source ~macritch/.cshrc
; ncl -V = 6.1.2

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

discodate = "20140912"

folder = (/"northamer","pacific","atlantic"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)

syyyy = 2014			;;; start date in yyyy mm dd hh
smm = 09
sdd = 06
shh = 00

eyyyy = 2014			;;; end date in yyyy mm dd hh (note end of analysis must ALWAYS end at 18 UTC)
emm = 09			;;; this is because grib files are packaged in .tar format which saves daily files
edd = 11			;;; (00,06,12,18) bundeling all the synoptic times in one file. This program
ehh = 18			;;; bridges the gap if you are looking at a forecast other than starting at 00 UTC
  				;;; by filling in the missing dates with the forecast analysis grib files

fcast = "yes" 		        ;;; do you want to plot the 192 hour GFS forecast at the next synoptic time?
hr = 06		         	;;; choose forecast synoptic time (e.g. 00 will plot the forecast initialized at 00 UTC)

timeUnits = "hours since 1800-01-01 00:00:00"

sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,timeUnits,0)    ;;; Convert string values to integers to use cd_inv_calendar function
edate = cd_inv_calendar(eyyyy,emm,edd,ehh,00,00,timeUnits,0)
  
fdate = edate + hr + 6
    
imgcount = 1			;;; this starts the image count at 1 (you can change this to any number you want
  				;;; but note it counts up by 1 at a time as you move 6h forward in time

dir_grib = "/lb13/abentley/scripts/mapdisco/therm_vort/grib/"		        
dir_out = "/lb11/abentley/www/mapdisco/"+discodate+"/images/"+domain+"/therm_vort/"
name = "therm_vort"

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
  a = addfile(filename,"r")

  lev_g = (/92500/) ; Needs to be in Pa

  g = a->HGT_P0_L100_GLL0({lev_g},::-1,:) 
  g = g/10

  levs = (/92500,50000/) ; Needs to be in Pa
  g2 = a->HGT_P0_L100_GLL0({levs},::-1,:)
  thick = g2(0,:,:)
  thick = g2({min(levs)},:,:)-g2({max(levs)},:,:)
  thick = thick * .1

  do d=0,3
     thick=smth9(thick,.5,.25,True)
  end do
  do d=0,3
     g=smth9(g,.5,.25,True)
  end do

  lev_bot = (/92500/)
  u_bot = a->UGRD_P0_L100_GLL0({lev_bot},::-1,:)
  v_bot = a->VGRD_P0_L100_GLL0({lev_bot},::-1,:)
  lev_top = (/50000/)
  u_top = a->UGRD_P0_L100_GLL0({lev_top},::-1,:)
  v_top = a->VGRD_P0_L100_GLL0({lev_top},::-1,:)
  
  relvort_bot = uv2vrF_Wrap(u_bot,v_bot)
  relvort_top = uv2vrF_Wrap(u_top,v_top)

  therm_vort = relvort_top-relvort_bot
  therm_vort = therm_vort*(10^5)
  copy_VarCoords(g,therm_vort)  

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1650
wks_type@wkHeight = 1650

wks = gsn_open_wks(wks_type,name+"_"+imgcount)
gsn_define_colormap(wks,"cmp_haxby")
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
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 1                            ; Shading interval
res@cnLevels = (/-8,-6,-4,-2,0,2,4,6,8/)
;res@cnFillColors = (/"white","gold","darkgoldenrod1","orange","darkorange1","orangered","orangered2"/)
;res@cnFillColors = (/8,13,17,21,-1,-1,62,60,57,53/)
res@cnFillColors = (/53,57,60,62,-1,-1,21,17,13,8/)

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

res@gsnLeftString = "925-hPa geo. height; 925~F15~-~F21~500-hPa thickness and therm. vort."
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightString = ut_string(sdate,"")
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013

  curdate = tim + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

  if (fhr_cur .gt. 0) then
     res@gsnRightString = "("+fhr_cur+" h fcst) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "red"
     res@gsnRightStringFontColor = "red"
  else
     res@gsnRightString = ut_string(curdate,"")
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  end if

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
res@mpGridLonSpacingF = 200.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey12"

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
tmres@tmXBMinorValues = (/-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35/)

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
cnres@cnLineThicknessF = 4                   ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 3
cnres@cnMinLevelValF = 30
cnres@cnMaxLevelValF = 120  
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 1
cnres@cnLineLabelDensityF = 1.05
;cnres@cnSmoothingOn = True
;cnres@cnSmoothingDistanceF = 0.009
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008


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
thres@cnLineThicknessF = 4
thres@cnLineColor = "magenta4"
thres@cnLineLabelFontColor = "magenta4"
thres@cnLevelSelectionMode = "ManualLevels"
thres@cnLevelSpacingF = 6
thres@cnMinLevelValF = 324
thres@cnMaxLevelValF = 540
thres@cnLineLabelAngleF = 0.0
thres@cnLineLabelInterval = 1
thres@cnLineLabelDensityF = .90
thres@cnLineLabelBackgroundColor = -1
thres@cnLineLabelFontHeightF = 0.008
thres@cnLineDashPattern = 5

; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
cnres@cnLineDrawOrder ="Draw"
thres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, therm_vort, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, g, cnres)
other = gsn_csm_contour(wks, thick, thres)
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

dum31 = gsn_add_polyline(wks,plot,(/180,180/),(/-90,90/),tres)
dum32 = gsn_add_polyline(wks,plot,(/160,160/),(/-90,90/),tres)
dum33 = gsn_add_polyline(wks,plot,(/140,140/),(/-90,90/),tres)
dum34 = gsn_add_polyline(wks,plot,(/120,120/),(/-90,90/),tres)
dum35 = gsn_add_polyline(wks,plot,(/100,100/),(/-90,90/),tres)
dum36 = gsn_add_polyline(wks,plot,(/80,80/),(/-90,90/),tres)
dum37 = gsn_add_polyline(wks,plot,(/60,60/),(/-90,90/),tres)
dum38 = gsn_add_polyline(wks,plot,(/40,40/),(/-90,90/),tres)
dum39 = gsn_add_polyline(wks,plot,(/20,20/),(/-90,90/),tres)
dum40 = gsn_add_polyline(wks,plot,(/0,0/),(/-90,90/),tres)
dum41 = gsn_add_polyline(wks,plot,(/-20,-20/),(/-90,90/),tres)
dum4 = gsn_add_polyline(wks,plot,(/-40,-40/),(/-90,90/),tres)
dum5 = gsn_add_polyline(wks,plot,(/-60,-60/),(/-90,90/),tres)
dum6 = gsn_add_polyline(wks,plot,(/-80,-80/),(/-90,90/),tres)
dum7 = gsn_add_polyline(wks,plot,(/-100,-100/),(/-90,90/),tres)
dum8 = gsn_add_polyline(wks,plot,(/-120,-120/),(/-90,90/),tres)
dum9 = gsn_add_polyline(wks,plot,(/-140,-140/),(/-90,90/),tres)
dum10 = gsn_add_polyline(wks,plot,(/-160,-160/),(/-90,90/),tres)

;********************************************

overlay(plot,other)
overlay(plot,contours)

;********************************************

draw(plot)
frame(wks)

system("convert -trim "+name+"_"+imgcount+".png "+name+"_"+imgcount+".png")
system ("mv "+name+"_"+imgcount+".png "+dir_out+name+"_"+imgcount+".png")

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
  a = addfile(filename,"r")

  lev_g = (/92500/) ; Needs to be in Pa

  g = a->HGT_P0_L100_GLL0({lev_g},::-1,:) 
  g = g/10

  levs = (/92500,50000/) ; Needs to be in Pa
  g2 = a->HGT_P0_L100_GLL0({levs},::-1,:)
  thick = g2(0,:,:)
  thick = g2({min(levs)},:,:)-g2({max(levs)},:,:)
  thick = thick * .1

  do d=0,3
     thick=smth9(thick,.5,.25,True)
  end do

  lev_bot = (/92500/)
  u_bot = a->UGRD_P0_L100_GLL0({lev_bot},::-1,:)
  v_bot = a->VGRD_P0_L100_GLL0({lev_bot},::-1,:)
  lev_top = (/50000/)
  u_top = a->UGRD_P0_L100_GLL0({lev_top},::-1,:)
  v_top = a->VGRD_P0_L100_GLL0({lev_top},::-1,:)
  
  relvort_bot = uv2vrF_Wrap(u_bot,v_bot)
  relvort_top = uv2vrF_Wrap(u_top,v_top)

  therm_vort = relvort_top-relvort_bot
  therm_vort = therm_vort*(10^5)
  copy_VarCoords(g,therm_vort)  
  
  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1650
wks_type@wkHeight = 1650

wks = gsn_open_wks(wks_type,name+"_"+imgcount)
gsn_define_colormap(wks,"cmp_haxby")
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
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 1                            ; Shading interval
res@cnLevels = (/-8,-6,-4,-2,0,2,4,6,8/)
;res@cnFillColors = (/"white","gold","darkgoldenrod1","orange","darkorange1","orangered","orangered2"/)
;res@cnFillColors = (/8,13,17,21,-1,-1,62,60,57,53/)
res@cnFillColors = (/53,57,60,62,-1,-1,21,17,13,8/)

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

res@gsnLeftString = "925-hPa geo. height; 925~F15~-~F21~500-hPa thickness and therm. vort."
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013
res@gsnRightString = ut_string(tim,"")
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
res@mpGridLonSpacingF = 200.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey12"

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
tmres@tmXBMinorValues = (/-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35/)

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
cnres@cnLineThicknessF = 4                   ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 3
cnres@cnMinLevelValF = 30
cnres@cnMaxLevelValF = 120  
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 1
cnres@cnLineLabelDensityF = 1.05
;cnres@cnSmoothingOn = True
;cnres@cnSmoothingDistanceF = 0.009
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008


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
thres@cnLineThicknessF = 4
thres@cnLineColor = "magenta4"
thres@cnLineLabelFontColor = "magenta4"
thres@cnLevelSelectionMode = "ManualLevels"
thres@cnLevelSpacingF = 6
thres@cnMinLevelValF = 324
thres@cnMaxLevelValF = 540
thres@cnLineLabelAngleF = 0.0
thres@cnLineLabelInterval = 1
thres@cnLineLabelDensityF = .90
thres@cnLineLabelBackgroundColor = -1
thres@cnLineLabelFontHeightF = 0.008
thres@cnLineDashPattern = 5

; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
cnres@cnLineDrawOrder ="Draw"
thres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, therm_vort, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, g, cnres)
other = gsn_csm_contour(wks, thick, thres)
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

dum31 = gsn_add_polyline(wks,plot,(/180,180/),(/-90,90/),tres)
dum32 = gsn_add_polyline(wks,plot,(/160,160/),(/-90,90/),tres)
dum33 = gsn_add_polyline(wks,plot,(/140,140/),(/-90,90/),tres)
dum34 = gsn_add_polyline(wks,plot,(/120,120/),(/-90,90/),tres)
dum35 = gsn_add_polyline(wks,plot,(/100,100/),(/-90,90/),tres)
dum36 = gsn_add_polyline(wks,plot,(/80,80/),(/-90,90/),tres)
dum37 = gsn_add_polyline(wks,plot,(/60,60/),(/-90,90/),tres)
dum38 = gsn_add_polyline(wks,plot,(/40,40/),(/-90,90/),tres)
dum39 = gsn_add_polyline(wks,plot,(/20,20/),(/-90,90/),tres)
dum40 = gsn_add_polyline(wks,plot,(/0,0/),(/-90,90/),tres)
dum41 = gsn_add_polyline(wks,plot,(/-20,-20/),(/-90,90/),tres)
dum4 = gsn_add_polyline(wks,plot,(/-40,-40/),(/-90,90/),tres)
dum5 = gsn_add_polyline(wks,plot,(/-60,-60/),(/-90,90/),tres)
dum6 = gsn_add_polyline(wks,plot,(/-80,-80/),(/-90,90/),tres)
dum7 = gsn_add_polyline(wks,plot,(/-100,-100/),(/-90,90/),tres)
dum8 = gsn_add_polyline(wks,plot,(/-120,-120/),(/-90,90/),tres)
dum9 = gsn_add_polyline(wks,plot,(/-140,-140/),(/-90,90/),tres)
dum10 = gsn_add_polyline(wks,plot,(/-160,-160/),(/-90,90/),tres)

;********************************************

overlay(plot,other)
overlay(plot,contours)

;********************************************

draw(plot)
frame(wks)

system("convert -trim "+name+"_"+imgcount+".png "+name+"_"+imgcount+".png")
system ("mv "+name+"_"+imgcount+".png "+dir_out+name+"_"+imgcount+".png")

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

             imgcount = imgcount + 1
          end if

          ; remove the grb2 file to save space
          if(tim .le. edate) then
             system("rm -f "+dir_grib+"GFS_"+str_time+"_"+str_hr+"_000")
             system("rm -f "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar") ; now remove the tar file (only have to do this once)
          end if
    end do

else
    print("Just the analysis")
    print("But I'll handle that later!")   ;maybe can always do the forecast and then just make it plot one time and quit
end if

end do     ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end