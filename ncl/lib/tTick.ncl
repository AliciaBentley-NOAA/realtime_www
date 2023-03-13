;******************************************************************************
; Obtained from http://www.ncl.ucar.edu/Support/talk_archives/2007/0763.html
; Modified May 2008 by Carl Schreck (carl@atmos.albany.edu)
;   Added support for minor ticks
;   Added resources for stride of major and minor tick 
; Modified April 2009 by Carl Schreck (carl@atmos.albany.edu)
;   Replaced "mod" function call on line 279 with modulus operator %
;******************************************************************************
;
undef("tTick")

procedure tTick(time:numeric,resplot:logical,restick:logical)
;******************************************************************************
; Purpose: Draw tickmark labels in the format of date/time on an axis.
;
; Arguments:
; time: The variable containing the values of time. This variable should
; have an attribute named "units". In other words, this variable
; holds the values of the coordinate axis 'time' along with the units.
;
; resplot: The general plot resources. This variable should then be used
; in the function to plot. It can have any other attributes, as
; usual. Only tmZZMode, tmZZValues and tmZZLabels are changed
; inside this procedure (where ZZ is one of XB, XT, YL or YR
; depending on which axis to mark).
;
; restick: Resources for the time axis tick formats. If this variable is
; true then its attributes are used to format the time axis.
; Valid attributes are:
; Format: a string specifying the format of the tick labels.
; This string is parsed as follows: the '%' acts as
; the escape character. The single character after every
; '%' is formatted according to the rule:
; Y => 4-digit year (e.g., 2007).
; y => 2-digit year (e.g., 07).
; C => CAPITAL month abbreviation (e.g., JUN).
; c => Small month abbreviation (e.g., Jun).
; F => CAPITAL full month (e.g., JUNE).
; f => Small full month (e.g., June).
; N => 2-digit month (e.g., 06).
; n => 1 or 2 digit month (e.g., 6 for June, 12 for December).
; D => 2-digit day (e.g., 04).
; d => 1 or 2 digit day (e.g., 4)
; H => 2-digit hour (e.g., 09).
; h => 1 or 2 digit hour (e.g., 9 or 11).
; M => 2 digit minute (e.g., 08).
; m => 1 or 2 digit minute (e.g., 07 or 56).
; S => 2 digit second (e.g., 02).
; s => 1 or 2 digit second (e.g., 2 or 23).
; Any character at any other place in the format string
; is drawn as is.
; NOTE: a '%' can be drawn using "%%".
; In case Format is absent, a minimal algorithm exists
; which tries to determine the format string depending
; on the length and values of the date-time.
;
; TickAxis: string. Can have values "XB", "XT", "YL", or "YR"
; depending on which axis is to label. Default is "XB".
;
; TickAt: integer. An Mx6 array containing M date-time values where
; tick labels should be marked. The 2nd dimension should
; contain the values of year, month, day, hour, minute
; and second in this order.
; If this attribute is missing, the script tries to
; determine the axis values for tick from the length
; of the data.
;
; nTicks: Approximate number of tick labels. Used only when
; TickAt is absent. Default value of this parameter is 4.
;
; MajorStride: Stride of time for Major ticks.  Note that this trumps nTicks
;
; MinorStride: Stride of time for Minor ticks
;
; Side effects:
; Values of tmZZMode, tmZZValues, tmZZMinorValues, and tmZZLabels (ZZ = one of
; XB, XT, YL, YR) are set. Also resplot is set to True inside this procedure.
;
; Examples:
; time = ... ; the time variable
; y = ... ; variable to plot
; resplot@... = ... ; general resources variable.
;
; #1
; resplot = True
; restick = True
; restick@Format = "%c%y"
; tTick(time,resplot,restick) ; call the formating procedure
; plot = gsn_csm_xy(wks,time,y,resplot) ; will produce bottom x-axis ticks
; as CccYy (Apr98, May98 etc).
;
; #2
; resplot = True
; restick = True
; restick@Format = "%N/%Y"
; restick@TickAxis = "YL"
; tTick(time,resplot,restick)
; plot = gsn_csm_xy(wks,y,time,resplot) ; will produce left y-axis ticks
; as NN/YYYY (04/1998, 05/1998 etc).
;
; #3
; resplot = True
; restick = True
; restick@TickAt = (/(/1998,4,16,0,0,0/), \
; (/1998,6,16,0,0,0/), \
; (/1998,8,16,0,0,0/), \
; (/1998,10,16,0,0,0/), \
; (/1998,12,16,0,0,0/), \
; (/1999,2,16,0,0,0/)/)
; tTick(time,resplot,restick)
; plot = gsn_csm_xy(wks,time,y,resplot) ; will produce bottom x-axis ticks
; at Apr 16, 1998, June 16, 1998 etc. Format will be determined
; in the procedure. Specify Format attribute to override the default.
;
; #4
; ...
; resplot@Format = "%H:%M:%S" will produce HH:MM:SS kind of time formatting.
; To specify month/day as well, use
; resplot@Format = "%N/%D %H:%M:%S"
;
; #5
; To write hour values as "HH:00 Hours" use
; resplot@Format = "%H:00 Hours"
;******************************************************************************

