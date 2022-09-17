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

zulu = "00Z"
day = "5"

outfile = "/lb13/abentley/scripts/mapdisco/pvmetrics/pvmetrics_"+zulu+"_"+day+"SEP2016.csv"

; ************************************************
; Specify size of box
; ************************************************

deg = 3      ; Distance from center to side of the box (degrees)
;print("Degrees from center: "+deg)
;print(" ")

dist = floattoint(deg/0.5+1)  ; Distance from center to side of the box (grid pts.)

timeUnits = "hours since 1800-01-01 00:00:00"
set_default_fillvalue("float", -999)      ; set default value for missing data

; ********************************************************
; Specify center lat/lon to use 
; ********************************************************
count = 0
totallines = 41
lines := new((/totallines/),"string")

fileread = asciiread("/lb13/abentley/scripts/mapdisco/pvmetrics/hermine_"+zulu+"_"+day+"SEP2016.csv",(/totallines,6/),"float")

; ************************************************
; Specify the date and lat/lon (read in from file)
; ************************************************

do timestep = 11,totallines-1

number = timestep + 1

print("Obtaining data from line: "+number+" of "+totallines)

;print("Line "+number+": "+fileread(timestep))

ryyyy = flt2dble(fileread(timestep,0))
rmm = flt2dble(fileread(timestep,1))
rdd = flt2dble(fileread(timestep,2))
rhh = flt2dble(fileread(timestep,3))
center_lat = flt2dble(fileread(timestep,4))
center_lon = flt2dble(fileread(timestep,5))

print(" ")
print("yyyy: "+ryyyy)
print("mm: "+rmm)
print("dd: "+rdd)
print("hh: "+rhh)
print("center_lat: "+center_lat)

center_lon = 360 + center_lon

print("center_lon: "+center_lon)

; ***********************************************
; Specify the date (eventually read in and split from file)
; ***********************************************

rdate = timestep
sdate = rdate-8
edate = rdate+8

; **********************************************
; Load files
; **********************************************

theta_file = addfile("/free2/abentley/realtime/pvmetrics/theta.nc", "r")
absvort_file = addfile("/free2/abentley/realtime/pvmetrics/absvort.nc", "r")
pv_file = addfile("/free2/abentley/realtime/pvmetrics/pv.nc", "r")
therm_file = addfile("/free2/abentley/realtime/pvmetrics/therm_vort.nc","r")

print("Files Loaded")

; *********************************************
; Extract variables
; *********************************************

