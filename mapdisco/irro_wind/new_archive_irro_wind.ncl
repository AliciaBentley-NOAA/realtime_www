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

name = "irro_wind"

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
  

  pwat = a->PWAT_P0_L200_GLL0(::-1,:)


  lev_wind  = (/25000/)
  u_all = a->UGRD_P0_L100_GLL0({lev_wind},::-1,:)
  v_all = a->VGRD_P0_L100_GLL0({lev_wind},::-1,:)
  if(dimsizes(lev_wind).eq.1) then
    u = u_all
    v = v_all
  else
    u = dim_avg_n_Wrap(u_all,0)
    v = dim_avg_n_Wrap(v_all,0)
  end if

  wind = u
  wind = ((u^2)+(v^2))^0.5


  lev_omega  = (/60000,50000,40000/)
  w_all = a->VVEL_P0_L100_GLL0({lev_omega},::-1,:)
  w = dim_avg_n_Wrap(w_all,0)
  w = w*(.01)
;  copy_VarCoords(u_all,w)



  lev_irro  = (/30000,25000,20000/)
  u_irro = a->UGRD_P0_L100_GLL0({lev_irro},::-1,:)
  v_irro = a->VGRD_P0_L100_GLL0({lev_irro},::-1,:)
  if(dimsizes(lev_irro).eq.1) then
    ui = u_irro
    vi = v_irro
  else
    ui = dim_avg_n_Wrap(u_irro,0)
    vi = dim_avg_n_Wrap(v_irro,0)
  end if
  div = uv2dvF_Wrap(ui,vi)
  irro = dv2uvF_Wrap(div)



  lev_pv  = (/20000,25000,30000/)
  upv = a->UGRD_P0_L100_GLL0({lev_pv},::-1,:)
  vpv = a->VGRD_P0_L100_GLL0({lev_pv},::-1,:)
  tpv = a->TMP_P0_L100_GLL0({lev_pv},::-1,:)

  lev_pv@units = "Pa"
  pv_all = PotVortIsobaric(lev_pv,upv,vpv,tpv,tpv&lat_0,1,0)
  pv = dim_avg_n_Wrap(pv_all,0)
  pv = pv*(10^6)
  copy_VarCoords(u,pv)
  
  

  do d=0,3
    pv=smth9(pv,.5,.25,True)
  end do

  print("Successfully got data from files!")
  
;==============================================

;folder = (/"australia"/)
folder = (/"conus","northamer","pacific","atlantic","europe","asia","southpac","southamer","india","australia","africa"/)   
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)	      	

dir_plot = "/free/abentley/realtime/"+name+"/"	         
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
gsn_define_colormap(wks,"alicia_pwat")
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
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                               ; Turn off contour lines
res@cnLevelSpacingF = 1
res@cnLevelSpacingF = 5                             ; Shading interval
res@cnMinLevelValF = 20
res@cnMaxLevelValF = 70                          ; Shading interval
res@cnFillColors = (/-1,116,103,84,75,129,139,144,149,157,185,192/)

;**********************************************

res@lbAutoManage = False                  ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02
res@pmLabelBarParallelPosF = .19  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.36
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                  ; Outline the color bar 
res@lbTopMarginF = .3

; *********************************************

res@mpGeophysicalLineThicknessF = 3.0
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"Brazil:states","United States:states"/)

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

; *************************************************************

jres = True

jres@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
jres@gsnDraw = False

jres@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
jres@mpDataSetName = "Earth..4"
jres@mpOutlineBoundarySets = "National"

jres@cnFillOn = True                                              ; Turn on color fill
jres@cnFillMode = "AreaFill"
jres@cnRasterSmoothingOn = True
jres@cnLevelSelectionMode = "ExplicitLevels"
jres@cnLinesOn = False                               ; Turn off contour lines
jres@cnLevelSpacingF = 1                            ; Shading interval
;jres@cnLevels = (/50,60,70,80,90,100/)
;jres@cnLevels = (/40,50,60,70,80,90/)
jres@cnLevels = (/30,40,50,60,70,80,90,100,110/)
jres@cnFillColors = (/-1,213,212,211,231,232,233,243,225,224/)
jres@lbLabelBarOn = True
jres@lbAutoManage = False
jres@cnLineLabelsOn = False
jres@cnInfoLabelOn = False 
jres@gsnAddCyclic =  True


if domain .eq. "northamer" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0169
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "pacific" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "atlantic" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "europe" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "asia" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "southpac" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "southamer" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "india" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "africa" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "australia" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

if domain .eq. "conus" then
;jres@pmLabelBarOrthogonalPosF = .0213
jres@pmLabelBarOrthogonalPosF = .0172
jres@pmLabelBarParallelPosF = .81    
;jres@pmLabelBarHeightF = 0.11
jres@pmLabelBarHeightF = 0.106
jres@pmLabelBarWidthF = 0.36
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0124
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
end if

; *************************************************************

pvres = True

pvres@gsnFrame = False                                        
pvres@gsnDraw = False

pvres@gsnLeftString = " "
pvres@gsnRightString = " "

