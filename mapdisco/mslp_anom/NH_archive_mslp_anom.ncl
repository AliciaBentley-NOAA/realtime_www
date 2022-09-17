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

name = "mslp_anom"

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
  fmean = addfile("/cfsr/data/climo/mean/pmsl.0p5.mean.climo.nc","r")
  fstdev = addfile("/cfsr/data/climo/stdev/pmsl.0p5.stdev.climo.nc","r")
  
  pmsl := a->PRMSL_P0_L101_GLL0(::-1,:)     ; MSLP
  mslp := pmsl * .01
  copy_VarCoords(pmsl,mslp)
  
  u = a->UGRD_P0_L103_GLL0(0,::-1,:)       ; 10-m wind
  v = a->VGRD_P0_L103_GLL0(0,::-1,:)
  u = u * 1.94384449 
  v = v * 1.94384449
  
  curdate = tim
  curdate@units = "hours since 1800-01-01 00:00:00"

	dne_yyyy = stringtoint(ut_string(curdate,"%Y"))
	dne_mm = stringtoint(ut_string(curdate,"%N"))
	dne_dd = stringtoint(ut_string(curdate,"%D"))
	dne_hh = stringtoint(ut_string(curdate,"%H"))
	print("dne_hh: "+dne_hh)

	print("stuff: "+dne_yyyy+" "+dne_mm+" "+dne_dd)

    sdoy = day_of_year(dne_yyyy,dne_mm,dne_dd)
    
;    g_all := a->HGT_P0_L100_GLL0({lev},::-1,:) 
    g_all = lonFlip(pmsl)
    g_mean := fmean->pmsl({sdoy},{dne_hh},:,:)
    g_stdev := fstdev->pmsl({sdoy},{dne_hh},:,:)
    
  	std_anom2 := ((g_all - g_mean)/g_stdev)
  	copy_VarMeta( g_all, std_anom2 )

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

cmap =  (/(/1.00,1.00,1.00/),\
          (/0.00,0.00,0.00/),\
          (/0.92,0.72,0.91/),\
          (/0.92,0.74,0.91/),\
          (/0.92,0.52,0.91/),\
          (/0.87,0.31,0.87/),\
          (/0.72,0.07,0.82/),\
          (/0.41,0.16,0.69/),\
          (/0.24,0.22,0.65/),\
          (/0.22,0.42,0.72/),\
          (/0.43,0.60,0.81/),\
          (/0.67,0.81,0.91/),\ first blue
          (/0.99,0.93,0.45/),\
          (/0.96,0.78,0.37/),\
          (/0.96,0.63,0.32/),\
          (/0.95,0.58,0.29/),\
          (/0.96,0.36,0.20/),\
          (/0.91,0.05,0.05/),\
          (/0.63,0.02,0.02/),\
          (/0.87,0.49,0.60/),\
          (/0.43,0.17,0.17/),\
          (/0.46,0.41,0.41/),\
          (/0.66,0.61,0.61/)/)
          
gsn_define_colormap(wks,cmap)
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
res@cnLevels = (/-6.0,-5.0,-4.0,-3.0,-2.5,-2.0,-1.5,-1.0,-0.5,0,0.5,1.0,1.5,2.0,2.5,3.0,4.0,5.0,6.0/)
res@cnFillColors = (/3,4,5,6,7,8,9,10,11,-1,-1,12,13,15,16,17,18,20,21,22/)

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

mres@gsnLeftString = "@AliciaMBentley"
mres@gsnLeftStringOrthogonalPosF = -1.015
;mres@gsnLeftStringParallelPosF = -0.05
mres@gsnLeftStringFontHeightF = .01

; *************************************************************

    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey12"
    bres@vcWindBarbCalmCircleSizeF = 0
    bres@vcWindBarbLineThicknessF = 3.0
    bres@vcRefAnnoOn = False
    bres@vcRefLengthF = 0.0242
    bres@vcRefMagnitudeF = 10.0
    bres@vcRefAnnoString2On = False
    bres@vcRefAnnoOrthogonalPosF = -1.08
    bres@vcMinDistanceF = 0.040
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
	res@gsnLeftString = "MSLP (black, dam), 10-m wind (barbs, kt), standardized MSLP anomaly (shaded, sigma)"
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(curdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .0085


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
mres@cnLineDrawOrder ="Draw"
bres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, std_anom2, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, mslp, mres)
barbs = gsn_csm_vector(wks, u, v, bres)
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

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
