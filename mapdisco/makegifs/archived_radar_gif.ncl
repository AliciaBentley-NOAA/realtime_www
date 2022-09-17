
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
  
  img_loc = "http://www2.mmm.ucar.edu/imagearchive1/RadarComposites/mid_atlantic/20160623/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
;  system("'rm' "+img_url+"*.gif")
  
  do i = 0,23,1
  		if i .lt. 10 then
  			t = "0"+i
;  			print(t)
  		else
  			t = i
  		end if
  		
  		do k = 0,30,30
  			if k .lt. 10 then
  				h = "0"+k
;  				print(h)
  			else
  				h = k
  			end if
  	
  		j = i+100
  		
  		print("Image to get: "+img_loc+"mid_atlantic_20160623"+t+h+".gif")

  		system("wget "+img_loc+"mid_atlantic_20160623"+t+h+".gif")
  		system("mv mid_atlantic_20160623"+t+h+".gif "+img_url+"standard_"+j+".png") 

  end do ; 0,30,30	
  end do ; 0,23,0 
  
  ;256x194

  gif_create = "convert -delay 30 "+img_url+"standard_*.png -loop 0 +repage -resize 1000x1000 "+img_url+"WV_radar_loop.gif" 
  
;  gif_create = "convert -delay 30 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"WV_radar_loop.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  print("Finished Tweet Gif!")
  
  end