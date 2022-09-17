
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
  
start_frame = 10
end_frame = 0
domain = "nwatl"
type="spag"
name = "march2018wind_lows"
stall = 4
speed = 80
  
;------------------------------------------------

;  img_loc = "https://www.emc.ncep.noaa.gov/users/meg/rapv5_hrrrv4/comp/cyc/rap/"
;   img_loc = "http://www.stormsurfing.com/stormuser2/images/grib/"
img_loc = "https://www.emc.ncep.noaa.gov/users/meg/gefsv12/retros/march2018wind/dprogdt/"

img_url = "/nfs/lb11/abentley/www/test/images/"
system("'rm' "+img_url+"standard_*.png")

alt_end_frame = end_frame-stall
print("alt_end_frame: "+alt_end_frame)

  do i = start_frame,alt_end_frame,1
  j = 200 - i
;  j = i + 10
;  j = (i*6)
  print("j: "+j)


  if i .ge. end_frame then
    print("i: "+i+" j:"+j)
    system("wget "+img_loc+"gefs_nwatl_lows_march2018wind_"+i+".png")
    system("cp gefs_nwatl_lows_march2018wind_"+i+".png "+img_url+"standard_"+j+".png")
  else
    print("Last "+stall+" images! End frame: "+end_frame) 
    system("cp gefs_nwatl_lows_march2018wind_0.png "+img_url+"standard_"+j+".png")
  end if
end do 
  
  ;256x194

  gif_create = "convert -delay "+speed+" "+img_url+"standard_*.png -loop 0 +repage "+img_url+name+".gif"   
  system(gif_create)
;  system("'rm' "+img_url+"standard_*.png")

  print("Finished Tweet Gif!")
  
  end
