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

name = "6hprecip"

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
	
	odate = bdate
	odate = bdate - 24
	odateInformation = calendar_decode2(odate,-5)
	oyyyy = odateInformation(:,0)			;;; start date in yyyy mm dd hh
	omm = odateInformation(:,1)
	odd = odateInformation(:,2)
	ohh = odateInformation(:,3)

	olddate = cd_inv_calendar(oyyyy,omm,odd,00,00,00,timeUnits,0)
	; Setting old_str_time in the analysis section every time imgcount = 1
	
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
res@lbOrientation =  "vertical"
res@pmLabelBarOrthogonalPosF = 0.175
res@pmLabelBarParallelPosF = 0.5  
res@pmLabelBarHeightF = 0.64
res@pmLabelBarWidthF = 0.062
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                  
res@lbTopMarginF = .3
res@lbLabelPosition = "left"

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

thres = True

thres@gsnFrame = False                                        
thres@gsnDraw = False

thres@gsnLeftString = " "
thres@gsnRightString = " "
thres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
thres@cnFillOn = False
thres@cnLinesOn = True
thres@cnLabelMasking = True
thres@cnLineThicknessF = 3.0
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
th2res@cnLineThicknessF = 3.0
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

th2res@gsnLeftString = "@AliciaMBentley"
th2res@gsnLeftStringOrthogonalPosF = -1.015
th2res@gsnLeftStringFontHeightF = .01

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
mres@cnLineThicknessF = 3                    ; Changes thickness of contours
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

mres@gsnRightString = "www.AliciaMBentley.com"
mres@gsnRightStringParallelPosF = 0.2535
mres@gsnRightStringOrthogonalPosF = -1.035
mres@gsnRightStringFontHeightF = .01

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
	res@gsnLeftString = "MSLP (black, hPa), precipitation (shaded, mm/6h), 850-hPa temperature (red/blue, C), 10-m wind (barbs, kt)"
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	mres@gsnLeftStringFontColor = "black"
	mres@gsnLeftString = "Initialized: "+ut_string(curdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	mres@gsnLeftStringOrthogonalPosF = .010
	mres@gsnLeftStringFontHeightF = .0085


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
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

overlay(plot,other)
overlay(plot,other2)
overlay(plot,contours)
;overlay(plot,barbs)

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
