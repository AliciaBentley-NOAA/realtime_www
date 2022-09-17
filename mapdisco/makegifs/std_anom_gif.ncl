
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

  print("Start std_anom!")
  
  img_loc = "/nfs/lb11/abentley/www/realtime/images/northamer/"
  
  do i = 0,1
  
  if i .eq. 0 then
  	img_url = "/nfs/lb11/abentley/www/images/"
  else if i .eq. 1 then
  	img_url = "/nfs/lb11/abentley/www/realtime/images/"
  end if
  end if
  
  system("cp "+img_loc+"250wind_anom/250wind_anom_57.png "+img_url+"std_anom_1.png")
  system("cp "+img_loc+"250v_anom/250v_anom_57.png "+img_url+"std_anom_2.png")
  system("cp "+img_loc+"500g_anom/500g_anom_57.png "+img_url+"std_anom_3.png")
  system("cp "+img_loc+"pw_anom/pw_anom_57.png "+img_url+"std_anom_4.png")
  system("cp "+img_loc+"850t_anom/850t_anom_57.png "+img_url+"std_anom_5.png")
  system("cp "+img_loc+"925wind_anom/925wind_anom_57.png "+img_url+"std_anom_6.png")
  system("cp "+img_loc+"mslp_anom/mslp_anom_57.png "+img_url+"std_anom_7.png")
  
  ;256x194
  
  gif_create = "convert -delay 100 "+img_url+"std_anom_*.png -loop 0 +repage "+img_url+"std_anom.gif" 
  system(gif_create)
  system("'rm' "+img_url+"std_anom_*.png")
  
  end do
  
  print("Finished std_anom!")
  
  end