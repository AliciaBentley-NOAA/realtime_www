; ===========================================
; Plot composited PV on isentropic surfaces
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
;load "/home/carl/nclscripts/lib/tTick.ncl"
;load "/home/carl/nclscripts/lib/ut_string.ncl"
;load "/home/kgriffin/ncl_lib/shea_util.ncl"
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

delall = 0
check_dne = 0
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
bdate = bdate - 7*24
dateInformation = calendar_decode2(bdate,-5)
syyyy = dateInformation(:,0)			;;; start date in yyyy mm dd hh
smm = dateInformation(:,1)
sdd = dateInformation(:,2)
shh = dateInformation(:,3)

ldate = cdate
ldate = ldate - 24
dateInformation = calendar_decode2(ldate,-5)
eyyyy = dateInformation(:,0)			;;; start date in yyyy mm dd hh
emm = dateInformation(:,1)
edd = dateInformation(:,2)

if shh .lt. 7 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,00,00,00,timeUnits,0) ;;; Convert string values to integers to use cd_inv_calendar function
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 00  ;;; choose forecast synoptic time (e.g. 00 will plot the forecast initialized at 00 UTC)
else if shh .ge. 7 .and. shh .lt. 15 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,06,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 06
else if shh .ge. 15 .and. shh .lt. 22 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 12
else if shh .ge. 22 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,18,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 18
end if
end if
end if
end if

print("GFS Forecast: "+hr+"Z run")

;;; end date in yyyy mm dd hh (note end of analysis must ALWAYS end at 18 UTC)
;;; this is because grib files are packaged in .tar format which saves daily files
;;; (00,06,12,18) bundeling all the synoptic times in one file. This program
;;; bridges the gap if you are looking at a forecast other than starting at 00 UTC
;;; by filling in the missing dates with the forecast analysis grib files 

print("sdate: "+ut_string(sdate,""))
print("edate: "+ut_string(edate,""))

folder = (/"southeast"/)  
;folder = (/"northamer","pacific","atlantic"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)

fcast = "yes" 		        ;;; do you want to plot the 192 hour GFS forecast at the next synoptic time?	         	
  
fdate = edate + hr + 6
    
