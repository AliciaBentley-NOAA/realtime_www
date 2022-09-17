
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
  
;  img_loc = "/nfs/lb11/abentley/www/realtime/images/NH/500g_anom/"
;  img_loc = "/nfs/lb11/abentley/www/research_images/gefs_prac/dprogdt/"
  img_loc = "/nfs/lb11/abentley/www/test/images/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
;  system("'rm' "+img_url+"dt_2pvu_*.gif")

var = "6hprecip"
start_frame = 1
end_frame = 32
name = "westcoast"
slowness = 25       ; Larger number is slower animation
alt_end_frame = end_frame+6
print("alt_end_frame: "+alt_end_frame)

  do i = start_frame,alt_end_frame,1
  ;  j = 200 - i
    j = i + 100
      print("j: "+j)

        if i .le. end_frame then
	    system("cp "+img_loc+var+"_"+i+".gif "+img_url+"standard_"+j+".png")
	      else
	          print("Last 4 images!")
		      system("cp "+img_loc+var+"_"+end_frame+".gif "+img_url+"standard_"+j+".png")
		        end if
			end do
  
  ;256x194

  gif_create = "convert -delay "+slowness+" "+img_url+"standard_*.png -loop 0 +repage "+img_url+name+".gif"   

;  gif_create = "convert -delay 50 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"SS93_track_animation.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")
  
  end
