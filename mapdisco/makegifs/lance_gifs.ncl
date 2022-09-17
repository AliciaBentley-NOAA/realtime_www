
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
  
;  img_loc = "/nfs/lb11/abentley/www/realtime/images/northamer/850_thetae/"
;  img_loc = "/nfs/lb11/abentley/www/research_images/jan2017/subset1/pacific/mslp_jet/"
;  img_loc = "/nfs/lb11/abentley/www/research_images/jan2017/subset1/pacific/rel_vort/"
  img_loc = "/nfs/lb11/abentley/www/research_images/jan2017/subset1/pacific/700wind_pw/"
;  img_loc = "/nfs/lb11/abentley/www/test/images/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
;  system("'rm' "+img_url+"dt_2pvu_*.gif")
  
  do i = 1,56,1
;  j = 200 - i
  j = i + 100
  system("'cp' "+img_loc+"700wind_pw_"+i+".gif "+img_url+"standard_"+j+".png")
  
;  system("cp "+img_loc+"2m_temp_"+i+".png "+img_url+"standard_"+j+".png")
  end do
  
  ;256x194

  gif_create = "convert -delay 23 "+img_url+"standard_*.png -loop 0 +repage "+img_url+"pacific_pw.gif"   
;  gif_create = "convert -delay 50 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"SS93_track_animation.gif" 
  system(gif_create)
  system("'rm' "+img_url+"*.png")
;  system("'rm' "+img_url+"6hprecip*.gif")
  
  print("Finished Tweet Gif!")
  
  end