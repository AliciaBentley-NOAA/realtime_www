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

;toplot = "no"
toplot = "yes"

name = "dt_2pvu"

timeUnits = "hours since 1800-01-01 00:00:00"

sdate = cd_inv_calendar(2021,4,26,18,00,00,timeUnits,0)

archive = "p000"

;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------

if toplot .eq. "yes" then

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

;sdate = cd_inv_calendar(2019,10,08,00,00,00,timeUnits,0)
;archive = "p018"

;print("GFS Forecast: "+hr+"Z run")
;sdate = cd_inv_calendar(2018,4,14,6,00,00,timeUnits,0)
print("Initialized on sdate: "+ut_string(sdate,""))
    
imgcount = 0			;;; this starts the image count at 57 (analysis)

;*****************************************************
         
; Set date strings
str_time = ut_string(sdate,"%Y%N%D")
str_hr = ut_string(sdate,"%H")

	print("Plotting from forecast grib files")
	fhr  = (/0,6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192/)
;	fhr  = (/0,6,12,24/)
	nfhr = dimsizes(fhr)
  
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
		 filename = "/lb13/abentley/data/gfs/gfs.t"+str_hr+"z.pgrb2.0p50.f"+filefhr+".grib2"
                 fhr_cur = fhr(f)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************


  a = addfile(filename,"r") 
  

  nht_pv = a->TMP_P0_L109_GLL0({2*10^-6},::-1,:)
  nhpres_pv = a->PRES_P0_L109_GLL0({2*10^-6},::-1,:)
  sht_pv = a->TMP_P0_L109_GLL0({-2*10^-6},::-1,:)
  shpres_pv = a->PRES_P0_L109_GLL0({-2*10^-6},::-1,:)

  nhu_pv = a->UGRD_P0_L109_GLL0({2*10^-6},::-1,:)
  nhv_pv = a->VGRD_P0_L109_GLL0({2*10^-6},::-1,:)
  shu_pv = a->UGRD_P0_L109_GLL0({-2*10^-6},::-1,:)
  shv_pv = a->VGRD_P0_L109_GLL0({-2*10^-6},::-1,:)

  pres_pv = new( (/dimsizes(nhpres_pv&lat_0),dimsizes(nhpres_pv&lon_0)/),typeof(nhpres_pv))
  t_pv = new( (/dimsizes(nht_pv&lat_0),dimsizes(nht_pv&lon_0)/),typeof(nht_pv))
  u_pv = new( (/dimsizes(nhu_pv&lat_0),dimsizes(nhu_pv&lon_0)/),typeof(nhu_pv))
  v_pv = new( (/dimsizes(nhv_pv&lat_0),dimsizes(nhv_pv&lon_0)/),typeof(nhv_pv))
  pres_pv!0 = "lat_0"
  pres_pv!1 = "lon_0"
  pres_pv&lat_0 = nhpres_pv&lat_0
  pres_pv&lon_0 = nhpres_pv&lon_0

  copy_VarMeta(pres_pv,t_pv)
  copy_VarMeta(pres_pv,u_pv)
  copy_VarMeta(pres_pv,v_pv)

  pres_pv({0:90},:) = nhpres_pv({0:90},:)
  pres_pv({-90:-0.5},:) = shpres_pv({-90:-0.5},:)
  t_pv({0:90},:) = nht_pv({0:90},:)
  t_pv({-90:-0.5},:) = sht_pv({-90:-0.5},:)
  u_pv({0:90},:) = nhu_pv({0:90},:)
  u_pv({-90:-0.5},:) = shu_pv({-90:-0.5},:)
  v_pv({0:90},:) = nhv_pv({0:90},:)
  v_pv({-90:-0.5},:) = shv_pv({-90:-0.5},:)

  u_pv = u_pv * 1.94384449 
  v_pv = v_pv * 1.94384449 

  theta = t_pv*((100000/pres_pv)^(0.286))
  copy_VarMeta(t_pv,theta)

  do d=0,1
          theta=smth9(theta,.5,.25,True)
  end do


  u = a->UGRD_P0_L100_GLL0({92500:85000},::-1,:)
  v = a->VGRD_P0_L100_GLL0({92500:85000},::-1,:)

  avgu = dim_avg_n_Wrap(u,0)
  avgv = dim_avg_n_Wrap(v,0) 


  relvort = uv2vrF_Wrap(avgu,avgv)

  print("Successfully got data from files!")
;==============================================

folder2 = (/"pacific","northamer","conus","atlantic"/)
;folder2 = (/"conus","northamer","pacific","atlantic","europe","asia","southpac","southamer","india","australia","africa"/)   
enddomain2 = dimsizes(folder2)

do x = 0,enddomain2-1

domain = folder2(x)

print(" ")
print("Plotting maps for: "+domain)	      	

dir_plot = "./"+name+"/"	         
dir_out = "/lb11/abentley/www/realtime/dprogdt/images/"+domain+"/"+name+"/"+archive+"/"
;;system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/")
;;system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/"+name+"/")


;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+"image_"+imgcount)
gsn_define_colormap(wks,"alicia")
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
res@cnLevelSpacingF = 1
res@cnLevelSpacingF = 6                             ; Shading interval
res@cnMinLevelValF = 264
res@cnMaxLevelValF = 384                            ; Shading interval
;res@cnLevels = (/0,.2,.4,.6,1,1.5,2,3,4,5,6,7,8,9,10/)
;res@cnFillColors = (/26,27,7,9,10,11,12,13,14,16,18,19,20,22,23,31/)
;res@cnFillColors = (/24,25,26,27,7,9,10,11,12,13,14,16,18,19,20,22,23,34,32,31,25,24/)
res@cnFillColors = (/24,25,26,27,7,9,10,11,12,13,14,16,17,18,19,20,21,22,23,35,37,38,34,31,0/)

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

