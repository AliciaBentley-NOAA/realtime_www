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
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
; ===========================================

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

;move = "no"
move = "yes"

;toplot = "no"
toplot = "yes"

name = "350K_isen"




;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------

if move .eq. "yes" then

start_img = 2    ; first image to move
end_img = 89	 ; last image to move

; First list is all possible domain options
folder = (/"conus","northamer","pacific","atlantic","europe","southpac","southamer","india","australia","africa","asia"/)   
;folder = (/"india"/)    
enddomain = dimsizes(folder)

; First list is all possible variable options    
variable = name    
endvariable = dimsizes(variable)

;*********************


dir_out = "/lb11/abentley/www/realtime/images/"    ; change to the directory you want to put images in

do x = 0,enddomain-1
	domain = folder(x)
	print("Moving GFS images to the previous time slot for ("+domain+") and ("+name+")")

	do y = 0,endvariable-1
	
		image = variable(y)	
		;system("mkdir "+dir_out+domain+"/")	
		;system("mkdir "+dir_out+domain+"/"+image+"/")
		
			do number = start_img,end_img,1
				minus_number = number - 1
			
				from = dir_out+domain+"/"+name+"/"+image+"_"+number+".png"
				to   = dir_out+domain+"/"+name+"/"+image+"_"+minus_number+".png"

				system("'cp' "+from+" "+to) 
				print("Copied "+from+" to "+to)

			end do     ; end number

end do     ; end name
end do     ; end domain

end if ; if move .eq. "yes"





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

print("chh: "+chh)

	if (chh .ge. 4) .and. (chh .lt. 10) then
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,00,00,00,timeUnits,0)
    	hr = 00
	else if (chh .ge. 10) .and. (chh .lt. 16) then
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,06,00,00,timeUnits,0)
    	hr = 06
	else if (chh .ge. 16) .and. (chh .lt. 22) then
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,12,00,00,timeUnits,0)
    	hr = 12
	else if (chh .ge. 22) .or. (chh .lt. 4) then
		if (chh .lt. 5) then
			cdd = cdd - 1
		end if
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,18,00,00,timeUnits,0)
    	hr = 18
	end if
	end if
	end if
	end if

;print("GFS Forecast: "+hr+"Z run")
;sdate = cd_inv_calendar(2018,4,14,6,00,00,timeUnits,0)
print("Initialized on sdate: "+ut_string(sdate,""))
    
imgcount = 57			;;; this starts the image count at 57 (analysis)

;*****************************************************
         
; Set date strings
str_time = ut_string(sdate,"%y%N%D")
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
                 filename = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+str_time+"_"+str_hr+"_"+filefhr+".grb2"
                 fhr_cur = fhr(f)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************


  a = addfile(filename,"r") 
  
  isen_lev = (/350/)
  
do il = 0,dimsizes(isen_lev)-1

  ;;;;;; read in the proper variables to make isentropic PV analysis 
  
  t = a->TMP_P0_L100_GLL0({100000:10000},:,:)
  u = a->UGRD_P0_L100_GLL0({100000:10000},:,:)
  v = a->VGRD_P0_L100_GLL0({100000:10000},:,:)
  avrt = a->ABSV_P0_L100_GLL0({100000:10000},:,:)
  
  lats = a->lat_0    
  lons = a->lon_0
  lev = a->lv_ISBL0({100000:10000})

  nlat = dimsizes(lats)
  nlon = dimsizes(lons)
  nlev = dimsizes(lev)
  
  p = t
  do l=0,nlev-1
    p(l,:,:) = lev(l)*0.01
  end do
  p@units = "hPa"

  ;#### Make potential temp. (all levs)
  theta = t
  theta = t*((1000./p)^(287./1004.))

