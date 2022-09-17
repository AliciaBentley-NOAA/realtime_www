; ===========================================
; Plot composited PV on isentropic surfaces
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "~/ncl/lib/tTick.ncl"
load "~/ncl/lib/ut_string.ncl"

; ===========================================
begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")
print(" ")

zulu = "00Z"
day = "5"

name = "hermine_"+zulu+"_"+day+"SEP2016"
;name = "bloop"
tots = 30

dir_out = "/lb11/abentley/www/test/"
fileout = "/lb13/abentley/scripts/mapdisco/pvmetrics/output.txt"
print("fileout: "+fileout)

; ************************************************
;  Load in input files
; ************************************************
; Added an extra two lines so that code will do the final timestep (changing casename so it will trip "if" statement)
fileread = asciiread("/lb13/abentley/scripts/mapdisco/pvmetrics/pvmetrics_"+zulu+"_"+day+"SEP2016.csv",(/tots,10/),"float")

fileread_casename = asciiread("/lb13/abentley/scripts/mapdisco/pvmetrics/input_hermine_casename.txt",-1,"string")

;Create output file for STC identification dates
stcs = new((/2/),"string")    ; make lines for final output
casename_plot = new((/tots/),"string")
lat_plot = new((/tots/),"float")
lon_plot = new((/tots/),"float")
yyyy_plot = new((/tots/),"float")
mm_plot = new((/tots/),"float")
dd_plot = new((/tots/),"float")
hh_plot = new((/tots/),"float") 
pv1_plot = new((/tots/),"float")
pv2_plot = new((/tots/),"float")
pv3_plot = new((/tots/),"float")
therm_plot = new((/tots/),"float")
xaxis_plot = new((/tots/),"double")      

out = 0
cand = 0

do timestep = 0,tots-1 ; Begin looping through each storm.

done = tots - 1

    print("Starting line "+timestep+" of "+done)
    casename = fileread_casename(timestep)

    lat = fileread(timestep,0)
    lon = fileread(timestep,1)

    yyyy = floattoint(fileread(timestep,2))
    mm = floattoint(fileread(timestep,3))
    dd = floattoint(fileread(timestep,4))
    hh = floattoint(fileread(timestep,5))

    pv1 = fileread(timestep,6)
    pv2 = fileread(timestep,7)
    pv3 = fileread(timestep,8)
    therm = fileread(timestep,9)
    
    print("dd: "+dd+" hh:"+hh)

    u_file = addfile("/cfsr/data/"+yyyy+"/u."+yyyy+".0p5.anl.nc","r")
    time = u_file->time
    timeUnits = "hours since 1800-01-01 00:00:00"     
    date = cd_inv_calendar(yyyy,mm,dd,hh,00,00,time@units,0)

    if (timestep .gt. 0) then
        previous_casename = fileread_casename(timestep-1)

        if (casename .eq. previous_casename) then
             casename_plot(timestep) = casename
             lat_plot(timestep) = lat
             lon_plot(timestep) = lon
             yyyy_plot(timestep) = yyyy
             mm_plot(timestep) = mm
             dd_plot(timestep) = dd
             hh_plot(timestep) = hh
             pv1_plot(timestep) = pv1
             pv2_plot(timestep) = pv2
             pv3_plot(timestep) = pv3
             therm_plot(timestep) = therm
             xaxis_plot(timestep) = date
             delete(time)
        else
             print(">"+previous_casename+" vs. "+casename+"<")
             print("Make a graph!")
             print(" ")

             if (counter_filename .eq. 1) then
                 startarray = 0
                 pv1_plot_fin = pv1_plot(0:timestep-1)
                 pv2_plot_fin = pv2_plot(0:timestep-1)
                 pv3_plot_fin = pv3_plot(0:timestep-1)
                 pv3pv2ratio_plot_fin = pv3_plot_fin/pv2_plot_fin
                 therm_plot_fin = therm_plot(0:timestep-1)

                 ; Smooth the plots with a 1-2-1 smoother
                 pv1_plot_smooth = (2*pv1_plot_fin(1:timestep-2) + pv1_plot_fin(0:timestep-3) + pv1_plot_fin(2:timestep-1))/4
                 pv2_plot_smooth = (2*pv2_plot_fin(1:timestep-2) + pv2_plot_fin(0:timestep-3) + pv2_plot_fin(2:timestep-1))/4
                 pv3_plot_smooth = (2*pv3_plot_fin(1:timestep-2) + pv3_plot_fin(0:timestep-3) + pv3_plot_fin(2:timestep-1))/4                
                 pv3pv2ratio_plot_smooth = (pv3_plot_smooth/pv2_plot_smooth)
                 therm_plot_smooth = (2*therm_plot_fin(1:timestep-2) + therm_plot_fin(0:timestep-3) + therm_plot_fin(2:timestep-1))/4
                 xaxis_plot_fin = xaxis_plot(1:timestep-2)

                 data_fin = new((/3,dimsizes(pv2_plot_smooth)/),float)
                 data_fin(1,:) = pv2_plot_smooth
                 data_fin(2,:) = pv3_plot_smooth
                 data_fin(0,:) = pv1_plot_smooth
                 

             else
                 delete(pv1_plot_fin)
                 delete(pv2_plot_fin)
                 delete(pv3_plot_fin)
