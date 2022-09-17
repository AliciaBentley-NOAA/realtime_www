; ===========================================
; Plotting GFS archive overnight to correct
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

name = "850_thetae"

;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------


	print(" ")
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
	
    print("chh: "+chh)
    
    if (chh .ge. 5) .and. (chh .lt. 11) then
    	sdate = cd_inv_calendar(syyyy,smm,sdd,0,00,00,timeUnits,0)
    	edate = cd_inv_calendar(cyyyy,cmm,cdd,0,00,00,timeUnits,0)
	else if (chh .ge. 11) .and. (chh .lt. 17) then
    	sdate = cd_inv_calendar(syyyy,smm,sdd,6,00,00,timeUnits,0)
    	edate = cd_inv_calendar(cyyyy,cmm,cdd,6,00,00,timeUnits,0)
	else if (chh .ge. 17) .and. (chh .lt. 23) then
    	sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
    	edate = cd_inv_calendar(cyyyy,cmm,cdd,12,00,00,timeUnits,0)
	else if (chh .ge. 23) .or. (chh .lt. 5) then
		if (chh .lt. 5) then
		    sdd = sdd - 1
			cdd = cdd - 1
		end if
    	sdate = cd_inv_calendar(syyyy,smm,sdd,18,00,00,timeUnits,0)
    	edate = cd_inv_calendar(cyyyy,cmm,cdd,18,00,00,timeUnits,0)
	end if
	end if
	end if
	end if

	print("Initialized on sdate:  "+ut_string(sdate,""))
	print("Stop archive on edate: "+ut_string(edate,""))
    
	imgcount = 1			;;; this starts the image count at 57 (analysis)

;*****************************************************

do tim = sdate,edate,6

; Set date strings
str_time = ut_string(tim,"%y%N%D")
str_hr = ut_string(tim,"%H")
filefhr = "000"

	print(" ")
	filename = "/free/abentley/realtime/prac/GFS_"+str_time+"_"+str_hr+"_"+filefhr+".grb2"
	print("filename: "+filename)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************


  a = addfile(filename,"r") 
  
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
  
  print("Successfully got data from files!")
  
;==============================================

;folder = (/"asia"/)
folder = (/"conus","northamer","pacific","atlantic","europe","southpac","southamer","india","australia","africa","asia"/)   
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)	      	

dir_plot = "/free/abentley/realtime/"+name+"/"	         
dir_out = "/lb11/abentley/www/realtime/images/"+domain+"/"+name+"/"
system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/")
system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/"+name+"/")


;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+name+"_"+imgcount)
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

; *********************************************

res@mpGeophysicalLineThicknessF = 4.5
res@mpNationalLineThicknessF = 4.5
res@mpUSStateLineThicknessF = 4.5
res@mpOutlineSpecifiers = (/"Brazil:states","United States:states"/)

res@mpGeophysicalLineColor = "navyblue"
res@mpNationalLineColor = "navyblue"
res@mpUSStateLineColor = "navyblue"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 2
res@mpGridLineColor = "grey40"
res@pmTickMarkDisplayMode = "Always"

tmres = True
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
res@mpMinLatF = 8.
res@mpMaxLatF = 72.
res@mpMinLonF = -151.
res@mpMaxLonF = -49.
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(0,80,20)
tmres@tmYRValues = ispan(0,80,20)
end if


if domain .eq. "pacific"
res@mpProjection = "LambertConformal"
  westlon = 124.
  eastlon = -124.
  centerlon = 180. ; to use this effectively remember its the the distance of lon between west and east divided by 2
  if(westlon.gt.eastlon)then
    useflip = True
    westlon = westlon
    eastlon = eastlon+360.
    if (centerlon.lt.0)then
      centerlon = centerlon+360.
    end if
  end if
res@mpLambertParallel2F = 29
res@mpLambertParallel1F = 9
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = centerlon
res@mpLimitMode = "LatLon"
res@mpMinLatF = -25.
res@mpMaxLatF = 75.
res@mpMinLonF = westlon
res@mpMaxLonF = eastlon
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(0,80,20)
tmres@tmYRValues = ispan(0,80,20)
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
res@mpMinLatF = 6.
res@mpMaxLatF = 71.
res@mpMinLonF = -90.
res@mpMaxLonF = 17.
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
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
res@mpMinLatF = 24.5
res@mpMaxLatF = 72.
res@mpMinLonF = -46.
res@mpMaxLonF = 46.
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(0,80,20)
tmres@tmYRValues = ispan(0,80,20)
end if


if domain .eq. "southamer"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
delete(res@mpCenterLonF)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -67.
res@mpMaxLatF = 12.
res@mpMinLonF = -122.
res@mpMaxLonF = 12.
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
end if


if domain .eq. "india"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
delete(res@mpCenterLonF)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -35.
res@mpMaxLatF = 35.
res@mpMinLonF = 30.
res@mpMaxLonF = 127.
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
end if


