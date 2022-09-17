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
else if shh .ge. 15 .and. shh .lt. 19 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 12
else if shh .ge. 19 then
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

folder = (/"northamer","pacific","atlantic","europe","southamer"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)

fcast = "yes" 		        ;;; do you want to plot the 192 hour GFS forecast at the next synoptic time?	         	
  
fdate = edate + hr + 6
    
imgcount = 1			;;; this starts the image count at 1 (you can change this to any number you want
  				        ;;; but note it counts up by 1 at a time as you move 6h forward in time

name = "irro_temp"
dir_grib = "/free2/abentley/realtime/"+name+"/grib/"		        
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
  	        system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
  	        system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if
  
             ;;; new... to read in files that don't start at 00 UTC
             if( (tim.eq.sdate) .and. (str_hr.ne."00")) then
                system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
  	        system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
             end if  
          end if
      
          ;now that the filename should be in the proper directory, go ahead and add it
          ;check to make sure it exists too!
  
          if(tim .le. edate) then
                filename = dir_grib+"GFS_"+str_time+"_"+str_hr+"_000.grb2"
				if (isfilepresent(filename)) then
				    if (imgcount .gt. 3) then
				        system("rm -f "+dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000")			
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
      	delete(mslp)      	
      	delete(w_all)
      	delete(w)
      	delete(u_irro)
      	delete(v_irro)
      	delete(ui)
      	delete(vi)
      	delete(div)
      	delete(irro)
      	delete(t)
      	delete(theta)

  a = addfile(filename,"r")

;  lev_wind  = (/85000/)
;  u_all = a->UGRD_P0_L100_GLL0({lev_wind},::-1,:)
;  v_all = a->VGRD_P0_L100_GLL0({lev_wind},::-1,:)
;  if(dimsizes(lev_wind).eq.1) then
;    u = u_all
;    v = v_all
;  else
;    u = dim_avg_n_Wrap(u_all,0)
;    v = dim_avg_n_Wrap(v_all,0)
;  end if
;  wind = u
;  wind = ((u^2)+(v^2))^0.5
;  print(u_all&lv_ISBL0)


  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01


  lev_omega  = (/70000,60000,50000/)
  w_all = a->VVEL_P0_L100_GLL0({lev_omega},::-1,:)
  w = dim_avg_n_Wrap(w_all,0)
  w = w*(.01)


  lev_irro  = (/90000,85000,80000/)
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


  lev_temp = (/85000/) ; Needs to be in Pa
  t = a->TMP_P0_L100_GLL0({lev_temp},::-1,:)
  theta = t*((100000/85000)^(0.286))
  copy_VarMeta(t,theta) 
  theta = theta - 273.15
  copy_VarMeta(t,theta) 
;  printMinMax(theta,True)

;  do d=0,3
;    pv=smth9(pv,.5,.25,True)
;  end do

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,"/free2/abentley/realtime/"+name+"/"+name+"_"+imgcount)
gsn_define_colormap(wks,"MPL_RdYlBu")
gsn_reverse_colormap(wks)
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
res@cnLevelSelectionMode = "ManualLevels"
res@cnLevelSpacingF = 4
res@cnMinLevelValF = -36
res@cnMaxLevelValF = 36  
;res@cnFillColors = (/9,11,14,19,24,29,33,38,45,53,70,80,86,92,97,102,107,111,114,117/)
;res@cnFillColors = (/"slateblue4","slateblue","slateblue3","slateblue2","slateblue1","steelblue2","skyblue2","skyblue","lightskyblue2","lightskyblue1","palegoldenrod","peachpuff1","peachpuff2","lightgoldenrod1","lightgoldenrod2","lightpink","lightpink2","palevioletred1","palevioletred2","palevioletred3"/)
;res@cnFillColors = (/14,11,7,5,2,46,56,75,81,92,255,253,251,250,249,178,184,189,193,197/)
res@cnFillColors = (/4,9,12,16,21,29,32,37,44,51,65,75,81,87,93,103,107,112,121,129/)

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

res@gsnLeftString = "MSLP; 850-hPa theta; 900~F15~-~F21~800-hPa irr. wind; 700~F15~-~F21~500-hPa w"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightStringOrthogonalPosF = .0075
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

res@mpGeophysicalLineThicknessF = 5.5
res@mpNationalLineThicknessF = 5.5
res@mpUSStateLineThicknessF = 5.5
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@pmTickMarkDisplayMode = "Always"

res@mpGeophysicalLineColor = "green4"
res@mpNationalLineColor = "green4"
res@mpUSStateLineColor = "green4"
;green4"

res@mpDefaultFillColor = "green2"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey12"
;res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
tmres@tmXBValues = ispan(-180,179,40)
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


; *************************************************************

tres = True

tres@gsnFrame = False                                        
tres@gsnDraw = False

tres@gsnLeftString = " "
tres@gsnRightString = " "

tres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
tres@cnFillOn = False
tres@cnLineLabelsOn = True
tres@cnLinesOn = True
tres@cnLabelMasking = True
tres@cnLineThicknessF = 4                    ; Changes thickness of contours
tres@cnLevelSelectionMode = "ManualLevels"
tres@cnLevelSpacingF = 2
tres@cnMinLevelValF = 200
tres@cnMaxLevelValF = 300  
tres@cnLineLabelAngleF = 0.0
tres@cnLineLabelInterval = 2
tres@cnLineLabelDensityF = 1.4
tres@cnSmoothingOn = True
tres@cnSmoothingDistanceF = 0.0001
tres@cnLineLabelBackgroundColor = -1
tres@cnLineLabelFontHeightF = 0.008
tres@cnLineLabelFontColor = "grey25"
tres@cnLineColor = "grey25"
tres@gsnAddCyclic =  True


; *************************************************************

cnres = True

cnres@gsnFrame = False                                        
cnres@gsnDraw = False

cnres@gsnLeftString = " "
cnres@gsnRightString = " "
cnres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cnres@cnFillOn = False
cnres@cnLinesOn = True
cnres@cnLabelMasking = True
cnres@cnLineLabelsOn = False
cnres@cnLineThicknessF = 2
cnres@cnLineColor = "white"
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 20
cnres@cnMinLevelValF = -40 
cnres@cnMaxLevelValF = 40 
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 1
cnres@cnLineLabelDensityF = .77
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.018
cnres@cnSmoothingOn = True
cnres@cnSmoothingDistanceF = 0.00001


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
mres@cnLineLabelInterval = 2
mres@cnLineLabelDensityF = 1.4
;mres@cnSmoothingOn = True
;mres@cnSmoothingDistanceF = 0.009
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

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
omres@cnLineColor = "red"
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

omres2 = True

omres2@gsnFrame = False                                        
omres2@gsnDraw = False

omres2@gsnLeftString = " "
omres2@gsnRightString = " "
omres2@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
omres2@cnFillOn = False
omres2@cnLinesOn = True
omres2@cnLabelMasking = True
omres2@cnLineLabelsOn = False
omres2@cnLineThicknessF = 4
omres2@cnLineColor = "blue"
omres2@cnLevelSelectionMode = "ManualLevels"
omres2@cnLevelSpacingF = 0.005
omres2@cnMinLevelValF = 0.005 
omres2@cnLineLabelAngleF = 0.0
omres2@cnLineLabelInterval = 1
omres2@cnLineLabelDensityF = .77
omres2@cnLineLabelBackgroundColor = -1
omres2@cnLineLabelFontHeightF = 0.018
omres2@gsnAddCyclic =  True

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
    vres@vcMinMagnitudeF = 2.0
    
    if domain .eq. "northamer" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.046
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
    vres@vcRefAnnoOrthogonalPosF = -1.049
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
    vres@vcRefAnnoOrthogonalPosF = -1.047
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
    vres@vcRefAnnoOrthogonalPosF = -1.044
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
    vres@vcRefAnnoOrthogonalPosF = -1.042
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if

    
; *************************************************************
res@mpFillOn = False
res@mpOutlineOn = True
;res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
cnres@cnLineDrawOrder ="Draw" 
mres@cnLineDrawOrder ="Draw"
omres@cnLineDrawOrder ="Draw" 
omres2@cnLineDrawOrder ="Draw" 
vres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, theta, res)          ; Plot filled contour map
lines = gsn_csm_contour(wks, theta, cnres)
contours = gsn_csm_contour(wks, mslp, mres)
other = gsn_csm_contour(wks, w, omres)
other2 = gsn_csm_contour(wks, w, omres2)
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
end if 
end if
end if
end if
end if 