local plot, ymdhms0, taxisvalues, minorValues, ymdhms1, ymdhms1i, format, months, fmonths, inside

begin

 months = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
 fmonths = (/"","January","February","March","April","May","June","July","August","September","October","November","December"/)

 ; check input
 if (.not. isatt(time,"units")) then
  print("tTick: The variable containing time values must have a 'units' attribute.")
  return
 end if

 resplot = True

 if (restick) then
  if (.not. isatt(restick,"TickAxis")) then
   restick@TickAxis = "XB"
  end if

  if (restick@TickAxis .eq. "XB") then
   resplot@tmXBMode = "Explicit"
  end if
  if (restick@TickAxis .eq. "XT") then
   resplot@tmXTMode = "Explicit"
  end if
  if (restick@TickAxis .eq. "YL") then
   resplot@tmYLMode = "Explicit"
  end if
  if (restick@TickAxis .eq. "YR") then
   resplot@tmYRMode = "Explicit"
  end if

  ymdhms0 = ut_calendar(time,0)
  ymdhms0dim = dimsizes(ymdhms0)
  nt = ymdhms0dim(0)

  if (.not. isatt(restick,"TickAt")) then
    if (.not. isatt(restick,"nTicks")) then
      restick@nTicks = 4
    end if
    if(.not.isatt(restick,"MajorStride")) then
      restick@MajorStride = floattoint((nt-1)/restick@nTicks)
    end if
    ymdhms1 = ymdhms0(::restick@MajorStride,:)
  else
    ymdhms1 = restick@TickAt
  end if
  if (typeof(ymdhms1) .eq. "float") then
    ymdhms1i = floattointeger(ymdhms1)
  else
    ymdhms1i = ymdhms1
  end if
  delete(ymdhms1)
  taxisvalues = ut_inv_calendar(ymdhms1i(:,0),ymdhms1i(:,1),ymdhms1i(:,2),ymdhms1i(:,3),ymdhms1i(:,4),ymdhms1i(:,5),time@units,0)

  dimsz = dimsizes(ymdhms1i)
  ntick = dimsz(0)
  tticklabels = new(ntick,"string")

  if( ( .not.isatt(restick,"MinorStride") ) \\
       .and.(isatt(restick,"MajorStride") ) ) then
    restick@MinorStride = restick@MajorStride / 5
  end if

  if( isatt(restick,"MinorStride") ) then
    minorValues = time(::restick@MinorStride)
  else
    minorValues = taxisvalues
  end if

  if (restick@TickAxis .eq. "XB") then
   resplot@tmXBValues = taxisvalues
   resplot@tmXBMinorValues = minorValues
  end if
  if (restick@TickAxis .eq. "XT") then
   resplot@tmXTValues = taxisvalues
   resplot@tmXTMinorValues = minorValues
  end if
  if (restick@TickAxis .eq. "YL") then
   resplot@tmYLValues = taxisvalues
   resplot@tmYLMinorValues = minorValues
  end if
  if (restick@TickAxis .eq. "YR") then
   resplot@tmYRValues = taxisvalues
   resplot@tmYRMinorValues = minorValues
  end if

  if (.not. isatt(restick,"Format")) then
   if (ymdhms0(nt-1,0) .ne. ymdhms0(0,0)) then ; year changes
    if (abs(ymdhms0(nt-1,0)-ymdhms0(0,0)) .gt. ntick) then
     restick@Format = "%Y"
    else
     restick@Format = "%c%y"
    end if
   else ; same year
    if (ymdhms0(nt-1,1) .ne. ymdhms0(0,1)) then ; month changes
     if (abs(ymdhms0(nt-1,1)-ymdhms0(0,1)) .gt. ntick) then
      restick@Format = "%c%y"
     else
      restick@Format = "%N/%D"
     end if
    else ; same year/month
     if (ymdhms0(nt-1,2) .ne. ymdhms0(0,2)) then ; day changes
      if (abs(ymdhms0(nt-1,2)-ymdhms0(0,2)) .gt. ntick) then
       restick@Format = "%N/%D"
      else
       restick@Format = "%D, %H hrs"
      end if
     else ; same year/month/day
      if (ymdhms0(nt-1,3) .ne. ymdhms0(0,3)) then ; hour changes
       if (abs(ymdhms0(nt-1,3)-ymdhms0(0,3)) .gt. ntick) then
        restick@Format = "%D, %H:%M"
       else
        restick@Format = "%H:%M:%S"
       end if
      else ; same year/month/day/hour
       if (ymdhms0(nt-1,4) .ne. ymdhms0(0,4)) then ; minute changes
        if (abs(ymdhms0(nt-1,4)-ymdhms0(0,4)) .gt. ntick) then
         restick@Format = "%H:%M:%S"
        else
         restick@Format = "%H:%M:%S"
        end if
       else ; same year/month/day/hour/minute
        restick@Format = "%H:%M:%S"
       end if
      end if
     end if
    end if
   end if
  end if

  lenfmt = strlen(restick@Format)
  format = stringtochar(restick@Format)

  do i = 0, ntick-1
   tticklabels(i) = ""
   inside = False
   j = 0
   do while(j .lt. lenfmt)
    if (format(j) .eq. "%") then
     inside = True
     j = j + 1
    end if

    if (.not. inside) then
     tticklabels(i) = tticklabels(i)+format(j)
    else
     if (format(j) .eq. "Y") then
      tticklabels(i) = tticklabels(i)+sprinti("%04d",ymdhms1i(i,0))
      inside = False
     end if
     if (format(j) .eq. "y") then
      retVal(i) = retVal(i)+sprinti("%02d",ymdhms1i(i,0)%100)
      inside = False
     end if
     if (format(j) .eq. "C") then
      tticklabels(i) = tticklabels(i)+changeCase(months(ymdhms1i(i,1)),"up")
      inside = False
     end if
     if (format(j) .eq. "c") then
      tticklabels(i) = tticklabels(i)+months(ymdhms1i(i,1))
      inside = False
     end if
     if (format(j) .eq. "F") then
      tticklabels(i) = tticklabels(i)+changeCase(fmonths(ymdhms1i(i,1)),"up")
      inside = False
     end if
     if (format(j) .eq. "f") then
      tticklabels(i) = tticklabels(i)+fmonths(ymdhms1i(i,1))
      inside = False
     end if
     if (format(j) .eq. "N") then
      tticklabels(i) = tticklabels(i)+sprinti("%02d",ymdhms1i(i,1))
      inside = False
     end if
     if (format(j) .eq. "n") then
      tticklabels(i) = tticklabels(i)+sprinti("%d",ymdhms1i(i,1))
      inside = False
     end if
     if (format(j) .eq. "D") then
      tticklabels(i) = tticklabels(i)+sprinti("%02d",ymdhms1i(i,2))
      inside = False
     end if
     if (format(j) .eq. "d") then
      tticklabels(i) = tticklabels(i)+sprinti("%d",ymdhms1i(i,2))
      inside = False
     end if
     if (format(j) .eq. "H") then
      tticklabels(i) = tticklabels(i)+sprinti("%02d",ymdhms1i(i,3))
      inside = False
     end if
     if (format(j) .eq. "h") then
      tticklabels(i) = tticklabels(i)+sprinti("%d",ymdhms1i(i,3))
      inside = False
     end if
     if (format(j) .eq. "M") then
      tticklabels(i) = tticklabels(i)+sprinti("%02d",ymdhms1i(i,4))
      inside = False
     end if
     if (format(j) .eq. "m") then
      tticklabels(i) = tticklabels(i)+sprinti("%d",ymdhms1i(i,4))
      inside = False
     end if
     if (format(j) .eq. "S") then
      tticklabels(i) = tticklabels(i)+sprinti("%02d",ymdhms1i(i,5))
      inside = False
     end if
     if (format(j) .eq. "s") then
      tticklabels(i) = tticklabels(i)+sprinti("%d",ymdhms1i(i,5))
      inside = False
     end if
     if (format(j) .eq. "%") then
      tticklabels(i) = tticklabels(i)+"%"
      inside = False
     end if
    end if

    j = j + 1
   end do

  end do

;  print(tticklabels)

  if (restick@TickAxis .eq. "XB") then
   resplot@tmXBLabels = tticklabels
  end if
  if (restick@TickAxis .eq. "XT") then
   resplot@tmXTLabels = tticklabels
  end if
  if (restick@TickAxis .eq. "YL") then
   resplot@tmYLLabels = tticklabels
  end if
  if (restick@TickAxis .eq. "YR") then
   resplot@tmYRLabels = tticklabels
  end if
 end if

 return
end 
