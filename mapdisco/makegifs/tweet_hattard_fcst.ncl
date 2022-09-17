
  ;************************************************
  ;     gif_create.ncl
  ;
  ;     Author: Philippe Papin
  ;		Date: 1-04-14
  ;		
  ;     simple script that uses convert
  ;     option in ImageMagik to make animations
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
  
  img_loc = "/home11/ugrad/2010/hattard/web/realtime/nh_strat/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
  do i = 1,21,2
  j = 100+i
  system("cp "+img_loc+"10_nh_stanom_"+i+".png "+img_url+"standard_"+j+".png")
  end do
  
  ;256x194
  
  gif_create = "convert -delay 30 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"awb.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")
  
  end