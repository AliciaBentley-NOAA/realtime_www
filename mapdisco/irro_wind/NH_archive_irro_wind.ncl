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

res@lbAutoManage = False                   ; Label Bar Information
res@lbOrientation =  "vertical"
res@pmLabelBarOrthogonalPosF = 0.186
res@pmLabelBarParallelPosF = 0.758  
res@pmLabelBarHeightF = 0.32
res@pmLabelBarWidthF = 0.062
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                  
res@lbTopMarginF = .3
res@lbLabelPosition = "left"

; *********************************************

res@mpGeophysicalLineThicknessF = 4.0
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
jres@cnFillColors = (/-1,213,212,211,231,232,233,243,225,224/)
jres@lbLabelBarOn = True
jres@lbAutoManage = False
jres@cnLineLabelsOn = False
jres@cnInfoLabelOn = False 
jres@gsnAddCyclic =  True


if domain .eq. "NH" then
jres@lbOrientation =  "vertical"
jres@lbLabelPosition = "left"
jres@pmLabelBarOrthogonalPosF = -.1081
jres@pmLabelBarParallelPosF = 0.25    
jres@pmLabelBarHeightF = 0.32
jres@pmLabelBarWidthF = 0.062
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0121
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
;jres@cnLevels = (/40,50,60,70,80,90/)
jres@cnLevels = (/30,40,50,60,70,80,90,100,110/)
end if

if domain .eq. "SH" then
jres@lbOrientation =  "vertical"
jres@lbLabelPosition = "left"
jres@pmLabelBarOrthogonalPosF = -.1081
jres@pmLabelBarParallelPosF = 0.25    
jres@pmLabelBarHeightF = 0.32
jres@pmLabelBarWidthF = 0.062
jres@lbLabelAutoStride = True
jres@lbLabelFontHeightF = 0.0121
jres@lbBoxLinesOn  = True                            ; Outline the color bar 
jres@lbTopMarginF = .3
jres@gsnLeftString = " "
jres@gsnRightString = " "
;jres@cnLevels = (/40,50,60,70,80,90/)
jres@cnLevels = (/30,40,50,60,70,80,90,100,110/)
end if

; *************************************************************

pvres = True

pvres@gsnFrame = False                                        
pvres@gsnDraw = False

pvres@gsnLeftString = " "
pvres@gsnRightString = " "

pvres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
pvres@cnFillOn = False
pvres@cnLineLabelsOn = False
pvres@cnLinesOn = True
pvres@cnLabelMasking = True
pvres@cnLineThicknessF = 3.5                    ; Changes thickness of contours
pvres@cnLevelSelectionMode = "ManualLevels"
pvres@cnLevelSpacingF = 1
pvres@cnMinLevelValF = 1
pvres@cnMaxLevelValF = 30 
if domain .eq. "SH" then
	pvres@cnMinLevelValF = -30
	pvres@cnMaxLevelValF = -1 
end if
pvres@cnLineLabelAngleF = 0.0
pvres@cnLineLabelInterval = 1
pvres@cnLineLabelDensityF = .77
pvres@cnLineLabelBackgroundColor = -1
pvres@cnLineLabelFontHeightF = 0.008
pvres@cnLineLabelFontColor = "grey15"
pvres@cnLineColor = "grey15"
pvres@gsnAddCyclic =  True

pvres@gsnLeftString = "@AliciaMBentley"
pvres@gsnLeftStringOrthogonalPosF = -1.015
pvres@gsnLeftStringFontHeightF = .01

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

omres@gsnLeftString = "www.AliciaMBentley.com"
omres@gsnLeftStringOrthogonalPosF = -1.035
omres@gsnLeftStringFontHeightF = .01


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
    vres@vcMinDistanceF = 0.015
;    vres@vcMinDistanceF = 0.019
    vres@vcMinMagnitudeF = 5.0
    
    if domain .eq. "NH" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 15.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.035
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "SH" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.035
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
	res@gsnLeftString = "300-200-hPa PV (gray, PVU) & irro. wind (vectors, m/s), 600-400-hPa ascent (red, 5 x 10^-3 hPa/s), 250-hPa jet" 
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	jres@gsnLeftStringFontColor = "black"
	jres@gsnLeftString = "(shaded, m/s), PW (shaded, mm)"
	jres@gsnLeftStringOrthogonalPosF = .010
	jres@gsnLeftStringParallelPosF = .771
	jres@gsnLeftStringFontHeightF = .0098
	
	vres@gsnLeftStringFontColor = "black"
	vres@gsnLeftString = "Initialized: "+ut_string(curdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	vres@gsnLeftStringOrthogonalPosF = .010
	vres@gsnLeftStringFontHeightF = .0085


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
jres@cnFillDrawOrder = "PreDraw"
pvres@cnLineDrawOrder ="Draw"
omres@cnLineDrawOrder ="Draw" 
vres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, pwat, res)          ; Plot filled contour map
jet = gsn_csm_contour(wks, wind, jres)
contours = gsn_csm_contour(wks, pv, pvres)
other = gsn_csm_contour(wks, w, omres)
vect = gsn_csm_vector(wks, irro(0,:,:), irro(1,:,:), vres)
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

overlay(plot,jet)
overlay(plot,contours)
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