res@mpGeophysicalLineThicknessF = 5.5
res@mpNationalLineThicknessF = 5.5
res@mpUSStateLineThicknessF = 5.5
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

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

relres = True

relres@gsnFrame = False                                        
relres@gsnDraw = False

relres@cnFillMode = "AreaFill"
relres@gsnLeftString = " "
relres@gsnRightString = " "
relres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
relres@cnFillOn = False
relres@cnLinesOn = True
relres@cnLabelMasking = True
relres@cnLineThicknessF = 4
relres@cnLineColor = "black"
;relres@cnLineColor = "navy"
relres@cnLevelSelectionMode = "ManualLevels"
relres@cnLevelSpacingF = .5*10^-4
relres@cnMinLevelValF = .5*10^-4
relres@cnMaxLevelValF = 10*10^-4
relres@cnLineLabelsOn = False
relres@cnLineLabelAngleF = 0.0
relres@cnLineLabelInterval = 1
relres@cnLineLabelDensityF = .77
relres@cnLineLabelBackgroundColor = -1
relres@cnLineLabelFontHeightF = 0.018
relres@gsnAddCyclic =  True

; *************************************************************


rel2res = True

rel2res@gsnFrame = False                                        
rel2res@gsnDraw = False

rel2res@cnFillMode = "AreaFill"
rel2res@gsnLeftString = " "
rel2res@gsnRightString = " "
rel2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
rel2res@cnFillOn = False
rel2res@cnLinesOn = True
rel2res@cnLabelMasking = True
rel2res@cnLineThicknessF = 4
rel2res@cnLineColor = "black"
;rel2res@cnLineColor = "navy"
rel2res@cnLevelSelectionMode = "ManualLevels"
rel2res@cnLevelSpacingF := .5*10^-4
rel2res@cnMinLevelValF := -10.0*10^-4
rel2res@cnMaxLevelValF := -.5*10^-4
rel2res@cnLineLabelsOn = False
rel2res@cnLineLabelAngleF = 0.0
rel2res@cnLineLabelInterval = 1
rel2res@cnLineLabelDensityF = .77
rel2res@cnLineLabelBackgroundColor = -1
rel2res@cnLineLabelFontHeightF = 0.018
rel2res@gsnAddCyclic =  True

; *************************************************************


    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey29"
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

  curdate = sdate	
  curdate = sdate + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

	res@tiMainString = " "
	res@tiMainJust = "CenterCenter"
	res@tiMainPosition = "Center" 
	res@tiMainOffsetYF = .02
	res@tiXAxisFontHeightF = .015
	
	res@gsnRightString = " "
	
	res@gsnLeftStringFontColor = "black"
	res@gsnLeftString = "DT potential temperature (shaded, K) & wind (barbs, kt), 925-850-hPa cycl. rel. vort. (black, 0.5 x 10^-4 s^-1)"
	res@gsnLeftStringOrthogonalPosF = .040
	res@gsnLeftStringFontHeightF = .009
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(sdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .010


; *************************************************************
res@mpGridAndLimbDrawOrder = "PostDraw"
res@cnFillDrawOrder = "PreDraw"
relres@cnLineDrawOrder ="Draw" 
bres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpFillOn = False
res@mpOutlineOn = True

plot = gsn_csm_contour_map(wks, theta, res)          ; Plot filled contour map
other = gsn_csm_contour(wks, relvort({0:90},:), relres)
other2 = gsn_csm_contour(wks, relvort({-90:0},:), rel2res)
barbs = gsn_csm_vector(wks, u_pv, v_pv, bres)
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
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",-148.5,3.5,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",-148,2,tres)
else if domain .eq. "pacific" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",124.0,-5.7,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",124.6,-7.4,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",-84.3,-4.2,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",-83.65,-5.7,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",-44.65,22.7,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",-44.35,21.35,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",-120.6,-65.4,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",-120.6,-66.3,tres)
else if domain .eq. "africa" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",-48.6,-45.3,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",-48.6,-46.8,tres)
else if domain .eq. "india" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",31.0,-32.6,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",31.0,-33.9,tres)
else if domain .eq. "australia" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",82.85,-58.35,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",82.85,-59.3,tres)
else if domain .eq. "southpac" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",141.75,-72.48,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",141.85,-73.35,tres)
else if domain .eq. "asia" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",33.7,-5.8,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",34.3,-7.5,tres)
else if domain .eq. "conus" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,other,"@AliciaMBentley",-124.15,16.88,tres)
    mytext2 = gsn_add_text(wks,other,"www.AliciaMBentley.com",-123.95,15.95,tres)
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

overlay(plot,other)
overlay(plot,other2)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("pngquant "+dir_plot+"image_"+imgcount+".png")
system("'mv' "+dir_plot+"image_"+imgcount+"-fs8.png "+dir_plot+"image_"+imgcount+".png") 
system("convert "+dir_plot+"image_"+imgcount+".png -trim +repage "+dir_out+"image_"+imgcount+".png")
;system ("'rm' "+dir_plot+"image_*.png")

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

end do     	; end domain

imgcount = imgcount + 1
end do		; end fcst_hr

end if ; toplot .eq. "yes"

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
