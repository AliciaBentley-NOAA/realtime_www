
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
  
  img_loc = "/nfs/lb11/abentley/www/test/images/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
  do i = 17,33,1
;  j = 200-i
  j = 100+i
  
  
  print("j: "+j)
  system("cp "+img_loc+"925wind_anom_"+i+".gif "+img_url+"standard_"+j+".png")
  end do
  
  ;256x194
 
;  gif_create = "convert -delay 30 "+img_url+"6hprecip_*.gif -loop 0 +repage -trim -resize 1000x1000 "+img_url+"3_twitter.gif" 
  
  gif_create = "convert -delay 20 "+img_url+"standard_*.png -loop 0 +repage -resize 1000x1000 "+img_url+"EC_EWE_animation.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  system("'rm' "+img_url+"925wind_*.gif")
  
  print("Finished Tweet Gif!")
  
  end