;####################################################
;#### Create Full Resolution Isentropic vars ########

  th_lev = (/isen_lev(il)-1,isen_lev(il),isen_lev(il)+1/) ;#### Only calculate desired levels!!
  nth_lev = dimsizes(th_lev)
  
  levs_todo = (/isen_lev(il)/)
  nlevs_todo = dimsizes(levs_todo)

  p_th = new((/nth_lev,nlat,nlon/),"float")
  u_th = p_th
  v_th = p_th
  avrt_th = p_th
  sf_th = p_th

  do j=0,nth_lev-1,1
    u_th(j,:,:)  = (/wrf_user_intrp3d(u(:,:,:),theta(:,:,:),"h",th_lev(j),0.,False)/)
    v_th(j,:,:)  = (/wrf_user_intrp3d(v(:,:,:),theta(:,:,:),"h",th_lev(j),0.,False)/)
    p_th(j,:,:)  = (/wrf_user_intrp3d(p(:,:,:),theta(:,:,:),"h",th_lev(j),0.,False)/)
    avrt_th(j,:,:)  = (/wrf_user_intrp3d(avrt(:,:,:),theta(:,:,:),"h",th_lev(j),0.,False)/)
  end do

  p_th!0 = "lev"
  p_th!1 = "lat"
  p_th!2 = "lon"
    
  p_th = p_th

  p_th&lev = th_lev
  p_th&lat = lats
  p_th&lon = lons
  p_th@_FillValue = -99999.

  copy_VarMeta(p_th,u_th)
  copy_VarMeta(p_th,v_th)
  copy_VarMeta(p_th,avrt_th)
  
  u_th@_FillValue = 9.96921e+36
  v_th@_FillValue = 9.96921e+36
  
  u_th = u_th*1.94384449
  v_th = v_th*1.94384449
  
;####################################################
;#### Calculate Full Res. Isentropic PV. ############

  pu_isen = p_th({isen_lev(il)},:,:)
  pb_isen = p_th({isen_lev(il)},:,:)
  avrt_isen = avrt_th({isen_lev(il)},:,:)

  pv_isen_all = new((/1,nlat,nlon/),"float")

  do i=0,nlevs_todo-1
    pu_isen = p_th({levs_todo(i)+1},:,:)*100.
    pb_isen = p_th({levs_todo(i)-1},:,:)*100.
    avrt_isen = avrt_th({levs_todo(i)},:,:)
    pv_isen = avrt_isen*9.8*(2.)*(1./(pb_isen-pu_isen))*10.^6.
    pv_isen_all(i,:,:) = (/pv_isen/)
  end do

  pv_isen_all!0 = "lev"
  pv_isen_all!1 = "lat"
  pv_isen_all!2 = "lon"

  pv_isen_all&lev = levs_todo
  pv_isen_all&lat = lats
  pv_isen_all&lon = lons

;***********Rel. Vort.**************

  do d=0,2
     p_th=smth9(p_th,.5,.25,True)
  end do

  print("Successfully got data from files!")
  
;==============================================

;folder2 = (/"australia"/)
folder2 = (/"conus","northamer","pacific","atlantic","europe","asia","southpac","southamer","india","australia","africa"/)   
enddomain2 = dimsizes(folder2)

do x = 0,enddomain2-1

domain = folder2(x)

print(" ")
print("Plotting maps for: "+domain)	      	

dir_plot = "/free/abentley/realtime/"+name+"/grib/"	         
dir_out = "/lb11/abentley/www/realtime/images/"+domain+"/"+name+"/"
;system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/")
;system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/"+name+"/")


;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+name+"_"+imgcount)
gsn_define_colormap(wks,"lance_isenpv")
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
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevels := (/0,0.5,1,1.5,2,4,6,8,10/)
res@cnFillColors := (/6,-1,14,13,12,16,19,22,33,26/)

;**********************************************

res@lbLabelBarOn = False

