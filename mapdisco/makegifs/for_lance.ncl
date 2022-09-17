
  ;************************************************
  ;     tweet_archive_gfs.ncl
  ;
  ;     Author: Alicia Bentley
  ;		Date: 1 August 2016
  ;    
  ;*************************************************

  ;***********************SCRIPTS*******************

  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

  ;***********************SCRIPTS******************* 


  begin

  print("Start Making Tweet Gif!")
  
;--------------------------------------------------

folder2 = (/"conus","northamer","pacific"/)
enddomain2 = dimsizes(folder2)
do d = 0,enddomain2-1
domain = folder2(d)

folder1 = (/"mslp_jet","dt_2pvu","rel_vort","850_thetae","6hprecip"/)
enddomain1 = dimsizes(folder1)
do t = 0,enddomain1-1
plot_type = folder1(t)

set = False

print(" ")
print("Plotting maps for: "+domain)

;--------------------------------------------------

run = 192
end_run = 90
start_frame = 17
end_frame = 0
alt_end_frame = end_frame-6
print("alt_end_frame: "+alt_end_frame)
speed = 25
gif_name = "dprogdt_2019102412_"+domain+"_"+plot_type

;--------------------------------------------------

  img_loc = "/nfs/lb11/abentley/www/realtime/dprogdt/images/"+domain+"/"+plot_type+"/"
  img_url = "/nfs/lb11/abentley/www/save/"

;--------------------------------------------------

  do i = start_frame,alt_end_frame,1
  j = 200 - i
;  j = i + 100
;  print("j: "+j)
  
  if i .eq. start_frame then
  	run = run - 0
  else 
  	run = run - 6
  end if
;  print("i: "+i+" | run: "+run)
  
		if run .lt. 10 then
			pXXX = "p00"+run
		end if
		if (run .ge. 10) .and. (run .lt. 100) then
			pXXX = "p0"+run
		end if
		if run .ge. 100 then
			pXXX = "p"+run
		end if
		print("i: "+i+" | pXXX: "+pXXX)

  if i .ge. end_frame then
    system("cp "+img_loc+pXXX+"/image_"+i+".png "+img_url+"standard_"+j+".png")
  else
    print("Last 6 images!") 
    system("cp "+img_loc+pYYY+"/image_"+save_i+".png "+img_url+"standard_"+j+".png")
  end if
  
		if (run .eq. end_run) then
			print("run .eq. end_run")
			print("i: "+i)
			save_i = i
			print("save_i: "+save_i)
			i = end_frame
			if set .eq. False then
			   pYYY = pXXX
			   set = True
			end if
		end if   
  
end do

  
  ;256x194

  gif_create = "convert -delay "+speed+" "+img_url+"standard_*.png -loop 0 +repage "+img_url+gif_name+".gif"   
;  gif_create = "convert -delay 50 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"SS93_track_animation.gif" 

system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")

end do   ;plot_type
end do   ;domain

  end