imgcount = 29			;;; this starts the image count at 1 (you can change this to any number you want
  				        ;;; but note it counts up by 1 at a time as you move 6h forward in time

name = "coupling"
dir_grib = "/free/abentley/realtime/grib/"	
dir_plot = "/free/abentley/realtime/"+name+"/grib4/"	        
dir_out = "/lb11/abentley/www/realtime/images/"+domain+"/"+name+"/"


if x .gt. 0 then
delete(fhr)
delete(fhr_cur)
delete(nfhr)
end if

;*****************************************************

if(fcast.eq."yes") then
  print("Will plot analysis first then forecast")

  do tim = sdate,fdate,6
         tim@units = "hours since 1800-01-01 00:00:00"   ;define units for t (which is the time in 6 hour intervals)
    
         if(tim.eq.sdate) then
             print("Time = Start Date")
         end if
         
         ; Let's make a few date strings
         str_time = ut_string(tim,"%y%N%D")
         str_hr = ut_string(tim,"%H")
         
         baddate1 = cd_inv_calendar(2016,4,14,0,00,00,timeUnits,0)
         baddate2 = cd_inv_calendar(2016,4,14,6,00,00,timeUnits,0)
         baddate3 = cd_inv_calendar(2016,4,14,12,00,00,timeUnits,0)
         baddate4 = cd_inv_calendar(2016,4,14,18,00,00,timeUnits,0)
         
         if (tim.eq.baddate1) .or. (tim.eq.baddate2) .or. (tim.eq.baddate3) .or. (tim.eq.baddate4) then
         	print("Got in here! It's gonna fail!")
         	system("'cp' /free2/abentley/realtime/GFS_"+str_time+"_"+str_hr+"_000 "+dir_grib+".")
         	print("Correct file moved to right folder!")
         end if	
  
         ; Get the tar file and opens the grib files
         if(tim .le. edate) then
             if(str_hr .eq. "00") then
;  	        system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
;  	        system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if
  
             ;;; new... to read in files that don't start at 00 UTC
             if( (tim.eq.sdate) .and. (str_hr.ne."00")) then
;                system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
;  	            system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if  
          end if
      
          ;now that the filename should be in the proper directory, go ahead and add it
          ;check to make sure it exists too!
  
          if(tim .le. edate) then
                filename = dir_grib+"GFS_"+str_time+"_"+str_hr+"_000.grb2"
				if (isfilepresent(filename)) then
				    if (imgcount .gt. 29) then
;				        system("rm -f "+dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000")			
				    end if
				else
				  	filename = dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000.grb2"
				  	print("File does not exist. Using last file that did...")
				    print("filename: "+filename)
				    check_dne = 1
                end if
                dne_time = ut_string(tim,"%y%N%D")
			    dne_hr = ut_string(tim,"%H")
          end if
  
          if(tim .eq. fdate) then
             print("Plotting from forecast grib files")
             ; HERE NEEDS A DELETE fhr????
             delete(fhr)
             fhr  = (/0,6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192/)
             nfhr = dimsizes(fhr)
          else
             fhr = (/0/)
             nfhr = dimsizes(fhr)
          end if
  
          if(tim .gt. edate) then
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
      	delete(a)
      	delete(nht_pv)
      	delete(nhpres_pv)
      	delete(sht_pv)
      	delete(shpres_pv)
      	delete(pres_pv)
      	delete(t_pv)
      	delete(theta_trop)
;      	delete(h)
;      	delete(uvgeo)
      	delete(u1)
      	delete(v1)
      	delete(u2)
      	delete(v2)
      	delete(relvort200)
      	delete(relvort500)
      	delete(therm_vort)
      	delete(ut)
      	delete(ub)
      	delete(vt)
      	delete(vb)
      	delete(ushear)
      	delete(vshear)

 a = addfile(filename,"r")

print("loading data")
;Compute the equivalent temperature in the 1000-850 hPa layer.
           t850 := a->TMP_P0_L100_GLL0({85000},::-1,:)
           rh850 := a->RH_P0_L100_GLL0({85000},::-1,:)
           pres := a->lv_ISBL0({85000})
           pres = pres/100
           phpa := t850
           phpa(:,:) = pres
           q850 := t850
           
           q850 := mixhum_ptrh(phpa,t850,rh850,1)
           t_e := t850
           t_e=t850+(2.6e6/1004)*q850      

;Compute the max theta-e in the 1000-850 hPa layer.
           theta_e_max := t_e*(1000/phpa)^0.286

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

;******************************************************

    u1 = a->UGRD_P0_L100_GLL0({20000},::-1,:)
    v1 = a->VGRD_P0_L100_GLL0({20000},::-1,:)
    u2 = a->UGRD_P0_L100_GLL0({50000},::-1,:)
    v2 = a->VGRD_P0_L100_GLL0({50000},::-1,:)

    relvort200 = uv2vrG_Wrap(u1,v1) ; Calculate relative vorticity using spherical harmonics
    relvort500 = uv2vrG_Wrap(u2,v2)
    therm_vort = relvort200(:,:)-relvort500(:,:)
    therm_vort = therm_vort*(10^5)
    copy_VarCoords(u1,therm_vort)
    
do c=0,25
therm_vort=smth9(therm_vort,.5,.25,True)
end do

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

  print("Successfully got data from files!")

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

;res@gsnLeftString = "PV, pres., and wind (350 K isen. sfc.); 925~F15~-~F21~850-hPa rel. vort."
res@gsnLeftString = "CI, 500~F15~-~F21~200-hPa therm. vort., 850~F15~-~F21~200-hPa shear, sfc lows"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .0075
res@gsnRightStringOrthogonalPosF = .0080
res@gsnRightStringFontHeightF = .013

  curdate = tim + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

  if (fhr_cur .gt. 0) then
     res@gsnRightString = "("+fhr_cur+" h fcst) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "red"
     res@gsnRightStringFontColor = "red"
  else
     res@gsnRightString = "(Analysis) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  end if


; *********************************************

res@mpGeophysicalLineThicknessF = 2.0
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 10.
res@mpGridLonSpacingF = 10.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey29"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,10)
tmres@tmYRValues = ispan(-80,80,10)
tmres@tmXBValues = ispan(-180,179,10)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/5,10,15,17.5,22.5,25,27.5,32.5,35,37.5,42.5,45,50,55,65/)
tmres@tmYLMinorValues = (/5,10,15,17.5,22.5,25,27.5,32.5,35,37.5,42.5,45,50,55,65/)
tmres@tmXBMinorValues = (/-97.5,-95,-92.5,-87.2,-85,-82.5,-77.5,-75,-72.5,-67.5,-65,-62.5/)
; *************************************************************

if domain .eq. "southeast"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 10
res@mpLambertParallel1F = 5
res@mpLambertMeridianF = -80
res@mpLimitMode = "LatLon"
res@mpMinLatF = 16.5
res@mpMaxLatF = 40.5
res@mpMinLonF = -98
res@mpMaxLonF = -64
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
cnres@cnLineThicknessF = 3.0                    ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 1
cnres@cnMaxLevelValF = -1 
;cnres@cnLevels = (/-1.5,-3.0,-4.5,-6.0,-7.5,-9.0,-10.5,-12.0,-13.5,-15.0/)
cnres@cnLineColor = "grey20" ;grey20
cnres@cnLineLabelFontColor = cnres@cnLineColor 
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = .8
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008
cnres@gsnAddCyclic =  True
cnres@cnLineDashPattern = 5

; *************************************************************

cn2res = True

cn2res@gsnFrame = False                                        
cn2res@gsnDraw = False

cn2res@gsnLeftString = " "
cn2res@gsnRightString = " "

cn2res@cnFillMode = "AreaFill"
cn2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cn2res@cnFillOn = False
cn2res@cnLinesOn = True
cn2res@cnLabelMasking = True
cn2res@cnLineThicknessF = 4.0                   
cn2res@cnLineColor = "navyblue"
cn2res@cnLineLabelFontColor = cn2res@cnLineColor
cn2res@cnLevelSelectionMode = "ManualLevels"
cn2res@cnLevelSpacingF = 1
cn2res@cnMinLevelValF = 0.0
cn2res@cnLineLabelAngleF = 0.0
cn2res@cnLineLabelInterval = 2
cn2res@cnLineLabelDensityF = .8
cn2res@cnLineLabelBackgroundColor = -1
cn2res@cnLineLabelFontHeightF = 0.008
cn2res@gsnAddCyclic =  True

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
mres@cnLowLabelString = "L"
mres@cnLowLabelPerimOn = False
mres@cnLowLabelFontHeightF = 0.018
mres@cnHighLabelFontHeightF = 0.018
mres@cnLowLabelFontThicknessF = 8.0
mres@cnHighLabelFontThicknessF = 8.0
mres@cnLowLabelFontColor = "red2"
;mres@cnLowLabelFont = "complex_roman"
;mres@cnLowLabelFont = "times-bold"
mres@cnLowLabelFont = "courier-bold"

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
	bres@vcMinDistanceF = 0.032
    bres@vcWindBarbTickLengthF = 0.37
    bres@vcWindBarbTickSpacingF = 0.130
    bres@vcWindBarbTickAngleF = 55.0
    bres@gsnFrame = False
    bres@gsnAddCyclic =  True


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
contours = gsn_csm_contour(wks, therm_vort(:,:), cnres)
contours2 = gsn_csm_contour(wks, therm_vort(:,:), cn2res)
lows = gsn_csm_contour(wks, mslp, mres)
barbs = gsn_csm_vector(wks, ushear, vshear, bres)
plot = add_map_tickmarks(wks,plot,tmres)


;==============================================
; Set Marker and Text Resources
;==============================================

tres = True
tres@txFontHeightF = 0.018
tres@txJust = "CenterLeft"
tres@gsLineDashPattern = 5
tres@gsLineThicknessF = 3
tres@gsLineColor = "grey29"

if domain .eq. "southeast" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-97.9,17.1,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-97.85,16.5,tres)
end if 