if (domain .eq. "conus") .or. (domain .eq. "northamer") .or. (domain .eq. "pacific") .or. (domain .eq. "atlantic") .or. (domain .eq. "europe") .or. (domain .eq. "asia") then
res@lbLabelBarOn = True
res@lbAutoManage = False
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                                  ; Outline the color bar 
res@lbTopMarginF = .3
end if

; *********************************************

res@mpGeophysicalLineThicknessF = 4.5
res@mpNationalLineThicknessF = 4.0
res@mpUSStateLineThicknessF = 4.0
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

cn2res = True

cn2res@gsnFrame = False                                        
cn2res@gsnDraw = False

cn2res@gsnLeftString = " "
cn2res@gsnRightString = " "

cn2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cn2res@cnFillOn = True
cn2res@cnLinesOn = False
cn2res@cnLabelMasking = True
cn2res@cnLineThicknessF = 4                     ; Changes thickness of contours
cn2res@cnLevelSelectionMode = "ExplicitLevels"
cn2res@cnLevels := (/0,-.5,-1,-1.5,-2,-4,-6,-8,-10/)
cn2res@cnFillColors := (/26,33,22,19,16,12,13,14,-1,6/)
cn2res@cnLineLabelAngleF = 0.0
cn2res@cnLineLabelInterval = 2
cn2res@cnLineLabelDensityF = .90
;cn2res@cnSmoothingOn = True
;cn2res@cnSmoothingDistanceF = 0.009
cn2res@cnLineLabelBackgroundColor = -1
cn2res@cnLineLabelFontHeightF = 0.008
cn2res@gsnAddCyclic =  True

cn2res@lbLabelBarOn = False

if (domain .eq. "southamer") .or. (domain .eq. "southpac") .or. (domain .eq. "africa") .or. (domain .eq. "australia") .or. (domain .eq. "india") then
cn2res@lbLabelBarOn = True
cn2res@lbAutoManage = False
cn2res@pmLabelBarOrthogonalPosF = .018  
cn2res@pmLabelBarHeightF = 0.105
cn2res@pmLabelBarWidthF = 0.73
cn2res@lbLabelAutoStride = True
cn2res@lbLabelFontHeightF = 0.0124
cn2res@lbBoxLinesOn  = True                                  ; Outline the color bar 
cn2res@lbTopMarginF = .3
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
cnres@cnLineThicknessF = 3.5                    ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 10
cnres@cnMinLevelValF = 0
cnres@cnMaxLevelValF = 1200   
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = .93
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008
cnres@gsnAddCyclic =  True

; *************************************************************


    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey14"
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
	res@gsnLeftString = isen_lev+" K PV (shaded, PVU), pressure (black, hPa), and wind (barbs, kt)"
	res@gsnLeftStringOrthogonalPosF = .040
	res@gsnLeftStringFontHeightF = .009
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(sdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .010


; *************************************************************
res@mpGridAndLimbDrawOrder = "PostDraw"
res@cnFillDrawOrder = "PreDraw"
cn2res@cnFillDrawOrder = "PreDraw"
bres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpFillOn = False
res@mpOutlineOn = True

plot = gsn_csm_contour_map(wks, pv_isen_all({isen_lev(il)},{0:90},:), res)          ; Plot filled contour map
contours2 = gsn_csm_contour(wks, pv_isen_all({isen_lev(il)},{-90:0},:), cn2res)
contours = gsn_csm_contour(wks, p_th({isen_lev(il)},:,:), cnres)
barbs = gsn_csm_vector(wks, u_th({isen_lev(il)},:,:), v_th({isen_lev(il)},:,:), bres)
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

overlay(plot,contours)
overlay(plot,contours2)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("pngquant "+dir_plot+name+"_"+imgcount+".png")
system("'mv' "+dir_plot+name+"_"+imgcount+"-fs8.png "+dir_plot+name+"_"+imgcount+".png") 
system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".png")
system ("'rm' "+dir_plot+name+"_*.png")
system ("'rm' "+dir_plot+name+"_*-fs8.png") 


print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************
end do		; end il
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