theta = theta_file->theta(sdate:edate,{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; 925 theta values over 5-day period

absvort = absvort_file->absvort(sdate:edate,{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg}) 

;printVarSummary(absvort) 

left = center_lon-deg
right = center_lon+deg
top = center_lat+deg
bottom = center_lat-deg

;print("left: "+left)
;print("right: "+right)
;print("top: "+top)
;print("bottom: "+bottom)

pv925 = pv_file->pv(sdate:edate,{92500},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg}) ; 925 pv values over 5-day period
pv850 = pv_file->pv(sdate:edate,{85000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv800 = pv_file->pv(sdate:edate,{80000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv700 = pv_file->pv(sdate:edate,{70000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
pv600 = pv_file->pv(sdate:edate,{60000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
pv500 = pv_file->pv(sdate:edate,{50000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv400 = pv_file->pv(sdate:edate,{40000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv300 = pv_file->pv(sdate:edate,{30000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
pv200 = pv_file->pv(sdate:edate,{20000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg}) 

print("Variables Extracted from Files")
print(" ")

; *********************************************
; Constants
; *********************************************

L_lon = todouble(111000.*(deg*2))      ; meters in 10 degrees
L_lat = todouble(L_lon * cos(center_lat * 3.1592653589792/180))
dy = tofloat(55500.)              ; meters in 0.5 degrees of latitude
lower_delta_p = todouble(42500.)         ; Pa
upper_delta_p = todouble(30000.)         ; Pa

g = todouble(9.80665)       ; m s^-2


; **************************************************
; Calculate the 5-day mean (average theta over time)
; **************************************************

avg_theta = dim_avg_n_Wrap(theta,0)     ; averages over the first dimension = time (21 x 21 grid)
;printVarSummary(avg_theta)

real_theta = theta_file->theta(rdate,{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})      ; 925 theta values over 5-day period 
pert_theta = real_theta - avg_theta    ; calculate theta anom. @ every pt.(925 hPa)
pert_theta@_FillValue = -999

lon1_theta = pert_theta(:,0)        ; extract theta anom around the edges of the box
lon2_theta = pert_theta(:,deg*2*2)
lat1_theta = pert_theta(0,:)
lat2_theta = pert_theta(deg*2*2,:)

; **************************************************
; Calculate the latitudinal integral
; **************************************************
Gx1_theta = lon1_theta(0)
Gx2_theta = lon2_theta(0)

do i = 1,deg*2*2-1
  Gx1_theta = Gx1_theta + 2 * lon1_theta(i)
  Gx2_theta = Gx2_theta + 2 * lon2_theta(i)
end do

Gx1_theta = (dy/2) * (Gx1_theta + lon1_theta(deg*2*2))
Gx2_theta = (dy/2) * (Gx2_theta + lon2_theta(deg*2*2))

Gx = (1/L_lon) * Gx2_theta - (1/L_lon) * Gx1_theta

;print(Gx)

; **************************************************
; Calculate the longitudinal integral
; **************************************************
Gy1_theta = todouble(0)
Gy2_theta = todouble(0)


do i = 0,deg*2*2-1
  Gy1_theta = Gy1_theta + 0.5*(lat1_theta(i)+lat1_theta(i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*3.141592653589792/180))
  ;print((center_lat-deg+0.5*(i+1)-0.25))
  Gy2_theta = Gy2_theta + 0.5*(lat2_theta(i)+lat2_theta(i+1)*dy*cos((center_lat-deg+0.5*(i+1)-0.25)*3.141592653589792/180))
end do

Gy = (1/L_lat) * Gy2_theta - (1/L_lat) * Gy1_theta

;print(Gy)

; Now, calculate total G
G = sqrt(Gx^2+Gy^2)

;print(G)

; ******************************************************
; Calculate absolute vorticity
; ******************************************************
avor = avg(absvort)

; ******************************************************
; Final Calculation of PV1
; ******************************************************
pv1 = (g*avor*G)/lower_delta_p

PV1 = pv1*10^6

print("PV1: "+PV1+" PVU")

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

real_pv925 = pv_file->pv(rdate,{92500},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})   ; 925 pv values over 5-day period
real_pv850 = pv_file->pv(rdate,{85000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv800 = pv_file->pv(rdate,{80000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv700 = pv_file->pv(rdate,{70000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
real_pv600 = pv_file->pv(rdate,{60000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})  
real_pv500 = pv_file->pv(rdate,{50000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv400 = pv_file->pv(rdate,{40000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv300 = pv_file->pv(rdate,{30000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})
real_pv200 = pv_file->pv(rdate,{20000},{center_lat-deg:center_lat+deg},{center_lon-deg:center_lon+deg})

pert_pv925 = real_pv925 - box_pv925   ; calculate pv anom. @ every pt.
pert_pv850 = real_pv850 - box_pv850
pert_pv800 = real_pv800 - box_pv800
pert_pv700 = real_pv700 - box_pv700
pert_pv600 = real_pv600 - box_pv600
pert_pv500 = real_pv500 - box_pv500
pert_pv400 = real_pv400 - box_pv400
pert_pv300 = real_pv300 - box_pv300
pert_pv200 = real_pv200 - box_pv200

pert_pv925@_FillValue = -999    ; Fill missing values with -999
pert_pv850@_FillValue = -999
pert_pv800@_FillValue = -999
pert_pv700@_FillValue = -999
pert_pv600@_FillValue = -999
pert_pv500@_FillValue = -999
pert_pv400@_FillValue = -999
pert_pv300@_FillValue = -999
pert_pv200@_FillValue = -999


; **************************************************
; Calculate vertical integral
; **************************************************
lower_q_prime = (pert_pv925+pert_pv850)*(7500/2) + (pert_pv850+pert_pv800)*(5000/2) + (pert_pv800+pert_pv700)*(10000/2) + (pert_pv700+pert_pv600)*(10000/2) + (pert_pv600+pert_pv500)*(10000/2)  ; lower_q_prime should be 2D (x and y)

;;;;

upper_q_prime = (pert_pv500+pert_pv400)*(10000/2) + (pert_pv400+pert_pv300)*(10000/2) + (pert_pv300+pert_pv200)*(10000/2)

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


; **************************************************
; Final Calculation of PV2
; **************************************************
PV2 = lower_q_prime_lon/(lower_delta_p*L_lat*L_lon);
print("PV2: "+PV2+" PVU")


; **************************************************
; Final Calculation of PV3
; **************************************************
PV3 = upper_q_prime_lon/(upper_delta_p*L_lat*L_lon);
print("PV3: "+PV3+" PVU")

therm = therm_file->therm_vort(rdate,{center_lat-(deg*2):center_lat+(deg*2)},{center_lon-(deg*2):center_lon+(deg*2)})  ; 12-deg box  
avg_thermlat = dim_avg_n_Wrap(therm,0)     ; averages over the first dimension
thermvort = avg(avg_thermlat)
print("Therm. Vort.: "+thermvort)

; ***************************************************
; Write values to text file
; ***************************************************

lines(timestep-11) = center_lat+","+center_lon+","+ryyyy+","+rmm+","+rdd+","+rhh+","+PV1+","+PV2+","+PV3+","+thermvort

asciiwrite(outfile, lines)

end do

;print("Date and Values = Printed to File")
;print(" ")

print(" ")
print("***************")
print("SCRIPT COMPLETE")
print("***************")
print(" ")
end