;                 delete(pv3pv2ratio_plot_fin)
                 delete(therm_plot_fin)
                 pv1_plot_fin = pv1_plot(startarray:timestep-1)
                 pv2_plot_fin = pv2_plot(startarray:timestep-1)
                 pv3_plot_fin = pv3_plot(startarray:timestep-1)
                 therm_plot_fin = therm_plot(startarray:timestep-1)

                 delete(pv1_plot_smooth)
                 delete(pv2_plot_smooth)
                 delete(pv3_plot_smooth)
                 delete(pv3pv2ratio_plot_smooth)
                 delete(therm_plot_smooth)
                 delete(xaxis_plot_fin)
                 delete(data_fin)
                 ; Smooth the plots with a 1-2-1 smoother
                 pv1_plot_smooth = (2*pv1_plot_fin(1:timestep-startarray-2) + pv1_plot_fin(0:timestep-startarray-3) + pv1_plot_fin(2:timestep-startarray-1))/4
                 pv2_plot_smooth = (2*pv2_plot_fin(1:timestep-startarray-2) + pv2_plot_fin(0:timestep-startarray-3) + pv2_plot_fin(2:timestep-startarray-1))/4
                 pv3_plot_smooth = (2*pv3_plot_fin(1:timestep-startarray-2) + pv3_plot_fin(0:timestep-startarray-3) + pv3_plot_fin(2:timestep-startarray-1))/4
                 pv3pv2ratio_plot_smooth = (pv3_plot_smooth/pv2_plot_smooth)
                 therm_plot_smooth = (2*therm_plot_fin(1:timestep-startarray-2) + therm_plot_fin(0:timestep-startarray-3) + therm_plot_fin(2:timestep-startarray-1))/4
                 xaxis_plot_fin = xaxis_plot(startarray+1:timestep-2)

                 data_fin = new((/3,dimsizes(pv2_plot_smooth)/),float)
                 data_fin(1,:) = pv2_plot_smooth
                 data_fin(2,:) = pv3_plot_smooth
                 data_fin(0,:) = pv1_plot_smooth

             end if

;             absmax_h1 = .35
;             absmin_h1 = -.25
             
             absmax_h1 = .3
             absmin_h1 = -.2

             absmax_h2 = 3.0
             absmin_h2 = -3.0

             maxvalues_h2 = new((/2,1/),float)
             maxvalues_h2(0,:) = absmin_h2
             maxvalues_h2(1,:) = absmax_h2
             minplot_h2 = -max(abs(maxvalues_h2))
             maxplot_h2 = max(abs(maxvalues_h2))

             if maxplot_h2 .gt.  5.0 then
                maxplot_h2 = 5.0
                minplot_h2 = -5.0
             end if

;             print("maxplot_h2: "+maxplot_h2)
;             print("minplot_h2: "+minplot_h2)
             
             absmax_h3 = 7.0
             absmin_h3 = -5.0
             
             absmax_h3 = 6.0
             absmin_h3 = -4.0
             
;             print(xaxis_plot_fin)
             print("Start: "+ut_string(xaxis_plot_fin(0),"")) 