;********************************************

overlay(plot,lows)
overlay(plot,contours)
overlay(plot,contours2)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' "+dir_plot+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

                 imgcount = imgcount + 1
             end do

          else
             if(tim .eq. sdate) then
                 print("Plotting from archived grib files")
             end if

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************
   if delall .eq. 1 then
      	delete(a)
      	delete(nht_pv)
      	delete(nhpres_pv)
      	delete(sht_pv)
      	delete(shpres_pv)
      	delete(pres_pv)
      	delete(t_pv)
      	delete(theta_trop)
;      	delete(h)
;      	delete(uvgeo)
      	delete(u1)
      	delete(v1)
      	delete(u2)
      	delete(v2)
      	delete(relvort200)
      	delete(relvort500)
      	delete(therm_vort)
      	delete(ut)
      	delete(ub)
      	delete(vt)
      	delete(vb)
      	delete(ushear)
      	delete(vshear)
  end if
 
 delall = 1
 a = addfile(filename,"r")
  
print("loading data")
;Compute the equivalent temperature in the 1000-850 hPa layer.
           t850 := a->TMP_P0_L100_GLL0({85000},::-1,:)
           rh850 := a->RH_P0_L100_GLL0({85000},::-1,:)
           pres := a->lv_ISBL0({85000})
           pres = pres/100
           phpa := t850
           phpa(:,:) = pres
           q850 := t850
           
           q850 := mixhum_ptrh(phpa,t850,rh850,1)
           t_e := t850
           t_e=t850+(2.6e6/1004)*q850      

