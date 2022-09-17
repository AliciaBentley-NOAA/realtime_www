; *************************************************
; Calculating PV from C. A. Davis (2010)
; Alicia M. Bentley
; M.S. Thesis
; August 23, 2014
; *************************************************

; ************************************************
; Load necessary NCL info. before doing anything
; ************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"

; ************************************************
; Begin script
; ************************************************

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")
print(" ")

set_default_fillvalue("float", -999)      ; set default value for missing data

; ************************************************
; Specify size of box
; ************************************************

deg = 3      ; Distance from center to side of the box (degrees)
;print("Degrees from center: "+deg)
;print(" ")

dist = floattoint(deg/0.5+1)  ; Distance from center to side of the box (grid pts.)

; ************************************************
;  Load in the input files
; ************************************************
;These will now be much shorter files (Strong TT, Weak TT, Trough Induced ONLY = 6648)
;Last line repeated to do all calculations, double time removed
;Remember to mac2unix these files before use

fileread = asciiread("/lb13/abentley/scripts/mthesis/paper/input/input_SWT_datlatlon_extraline.csv",(/6648,6/),"float")
fileread_name = asciiread("/lb13/abentley/scripts/mthesis/paper/input/input_SWT_casename_extraline.txt",-1,"string")

lines = new((/6647/),"string")    ; make lines for final output

do timestep = 0,6646

print("Starting line "+timestep+" of 6646")

; ************************************************
; Define center point & analysis box
; ************************************************

cyclone = str_strip(fileread_name(timestep))

center_lat = round(2*fileread(timestep,4),0)/2        ; define center point to nearest 0.5-deg
center_lon = round(2*fileread(timestep,5),0)/2

; ***********************************************
; Specify the date (eventually read in and split from file)
; ***********************************************

ryyyy = floattoint(fileread(timestep,0))    ; r = real date
rmm = floattoint(fileread(timestep,1))          
rdd = floattoint(fileread(timestep,2))
rhh = floattoint(fileread(timestep,3))

;print("Timestep: "+timestep)

syyyy = ryyyy   ; s = start date of the 5-day mean
smm = rmm
sdd = rdd - 5
shh = rhh - 12

eyyyy = ryyyy   ; e = end date of the 5-day mean
emm = rmm
edd = rdd + 5     
ehh = rhh + 12 


timeUnits = "hours since 1800-01-01 00:00:00"      ; converting to correct units

sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,timeUnits,0)
rdate = cd_inv_calendar(ryyyy,rmm,rdd,rhh,00,00,timeUnits,0)
edate = cd_inv_calendar(eyyyy,emm,edd,ehh,00,00,timeUnits,0)

;print("Start: "+ut_string(sdate,""))
;print("Date:  "+ut_string(rdate,""))
;print("11-day Centered Mean: "+ut_string(sdate,"")+" to "+ut_string(edate,""))
;print("End:   "+ut_string(edate,""))


; *****************************************************
; Identify number of days in average theta calculation
; *****************************************************

avg_days = ((edate-sdate)/24)     ; find the number of days span (11) in 11-day mean	  
  
;print("Number of Days Span: "+avg_days)


; **********************************************
; Load files
; **********************************************

; Load special combined files for Zeta in 2005 because it crosses years. This happens near lines 1636 and 1677.
if timestep .ge. 1635 .and. timestep .le. 1679 then
	files925 = addfiles("/lb13/abentley/data/cfsr/comb0506_theta.925.anl.nc", "r")
	files850 = addfiles("/lb13/abentley/data/cfsr/comb0506_theta.850.anl.nc", "r")
	files_absvort925 = addfiles("/lb13/abentley/data/cfsr/comb0506_abs_vort.925.anl.nc", "r")
	files_absvort850 = addfiles("/lb13/abentley/data/cfsr/comb0506_abs_vort.850.anl.nc", "r")
	files_pv = addfiles("/lb13/abentley/data/cfsr/comb0506_pv.anl.nc", "r")
