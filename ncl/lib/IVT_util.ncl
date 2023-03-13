;***********************************************************************
;Herein are two NCL functions, which compute instantaneoous vertically
;integrated water vapor transport (IVT) and time-integrated IVT for a 
;specified period.  The functions should work for most all types of grids 
;provided they are in isobaric coordinates.
;
;Written by Ben Moore, bjmoore@albany.edu
;Last updated: October 2013
;
;***********************************************************************

undef("uvIVT")
function uvIVT (uwnd:numeric, vwnd:numeric,q:numeric)
;
; Compute u and v component of total column IVT 
;
;Calculation is based upon method used by Neiman et al. (2008, JHM),
; described in section 4c, page 31
;
; Nomenclature:
;     uwnd       - u-component of the flow (m/s) [3D or 4D]
;     vwnd       - v-component of the flow (m/s) [3D or 4D]
;    q       - specific humidity (kg/kg)       [3D or 4D]          
;               (lev,lat,lon) or (time,lev,lat,lon); q and u and v must have same rank!


local rank, ql, ul, uflux, IVT, comp, dum, dims, p, unit_conv

begin

dims = dimsizes(q)
rank = dimsizes(dims)

if(rank.eq.4) then
IVT = new((/2,dims(0),dims(rank-2),dims(rank-1)/),"float")
end if

if(rank.eq.5) then
IVT = new((/2,dims(0),dims(rank-4),dims(rank-2),dims(rank-1)/),"float")
end if

if(rank.eq.3) then
IVT = new((/2,dims(rank-2),dims(rank-1)/),"float")
end if

do c=0,1

	if(c.eq.0) then
	u = uwnd
	end if

	if(c.eq.1) then
	u=vwnd
	end if


	if(rank.eq.4) then 

	;extract vertical coordinate and determine units
	  p = u&$u!1$  

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


	; create arrays to hold layer values of q and u
	  ql = new((/dims(0),dims(1)-1,dims(2),dims(3)/),"float")
	  ul = ql

	  dum = u(:,0,:,:)

	; loop through all levels and compute layer values of u and q
	  do i=0,dims(1)-2
		layer_diff = abs(p(i)-p(i+1))
		ql(:,i,:,:) = dim_avg_n(q(:,i:i+1,:,:),1)/9.8*layer_diff*unit_conv
		ul(:,i,:,:) = dim_avg_n(u(:,i:i+1,:,:),1)
	  end do

	  uflux = ql*ul

	;take sum of layer fluxes to compute vertical integral of vapor flux
	  IVT(c,:,:,:) = dim_sum_n(uflux,1)

end if

	if(rank.eq.5) then 

	;extract vertical coordinate and determine units
	  p = u&$u!2$  

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


	; create arrays to hold layer values of q and u
	  ql = new((/dims(0),dims(1),dims(2)-1,dims(3),dims(4)/),"float")
	  ul = ql

	  dum = u(:,:,0,:,:)

	; loop through all levels and compute layer values of u and q
	  do i=0,dims(2)-2
		layer_diff = abs(p(i)-p(i+1))
		ql(:,:,i,:,:) = dim_avg_n(q(:,:,i:i+1,:,:),2)/9.8*layer_diff*unit_conv
		ul(:,:,i,:,:) = dim_avg_n(u(:,:,i:i+1,:,:),2)
	  end do

	  uflux = ql*ul

	;take sum of layer fluxes to compute vertical integral of vapor flux
	  IVT(c,:,:,:,:) = dim_sum_n(uflux,2)

end if

	if(rank.eq.3) then 


	;extract vertical coordinate and determine units
	  p = u&$u!0$

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

	; create arrays to hold layer values of q and u
	  ql = new((/dims(0)-1,dims(1),dims(2)/),"float")
	  ul = ql

	  dum = u(0,:,:)

	; loop through all levels and compute layer values of u and q
	  do i=0,dims(0)-2
	  
			layer_diff = abs(p(i)-p(i+1))
			ql(i,:,:) = dim_avg_n(q(i:i+1,:,:),0)/9.8*layer_diff*unit_conv
			ul(i,:,:) = dim_avg_n(u(i:i+1,:,:),0)
			
	  end do

	  uflux = ql*ul

	;take sum of layer fluxes to compute vertical integral of vapor flux
	  IVT(c,:,:) = dim_sum_n(uflux,0)

	end if    ; rank

end do    ; c

;Assigning metadata here

 IVT@units = "kg/m/s"
 IVT@long_name = "u and v-component of IVT"
 
 if(rank.eq.4) then
	 IVT!1 = dum!0
	 IVT&$dum!0$ = dum&$dum!0$
 end if
 
 if(rank.eq.5) then
	 IVT!1 = dum!0
	 IVT&$dum!0$ = dum&$dum!0$
	 	 IVT!2 = dum!1
	 IVT&$dum!1$ = dum&$dum!1$
 end if

IVT!(rank-2) = dum!(rank-3)
IVT!(rank-1) = dum!(rank-2)

IVT&$IVT!(rank-2)$ = dum&$dum!(rank-3)$
IVT&$IVT!(rank-1)$ = dum&$dum!(rank-2)$
IVT!0 = "component"

  return( IVT )

end

;-----------------------------------------------------------

undef("timeintIVT")
function timeintIVT (t:numeric, uIVT:numeric, vIVT:numeric, dt:numeric)
;
;
;This function will integrate IVT with respect to time over a specified period
;
; Nomenclature:
;     t       - times of interest  [1D], must be monotonically increasing 
;             and in appropriate units
;    uIVT, vIVT       - components of IVT (kg/m/s)       [3D]          
;           (time,lat,lon);
;     dt   - number of hours between time steps for t array



local ntimes, IVT_temp, tiIVT, dimIVT_temp, IVT_temp2, dum, dimsIVT

begin

ntimes = dimsizes(t)

dimsIVT = dimsizes(uIVT)


tiIVT = new((/2,dimsIVT(1),dimsIVT(2)/),"float")

do c=0,1  ;Loop through both components of IVT

	if(c.eq.0) then
		IVT = uIVT
	end if

	if(c.eq.1) then
		IVT = vIVT
	end if



	dum = IVT(0,:,:)

	IVT_temp = IVT({t},:,:)

	dimIVT_temp = dimsizes(IVT_temp)
	IVT_temp2 = new((/ntimes-1,dimIVT_temp(1),dimIVT_temp(2)/),"float")

; Trapazoidal integration here
	do z=0,ntimes-2

		IVT_temp2(z,:,:) = (IVT_temp(z,:,:)+IVT_temp(z+1,:,:))/2.

	end do

	tiIVT(c,:,:) = (dim_sum_n(IVT_temp2,0))*tofloat(dt)*60.*60.

end do

;Assign metadata

tiIVT!1 = dum!0
tiIVT!2 = dum!1
tiIVT&$tiIVT!1$ = dum&$dum!0$
tiIVT&$tiIVT!2$ = dum&$dum!1$
tiIVT!0 = "component"

tiIVT@units = "kg/m"
tiIVT@long_name = "u and v-components of time-integrated IVT"


return (tiIVT)

end
