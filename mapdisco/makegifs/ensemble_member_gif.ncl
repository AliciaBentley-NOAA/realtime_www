
  ;************************************************
  ;     tweet_archive_gfs.ncl
  ;
  ;     Author: Alicia Bentley
  ;		Date: 6 July 2017
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
  
;  img_loc = "/nfs/lb11/abentley/www/realtime/images/northamer/850t_anom/"
  img_loc = "/nfs/lb11/abentley/www/phd/redoEWEs/GEFS/test_track/"
;  img_loc = "/nfs/lb11/abentley/www/test/images/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
;  system("'rm' "+img_url+"dt_2pvu_*.gif")
  
  do i = 0,6,1
;  j = 200 - i
  j = i + 100
  system("cp "+img_loc+"EWE_1993031400_120h_ens0_"+i+".gif "+img_url+"standard_"+j+".png")
  
;  system("cp "+img_loc+"2m_temp_"+i+".png "+img_url+"standard_"+j+".png")
  end do
  
  ;256x194
  
  gif_create = "convert -delay 80 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"SS93_AAVORT_v2.gif" 
  system(gif_create)
  system("'rm' "+img_url+"*.png")
  
  print("Finished Tweet Gif!")
  
  end