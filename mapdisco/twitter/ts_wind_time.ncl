; ===========================================
; Plot composited PV on isentropic surfaces
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

delall = 0
check_dne = 0
timeUnits = "hours since 1800-01-01 00:00:00"

datestr = systemfunc("date")
print("datestr: "+datestr)

cyc = "18"
date = 20180912
sdate = cd_inv_calendar(2018,09,12,tofloat(cyc),00,00,timeUnits,0)
total_hr := new((/721,1440/),"float",-999999999999)

folder = (/"midatl"/)   
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)
    
imgcount = 1			;;; this starts the image count at 1 (you can change this to any number you want
  				        ;;; but note it counts up by 1 at a time as you move 6h forward in time

name = "10mwind"
dir_grib = "/free2/abentley/realtime/"+name+"/archive/"		        
dir_out = "/lb11/abentley/www/test/images/"

;*****************************************************

             print("Plotting from forecast grib files")
;             fhr  := (/6,12/)
             fhr  := ispan(0,96,1)
;             fhr  := (/6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192/)
             nfhr = dimsizes(fhr)
  
             do f = 0,nfhr-1
                 if (fhr(f).lt.10) then
                      filefhr = "00"+fhr(f)
                 else if ((fhr(f).lt.100).and.(fhr(f).ge.10)) then
                      filefhr = "0"+fhr(f)
                 else if (fhr(f).ge.100) then
                      filefhr = fhr(f)
                 end if 
                 end if
                 end if
                 
                 ;print(filefhr)
                 

  print("http://para.nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/para/gfs."+date+"/"+cyc+"/gfs.t"+cyc+"z.pgrb2.0p25.f"+filefhr+".grib2")
  fv3file = "gfs.t"+cyc+"z.pgrb2.0p25.f"+filefhr+".grib2"

if (isfilepresent(fv3file)) then
   print("Found FV3GFS file!")
else  
   system("wget http://para.nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/para/gfs."+date+"/"+cyc+"/gfs.t"+cyc+"z.pgrb2.0p25.f"+filefhr)
end if

  filename = fv3file
  fhr_cur = fhr(f)
  
 ;*****************************************************
 
  a = addfile(filename,"r")
  
  	u10m := a->UGRD_P0_L103_GLL0({10},::-1,:)                           ;UGRD_P0_L103_GGA0(::-1,:)
  	v10m := a->VGRD_P0_L103_GLL0({10},::-1,:)
  	
  	speedms := ((u10m^2)+(v10m^2))^0.5
	copy_VarCoords(u10m,speedms)  	
	speedmph := (speedms*2.23694) ; convert from m/s to mph
	copy_VarCoords(speedms,speedmph)
	
	if fhr(f) .lt. 1 then
	   	copy_VarCoords(speedmph,total_hr)
	   	total_hr(:,:) = 0
;	   	print("In here!")
	end if
	
;	printVarSummary(total_hr)
;    printMinMax(speedmph,True)

;	print("Number of hrs: "+total_hr({31},{360-71}))
    total_hr = where(speedmph .ge. 39.0, total_hr+1, total_hr+0)
;    printMinMax(total_hr,True)
;	print("Number of hrs: "+total_hr({31},{360-71}))
	

;  mslp = a->MSLET_P0_L101_GLL0(::-1,:)
;  mslp = mslp/100.
;  printMinMax(mslp,True)
  
print("Successfully did that step!")

end do
end do

printMinMax(total_hr,True)
	
 
;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,"./"+name+"_"+imgcount)
gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
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
;res@cnLevelSpacingF = 2
;res@cnMinLevelValF = 2
;res@cnMaxLevelValF = 48
res@cnLevels = (/1,2,4,6,8,10,12,14,16,18,20,22,24,26,30,35,40,45,50,55,60,65,70,75,80/)
res@cnFillColors = (/0,21,31,35,42,47,55,62,67,72,84,90,110,120,130,138,154,162,168,175,180,186,192,196,199,201/)

;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                   ; Outline the color bar 
res@lbTopMarginF = .3

;**********************************************

res@tiMainString = " "
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = .02
res@tiXAxisFontHeightF = .015

res@gsnLeftString = "[FV3GFS] Duration of TS force winds (hours) since "+ut_string(sdate,"")
res@gsnLeftStringOrthogonalPosF = .0075
res@gsnLeftStringFontHeightF = .010
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .009

  curdate = sdate + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

  if (fhr_cur .gt. 0) then
;     res@gsnRightString = "(F"+filefhr+") Valid: "+ut_string(curdate,"")
     res@gsnRightString = " "
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  else
     res@gsnRightString = "(Analysis) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  end if
; *********************************************