else
	files925 = addfiles("/lb13/abentley/data/cfsr/theta.925."+ryyyy+".anl.nc", "r")
	files850 = addfiles("/lb13/abentley/data/cfsr/theta.850."+ryyyy+".anl.nc", "r")
	files_absvort925 = addfiles("/lb13/abentley/data/cfsr/abs_vort.925."+ryyyy+".anl.nc", "r")
	files_absvort850 = addfiles("/lb13/abentley/data/cfsr/abs_vort.850."+ryyyy+".anl.nc", "r")
	files_pv = addfiles("/lb13/abentley/data/cfsr/pv."+ryyyy+".anl.nc", "r")
end if

u_raw = addfile("/cfsr/data/"+ryyyy+"/u."+ryyyy+".0p5.anl.nc","r")
v_raw = addfile("/cfsr/data/"+ryyyy+"/v."+ryyyy+".0p5.anl.nc","r")

;print("Files Loaded")


; *********************************************
; Extract variables
; *********************************************

time925 = files925[:]->time({sdate:edate})               ; extracting the time

temp925 = files925[:]->theta({sdate:edate},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; 925 theta values over 5-day period
temp850 = files850[:]->theta({sdate:edate},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; 850 theta values over 5-day period
avor925 = files_absvort925[:]->absvort({rdate},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})    ; 925 absvort at the real date and time
avor850 = files_absvort850[:]->absvort({rdate},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})    ; 850 absvort at the real date and time

