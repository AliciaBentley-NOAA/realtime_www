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

name = "310K_isen"




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

  isen_lev = (/310/)
  
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
  
;print("Creating Isentropic PV")

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

  do d=0,3
     p_th=smth9(p_th,.5,.25,True)
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
res@cnLevelSpacingF = 1                            ; Shading interval
res@cnLevels := (/0,0.5,1,1.5,2,4,6,8,10/)
res@cnFillColors := (/6,-1,14,13,12,16,19,22,33,26/)
if domain .eq. "SH" then
res@cnLevels := (/0,-0.5,-1,-1.5,-2,-4,-6,-8,-10/)
res@cnFillColors := (/26,33,22,19,16,12,13,14,-1,6/)
end if
;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@lbOrientation =  "vertical"
res@pmLabelBarOrthogonalPosF = 0.183
res@pmLabelBarParallelPosF = 0.5  
res@pmLabelBarHeightF = 0.64
res@pmLabelBarWidthF = 0.062
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                  
res@lbTopMarginF = .3
res@lbLabelPosition = "left"

if domain .eq. "SH" then
res@pmLabelBarOrthogonalPosF = 0.179
end if

; *********************************************

res@mpGeophysicalLineThicknessF = 4.5
res@mpNationalLineThicknessF = 4.0
res@mpUSStateLineThicknessF = 3.0
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
cnres@cnLineThicknessF = 3                    ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 30
cnres@cnMinLevelValF = 90
cnres@cnMaxLevelValF = 900  
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = .93
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008
cnres@gsnAddCyclic =  True

cnres@gsnLeftString = "@AliciaMBentley"
cnres@gsnLeftStringOrthogonalPosF = -1.015
cnres@gsnLeftStringFontHeightF = .01

; *************************************************************


    bres = True

    bres@gsnFrame = False                                        
    bres@gsnDraw = False

    bres@gsnLeftString = " "
    bres@gsnRightString = " "

    bres@vcGlyphStyle = "WindBarb"
    bres@vcWindBarbColor = "grey17"
    bres@vcWindBarbCalmCircleSizeF = 0
    bres@vcWindBarbLineThicknessF = 3.0
    bres@vcRefAnnoOn = False
    bres@vcRefLengthF = 0.0242
    bres@vcRefMagnitudeF = 10.0
    bres@vcRefAnnoString2On = False
    bres@vcRefAnnoOrthogonalPosF = -1.08
    bres@vcMinDistanceF = 0.050
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
	res@gsnLeftString = isen_lev+" K PV (shaded, PVU), pressure (black, hPa), and wind (barbs, kt)"
	res@gsnLeftStringOrthogonalPosF = .034
	res@gsnLeftStringFontHeightF = .010
	
	bres@gsnLeftStringFontColor = "black"
	bres@gsnLeftString = "Initialized: "+ut_string(sdate,"")+" | Forecast hour: "+fhr_cur+" | Valid: "+ut_string(curdate,"")
	bres@gsnLeftStringOrthogonalPosF = .010
	bres@gsnLeftStringFontHeightF = .0085


; *************************************************************
res@mpGridAndLimbDrawOrder = "PostDraw"
res@cnFillDrawOrder = "PreDraw"
bres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpFillOn = False
res@mpOutlineOn = True

plot = gsn_csm_contour_map(wks, pv_isen_all({isen_lev(il)},:,:), res)          ; Plot filled contour map
contours = gsn_csm_contour(wks, p_th({isen_lev(il)},:,:), cnres)
barbs = gsn_csm_vector(wks, u_th({isen_lev(il)},:,:), v_th({isen_lev(il)},:,:), bres)
;plot = add_map_tickmarks(wks,plot,tmres)

;********************************************

overlay(plot,contours)
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
end do 		; end il
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
