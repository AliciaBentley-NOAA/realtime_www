;******************************************************************************
; fgen.ncl
; Philippe Papin (ppapin@albany.edu)
; Last Updated: Oct 2nd, 2014
; 
; My attempt to calculate 2 dimensional frontogenesis (Petterson Frontogenesis)
;
; Calculated using this guide: http://www-das.uwyo.edu/~geerts/atsc5160/gem7.pdf
;
; Variables Needed: U,V,T,P
;
; Updated from "uber" jet calculations made in early 2014
;
;******************************************************************************

undef ("fgen_globe")
function fgen_globe(u,v,t,p)
local ntim, npr, nlt, nlo, ranku, rankv, rankt
begin

;;;; checking to see if you have 2d, 3d, or 4d data

ranku  = dimsizes(dimsizes(u))
  if (.not.(ranku.eq.2 .or. ranku.eq.3 .or. ranku.eq.4)) then
      print("fgen: only 3D and 4D arrays allowed: rank="+ranku)
      exit
  end if
rankv  = dimsizes(dimsizes(v))
rankt  = dimsizes(dimsizes(t))   
  if (.not.(ranku.eq.rankv .and. ranku.eq.rankt)) then
      print("fgen: u, v, t must be the same rank: ranku=" \
            +ranku+"  rankv="+rankv+"  rankt="+rankt)
      exit
  end if
  
  if (ranku.eq.2) then       ; (lat,lon)  => (0,1) > (nlt,nlo)
      nlt = 0
      nlo = 1
  end if
  if (ranku.eq.3) then       ; (lev,lat,lon)  => (0,1,2) > (npr,nlt,nlo)
      npr = 0
      nlt = 1
      nlo = 2
  end if
  if (ranku.eq.4) then       ; (tim,lev,lat,lon)  => (0,1,2,3) > (ntim,npr,nlt,nlo)
      ntim = 0
      npr = 1
      nlt = 2
      nlo = 3
  end if

  lat = u&$u!nlt$
  lon = u&$u!nlo$

  if ((lat(1)-lat(0)).le.0) then
      print("fgen: data must be in S-N order")
      exit
  end if


;;;; ok lets now try to calculate frontogenesis ;;;;;

print("calculating frontogenesis")

;;;; calculating theta
k = 0.286
if(ranku.gt.2) then
theta  = t*(100000./conform(t,p,npr))^k  ; p must be 1d array of all pressures!
else if(ranku.eq.2) then
theta  = t*(100000./p)^k  ; p must be a scaler of same isobaric level at u! 
end if
end if
copy_VarCoords(t, theta)


;;;;;;;;; Calculation of Frontogenesis in GEMPAK;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;	     FRNT  Frontogenesis  ( K / 100 km / 3 h )
;;;      FRNT ( THTA, V ) = 1/2 * CONV * MAG ( GRAD (THTA) ) *
;;;                         ( DEF * COS (2 * BETA) - DIV )
;;;                         CONV  = unit conversion factor
;;;                               = 1.08E4 * 1.E5
;;;                         BETA  = ASIN ( ( - COS (DELTA) * DDX (THTA) -
;;;                                            SIN (DELTA) * DDY (THTA) /
;;;                                            MAG ( GRAD (THTA) ) )
;;;                        DELTA = 1/2 ATAN ( SHR / STR )
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; calculating derivatives of u, v, theta

dudx = u
dudy = u
dvdx = v
dvdy = v

gradsf(u,dudx,dudy)
gradsf(v,dvdx,dvdy)

g_theta_x = theta
g_theta_y = theta
mag_grad_theta = theta

gradsf(theta,g_theta_x,g_theta_y) ; calculates gradient of theta


;;;; calculate shearing and stretching deformation, divergence and regular deformation

conv = (1.08*10^4) * (1*10^5)

shr = dvdx + dudy ;;; shear deformation
str = dudx - dvdy ;;; stretching deformation
div = dudx + dvdy ;;; divergence

str = where(str.eq.0,str@_FillValue,str) ;;;; make sure stretching isn't zero or make a missing value

delta = (0.5)*tanh( shr / str)
mag_grad_theta = sqrt( (g_theta_x)^2 + (g_theta_y)^2 )

;beta = sinh( (-1*cos(delta) * dthetadx - sin(delta) * dthetady) / (mag_grad_theta) )
beta = sinh( (-1 * cos(delta) * g_theta_x - sin(delta) *  g_theta_y / (mag_grad_theta) ) )



def = (str^2+shr^2)^0.5
fgen = 0.5*conv*mag_grad_theta*(def*cos(2*beta)-div)

;;; if everything worked, you should now have frontogenesis (K/100km/3h)
copy_VarCoords(u,fgen)
;;; now write the variable back
fgen@units = "K 100km^-1 3hr^-1"
return(fgen)
end

;-- new interface
;undef("frontogenesis_2d")
;function frontogenesis_2d\
;        (u:numeric, v:numeric, t:numeric, p:numeric)
;begin
;        ; fgen is the original function name
;  return(fgen (u,v,t,p))
;end