pv925 = files_pv[:]->pv({sdate:edate},{925},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg}) ; 925 pv values over 5-day period
pv850 = files_pv[:]->pv({sdate:edate},{850},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv800 = files_pv[:]->pv({sdate:edate},{800},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv700 = files_pv[:]->pv({sdate:edate},{700},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
pv600 = files_pv[:]->pv({sdate:edate},{600},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
pv500 = files_pv[:]->pv({sdate:edate},{500},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv400 = files_pv[:]->pv({sdate:edate},{400},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv300 = files_pv[:]->pv({sdate:edate},{300},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv200 = files_pv[:]->pv({sdate:edate},{200},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv100 = files_pv[:]->pv({sdate:edate},{100},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   

uwnd925 = u_raw->u({rdate},{925},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; units m s^1  
vwnd925 = v_raw->v({rdate},{925},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; extracting wind values for vertical wind shear
uwnd300 = u_raw->u({rdate},{300},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})     
vwnd300 = v_raw->v({rdate},{300},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg}) 

u1 = u_raw->u({rdate},{200},:,:)   ; getting winds for thermvort
v1 = v_raw->v({rdate},{200},:,:)
u2 = u_raw->u({rdate},{500},:,:)
v2 = v_raw->v({rdate},{500},:,:)
u3 = u_raw->u({rdate},{100},:,:)
v3 = v_raw->v({rdate},{100},:,:)

;print("Variables Extracted from Files")
;print(" ")


; *********************************************
; Constants
; *********************************************

L_lon = todouble(111000.*(deg*2))      ; meters in 10 degrees
L_lat = todouble(L_lon * cos(center_lat * 3.1592653589792/180))
dy = tofloat(55500.)              ; meters in 0.5 degrees of latitude
lower_delta_p = todouble(42500.)         ; Pa
upper_delta_p = todouble(30000.)         ; Pa
upper_delta_p_high = todouble(40000.)    ; Pa

g = todouble(9.80665)       ; m s^-2


; **************************************************
; Calculate the 5-day mean (average theta over time)
; **************************************************

avg_temp925 = dim_avg_n_Wrap(temp925,0)     ; averages over the first dimension = time (21 x 21 grid)
avg_temp850 = dim_avg_n_Wrap(temp850,0)

real_temp925 = files925[:]->theta({rdate},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})      ; 925 theta values over 5-day period
real_temp850 = files850[:]->theta({rdate},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  

pert_theta925 = real_temp925 - avg_temp925    ; calculate theta anom. @ every pt.(925 hPa)
pert_theta925@_FillValue = -999

pert_theta850 = real_temp850 - avg_temp850    ; calculate theta anom. @ every pt.(925 hPa)
pert_theta850@_FillValue = -999

lon1_925 = pert_theta925(:,0)        ; extract theta anom around the edges of the box
lon2_925 = pert_theta925(:,deg*2*2)
lat1_925 = pert_theta925(0,:)
lat2_925 = pert_theta925(deg*2*2,:)

lon1_850 = pert_theta850(:,0)
lon2_850 = pert_theta850(:,deg*2*2)
lat1_850 = pert_theta850(0,:)
lat2_850 = pert_theta850(deg*2*2,:)

; **************************************************
; Calculate the latitudinal integral
; **************************************************
Gx1_925 = lon1_925(0)
Gx2_925 = lon2_925(0)
Gx1_850 = lon1_850(0)
Gx2_850 = lon2_850(0)

do i = 1,deg*2*2-1
  Gx1_925 = Gx1_925 + 2 * lon1_925(i)
  Gx2_925 = Gx2_925 + 2 * lon2_925(i)
  Gx1_850 = Gx1_850 + 2 * lon1_850(i)
  Gx2_850 = Gx2_850 + 2 * lon2_850(i)
end do

Gx1_925 = (dy/2) * (Gx1_925 + lon1_925(deg*2*2))
Gx2_925 = (dy/2) * (Gx2_925 + lon2_925(deg*2*2))
Gx1_850 = (dy/2) * (Gx1_850 + lon1_850(deg*2*2))
Gx2_850 = (dy/2) * (Gx2_850 + lon2_850(deg*2*2))

Gx_925 = (1/L_lon) * Gx2_925 - (1/L_lon) * Gx1_925
Gx_850 = (1/L_lon) * Gx2_850 - (1/L_lon) * Gx1_850

Gx = 0.5 * (Gx_925 + Gx_850)

; **************************************************
; Calculate the longitudinal integral
; **************************************************
Gy1_925 = todouble(0)
Gy2_925 = todouble(0)
Gy1_850 = todouble(0)
Gy2_850 = todouble(0)

do i = 0,deg*2*2-1
  Gy1_925 = Gy1_925 + 0.5*(lat1_925(i)+lat1_925(i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*3.141592653589792/180))
  ;print((center_lat-deg+0.5*(i+1)-0.25))
  Gy2_925 = Gy2_925 + 0.5*(lat2_925(i)+lat2_925(i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*3.141592653589792/180))
  Gy1_850 = Gy1_850 + 0.5*(lat1_850(i)+lat1_850(i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*3.141592653589792/180))
  Gy2_850 = Gy2_850 + 0.5*(lat2_850(i)+lat2_850(i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*3.141592653589792/180))
end do

Gy_925 = (1/L_lat) * Gy2_925 - (1/L_lat) * Gy1_925
Gy_850 = (1/L_lat) * Gy2_850 - (1/L_lat) * Gy1_850

Gy = 0.5 * (Gy_925 + Gy_850)

; Now, calculate total G
G = sqrt(Gx^2+Gy^2)

; ******************************************************
; Calculate absolute vorticity
; ******************************************************
avor = 0.5*(avg(avor925)+avg(avor850))

; ******************************************************
; Final Calculation of PV1
; ******************************************************
pv1 = (g*avor*G)/lower_delta_p

PV1 = pv1*10^6

;print("PV1: "+PV1+" PVU")



; **************************************************
; Calculate the 11-day mean (average pv over time)
; **************************************************
box_pv925 = dim_avg_n_Wrap(pv925,0)    ; averages over the first dimension (time)
box_pv850 = dim_avg_n_Wrap(pv850,0)     
box_pv800 = dim_avg_n_Wrap(pv800,0)
box_pv700 = dim_avg_n_Wrap(pv700,0)
box_pv600 = dim_avg_n_Wrap(pv600,0)
box_pv500 = dim_avg_n_Wrap(pv500,0)
box_pv400 = dim_avg_n_Wrap(pv400,0)
box_pv300 = dim_avg_n_Wrap(pv300,0)
box_pv200 = dim_avg_n_Wrap(pv200,0)
box_pv100 = dim_avg_n_Wrap(pv100,0)

real_pv925 = files_pv[:]->pv({rdate},{925},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; 925 pv values over 5-day period
real_pv850 = files_pv[:]->pv({rdate},{850},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv800 = files_pv[:]->pv({rdate},{800},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv700 = files_pv[:]->pv({rdate},{700},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
real_pv600 = files_pv[:]->pv({rdate},{600},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
real_pv500 = files_pv[:]->pv({rdate},{500},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv400 = files_pv[:]->pv({rdate},{400},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv300 = files_pv[:]->pv({rdate},{300},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv200 = files_pv[:]->pv({rdate},{200},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv100 = files_pv[:]->pv({rdate},{100},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})

pert_pv925 = real_pv925 - box_pv925   ; calculate pv anom. @ every pt.
pert_pv850 = real_pv850 - box_pv850
pert_pv800 = real_pv800 - box_pv800
pert_pv700 = real_pv700 - box_pv700
pert_pv600 = real_pv600 - box_pv600
pert_pv500 = real_pv500 - box_pv500
pert_pv400 = real_pv400 - box_pv400
pert_pv300 = real_pv300 - box_pv300
pert_pv200 = real_pv200 - box_pv200
pert_pv100 = real_pv100 - box_pv100

pert_pv925@_FillValue = -999    ; Fill missing values with -999
pert_pv850@_FillValue = -999
pert_pv800@_FillValue = -999
pert_pv700@_FillValue = -999
pert_pv600@_FillValue = -999
pert_pv500@_FillValue = -999
pert_pv400@_FillValue = -999
pert_pv300@_FillValue = -999
pert_pv200@_FillValue = -999
pert_pv100@_FillValue = -999 


; **************************************************
; Calculate vertical integral
; **************************************************
lower_q_prime = (pert_pv925+pert_pv850)*(7500/2) + (pert_pv850+pert_pv800)*(5000/2) + (pert_pv800+pert_pv700)*(10000/2) + (pert_pv700+pert_pv600)*(10000/2) + (pert_pv600+pert_pv500)*(10000/2)  ; lower_q_prime should be 2D (x and y)

;;;;

upper_q_prime = (pert_pv500+pert_pv400)*(10000/2) + (pert_pv400+pert_pv300)*(10000/2) + (pert_pv300+pert_pv200)*(10000/2)

;;;;

upper_q_prime_high = (pert_pv500+pert_pv400)*(10000/2) + (pert_pv400+pert_pv300)*(10000/2) + (pert_pv300+pert_pv200)*(10000/2) + (pert_pv200+pert_pv100)*(10000/2)

; **************************************************
; Calculate latitude integral
; **************************************************
lower_q_prime_lat = new((/1,deg*2*2+1/),double)

lower_q_prime_lat(0,:) = lower_q_prime(0,:) ; do the ends first, because they only appear once

; Now, we will loop through the middle latitudes and add each one to lower_q_prime_lat
do i = 1,deg*2*2-1 ; loops over each GRID POINT in the MIDDLE
	lower_q_prime_lat(0,:) = lower_q_prime_lat(0,:) + 2 * lower_q_prime(i,:) ;
end do

lower_q_prime_lat(0,:) = lower_q_prime_lat(0,:) + lower_q_prime(deg*2*2,:)

lower_q_prime_lat = lower_q_prime_lat * dy / 2       ; multiply by dy/2 because they were constants that we factored out


;;;;


upper_q_prime_lat = new((/1,deg*2*2+1/),double)

upper_q_prime_lat(0,:) = upper_q_prime(0,:) ; do the ends first, because they only appear once

; Now, we will loop through the middle latitudes and add each one to q_prime_lat
do i = 1,deg*2*2-1 ; loops over each GRID POINT in the MIDDLE
  upper_q_prime_lat(0,:) = upper_q_prime_lat(0,:) + 2 * upper_q_prime(i,:) ;
end do

upper_q_prime_lat(0,:) = upper_q_prime_lat(0,:) + upper_q_prime(deg*2*2,:)

upper_q_prime_lat = upper_q_prime_lat * dy / 2 ; multiply by dy/2 because they were constants that we factored out


;;;;


upper_q_prime_high_lat = new((/1,deg*2*2+1/),double)

upper_q_prime_high_lat(0,:) = upper_q_prime_high(0,:) ; do the ends first, because they only appear once

; Now, we will loop through the middle latitudes and add each one to q_prime_lat
do i = 1,deg*2*2-1 ; loops over each GRID POINT in the MIDDLE
  upper_q_prime_high_lat(0,:) = upper_q_prime_high_lat(0,:) + 2 * upper_q_prime_high(i,:) ;
end do

upper_q_prime_high_lat(0,:) = upper_q_prime_high_lat(0,:) + upper_q_prime_high(deg*2*2,:)

upper_q_prime_high_lat = upper_q_prime_high_lat * dy / 2 ; multiply by dy/2 because they were constants that we factored out



; **************************************************
; Calculate longitude integral
; **************************************************
lower_q_prime_lon = todouble(0)

do i = 0,deg*2*2-1 ; loop over each longitude
  lower_q_prime_lon = lower_q_prime_lon + 0.5*(lower_q_prime_lat(0,i)+lower_q_prime_lat(0,i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*(3.141592653589792/180)))
  ;print((center_lat-deg+0.5*(i+1)-0.25))
end do

;;;;

upper_q_prime_lon = todouble(0)

do i = 0,deg*2*2-1 ; loop over each longitude
  upper_q_prime_lon = upper_q_prime_lon + 0.5*(upper_q_prime_lat(0,i)+upper_q_prime_lat(0,i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*(3.141592653589792/180)))
end do

;;;;

upper_q_prime_high_lon = todouble(0)

do i = 0,deg*2*2-1 ; loop over each longitude
  upper_q_prime_high_lon = upper_q_prime_high_lon + 0.5*(upper_q_prime_high_lat(0,i)+upper_q_prime_high_lat(0,i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*(3.141592653589792/180)))
  ;print((center_lat-deg+0.5*(i+1)-0.25))
end do





; **************************************************
; Final Calculation of PV2
; **************************************************
PV2 = lower_q_prime_lon/(lower_delta_p*L_lat*L_lon);
;print("PV2: "+PV2+" PVU")


; **************************************************
; Final Calculation of PV3
; **************************************************
PV3 = upper_q_prime_lon/(upper_delta_p*L_lat*L_lon);
;print("PV3: "+PV3+" PVU")


; **************************************************
; Final Calculation of PV4
; **************************************************
PV4 = upper_q_prime_high_lon/(upper_delta_p_high*L_lat*L_lon);
;print("PV4: "+PV4+" PVU")



; ******************************************************
; Final Calculation of PV3/PV2
; ******************************************************
;pv3pv2 = PV3/PV2
;print("PV3/PV2: "+pv3pv2)



; ******************************************************
; Calculate thermal vorticity
; ******************************************************

relvort200 = uv2vrG_Wrap(u1,v1) ; Calculate relative vorticity using spherical harmonics
relvort500 = uv2vrG_Wrap(u2,v2)
therm_vort200 = relvort200(:,:)-relvort500(:,:)
therm_vort200 = therm_vort200*(10^5)
copy_VarCoords(u1,therm_vort200)

therm200 = therm_vort200({center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
therm200avg = decimalPlaces(avg(therm200),10,True)

;;;;;;

relvort100 = uv2vrG_Wrap(u3,v3)
therm_vort100 = relvort100(:,:)-relvort500(:,:)
therm_vort100 = therm_vort100*(10^5)
copy_VarCoords(u1,therm_vort100)

therm100 = therm_vort100({center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
therm100avg = decimalPlaces(avg(therm100),10,True)



; ******************************************************
; Calculation of vertical wind shear
; ******************************************************
ushear = uwnd300-uwnd925
vshear = vwnd300-vwnd925

shear_mag_mat = sqrt(((ushear)^2)+((vshear)^2))
shear_mag = decimalPlaces(avg(shear_mag_mat),1,True)    ; average shear magnitude inside the box

;print("Shear: "+shear_mag+" m/s")
;print(" ")


; ***************************************************
; Write values to text file
; ***************************************************

lines(timestep) = cyclone+","+avg_days+","+2*deg+","+center_lat+","+center_lon+","+ut_string(rdate,"%Y")+","+ut_string(rdate,"%N")+","+ut_string(rdate,"%D")+","+ut_string(rdate,"%H")+","+PV1+","+PV2+","+PV3+","+PV4+","+therm200avg+","+therm100avg+","+shear_mag

asciiwrite("/lb13/abentley/scripts/mthesis/paper/output/output_SWT_extraline.txt", lines)

end do

;print("Date and Values = Printed to File")
;print(" ")

print(" ")
print("***************")
print("SCRIPT COMPLETE")
print("***************")
print(" ")
end