;Compute the max theta-e in the 1000-850 hPa layer.
           theta_e_max := t_e*(1000/phpa)^0.286

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

;******************************************************

    u1 = a->UGRD_P0_L100_GLL0({20000},::-1,:)
    v1 = a->VGRD_P0_L100_GLL0({20000},::-1,:)
    u2 = a->UGRD_P0_L100_GLL0({50000},::-1,:)
    v2 = a->VGRD_P0_L100_GLL0({50000},::-1,:)

    relvort200 = uv2vrG_Wrap(u1,v1) ; Calculate relative vorticity using spherical harmonics
    relvort500 = uv2vrG_Wrap(u2,v2)
    therm_vort = relvort200(:,:)-relvort500(:,:)
    therm_vort = therm_vort*(10^5)
    copy_VarCoords(u1,therm_vort)
    
do c=0,25
therm_vort=smth9(therm_vort,.5,.25,True)
end do

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

  print("Successfully got data from files!")

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

;res@gsnLeftString = "PV, pres., and wind (350 K isen. sfc.); 925~F15~-~F21~850-hPa rel. vort."
res@gsnLeftString = "CI, 500~F15~-~F21~200-hPa therm. vort., 850~F15~-~F21~200-hPa shear, sfc lows"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .0075
res@gsnRightStringOrthogonalPosF = .0080
res@gsnRightStringFontHeightF = .013

res@gsnRightString = "(Analysis) "+ut_string(tim,"")
res@gsnLeftStringFontColor = "black"
res@gsnRightStringFontColor = "black"


; *********************************************

res@mpGeophysicalLineThicknessF = 2.0
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 10.
res@mpGridLonSpacingF = 10.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey29"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,10)
tmres@tmYRValues = ispan(-80,80,10)
tmres@tmXBValues = ispan(-180,179,10)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/5,10,15,17.5,22.5,25,27.5,32.5,35,37.5,42.5,45,50,55,65/)
tmres@tmYLMinorValues = (/5,10,15,17.5,22.5,25,27.5,32.5,35,37.5,42.5,45,50,55,65/)
tmres@tmXBMinorValues = (/-97.5,-95,-92.5,-87.2,-85,-82.5,-77.5,-75,-72.5,-67.5,-65,-62.5/)
; *************************************************************