;********************************************

overlay(plot,lines)
overlay(plot,contours)
overlay(plot,other)
overlay(plot,other2)
overlay(plot,vect)

;********************************************

draw(plot)
frame(wks)

system("convert /free2/abentley/realtime/"+name+"/"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' /free2/abentley/realtime/"+name+"/"+name+"_*.png") 

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
      	delete(mslp)      	
      	delete(w_all)
      	delete(w)
      	delete(u_irro)
      	delete(v_irro)
      	delete(ui)
      	delete(vi)
      	delete(div)
      	delete(irro)
      	delete(t)
      	delete(theta)
  end if

  delall = 1
  a = addfile(filename,"r")

;  lev_wind  = (/85000/)
;  u_all = a->UGRD_P0_L100_GLL0({lev_wind},::-1,:)
;  v_all = a->VGRD_P0_L100_GLL0({lev_wind},::-1,:)
;  if(dimsizes(lev_wind).eq.1) then
;    u = u_all
;    v = v_all
;  else
;    u = dim_avg_n_Wrap(u_all,0)
;    v = dim_avg_n_Wrap(v_all,0)
;  end if
;  wind = u
;  wind = ((u^2)+(v^2))^0.5
;  print(u_all&lv_ISBL0)


  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01


  lev_omega  = (/70000,60000,50000/)
  w_all = a->VVEL_P0_L100_GLL0({lev_omega},::-1,:)
  w = dim_avg_n_Wrap(w_all,0)
  w = w*(.01)


  lev_irro  = (/90000,85000,80000/)
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


  lev_temp = (/85000/) ; Needs to be in Pa
  t = a->TMP_P0_L100_GLL0({lev_temp},::-1,:)
  theta = t*((100000/85000)^(0.286))
  copy_VarMeta(t,theta) 
  theta = theta - 273.15
  copy_VarMeta(t,theta) 
;  printMinMax(theta,True)

;  do d=0,3
;    pv=smth9(pv,.5,.25,True)
;  end do

  print("Successfully got data from files!")

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,"/free2/abentley/realtime/"+name+"/"+name+"_"+imgcount)
gsn_define_colormap(wks,"MPL_RdYlBu")
gsn_reverse_colormap(wks)
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
res@cnLevelSelectionMode = "ManualLevels"
res@cnLevelSpacingF = 4
res@cnMinLevelValF = -36
res@cnMaxLevelValF = 36  
;res@cnFillColors = (/9,11,14,19,24,29,33,38,45,53,70,80,86,92,97,102,107,111,114,117/)
;res@cnFillColors = (/"slateblue4","slateblue","slateblue3","slateblue2","slateblue1","steelblue2","skyblue2","skyblue","lightskyblue2","lightskyblue1","palegoldenrod","peachpuff1","peachpuff2","lightgoldenrod1","lightgoldenrod2","lightpink","lightpink2","palevioletred1","palevioletred2","palevioletred3"/)
;res@cnFillColors = (/14,11,7,5,2,46,56,75,81,92,255,253,251,250,249,178,184,189,193,197/)
res@cnFillColors = (/4,9,12,16,21,29,32,37,44,51,65,75,81,87,93,103,107,112,121,129/)

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