pvres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
pvres@cnFillOn = False
pvres@cnLineLabelsOn = True
pvres@cnLinesOn = True
pvres@cnLabelMasking = True
pvres@cnLineThicknessF = 4.5                    ; Changes thickness of contours
pvres@cnLevelSelectionMode = "ManualLevels"
pvres@cnLevelSpacingF = 1
pvres@cnMinLevelValF = 1
pvres@cnMaxLevelValF = 30 
if domain .eq. "southamer" then
	pvres@cnMinLevelValF = -30
	pvres@cnMaxLevelValF = -1 
end if
pvres@cnLineLabelAngleF = 0.0
pvres@cnLineLabelInterval = 2
pvres@cnLineLabelDensityF = .77
pvres@cnLineLabelBackgroundColor = -1
pvres@cnLineLabelFontHeightF = 0.008
pvres@cnLineLabelFontColor = "grey15"
pvres@cnLineColor = "grey15"
pvres@gsnAddCyclic =  True

; *************************************************************

pv2res = True

pv2res@gsnFrame = False                                        
pv2res@gsnDraw = False

pv2res@gsnLeftString = " "
pv2res@gsnRightString = " "

pv2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
pv2res@cnFillOn = False
pv2res@cnLineLabelsOn = True
pv2res@cnLinesOn = True
pv2res@cnLabelMasking = True
pv2res@cnLineThicknessF = 4.5                    ; Changes thickness of contours
pv2res@cnLevelSelectionMode = "ManualLevels"
pv2res@cnLevelSpacingF = 1
pv2res@cnMinLevelValF = -30
pv2res@cnMaxLevelValF = -1 
pv2res@cnLineLabelAngleF = 0.0
pv2res@cnLineLabelInterval = 2
pv2res@cnLineLabelDensityF = .77
pv2res@cnLineLabelBackgroundColor = -1
pv2res@cnLineLabelFontHeightF = 0.012
pv2res@cnLineLabelFontColor = "grey15"
pv2res@cnLineColor = "grey15"
pv2res@gsnAddCyclic =  True


; *************************************************************

omres = True

omres@gsnFrame = False                                        
omres@gsnDraw = False

omres@gsnLeftString = " "
omres@gsnRightString = " "
omres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
omres@cnFillOn = False
omres@cnLinesOn = True
omres@cnLabelMasking = True
omres@cnLineLabelsOn = False
omres@cnLineThicknessF = 4
omres@cnLineColor = "red2"
omres@cnLevelSelectionMode = "ManualLevels"
omres@cnLevelSpacingF = 0.005
omres@cnMaxLevelValF = -0.005 
omres@cnLineLabelAngleF = 0.0
omres@cnLineLabelInterval = 1
omres@cnLineLabelDensityF = .77
omres@cnLineLabelBackgroundColor = -1
omres@cnLineLabelFontHeightF = 0.018
omres@gsnAddCyclic =  True


; *************************************************************

    vres = True

    vres@gsnFrame = False                                        
    vres@gsnDraw = False
    vres@gsnAddCyclic =  True
    vres@gsnLeftString = " "
    vres@gsnRightString = " "
    
    vres@vcGlyphStyle = "FillArrow"
    vres@vcWindBarbColor = "black"
    vres@vcLineArrowColor = "black"
    vres@vcFillArrowEdgeColor = "black"
    vres@vcLineArrowThicknessF = 7
    vres@vcWindBarbCalmCircleSizeF = 0
    vres@vcWindBarbLineThicknessF = 7.5
    vres@vcMinDistanceF = 0.023
;    vres@vcMinDistanceF = 0.019
    vres@vcMinMagnitudeF = 3.0
    
    if domain .eq. "northamer" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "pacific" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "atlantic" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "europe" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "asia" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "southpac" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "southamer" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if

    if domain .eq. "india" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "africa" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "australia" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "conus" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.065
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if

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
	res@gsnLeftString = "300-200-hPa PV (gray, PVU) & irro. wind (vectors, m/s), 600-400-hPa ascent (red, 5 x 10^-3 hPa/s), 250-hPa" 
	res@gsnLeftStringOrthogonalPosF = .040
	res@gsnLeftStringFontHeightF = .009
	
	pv2res@gsnLeftStringFontColor = "black"
	pv2res@gsnLeftString = "jet (shaded, m/s), PW (shaded, mm)"
	pv2res@gsnLeftStringOrthogonalPosF = .010
	pv2res@gsnLeftStringParallelPosF = .662
	pv2res@gsnLeftStringFontHeightF = .012
	
	pvres@gsnLeftStringFontColor = "black"
	pvres@gsnLeftString = "Initialized: "+ut_string(curdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	pvres@gsnLeftStringOrthogonalPosF = .010
	pvres@gsnLeftStringFontHeightF = .010


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
jres@cnFillDrawOrder = "PreDraw"
pvres@cnLineDrawOrder ="Draw"
pv2res@cnLineDrawOrder ="Draw"
omres@cnLineDrawOrder ="Draw" 
vres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, pwat, res)          ; Plot filled contour map
jet = gsn_csm_contour(wks, wind, jres)
contours = gsn_csm_contour(wks, pv({0:90},:), pvres)
contours2 = gsn_csm_contour(wks, pv({-90:0},:), pv2res)
other = gsn_csm_contour(wks, w, omres)
vect = gsn_csm_vector(wks, irro(0,:,:), irro(1,:,:), vres)
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

overlay(plot,jet)
overlay(plot,contours)
overlay(plot,contours2)
overlay(plot,other)
overlay(plot,vect)


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