if domain .eq. "australia"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
delete(res@mpCenterLonF)
delete(tmres@tmXBValues)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues := ispan(-180,179,20)
tmres@tmYRValues := ispan(-180,179,20)
tmres@tmXBValues := ispan(-180,179,20)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -60.
res@mpMaxLatF = 8.
res@mpMinLonF = 81.75
res@mpMaxLonF = -170.+360.
res@mpCenterLonF = 140.
end if

if domain .eq. "africa"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
delete(res@mpCenterLonF)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMaxLatF = 43.
res@mpMinLatF = -48.
res@mpMinLonF = -50.
res@mpMaxLonF = 83.
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
end if


if domain .eq. "southpac"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
delete(res@mpCenterLonF)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -74.
res@mpMaxLatF = 25.
res@mpMinLonF = 139.9
res@mpMaxLonF = -40.5+360.
res@mpCenterLonF = 260.
delete(tmres@tmXBValues)
tmres@tmXBValues = (/140,180,-140,-100,-60/)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
end if

if domain .eq. "asia"
res@mpProjection = "LambertConformal"
  westlon = 30.5
  eastlon = 149.5
  centerlon = 90. ; to use this effectively remember its the the distance of lon between west and east divided by 2
  if(westlon.gt.eastlon)then
    useflip = True
    westlon = westlon
    eastlon = eastlon+360.
    if (centerlon.lt.0)then
      centerlon = centerlon+360.
    end if
  end if
res@mpLambertParallel2F = 29
res@mpLambertParallel1F = 9
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = centerlon
res@mpLimitMode = "LatLon"
res@mpMinLatF = 0.
res@mpMaxLatF = 75.
res@mpMinLonF = westlon
res@mpMaxLonF = eastlon
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(0,80,20)
tmres@tmYRValues = ispan(0,80,20)
end if

if domain .eq. "conus"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 15
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = -95
res@mpLimitMode = "LatLon"
res@mpMinLatF = 18.
res@mpMaxLatF = 57.
res@mpMinLonF = -125.
res@mpMaxLonF = -65.5
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
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
    bres@vcMinDistanceF = 0.035
    bres@vcWindBarbTickLengthF = 0.37
    bres@vcWindBarbTickSpacingF = 0.130
    bres@vcWindBarbTickAngleF = 55.0
    bres@gsnFrame = False
    bres@gsnAddCyclic =  True

;**********************************************

  curdate = tim	
  curdate@units = "hours since 1800-01-01 00:00:00"
  fhr_cur = "0"

	res@tiMainString = " "
	res@tiMainJust = "CenterCenter"
	res@tiMainPosition = "Center" 
	res@tiMainOffsetYF = .02
	res@tiXAxisFontHeightF = .015
	
	res@gsnRightString = " "
	
	res@gsnLeftStringFontColor = "black"
	res@gsnLeftString = "850-hPa geo. height (black, dam), equivalent potential temp. (shaded, K), wind (barbs, kt)"
	res@gsnLeftStringOrthogonalPosF = .040
	res@gsnLeftStringFontHeightF = .009
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(curdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .010


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
cnres@cnLineDrawOrder ="Draw"
tres@cnLineDrawOrder ="Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, theta_e, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, g, cnres)
;other = gsn_csm_contour(wks, t, tres)
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
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-148.5,3.5,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-148,2,tres)
else if domain .eq. "pacific" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",124.0,-5.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",124.6,-7.4,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-84.3,-4.2,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-83.65,-5.7,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-44.65,22.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-44.35,21.35,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-120.6,-65.4,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-120.6,-66.3,tres)
else if domain .eq. "africa" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-48.6,-45.3,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-48.6,-46.8,tres)
else if domain .eq. "india" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",31.0,-32.6,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",31.0,-33.9,tres)
else if domain .eq. "australia" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",82.85,-58.35,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",82.85,-59.3,tres)
else if domain .eq. "southpac" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",141.75,-72.48,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",141.85,-73.35,tres)
else if domain .eq. "asia" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",33.7,-5.8,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",34.3,-7.5,tres)
else if domain .eq. "conus" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-124.15,16.88,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-123.95,15.95,tres)
end if
end if
end if
end if
end if
end if
end if 
end if
end if
end if
end if

;********************************************

;overlay(plot,other)
overlay(plot,contours)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

;********************************************

system("pngquant "+dir_plot+name+"_"+imgcount+".png")
system("'mv' "+dir_plot+name+"_"+imgcount+"-fs8.png "+dir_plot+name+"_"+imgcount+".png") 
system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".png")
system ("'rm' "+dir_plot+name+"_"+imgcount+".png")

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

end do     	; end domain

imgcount = imgcount + 1
end do		; end tim

system ("'rm' "+dir_plot+name+"_*.png")
system ("'rm' "+dir_plot+name+"_*-fs8.png")

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
