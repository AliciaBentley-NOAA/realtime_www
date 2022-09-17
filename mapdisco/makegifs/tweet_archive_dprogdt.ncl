
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

domain = "pacific"
plot_type = "mslp_jet"
run = 192    ;192
end_run = 0  ;0
start_frame = 32     ;32
end_frame = 0     ;0
alt_end_frame = end_frame-10
print("alt_end_frame: "+alt_end_frame)
speed = 20      ; lower is faster
gif_name = "dprogdt_2021042706_"+domain+"_"+plot_type

;--------------------------------------------------

  img_loc = "/nfs/lb11/abentley/www/realtime/dprogdt/images/"+domain+"/"+plot_type+"/"
  img_url = "/nfs/lb11/abentley/www/test/images/"

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
    print("Last 4 images!") 
    system("cp "+img_loc+"p000/image_"+save_i+".png "+img_url+"standard_"+j+".png")
  end if
  

   print("end_run: "+end_run+" | run: "+run)
                if (run-6) .eq. (end_run) then
			print("i: "+i)
			save_i = i-1
			i = end_frame
		end if   
  
end do

  
  ;256x194

  gif_create = "convert -delay "+speed+" "+img_url+"standard_*.png -loop 0 +repage "+img_url+gif_name+".gif"   
;  gif_create = "convert -delay 50 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"SS93_track_animation.gif" 

system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")
  
  end
