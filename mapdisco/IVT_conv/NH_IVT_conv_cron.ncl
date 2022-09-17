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
load "~/ncl/lib/IVT_util.ncl"
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

name = "IVT_conv"




;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------

if move .eq. "yes" then

start_img = 2    ; first image to move
end_img = 89	 ; last image to move

; First list is all possible domain options
folder = (/"NH","SH"/)    
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

  a := addfile(filename,"r")

  u := a->UGRD_P0_L100_GLL0({100000:30000},::-1,:)
  v := a->VGRD_P0_L100_GLL0({100000:30000},::-1,:)

  rh := a->RH_P0_L100_GLL0({100000:30000},::-1,:)	; relative humidity
  tk := a->TMP_P0_L100_GLL0({100000:30000},::-1,:)   ; in kelvin
  p_temp := tk&lv_ISBL0
  p_temp := p_temp/100
;  print(p_temp)
  
  p := conform_dims(dimsizes(rh), p_temp, 0)
  
  q := mixhum_ptrh (p, tk, rh, 2)
  copy_VarCoords(rh,q)
;  printVarSummary(q)
  
  	IVT := uvIVT(u,v,q)  	;calculate IVT
	uIVT := IVT(0,:,:)   	;u-comp of IVT
	vIVT := IVT(1,:,:)    	;v-comp of IVT

mag_IVT := (uIVT^2.+vIVT^2.)^0.5   ;calculate magnitude of IVT
copy_VarCoords(uIVT,mag_IVT)
mag_IVT@units = "kg m^-1 s^-1"
mag_IVT@long_name = "magnitude of IVT"
;printVarSummary(mag_IVT)

IVT_conv := -1.0*uv2dv_cfd(uIVT,vIVT,uIVT&lat_0,vIVT&lon_0,0)
IVT_conv := IVT_conv*(10^3)
copy_VarCoords(uIVT,IVT_conv)
;printMinMax(IVT_conv,True)

g := a->HGT_P0_L100_GLL0({70000},::-1,:) 
g = g/10   

  print("Successfully got data from files!")
  
;==============================================

folder2 = (/"NH","SH"/)
enddomain2 = dimsizes(folder2)

do x = 0,enddomain2-1

domain = folder2(x)

print(" ")
print("Plotting maps for: "+domain)	      	

dir_plot = "/free/abentley/realtime/"+name+"/grib2/"	         
dir_out = "/lb11/abentley/www/realtime/images/"+domain+"/"+name+"/"
;;system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/")
;;system("mkdir /lb11/abentley/www/realtime/images/"+domain+"/"+name+"/")


;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+name+"_"+imgcount)
gsn_define_colormap(wks,"ncl_default_with_gray")  
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
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLinesOn = True                              ; Turn off contour lines
res@cnLineColor 		= "grey30"
res@cnLevels = (/250,300,400,500,600,700,800,1000,1200,1400,1600/)
res@cnFillColors = (/-1,140,152,163,173,183,194,202,240,7,8,9,10,0/)

;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@lbOrientation =  "vertical"
res@pmLabelBarOrthogonalPosF = 0.170
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
cnres@cnLineThicknessF = 3.0                   ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 3
cnres@cnMinLevelValF = 150
cnres@cnMaxLevelValF = 420  
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = 1.1
;cnres@cnSmoothingOn = True
;cnres@cnSmoothingDistanceF = 0.009
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008
cnres@gsnAddCyclic =  True

cnres@gsnLeftString = "@AliciaMBentley"
cnres@gsnLeftStringOrthogonalPosF = -1.015
cnres@gsnLeftStringFontHeightF = .01


; *************************************************************

conres = True

conres@gsnFrame = False                                        
conres@gsnDraw = False

conres@gsnLeftString = " "
conres@gsnRightString = " "

conres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
conres@cnFillOn = False
conres@cnLineLabelsOn = False
conres@cnLinesOn = True
conres@cnLabelMasking = True
conres@cnLineThicknessF = 7.0                    ; Changes thickness of contours
conres@cnLevelSelectionMode = "ManualLevels"
conres@cnLevelSpacingF = 0.5
conres@cnMinLevelValF = 0.5
conres@cnLineColor = "blue"
conres@cnLineLabelFontColor = conres@cnLineColor
conres@cnLineLabelAngleF = 0.0
conres@cnLineLabelInterval = 3
conres@cnLineLabelDensityF = 1.4
conres@cnLineLabelBackgroundColor = -1
conres@cnLineLabelFontHeightF = 0.008

conres@cnLevelSelectionMode = "ExplicitLevels"
conres@cnLevels = (/0.5/)

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
    vres@vcMinDistanceF = 0.030
;    vres@vcMinDistanceF = 0.019
    vres@vcMinMagnitudeF = 0.0
    
    if domain .eq. "NH" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ kg m~S~~F19~@~F21~1"+" ~N~"+"s~S~~F19~@~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 1000.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.035
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "SH" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ kg m~S~~F19~@~F21~1"+" ~N~"+"s~S~~F19~@~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 1000.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.035
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if
    
vres@gsnRightString = "www.AliciaMBentley.com"
vres@gsnRightStringParallelPosF = 0.2535
vres@gsnRightStringOrthogonalPosF = -1.035
vres@gsnRightStringFontHeightF = .01

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
	res@gsnLeftString = "700-hPa geo. height (black, dam), Integrated water vapor transport [IVT] (shaded, kg/m/s) (vectors, kg/m/s)"
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	vres@gsnLeftStringFontColor = "black"
	vres@gsnLeftString = "Initialized: "+ut_string(sdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	vres@gsnLeftStringOrthogonalPosF = .010
	vres@gsnLeftStringFontHeightF = .0085


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
cnres@cnLineDrawOrder ="Draw" 
conres@cnLineDrawOrder ="Draw" 
vres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, mag_IVT, res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, g, cnres)
conv = gsn_csm_contour(wks, IVT_conv, conres)
vect = gsn_csm_vector(wks, uIVT, vIVT, vres)
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

overlay(plot,contours)
overlay(plot,vect)

;********************************************

draw(plot)
frame(wks)

;*********************************************

system("pngquant "+dir_plot+name+"_"+imgcount+".png")
system("'mv' "+dir_plot+name+"_"+imgcount+"-fs8.png "+dir_plot+name+"_"+imgcount+".png") 
system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".png")
system ("'rm' "+dir_plot+name+"_*.png")
system ("'rm' "+dir_plot+name+"_*-fs8.png")


print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

end do     	; end domain

imgcount = imgcount + 1
end do		; end tim

end if ; toplot .eq. "yes"

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
