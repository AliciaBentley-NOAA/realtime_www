; ===========================================
; Moving archive and plotting GFS forecast 
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

;shift = "no"
shift = "yes"

image = "6hprecip"

;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------

if shift .eq. "yes" then

start_img = 0    ; first image to move
end_img = 32	 ; last image to move

; First list is all possible domain options
folder = (/"conus","northamer","pacific","atlantic"/)   
;folder = (/"india"/)    
enddomain = dimsizes(folder)

; First list is all possible variable options    
variable = image    
endvariable = dimsizes(variable)

;*********************


dir_out = "/lb11/abentley/www/realtime/dprogdt/images/"    ; change to the directory you want to put images in

do x = 0,enddomain-1
	domain = folder(x)
	print("Moving GFS images to the previous model run for ("+domain+") and ("+variable+")")
	
	do run = 12,192,6
;		print("run: "+run)
		if run .lt. 10 then
			pXXX = "p00"+run
		end if
		if (run .ge. 10) .and. (run .lt. 100) then
			pXXX = "p0"+run
		end if
		if run .ge. 100 then
			pXXX = "p"+run
		end if
		print("pXXX: "+pXXX)

		prun = run-6		
;		print("prun: "+prun)
		if prun .lt. 10 then
			pYYY = "p00"+prun
		end if
		if (prun .ge. 10) .and. (prun .lt. 100) then
			pYYY = "p0"+prun
		end if
		if prun .ge. 100 then
			pYYY = "p"+prun
		end if
		print("pYYY: "+pYYY)
		

	do y = 0,endvariable-1
	
		image = variable(y)	
		system("mkdir "+dir_out+domain+"/")	
		system("mkdir "+dir_out+domain+"/"+variable+"/")
        system("mkdir "+dir_out+domain+"/"+variable+"/"+pXXX+"/")
        system("mkdir "+dir_out+domain+"/"+variable+"/"+pYYY+"/")
		
			do number = start_img,end_img,1
				minus_number = number - 1
			
				from = dir_out+domain+"/"+variable+"/"+pXXX+"/image_"+number+".png"
				to   = dir_out+domain+"/"+variable+"/"+pYYY+"/image_"+number+".png"

				system("'cp' "+from+" "+to) 
				print("Copied "+from+" to "+to)

			end do     ; end number

end do     ; end name
end do 	   ; end run
end do     ; end domain

end if ; if shift .eq. "yes"

;***********************************************************************
;***********************************************************************

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
