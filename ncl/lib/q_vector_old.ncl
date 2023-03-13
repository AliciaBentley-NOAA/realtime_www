;************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;************************************************************************************

;************************************************************************************
;This script defines an NCL procedure that calculates Q-vectors and 
;Q-vector forcing (i.e., the rhs of the Q-vector form of the QG omega equation) using
;center finite differencing. 
;
;Calculations follow equations from Hoskins and Pedder (1980), and Keyser et al. 1992.,
; and Martin (2006) text book
;
; Inputs:
;     t  - air temperature (K) [3D, 4D, or 5D]
;     z - geopotential height (m) [3D, 4D, or 5D]
;    np - desired number of passes of 9-point smoother to apply to geopotential height 
; 				and temp fields prior to calculating derivatives
;
; Outputs:   
;   q1, q2 - zonal and meridional components of Q-vector (K m^-1 s^-1) [3D, 4D, or 5D]
;   qn1, qn2 – zonal and meridional components of Qn-vector (K m^-1 s^-1) [3D, 4D, or 5D]
;   qs1, qs2 – zonal and meridional components of Qs-vector (K m^-1 s^-1) [3D, 4D, or 5D]   
;   dv, dvn, dvs - rhs of Q-vector form of QG omega eq. (Q, Qn, and Qs forcings for 
;                  vertical motion (Pa^-1 s^-3) [3D, 4D, or 5D]
;              
; All arrays must be dimensioned (lev,lat,lon), (time,lev,lat,lon), or (
; ensemble,time,lev,lat,lon) and MUST all have same dimensions!
;
; Script adapted from Q-vector script provided by Ben Moore
; Last updated: April 2016
;************************************************************************************

undef("Q_vector_natural")
procedure Q_vector_natural (t:numeric,z:numeric,np:numeric,q1:numeric,q2:numeric,qn1:numeric,qn2:numeric,qs1:numeric,qs2:numeric,dv:numeric,dvn:numeric,dvs:numeric)

local theta, pc, Rcpd, lat, lon, R, c_pd, x, uvg, ug, vg, rank, dimsv,omega,rad,\ 
p,unit_conv,ugrad_lat,ugrad_lon,vgrad_lat,vgrad_lon,tgrad_lat,tgrad_lon,vg_sm,ug_sm,\ 
theta_sm,nlat,nlon,dlat,dlon,dX,nl,dY,z_sm,mag_grad_theta,h

begin

c_pd = 1004. ; specific heat at constant pressure for air [approx 1004 J/(kg-K)]
R = 287. ; specific gas constant for air [J/(kg-K)]
Rcpd = R/c_pd
rad    = 4.0*atan(1.0)/180.0 ; convert to radians
omega = 7.2921e-5
dimsv = dimsizes(t)
rank  = dimsizes(dimsv)
lat = z&$z!(rank-2)$
lon = z&$z!(rank-1)$	
p0 = 100000.

p = t&$t!(rank-3)$ ;array of pressure levels

if((p@units.eq."mb" .or. p@units.eq."MB"   .or. \
						  p@units.eq."millibar"    .or. \
						  p@units.eq."millibars"   .or. \
						  p@units.eq."hPa"  .or. \
						  p@units.eq."HPA"  .or. \
						  p@units.eq."hPA"  .or. \
						  p@units.eq."hpa" )) then
	unit_conv = 100.  ;convert hPa to Pa
else
	unit_conv = 1.
end if

pc = conform(t,p,rank-3)
pc = pc*unit_conv
;print(pc)
;print(p0)

;calculate potential temperature
theta = t
theta = t*(p0/pc)^Rcpd 
;print(theta)

theta_sm = theta
z_sm = z

;smooth theta and z
do x=0,np-1
z_sm = smth9_Wrap(z_sm,0.5,.25,False)
theta_sm = smth9_Wrap(theta_sm,0.5,.25,False)
end do

;calculate geostrophic wind
uvg = z2geouv(z_sm,z&$z!(rank-2)$,z&$z!(rank-1)$,0)

;print(rank)

if(rank.eq.3) then
ug = uvg(0,:,:,:)
vg = uvg(1,:,:,:)
end if

if(rank.eq.4) then
ug = uvg(0,:,:,:,:)
vg = uvg(1,:,:,:,:)
end if

if(rank.eq.5) then
ug = uvg(0,:,:,:,:,:)
vg = uvg(1,:,:,:,:,:)
end if

copy_VarCoords(z,ug)
copy_VarCoords(z,vg)

ug_sm = ug
vg_sm = vg

;arrays to hold gradient information
ugrad_lat = vg
ugrad_lon = ug
vgrad_lat = vg
vgrad_lon = vg
tgrad_lat = theta
tgrad_lon = theta

;************************************************
;computing gradients of theta and wind
;************************************************

if(rank.eq.3) then ;if data are 3D
	nlat = dimsizes(lat)
	dlon = (lon(2)-lon(1))*rad
	dlat = (lat(2)-lat(1))
	
	do nl=0,nlat-1                      ; loop over each latitude
		dX = 6378388.*cos(0.0174533*lat(nl))*dlon  ; constant at this latitude
		tgrad_lon(:,nl,:) = center_finite_diff (theta_sm(:,nl,:), dX , False,0)
		ugrad_lon(:,nl,:) = center_finite_diff (ug_sm(:,nl,:), dX , False,0)
		vgrad_lon(:,nl,:) = center_finite_diff (vg_sm(:,nl,:), dX , False,0)
	end do

	dY = dlat*111200.0 ;m/deg lat

	tgrad_lat = center_finite_diff_n (theta_sm, dY , False,0,2)
	ugrad_lat = center_finite_diff_n (ug_sm, dY, False,0,2)
	vgrad_lat = center_finite_diff_n (vg_sm, dY, False,0,2)	
end if


if(rank.eq.4) then ;if data are 4D
	nlat = dimsizes(lat)
	dlon = (lon(2)-lon(1))*rad 
	dlat = (lat(2)-lat(1))
	
   do nl=0,nlat-1                      ; loop over each latitude
		dX = 6378388.*cos(0.0174533*lat(nl))*dlon  ; constant at this latitude
		tgrad_lon(:,:,nl,:) = center_finite_diff (theta_sm(:,:,nl,:), dX , False,0)
		ugrad_lon(:,:,nl,:) = center_finite_diff (ug_sm(:,:,nl,:), dX , False,0)
		vgrad_lon(:,:,nl,:) = center_finite_diff (vg_sm(:,:,nl,:), dX , False,0)
	end do

	dY = dlat*111200.0 ;m/deg lat

	tgrad_lat = center_finite_diff_n (theta_sm, dY , False,0,2)
	ugrad_lat = center_finite_diff_n (ug_sm, dY, False,0,2)
	vgrad_lat = center_finite_diff_n (vg_sm, dY, False,0,2)
end if


if(rank.eq.5) then  ;if data are 5D
	nlat = dimsizes(lat)
	dlon = (lon(2)-lon(1))*rad
	dlat = (lat(2)-lat(1))
	
   do nl=0,nlat-1                      ; loop over each latitude
		dX = 6378388.*cos(0.0174533*lat(nl))*dlon  ; constant at this latitude
		tgrad_lon(:,:,:,nl,:) = center_finite_diff (theta_sm(:,:,:,nl,:), dX , False,0)
		ugrad_lon(:,:,:,nl,:) = center_finite_diff (ug_sm(:,:,:,nl,:), dX , False,0)
		vgrad_lon(:,:,:,nl,:) = center_finite_diff (vg_sm(:,:,:,nl,:), dX , False,0)
	end do

	dY = dlat*111200.0 ;m/deg lat

	tgrad_lat = center_finite_diff_n (theta_sm, dY , False,0,3)
	ugrad_lat = center_finite_diff_n (ug_sm, dY, False,0,3)
	vgrad_lat = center_finite_diff_n (vg_sm, dY, False,0,3)
end if
;************************************************

; Calculate potential temperature gradient magnitude 
mag_grad_theta = sqrt( (tgrad_lon)^2 + (tgrad_lat)^2 )
;mag_grad_theta = mag_grad_theta + 1e-35 ; prevent division by zero error
mag_grad_theta = where(mag_grad_theta.eq.0,tgrad_lat@_FillValue,mag_grad_theta)

;calculate Q vector components following equation 2.2 from Keyser et al. (1992)
q1 = -1.0*((ugrad_lon*tgrad_lon)+(vgrad_lon*tgrad_lat))
q2 = -1.0*((ugrad_lat*tgrad_lon)+(vgrad_lat*tgrad_lat))

;Calculate Qn vector components following equation 6.49 from Martin (2006) text book

qn1 = ((q1*tgrad_lon + q2*tgrad_lat)/mag_grad_theta)*(tgrad_lon/mag_grad_theta)
qn2 = ((q1*tgrad_lon + q2*tgrad_lat)/mag_grad_theta)*(tgrad_lat/mag_grad_theta)

;Calculate Qs vector components following equation 6.50 from Martin (2006) text book

qs1 = ((-q1*tgrad_lat + q2*tgrad_lon)/mag_grad_theta)*(-tgrad_lat/mag_grad_theta)
qs2 = ((-q1*tgrad_lat + q2*tgrad_lon)/mag_grad_theta)*(tgrad_lon/mag_grad_theta)


;compute Q vector forcing term (i.e., Q-vector convergence) following equation 2.1 from
;Keyser et al. (1992)

h = (R/p0)*((p0/pc)^(1./1.4))

dv  = -2.*h*uv2dv_cfd(q1,q2,lat,lon,0)
;printVarSummary(dv)

;compute Qn vector forcing term (i.e., Qn-vector convergence)
dvn  = -2.*h*uv2dv_cfd(qn1,qn2,lat,lon,0)


;compute Qs vector forcing term (i.e., Qs-vector convergence)
dvs  = -2.*h*uv2dv_cfd(qs1,qs2,lat,lon,0)


copy_VarCoords(t,q1)
copy_VarCoords(t,q2)
copy_VarCoords(t,qn1)
copy_VarCoords(t,qn2)
copy_VarCoords(t,qs1)
copy_VarCoords(t,qs2)
copy_VarCoords(t,dv)
copy_VarCoords(t,dvn)
copy_VarCoords(t,dvs)

return(q1)
return(q2)
return(qn1)
return(qn2)
return(qs1)
return(qs2)
return(dv)
return(dvn)
return(dvs)

end