res@gsnLeftString = "MSLP; 850-hPa theta; 900~F15~-~F21~800-hPa irr. wind; 700~F15~-~F21~500-hPa w"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013

res@gsnRightString = "(Analysis) "+ut_string(tim,"")
res@gsnLeftStringFontColor = "black"
res@gsnRightStringFontColor = "black"


; *********************************************

res@mpGeophysicalLineThicknessF = 5.5
res@mpNationalLineThicknessF = 5.5
res@mpUSStateLineThicknessF = 5.5
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@pmTickMarkDisplayMode = "Always"

res@mpGeophysicalLineColor = "green4"
res@mpNationalLineColor = "green4"
res@mpUSStateLineColor = "green4"
;green4"

res@mpDefaultFillColor = "green2"

; *********************************************

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey12"
;res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
tmres@tmXBValues = ispan(-180,179,40)
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

; *************************************************************

tres = True

tres@gsnFrame = False                                        
tres@gsnDraw = False

tres@gsnLeftString = " "
tres@gsnRightString = " "

tres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
tres@cnFillOn = False
tres@cnLineLabelsOn = True
tres@cnLinesOn = True
tres@cnLabelMasking = True
tres@cnLineThicknessF = 4                    ; Changes thickness of contours
tres@cnLevelSelectionMode = "ManualLevels"
tres@cnLevelSpacingF = 2
tres@cnMinLevelValF = 200
tres@cnMaxLevelValF = 300  
tres@cnLineLabelAngleF = 0.0
tres@cnLineLabelInterval = 2
tres@cnLineLabelDensityF = 1.4
tres@cnSmoothingOn = True
tres@cnSmoothingDistanceF = 0.0001
tres@cnLineLabelBackgroundColor = -1
tres@cnLineLabelFontHeightF = 0.008
tres@cnLineLabelFontColor = "grey25"
tres@cnLineColor = "grey25"
tres@gsnAddCyclic =  True


