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

name = "dt_2pvu"

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

folder = (/"NH","SH"/)
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)	      	

dir_plot = "/free/abentley/realtime/"+name+"/"	         
dir_out = "/lb11/abentley/www/realtime/images/"+domain+"/"+name+"/"


;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+name+"_"+imgcount)
gsn_define_colormap(wks,"alicia")
;**********************************************
res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                              ; Turn on color fill
res@cnFillMode = "RasterFill"
;res@cnFillMode = "AreaFill"
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
res@lbOrientation =  "vertical"
res@pmLabelBarOrthogonalPosF = 0.179
res@pmLabelBarParallelPosF = 0.5  
res@pmLabelBarHeightF = 0.64
res@pmLabelBarWidthF = 0.062
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                  
res@lbTopMarginF = .3
res@lbLabelPosition = "left"

; *********************************************

res@mpGeophysicalLineThicknessF = 5.0
res@mpNationalLineThicknessF = 4.0
res@mpUSStateLineThicknessF = 4.0
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
;res@pmTickMarkDisplayMode = "Always"

; *************************************************************


if domain .eq. "NH"
res@gsnPolar = "NH"
res@mpCenterLonF = -90.
res@mpMinLatF    = 10
res@mpMaxLatF    = 90
end if


if domain .eq. "SH"
res@gsnPolar = "SH"
res@mpCenterLonF = -90.
res@mpMinLatF    = -90
res@mpMaxLatF    = -10
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
relres@cnLineThicknessF = 3
relres@cnLineColor = "black"
;relres@cnLineColor = "navy"
relres@cnLevelSelectionMode = "ManualLevels"
relres@cnLevelSpacingF = .5*10^-4
relres@cnMinLevelValF = .5*10^-4
relres@cnMaxLevelValF = 10*10^-4
if domain .eq. "SH" then
	relres@cnMinLevelValF := -10.0*10^-4
	relres@cnMaxLevelValF := -.5*10^-4
end if
relres@cnLineLabelsOn = False
relres@cnLineLabelAngleF = 0.0
relres@cnLineLabelInterval = 1
relres@cnLineLabelDensityF = .77
relres@cnLineLabelBackgroundColor = -1
relres@cnLineLabelFontHeightF = 0.018
relres@gsnAddCyclic =  True

relres@gsnLeftString = "@AliciaMBentley"
relres@gsnLeftStringOrthogonalPosF = -1.015
relres@gsnLeftStringFontHeightF = .01

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

bres@gsnRightString = "www.AliciaMBentley.com"
bres@gsnRightStringParallelPosF = 0.2535
bres@gsnRightStringOrthogonalPosF = -1.035
bres@gsnRightStringFontHeightF = .01

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
	res@gsnLeftString = "DT potential temperature (shaded, K) & wind (barbs, kt), 925-850-hPa cycl. rel. vort. (black, 0.5 x 10^-4 s^-1)"
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(curdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .0085


; *************************************************************
res@mpGridAndLimbDrawOrder = "PostDraw"
res@cnFillDrawOrder = "PreDraw"
relres@cnLineDrawOrder ="Draw" 
bres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpFillOn = False
res@mpOutlineOn = True

plot = gsn_csm_contour_map(wks, theta, res)          ; Plot filled contour map
other = gsn_csm_contour(wks, relvort, relres)
barbs = gsn_csm_vector(wks, u_pv, v_pv, bres)
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

overlay(plot,other)
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
