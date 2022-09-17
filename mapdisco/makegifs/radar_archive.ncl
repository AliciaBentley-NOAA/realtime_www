
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
  
  img_loc = "http://operations.nysmesonet.org/~nbassill/archive/2017/03/14/radar/"
  img_url = "/nfs/lb11/abentley/www/test/images/"
  
;  system("'rm' "+img_url+"*.gif")
  
  counter = 100
  
do h = 12,21,1 
;  print(h) 
  do i = 0,50,10
  		if i .lt. 10 then
  			m = "0"+i
;  			print(m)
  		else
  			m = i
;  			print(m)
  		end if
  	
;  		j = 200-counter
  		j = counter

  system("wget "+img_loc+"20170314"+h+m+"-radar.gif")                             ;201703141200-radar.gif
  system("mv 20170314"+h+m+"-radar.gif "+img_url+"internet_"+j+".png") 
  
  		counter = counter + 1

  end do
end do
  
  ;256x194
  
  gif_create = "convert -delay 15 "+img_url+"internet_*.png -loop 0 +repage -resize 1000x1000 "+img_url+"pi_day_radar.gif" 
  system(gif_create)
  system("'rm' "+img_url+"internet_*.png")
  
  print("Finished Tweet Gif!")
  
  end