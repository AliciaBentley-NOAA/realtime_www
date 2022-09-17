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

;move = "no"
move = "yes"

;toplot = "no"
toplot = "yes"

name = "coupling"




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

 a = addfile(filename,"r")
  
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
           theta_e := t_e*(1000/conform(t_e,phpa,0))^0.286
           theta_e_max := dim_max_n_Wrap(theta_e,0)

;**********************************************************

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
  pres_pv!0 = "lat_0"
  pres_pv!1 = "lon_0"
  pres_pv&lat_0 = nhpres_pv&lat_0
  pres_pv&lon_0 = nhpres_pv&lon_0

  copy_VarMeta(pres_pv,t_pv)

  pres_pv({0:90},:) = nhpres_pv({0:90},:)
  pres_pv({-90:-0.5},:) = shpres_pv({-90:-0.5},:)
  t_pv({0:90},:) = nht_pv({0:90},:)
  t_pv({-90:-0.5},:) = sht_pv({-90:-0.5},:)

  theta_trop = t_pv*((100000/pres_pv)^(0.286))
  copy_VarMeta(t_pv,theta_trop)
  
  coup = theta_trop(:,:) - theta_e_max(:,:)
  copy_VarCoords(theta_trop,coup)

;*******************************************************

    ut = a->UGRD_P0_L100_GLL0({20000},::-1,:)
    vt = a->VGRD_P0_L100_GLL0({20000},::-1,:)
    ub = a->UGRD_P0_L100_GLL0({85000},::-1,:)
    vb = a->VGRD_P0_L100_GLL0({85000},::-1,:)

    ushear = ut - ub
    vshear = vt - vb 
    ushear = ushear * 1.94384449 
    vshear = vshear * 1.94384449
    copy_VarCoords(ut,ushear)
    copy_VarCoords(vt,vshear)
    
    mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  	mslp = mslp * .01
  	
;*******************************************************
  	
  lev_pv  = (/20000,25000,30000/)
  upv = a->UGRD_P0_L100_GLL0({lev_pv},::-1,:)
  vpv = a->VGRD_P0_L100_GLL0({lev_pv},::-1,:)
  tpv = a->TMP_P0_L100_GLL0({lev_pv},::-1,:)

  lev_pv@units = "Pa"
  pv_all = PotVortIsobaric(lev_pv,upv,vpv,tpv,tpv&lat_0,1,0)
  pv = dim_avg_n_Wrap(pv_all,0)
  pv = pv*(10^6)
  copy_VarCoords(ut,pv)
  
  do d=0,3
    pv=smth9(pv,.5,.25,True)
  end do

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
gsn_define_colormap(wks,"BlueRedGray")
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
;res@cnLevels = (/-10,-7.5,-5,-2.5,0,2.5,5,7.5,10/)
res@cnLevels = (/-20,-15,-10,-5,0,5,10,15,22.5/)
;res@cnFillColors = (/240,217,187,162,138,36,68,95,116,-1/)
res@cnFillColors = (/227,212,187,162,138,36,68,95,116,-1/)
res@cnSmoothingOn = True
res@cnSmoothingTensionF = -2.
res@cnSmoothingDistanceF = 0.001

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
pvres@cnLineLabelInterval = 2
pvres@cnLineLabelDensityF = .77
pvres@cnLineLabelBackgroundColor = -1
pvres@cnLineLabelFontHeightF = 0.012
pvres@cnLineLabelFontColor = "grey15"
pvres@cnLineColor = "grey15"
pvres@gsnAddCyclic =  True

; *************************************************************

mres = True

mres@gsnFrame = False                                        
mres@gsnDraw = False

mres@gsnLeftString = " "
mres@gsnRightString = " "

mres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
mres@cnFillOn = False
mres@cnLineLabelsOn = False
mres@cnLinesOn = False
mres@gsnAddCyclic =  True
mres@cnLowLabelsOn = True
mres@cnLowLabelBackgroundColor = -1
mres@cnLowLabelString = "$ZDV$"
mres@cnLowLabelPerimOn = False
mres@cnLowLabelFontHeightF = 0.0005
;mres@cnHighLabelFontHeightF = 0.016
mres@cnLowLabelFontThicknessF = 8.0
;mres@cnHighLabelFontThicknessF = 8.0
mres@cnLowLabelFontColor = "red2"
;mres@cnLowLabelFont = "complex_roman"
;mres@cnLowLabelFont = "times-bold"
;mres@cnLowLabelFont = "courier-bold"

mres@gsnLeftString = "@AliciaMBentley"
mres@gsnLeftStringOrthogonalPosF = -1.015
mres@gsnLeftStringFontHeightF = .01

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
	res@gsnLeftString = "300-200-hPa PV (gray, PVU), Coupling Index (shaded, C), 850-200-hPa shear (barbs, kt), Lows (red, hPa)"
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(sdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .0085


; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
bres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
mres@cnLabelDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, coup(:,:), res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, pv, pvres)
lows = gsn_csm_contour(wks, mslp, mres)
barbs = gsn_csm_vector(wks, ushear, vshear, bres)
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

overlay(plot,contours)
overlay(plot,lows)
overlay(plot,barbs)

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