res@mpGeophysicalLineThicknessF = 5.0
res@mpNationalLineThicknessF = 4.0
res@mpUSStateLineThicknessF = 4.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "black"
res@mpNationalLineColor = res@mpGeophysicalLineColor
res@mpUSStateLineColor = res@mpGeophysicalLineColor

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 5.
res@mpGridLonSpacingF = 5.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey28"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,5)
tmres@tmYRValues = ispan(-80,80,5)
tmres@tmXBValues = ispan(-180,179,5)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = ispan(-180,179,5)
; *************************************************************

if domain .eq. "northamer"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
res@mpLambertMeridianF = -100
res@mpLimitMode = "LatLon"
res@mpMinLatF = 8
res@mpMaxLatF = 69
res@mpMinLonF = -151
res@mpMaxLonF = -49
end if


if domain .eq. "pacific"
res@mpProjection = "LambertConformal"
  westlon = 118.
  eastlon = -118.
  centerlon = 180. ; to use this effectively remember its the the distance of lon between west and east divided by 2
  if(westlon.gt.eastlon)then
    useflip = True
    westlon = westlon
    eastlon = eastlon+360.
    if (centerlon.lt.0)then
      centerlon = centerlon+360.
    end if
  end if
res@mpLambertParallel2F = 28
res@mpLambertParallel1F = 7
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
res@mpLambertMeridianF = centerlon
res@mpLimitMode = "LatLon"
res@mpMinLatF = -15
res@mpMaxLatF = 71
res@mpMinLonF = westlon
res@mpMaxLonF = eastlon
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
res@mpMinLatF = 6
res@mpMaxLatF = 71
res@mpMinLonF = -90
res@mpMaxLonF = 30
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
res@mpMinLatF = 25
res@mpMaxLatF = 72
res@mpMinLonF = -46
res@mpMaxLonF = 46
end if

if domain .eq. "southamer"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
delete(res@mpProjection)
res@mpProjection = "Mercator"
res@mpLimitMode = "LatLon"
res@mpMinLatF = -70
res@mpMaxLatF = 8
res@mpMinLonF = -122
res@mpMaxLonF = 12
end if

if domain .eq. "eastcoast"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 20
res@mpLambertParallel1F = 10
res@mpLambertMeridianF = -80
res@mpLimitMode = "LatLon"
res@mpMinLatF = 8
res@mpMaxLatF = 56
res@mpMinLonF = -101
res@mpMaxLonF = -49
end if

if domain .eq. "conus" then
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 11
res@mpLambertParallel1F = 5
res@mpLambertMeridianF = -100
res@mpLimitMode = "LatLon"
res@mpMinLatF = 20
res@mpMaxLatF = 52
res@mpMinLonF = -125
res@mpMaxLonF = -67
delete(tmres@tmXBValues)
tmres@tmXBValues = ispan(-180,179,20)
delete(tmres@tmYRValues)
delete(tmres@tmYLValues)
tmres@tmYLValues = ispan(0,80,10)
tmres@tmYRValues = ispan(0,80,10)
end if

if domain .eq. "midatl"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 20
res@mpLambertParallel1F = 10
res@mpLambertMeridianF = -75
res@mpLimitMode = "LatLon"
res@mpMinLatF = 27            ;24
res@mpMaxLatF = 38              ;47
res@mpMinLonF = -82            ;-91
res@mpMaxLonF = -68               ;-59
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
mres@cnLineThicknessF = 4                    ; Changes thickness of contours
mres@cnLevelSelectionMode = "ManualLevels"
mres@cnLevelSpacingF = 4
mres@cnMinLevelValF = 800
mres@cnMaxLevelValF = 1200  
mres@cnLineLabelAngleF = 0.0
mres@cnLineLabelInterval = 1
mres@cnLineLabelDensityF = 1.0
;mres@cnLineColor = "navyblue"
;mres@cnLineLabelFontColor = mres@cnLineColor
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

; *************************************************************
res@mpFillOn = False
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
res@mpOutlineDrawOrder = "Draw"
mres@cnLineDrawOrder ="Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, total_hr, res)          ; Plot filled contour map
;contours = gsn_csm_contour(wks, mslp, mres)
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
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",117.7,-6.7,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",118.4,-8.8,tres)
else if domain .eq. "atlantic" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-85.0,-4,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-84,-6,tres)
else if domain .eq. "europe" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.011
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-45.0,23.2,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-44.7,21.7,tres)
else if domain .eq. "southamer" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-121.5,-68.6,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-121.5,-69.5,tres)
else if domain .eq. "eastcoast" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    print("Got in here!")
    mytext = gsn_add_text(wks,plot,"@AliciaMBentley",-100.8,9.0,tres)
    mytext2 = gsn_add_text(wks,plot,"www.AliciaMBentley.com",-100.7,7.8,tres)
end if 
end if 
end if
end if
end if
end if 

;********************************************

;overlay(plot,contours)

;********************************************

draw(plot)
frame(wks)

system("convert ./"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
;system ("'rm' ./"+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)  

imgcount = imgcount + 1



end
