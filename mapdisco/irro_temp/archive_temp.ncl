; ===========================================
; Plot composited PV on isentropic surfaces
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "/home/carl/nclscripts/lib/tTick.ncl"
load "/home/carl/nclscripts/lib/ut_string.ncl"
load "/home/abentley/ncl/lib/latlon.ncl"
load "/home/kgriffin/ncl_lib/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
; ===========================================

; source ~macritch/.cshrc
; ncl -V = 6.1.2

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

timeUnits = "hours since 1800-01-01 00:00:00"

syyyy = 2015			;;; start date in yyyy mm dd hh
smm = 1
sdd = 15
shh = 0

eyyyy = 2015			;;; start date in yyyy mm dd hh
emm = 1
edd = 20
ehh = 18

sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,timeUnits,0)
edate = cd_inv_calendar(eyyyy,emm,edd,ehh,00,00,timeUnits,0)

print("sdate: "+ut_string(sdate,""))
print("edate: "+ut_string(edate,""))

; **************DOMAIN*************************

folder = (/"midatlantic","northamer"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

domain = folder(x)

print(" ")
print("Plotting maps for: "+domain)
    
imgcount = 1			;;; this starts the image count at 1 

name = "irro_temp"
dir_grib = "/free2/abentley/realtime/"+name+"/grib/"		        
dir_out = "/lb11/abentley/www/research_images/fzra_alb2015/images/"+domain+"/"+name+"/"

;*****************************************************

  do tim = sdate,edate,6
         tim@units = "hours since 1800-01-01 00:00:00"   ;define units for t (which is the time in 6 hour intervals)
    
         if(tim.eq.sdate) then
             print("Time = Start Date")
         end if
  
         ; Let's make a few date strings
         str_time = ut_string(tim,"%y%N%D")
         str_hr = ut_string(tim,"%H")
         
  
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
				    if (imgcount .gt. 1) then
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

;**********************************************************************************************************
;**********************************************************************************************************
;**********************************************************************************************************
   if imgcount .gt. 1 then
      	delete(a)
      	delete(u_all)
      	delete(v_all)
      	delete(u)
      	delete(v)
      	delete(wind)
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

  a = addfile(filename,"r")

  lev_wind  = (/85000/)
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
res@cnMinLevelValF = 237
res@cnMaxLevelValF = 309  
;res@cnFillColors = (/16,18,21,24,26,28,30,32,34,36,42,48,54,78,83,88,90,92,94,96,98,101,105,108,110,113/)
res@cnFillColors = (/9,11,14,19,24,29,33,38,45,53,70,80,86,92,97,102,107,111,114,117/)

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

res@mpGeophysicalLineThicknessF = 4.0
res@mpNationalLineThicknessF = 4.0
res@mpUSStateLineThicknessF = 4.0
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
res@mpGridLonSpacingF = 200.
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

tmres@tmYRMinorValues = (/5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = (/-175,-170,-165,-160,-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,145,150,155,160,165,170,175/)

; *************************************************************

if domain .eq. "northamer"
delete(res@mpLambertMeridianF)
delete(res@mpMinLonF)
delete(res@mpMaxLonF)
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


if domain .eq. "midatlantic"
res@mpProjection = "LambertConformal"
res@mpLambertParallel2F = 31
res@mpLambertParallel1F = 11
res@mpLambertMeridianF = -77
res@mpLimitMode = "LatLon"
res@mpMinLatF = 30
res@mpMaxLatF = 50
res@mpMinLonF = -92
res@mpMaxLonF = -62
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

; *************************************************************

    vres = True

    vres@gsnFrame = False                                        
    vres@gsnDraw = False

    vres@gsnLeftString = " "
    vres@gsnRightString = " "

    vres@vcGlyphStyle = "FillArrow"
    vres@vcWindBarbColor = "black"
    vres@vcWindBarbCalmCircleSizeF = 0
    vres@vcWindBarbLineThicknessF = 7.5
    vres@vcMinDistanceF = 0.019
    vres@vcMinMagnitudeF = 2.0
    
    if domain .eq. "midatlantic" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.0415
    vres@vcRefAnnoParallelPosF = .095
    vres@vcRefAnnoString2On = False
    end if
    
    if domain .eq. "northamer" then
    vres@vcRefAnnoOn = True 
    vres@vcRefAnnoString1 = "$VMG$ m s~S~~F15~-~F21~1"
    vres@vcRefLengthF = 0.035
    vres@vcRefMagnitudeF = 10.0
    vres@vcRefAnnoSide = "Top"
    vres@vcRefAnnoOrthogonalPosF = -1.046
    vres@vcRefAnnoParallelPosF = .095
    vres@vcRefAnnoString2On = False
    end if

; *************************************************************
res@mpFillOn = False
res@mpOutlineOn = True
;res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
mres@cnLineDrawOrder ="Draw"
omres@cnLineDrawOrder ="Draw" 
omres2@cnLineDrawOrder ="Draw" 
vres@vcVectorDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, theta, res)          ; Plot filled contour map
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

dum31 = gsn_add_polyline(wks,plot,(/180,180/),(/-90,90/),tres)
dum32 = gsn_add_polyline(wks,plot,(/160,160/),(/-90,90/),tres)
dum33 = gsn_add_polyline(wks,plot,(/140,140/),(/-90,90/),tres)
dum34 = gsn_add_polyline(wks,plot,(/120,120/),(/-90,90/),tres)
dum35 = gsn_add_polyline(wks,plot,(/100,100/),(/-90,90/),tres)
dum36 = gsn_add_polyline(wks,plot,(/80,80/),(/-90,90/),tres)
dum37 = gsn_add_polyline(wks,plot,(/60,60/),(/-90,90/),tres)
dum38 = gsn_add_polyline(wks,plot,(/40,40/),(/-90,90/),tres)
dum39 = gsn_add_polyline(wks,plot,(/20,20/),(/-90,90/),tres)
dum40 = gsn_add_polyline(wks,plot,(/0,0/),(/-90,90/),tres)
dum41 = gsn_add_polyline(wks,plot,(/-20,-20/),(/-90,90/),tres)
dum4 = gsn_add_polyline(wks,plot,(/-40,-40/),(/-90,90/),tres)
dum5 = gsn_add_polyline(wks,plot,(/-60,-60/),(/-90,90/),tres)
dum6 = gsn_add_polyline(wks,plot,(/-80,-80/),(/-90,90/),tres)
dum7 = gsn_add_polyline(wks,plot,(/-100,-100/),(/-90,90/),tres)
dum8 = gsn_add_polyline(wks,plot,(/-120,-120/),(/-90,90/),tres)
dum9 = gsn_add_polyline(wks,plot,(/-140,-140/),(/-90,90/),tres)
dum10 = gsn_add_polyline(wks,plot,(/-160,-160/),(/-90,90/),tres)

;********************************************

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

          ; remove the grb2 file to save space
          if(tim .le. edate) then
             system("rm -f "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar") ; now remove the tar file (only have to do this once)
          end if
    end do

system("rm -f "+dir_grib+"GFS_*_000")
system("rm -f "+dir_grib+"*.grb2.tar")

end do ; end domain

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end