; *************************************************************

cnres = True

cnres@gsnFrame = False                                        
cnres@gsnDraw = False

cnres@gsnLeftString = " "
cnres@gsnRightString = " "
cnres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
cnres@cnFillOn = False
cnres@cnLinesOn = True
cnres@cnLabelMasking = True
cnres@cnLineLabelsOn = False
cnres@cnLineThicknessF = 2
cnres@cnLineColor = "white"
cnres@cnLevelSelectionMode = "ManualLevels"
cnres@cnLevelSpacingF = 20
cnres@cnMinLevelValF = -40 
cnres@cnMaxLevelValF = 40 
cnres@cnLineLabelAngleF = 0.0
cnres@cnLineLabelInterval = 1
cnres@cnLineLabelDensityF = .77
cnres@cnLineLabelBackgroundColor = -1
cnres@cnLineLabelFontHeightF = 0.018
cnres@cnSmoothingOn = True
cnres@cnSmoothingDistanceF = 0.00001


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
mres@cnLineLabelInterval = 2
mres@cnLineLabelDensityF = 1.4
;mres@cnSmoothingOn = True
;mres@cnSmoothingDistanceF = 0.009
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

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
omres@cnLineColor = "red"
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

omres2 = True

omres2@gsnFrame = False                                        
omres2@gsnDraw = False

omres2@gsnLeftString = " "
omres2@gsnRightString = " "
omres2@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner
omres2@cnFillOn = False
omres2@cnLinesOn = True
omres2@cnLabelMasking = True
omres2@cnLineLabelsOn = False
omres2@cnLineThicknessF = 4
omres2@cnLineColor = "blue"
omres2@cnLevelSelectionMode = "ManualLevels"
omres2@cnLevelSpacingF = 0.005
omres2@cnMinLevelValF = 0.005 
omres2@cnLineLabelAngleF = 0.0
omres2@cnLineLabelInterval = 1
omres2@cnLineLabelDensityF = .77
omres2@cnLineLabelBackgroundColor = -1
omres2@cnLineLabelFontHeightF = 0.018
omres2@gsnAddCyclic =  True

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
    vres@vcMinMagnitudeF = 2.0
    
    if domain .eq. "northamer" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
;    vres@vcRefLengthF = 0.028
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.046
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
    vres@vcRefAnnoOrthogonalPosF = -1.049
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
    vres@vcRefAnnoOrthogonalPosF = -1.047
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
    vres@vcRefAnnoOrthogonalPosF = -1.044
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
    vres@vcRefAnnoOrthogonalPosF = -1.042
    vres@vcRefAnnoParallelPosF = .999
    vres@vcRefAnnoString2On = False
    end if

; *************************************************************
res@mpFillOn = False
res@mpOutlineOn = True
;res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
cnres@cnLineDrawOrder ="Draw" 
mres@cnLineDrawOrder ="Draw"
omres@cnLineDrawOrder ="Draw" 
omres2@cnLineDrawOrder ="Draw" 
vres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, theta, res)          ; Plot filled contour map
lines = gsn_csm_contour(wks, theta, cnres)
contours = gsn_csm_contour(wks, mslp, mres)
other = gsn_csm_contour(wks, w, omres)
other2 = gsn_csm_contour(wks, w, omres2)
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
end if       
end if
end if
end if
end if 

;********************************************

overlay(plot,lines)
overlay(plot,contours)
overlay(plot,other)
overlay(plot,other2)
overlay(plot,vect)

;********************************************

draw(plot)
frame(wks)

system("convert /free2/abentley/realtime/"+name+"/"+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' /free2/abentley/realtime/"+name+"/"+name+"_*.png") 

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

system("rm -f "+dir_grib+"GFS_*_000")
system("rm -f "+dir_grib+"*.grb2.tar")

end do ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end