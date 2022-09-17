
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
  
  img_loc = "/nfs/lb11/abentley/www/realtime/gefs/images/conus/wind250/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
;  system("'rm' "+img_url+"dt_2pvu_*.gif")
  
  do i = 17,29,1
  j = 200 - i
  fcst_hr = (i-17)*6  
  print("fcst_hr: "+fcst_hr)
  
  if fcst_hr .lt. 10 then
  	newhr = "00"+fcst_hr
  else if fcst_hr .lt. 100 then
  	newhr = "0"+fcst_hr  
  else if fcst_hr .ge. 100 then
  	newhr = fcst_hr
  end if
  end if
  end if
  print("newhr: "+newhr)
;  j = i + 100

    system("cp "+img_loc+"/p"+newhr+"/image_"+i+".png "+img_url+"standard_"+j+".png")
  end do
  
  ;256x194

  gif_create = "convert -delay 25 "+img_url+"standard_*.png -loop 0 +repage "+img_url+"spc_day5_wind250.gif"   
;  gif_create = "convert -delay 50 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"SS93_track_animation.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")
  
  end