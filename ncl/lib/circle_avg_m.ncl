;******************************************************************************
; circle_avg_m.ncl
; Alicia M. Bentley (ambentley@albany.edu) - Adapted from P. Papin and A. Brammer
; Last Updated: 23 June 2017
; 
; Description: Performs radial averaging given a distance in km.
;
;******************************************************************************

external bx01 "/nfs/home11/grad/2011/abentley/ncl/lib/box_average.so"

undef("circle_avg_m")
function circle_avg_m(x,r)
local dims, ndims, i
begin

dims = dimsizes(x)
ndims = dimsizes(dims)

ret = x
ret = default_fillvalue(typeof(x))

if ndims.eq.2 then
  bx01::circle_avg_m(x, ret, x&lat, dims(ndims-1), dims(ndims-2),r)
  else if ndims.eq.3 then
    do i=0, dims(0)-1
      bx01::circle_avg_m(x(i,:,:), ret(i,:,:), x&lat, dims(ndims-1), dims(ndims-2), r )
    end do
  else
    print("only supports 2 or 3 dimension arrays")
  end if
end if
ret@smoothed = "Smoothed over radius of "+r+" km"
ret@_FillValue = default_fillvalue(typeof(x))
return(ret)
end