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

;move = "no"
move = "yes"

;toplot = "no"
toplot = "yes"

image = "mslp_jet"

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
	
	do run = 186,0,6
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

		prun = run+6		
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





;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------



if move .eq. "yes" then

start_img = 57    ; first image to move
end_img = 89	 ; last image to move

; First list is all possible domain options
folder = (/"conus","northamer","pacific","atlantic"/)   
;folder = (/"india"/)    
enddomain = dimsizes(folder)

; First list is all possible variable options    
variable = image    
endvariable = dimsizes(variable)

;*********************

dir_in = "/lb11/abentley/www/realtime/images/"
dir_out = "/lb11/abentley/www/realtime/dprogdt/images/"    ; change to the directory you want to put images in

do x = 0,enddomain-1
	domain = folder(x)
	print("Moving GFS images to d(prog)/dt timeslots for ("+domain+") and ("+variable+")")

	do y = 0,endvariable-1
	
		image = variable(y)	
		system("mkdir "+dir_out+domain+"/")	
		system("mkdir "+dir_out+domain+"/"+variable+"/")
        system("mkdir "+dir_out+domain+"/"+variable+"/p000/")
		
			do number = start_img,end_img,1
				minus_number = number - 1
				new_number = number-57
			
				from = dir_in+domain+"/"+variable+"/"+variable+"_"+number+".png"
				to   = dir_out+domain+"/"+variable+"/p000/image_"+new_number+".png"

				system("'cp' "+from+" "+to) 
				print("Copied "+from+" to "+to)

			end do     ; end number

end do     ; end name
end do     ; end domain

end if ; if move .eq. "yes"

;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------

if toplot .eq. "yes" then

	print(" ")
	timeUnits = "hours since 1800-01-01 00:00:00"

	datestr = systemfunc("date")
	print("datestr: "+datestr)

	quote = inttochar(34) 
	cyyyy = stringtoint(systemfunc("date "+quote+"+%Y"+quote))
	cmm = stringtoint(systemfunc("date "+quote+"+%m"+quote))
	cdd = stringtoint(systemfunc("date "+quote+"+%d"+quote))
	chh = stringtoint(systemfunc("date "+quote+"+%H"+quote))
	cdate = cd_inv_calendar(cyyyy,cmm,cdd,chh,00,00,timeUnits,0)

print("chh: "+chh)

	if (chh .ge. 4) .and. (chh .lt. 10) then
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,00,00,00,timeUnits,0)
    	hr = 00
	else if (chh .ge. 10) .and. (chh .lt. 16) then
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,06,00,00,timeUnits,0)
    	hr = 06
	else if (chh .ge. 16) .and. (chh .lt. 22) then
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,12,00,00,timeUnits,0)
    	hr = 12
	else if (chh .ge. 22) .or. (chh .lt. 4) then
		if (chh .lt. 5) then
			cdd = cdd - 1
		end if
    	sdate = cd_inv_calendar(cyyyy,cmm,cdd,18,00,00,timeUnits,0)
    	hr = 18
	end if
	end if
	end if
	end if

;print("GFS Forecast: "+hr+"Z run")
;sdate = cd_inv_calendar(2018,4,14,6,00,00,timeUnits,0)
print("Initialized on sdate: "+ut_string(sdate,""))
    
imgcount = 57			;;; this starts the image count at 57 (analysis)

;--------------------------------------------
; Print date of last completed run to file
;--------------------------------------------

print("chh: "+chh)

	if (chh .ge. 4) .and. (chh .lt. 10) then
    	savedate = cd_inv_calendar(cyyyy,cmm,cdd,00,00,00,timeUnits,0)
    	hr = 00
	else if (chh .ge. 10) .and. (chh .lt. 16) then
    	savedate = cd_inv_calendar(cyyyy,cmm,cdd,06,00,00,timeUnits,0)
    	hr = 06
	else if (chh .ge. 16) .and. (chh .lt. 22) then
    	savedate = cd_inv_calendar(cyyyy,cmm,cdd,12,00,00,timeUnits,0)
    	hr = 12
	else if (chh .ge. 22) .or. (chh .lt. 4) then
		if (chh .lt. 5) then
			cdd = cdd
		end if
    	savedate = cd_inv_calendar(cyyyy,cmm,cdd,18,00,00,timeUnits,0)
    	hr = 18
	end if
	end if
	end if
	end if
	
;	savedate = cd_inv_calendar(2018,4,6,18,00,00,timeUnits,0)

print("savedate: "+ut_string(savedate,""))
	
save_date = ut_string(savedate,"%Y%N%D")
print("save_date: "+save_date)
save_hh = ut_string(savedate,"%H")
print("save_hh: "+save_hh)

dateout = save_date+save_hh
print("dateout: "+dateout)

fileout = "/lb11/abentley/www/test/lastdate.txt"
print("fileout: "+fileout)
system("'rm' /lb11/abentley/www/test/lastdate.txt")
asciiwrite(fileout, dateout)

end if ; toplot .eq. "yes"

;***********************************************************************
;***********************************************************************

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
