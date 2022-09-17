
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

  print("Start Subtrop!")
  
  img_loc = "/nfs/lb11/abentley/www/realtime/images/northamer/"
  
  do i = 0,1
  
  if i .eq. 0 then
  	img_url = "/nfs/lb11/abentley/www/images/"
  else if i .eq. 1 then
  	img_url = "/nfs/lb11/abentley/www/realtime/images/"
  end if
  end if
  
  system("cp "+img_loc+"mslp_jet/mslp_jet_57.png "+img_url+"standard_1.png")
  system("cp "+img_loc+"irro_wind/irro_wind_57.png "+img_url+"standard_2.png")
  system("cp "+img_loc+"dt_2pvu/dt_2pvu_57.png "+img_url+"standard_3.png")
  system("cp "+img_loc+"coupling/coupling_57.png "+img_url+"subtrop_4.png")
  system("cp "+img_loc+"350K_isen/350K_isen_57.png "+img_url+"subtrop_5.png")
  system("cp "+img_loc+"330K_isen/330K_isen_57.png "+img_url+"subtrop_6.png")
  system("cp "+img_loc+"310K_isen/310K_isen_57.png "+img_url+"subtrop_7.png")
  system("cp "+img_loc+"850_thetae/850_thetae_57.png "+img_url+"subtrop_8.png")  

  
  ;256x194
  
  gif_create = "convert -delay 100 "+img_url+"subtrop_*.png -loop 0 +repage "+img_url+"subtrop.gif" 
  system(gif_create)
  system("'rm' "+img_url+"subtrop_*.png")
  
  end do
  
  print("Finished Subtrop!")
  
  end