;             print("End: "+ut_string(xaxis_plot_fin(31),"")) 
             
             ;==============================================
             ; Make the graphs
             ;==============================================
             wks_type = "png"

             wks_type@wkWidth = 1900
             wks_type@wkHeight = 1900

             wks = gsn_open_wks(wks_type,name+"_"+counter_filename)
             ;**********************************************

             ; resources for "left" variable
             resL                   = True 
             resL@gsnFrame          = False                   ;DO NOT PLOT FIRST MAP
             resL@gsnDraw           = False
             resL@xyLineThicknesses = (/23.,23.,23./)
             resL@xyLineColors      = (/"black","red","forestgreen"/) 
             resL@xyDashPatterns    = (/0.,0.,0./)    
             resL@trYMaxF           =   absmax_h1             ; axis max
             resL@trYMinF           =   absmin_h1             ; axis min
             resL@tiYAxisString     = "PV1 (black), PV2 (red), PV3 (green) [PVU]" 
             resL@tmXBMode = "Explicit"
             resL@tmXBValues = xaxis_plot_fin(::1)
             resL@tmXBLabels = ut_string(xaxis_plot_fin(::1) , "%n/%d %H")
             resL@trXMaxF= max(xaxis_plot_fin)
             resL@trXMinF = min(xaxis_plot_fin)
             resL@tiMainString      = "Hermine "+zulu+" GFS PV Metrics [Bentley et al. (2016)]"
             resL@tmXBLabelFontHeightF = 0.008
             resL@tiMainFontHeightF    = 0.018
             resL@tmYLLabelFontHeightF = 0.019
             resL@tiYAxisFontHeightF   = 0.015     
             resL@tmYLMinorPerMajor = 0
			 resL@tmXBLabelAngleF = 90.0
			 resL@tmXBMajorThicknessF = 2.0
			 resL@tmXBMinorThicknessF = 2.0
             resL@tmYLMinorThicknessF = 4.0
             resL@tmYLMajorThicknessF = 4.0
             resL@tmYLLabelDeltaF     = -0.7
             

             ; resources for "right" variable
             resR2                   = True 
             resR2@gsnFrame          = False                           ;DO NOT PLOT FIRST MAP
             resR2@gsnDraw           = False                                  
             resR2@xyLineThicknesses = 23.
             resR2@trYMaxF           =   absmax_h3             ; axis max
             resR2@trYMinF           =   absmin_h3             ; axis min               
             resR2@xyLineColors      = "gray60"
                            
             resR2@tiYAxisString     = "500-200-hPa thermal vorticity [x 10^-5 s^-1] (gray)"
             resR2@tmYRLabelFontHeightF = 0.011
             resR2@tiYAxisFontHeightF   = 0.015
             resR2@tmYRMaxTicks = 8  
             resR2@tmYRMinorPerMajor = 1
             
             resR2@tmYMajorGrid                = True          ; implement y grid
             resR2@tmYMajorGridThicknessF      = 4.0           ; 2.0 is default
             resR2@tmYMajorGridLineDashPattern = 0             ; select short dash lines
             resR2@tmYMinorGrid                = True          ; implement y grid
             resR2@tmYMinorGridThicknessF      = 4.0           ; 2.0 is default
             resR2@tmYMinorGridLineDashPattern = 0             ; select short dash lines
             resR2@tmYRMinorThicknessF = 4.0
             resR2@tmYRMajorThicknessF = 4.0
             resR2@tmYRLabelDeltaF     = -0.5

             plot = gsn_csm_xy2(wks,xaxis_plot_fin,data_fin,therm_plot_smooth,resL,resR2)  





             line = new(460,graphic)
             text = new(460,graphic)
             dum = 0

             resL@gsLineDashPattern = 0
             resL@gsLineThicknessF = 4
             resL@gsLineColor = "black"
;             zero1 = gsn_add_polyline(wks,plot,(/min(xaxis_plot_fin),max(xaxis_plot_fin)/),(/0,0/),resL)
;             zero2 = gsn_add_polyline(wks,plot,(/min(xaxis_plot_fin),max(xaxis_plot_fin)/),(/.2,.2/),resL)

             STC = new(460,graphic)
             star = 0
             full = timestep-startarray-6
             iden = 0
            

            do j = 1,full
                  pv3_slope_curr = (pv3_plot_smooth(j)-pv3_plot_smooth(j-1))
                  pv3_slope_next = (pv3_plot_smooth(j+1)-pv3_plot_smooth(j))
                  pv3_slope_next2 = (pv3_plot_smooth(j+2)-pv3_plot_smooth(j+1))
                  pv2_slope_curr = (pv2_plot_smooth(j)-pv2_plot_smooth(j-1))                  
                  pv2_slope_next = (pv2_plot_smooth(j+1)-pv2_plot_smooth(j))
                  pv2_slope_next2 = (pv2_plot_smooth(j+2)-pv2_plot_smooth(j+1))
                  pv3pv2ratio_slope_curr = (pv3pv2ratio_plot_smooth(j)-pv3pv2ratio_plot_smooth(j-1))
