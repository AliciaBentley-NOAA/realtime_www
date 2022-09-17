
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
  
  img_loc = "https://www.glerl.noaa.gov/res/glcfs/glsea/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
  system("'rm' "+img_url+"*.gif")
  
  do i = 0,16,1
  		if i .lt. 10 then
  			t = "0"+i
  			print(t)
  		else
  			t = i
  		end if
  	
  		j = 200-i

  system("wget "+img_loc+"lglsea-"+t+".png")
  system("mv lglsea-"+t+".png "+img_url+"standard_"+j+".png") 

  end do
  
  ;256x194
  
  gif_create = "convert -delay 26 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"jet.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")
  
  end