if domain .eq. "southeast"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 10
res@mpLambertParallel1F = 5
res@mpLambertMeridianF = -80
res@mpLimitMode = "LatLon"
res@mpMinLatF = 16.5
res@mpMaxLatF = 40.5
res@mpMinLonF = -98
res@mpMaxLonF = -64
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
cnres@cnLineThicknessF = 3.0                    ; Changes thickness of contours
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 1
cnres@cnMaxLevelValF = -1 
;cnres@cnLevels = (/-1.5,-3.0,-4.5,-6.0,-7.5,-9.0,-10.5,-12.0,-13.5,-15.0/)
cnres@cnLineColor = "grey20" ;grey20
cnres@cnLineLabelFontColor = cnres@cnLineColor 
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 2
cnres@cnLineLabelDensityF = .8
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.008
cnres@gsnAddCyclic =  True
cnres@cnLineDashPattern = 5

; *************************************************************

cn2res = True

cn2res@gsnFrame = False                                        
cn2res@gsnDraw = False

cn2res@gsnLeftString = " "
cn2res@gsnRightString = " "

cn2res@cnFillMode = "AreaFill"
cn2res@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cn2res@cnFillOn = False
cn2res@cnLinesOn = True
cn2res@cnLabelMasking = True
cn2res@cnLineThicknessF = 4.0                   
cn2res@cnLineColor = "navyblue"
cn2res@cnLineLabelFontColor = cn2res@cnLineColor
cn2res@cnLevelSelectionMode = "ManualLevels"
cn2res@cnLevelSpacingF = 1
cn2res@cnMinLevelValF = 0.0
cn2res@cnLineLabelAngleF = 0.0
cn2res@cnLineLabelInterval = 2
cn2res@cnLineLabelDensityF = .8
cn2res@cnLineLabelBackgroundColor = -1
cn2res@cnLineLabelFontHeightF = 0.008
cn2res@gsnAddCyclic =  True

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
mres@cnLowLabelString = "L"
mres@cnLowLabelPerimOn = False
mres@cnLowLabelFontHeightF = 0.018
mres@cnHighLabelFontHeightF = 0.018
mres@cnLowLabelFontThicknessF = 8.0
mres@cnHighLabelFontThicknessF = 8.0
mres@cnLowLabelFontColor = "red2"
;mres@cnLowLabelFont = "complex_roman"
;mres@cnLowLabelFont = "times-bold"
mres@cnLowLabelFont = "courier-bold"

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
	bres@vcMinDistanceF = 0.032
    bres@vcWindBarbTickLengthF = 0.37
    bres@vcWindBarbTickSpacingF = 0.130
    bres@vcWindBarbTickAngleF = 55.0
    bres@gsnFrame = False
    bres@gsnAddCyclic =  True


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
contours = gsn_csm_contour(wks, therm_vort(:,:), cnres)
contours2 = gsn_csm_contour(wks, therm_vort(:,:), cn2res)
lows = gsn_csm_contour(wks, mslp, mres)
barbs = gsn_csm_vector(wks, ushear, vshear, bres)
plot = add_map_tickmarks(wks,plot,tmres)


;==============================================
; Set Marker and Text Resources
;==============================================

tres = True
tres@txFontHeightF = 0.018
tres@txJust = "CenterLeft"
tres@gsLineDashPattern = 5
tres@gsLineThicknessF = 3
tres@gsLineColor = "grey29"

if domain .eq. "southeast" then
    tres@txJust = "CenterLeft"
    tres@txFontHeightF = 0.01
    mytext = gsn_add_text(wks,contours,"@AliciaMBentley",-97.9,17.1,tres)
    mytext2 = gsn_add_text(wks,contours,"www.AliciaMBentley.com",-97.85,16.5,tres)
end if 

;********************************************

overlay(plot,lows)
overlay(plot,contours)
overlay(plot,contours2)
overlay(plot,barbs)

;********************************************

draw(plot)
frame(wks)

system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' "+dir_plot+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************

             imgcount = imgcount + 1
          end if

          ; remove the grb2 file to save space
          if(tim .le. edate) then
             system("rm -f "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar") ; now remove the tar file (only have to do this once)
          end if
    end do

else
    print("Just the analysis")
    print("But I'll handle that later!")   ;maybe can always do the forecast and then just make it plot one time and quit
end if

;system("rm -f "+dir_grib+"GFS_*_000")
system("rm -f "+dir_grib+"*.grb2.tar")

end do ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end