;                  pv3pv2ratio_slope_next = (pv3pv2ratio_plot_smooth(j+1)-pv3pv2ratio_plot_smooth(j))
;                  pv3pv2ratio_slope_next2 = (pv3pv2ratio_plot_smooth(j+2)-pv3pv2ratio_plot_smooth(j+1))
                  pv3pv2ratio_slope_next = ((pv3_plot_smooth(j+1)/pv2_plot_smooth(j+1))-(pv3_plot_smooth(j)/pv2_plot_smooth(j)))
                  pv3pv2ratio_slope_next2 = ((pv3_plot_smooth(j+2)/pv2_plot_smooth(j+2))-(pv3_plot_smooth(j+1)/pv2_plot_smooth(j+1)))                  
                  resL@txFontHeightF = 0.06
                  star = star + 1
                  if ((pv3_plot_smooth(j) .gt. 0) .and. (pv2_plot_smooth(j) .gt. 0) .and. (pv3_slope_next .lt. 0) .and. (pv3_slope_next2 .lt. 0) .and. (pv3_slope_next .lt. pv2_slope_next) .and. (pv3_slope_next2 .lt. pv2_slope_next2) .and. (therm_plot_smooth(j) .gt. 0)) .and. (j .le. 16) then
;                       STC(star) = gsn_add_text(wks,plot,"*",xaxis_plot_fin(j),0,resL)
                       print("iden: "+iden)
                       iden = iden + 1
                       if (iden .eq. 1) then
                            stcs(out) = casename_plot(startarray+j+1)+","+lat_plot(startarray+j+1)+","+lon_plot(startarray+j+1)+","+yyyy_plot(startarray+j+1)+","+mm_plot(startarray+j+1)+","+dd_plot(startarray+j+1)+","+hh_plot(startarray+j+1)+",Y"
                            asciiwrite(fileout, stcs)
                            out = out + 1
                       end if
                  end if
             end do
             if (iden .eq. 0) 
 ;                 stcs(out) = "missing,missing,missing,missing,missing,missing,missing,N"
;                  asciiwrite(fileout, stcs)
                  out = out + 1
             end if




             draw(plot)
             frame(wks)

             delete(resL@tmXBValues)
             delete(resL@tmXBLabels)
             delete(resL@gsLineDashPattern)
             delete(resL@gsLineThicknessF)
             delete(resL@gsLineColor)
             delete(pv3_slope_next)
             delete(pv3_slope_next2)
             delete(pv3pv2ratio_slope_curr)
             delete(pv3pv2ratio_slope_next)
             delete(pv3pv2ratio_slope_next2)

             ;==============================================

             system("convert -trim "+name+"_"+counter_filename+".png "+name+"_"+counter_filename+".png")
             system ("mv "+name+"_"+counter_filename+".png "+dir_out+name+"_"+counter_filename+".png")
             ;==============================================

             ; Continuing along
             delete(time)

             startarray = timestep
             counter_filename = counter_filename + 1
             casenum = casenum + 1

             casename_plot(timestep) = casename
             lat_plot(timestep) = lat
             lon_plot(timestep) = lon
             yyyy_plot(timestep) = yyyy
             mm_plot(timestep) = mm
             dd_plot(timestep) = dd
             hh_plot(timestep) = hh
             pv1_plot(timestep) = pv1
             pv2_plot(timestep) = pv2
             pv3_plot(timestep) = pv3
             therm_plot(timestep) = therm
             xaxis_plot(timestep) = date
             print(" ")
        end if
         

 
   else 
        counter_filename = 1
        casenum = 1

        casename_plot(timestep) = casename 
        lat_plot(timestep) = lat
        lon_plot(timestep) = lon            
        yyyy_plot(timestep) = yyyy
        mm_plot(timestep) = mm
        dd_plot(timestep) = dd
        hh_plot(timestep) = hh
        pv1_plot(timestep) = pv1
        pv2_plot(timestep) = pv2
        pv3_plot(timestep) = pv3
        therm_plot(timestep) = therm
        xaxis_plot(timestep) = date
   end if 

end do

    print(" ")
    print("**************")
    print(" END SCRIPT ")
    print("**************")
    print(" ")

end