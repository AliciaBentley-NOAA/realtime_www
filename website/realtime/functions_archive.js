<!--

/* ============================================================================================================= */
/* Preloading & displaying functions */
/* ============================================================================================================= */

//Populate the dropdown menu with items
function populateMenu(mode){
	if(mode == 'year'){
		var element = document.getElementById("year");
		for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}
		
		for(i=0; i<menu['years'].length; i++){
			var option = document.createElement("option");
			option.text = menu['years'][i].displayName;
			option.value = menu['years'][i].name;
			element.add(option);
		}
	}
        else if(mode == 'month'){
                var element = document.getElementById("month");
                for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}

                for(i=0; i<menu['months'].length; i++){
                        var option = document.createElement("option");
                        option.text = menu['months'][i].displayName;
                        option.value = menu['months'][i].name;
                        element.add(option);
                }
        }
        else if(mode == 'day'){
                var element = document.getElementById("day");
                for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}

                for(i=0; i<menu['days'].length; i++){
                        var option = document.createElement("option");
                        option.text = menu['days'][i].displayName;
                        option.value = menu['days'][i].name;
                        element.add(option);
                }
        }
        else if(mode == 'hour'){
	        var element = document.getElementById("hour");
		for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}

		for(i=0; i<menu['hours'].length; i++){
			var option = document.createElement("option");
			option.text = menu['hours'][i].displayName;
			option.value = menu['hours'][i].name;
			element.add(option);
		}
	}
        else if(mode == 'domain'){
	        var element = document.getElementById("domain");
		for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}

		for(i=0; i<menu['domains'].length; i++){
			var option = document.createElement("option");
			option.text = menu['domains'][i].displayName;
			option.value = menu['domains'][i].name;
			element.add(option);
		}
	}
        else if(mode == 'variable'){
	       	var element = document.getElementById("variable");
		for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}

		for(i=0; i<menu['variables'].length; i++){
			var option = document.createElement("option");
			option.text = menu['variables'][i].displayName;
			option.value = menu['variables'][i].name;
			element.add(option);
		}
	}
}

//Format URL to the requested month, year, run & frame

function getURL(variable,domain,hour,day,month,year,frame){

        var newurl = url.replace("YYY",year);
	for(var i=0; i<5; i++){
		newurl = newurl.replace("MMM",month);
                newurl = newurl.replace("DDD",day);
                newurl = newurl.replace("HHH",hour);
                newurl = newurl.replace("OOO",domain);
                newurl = newurl.replace("VVV",variable);
		newurl = newurl.replace("Z",frame);
	}

	return newurl;
}

//Search for a name within an object
function searchByName(keyname, arr){
    for (var i=0; i < arr.length; i++){
        if (arr[i].name === keyname){
            return i;
        }
    }
	return -1;
}

//Display the current image object
function showImage(){
	
	//Display image
	//document.getElementById('loading').style.display = "none";
	var url = getURL(imageObj.variable,imageObj.domain,imageObj.hour,imageObj.day,imageObj.month,imageObj.year,i);
	document.map.src = url;
	
	//Update dropdown menus
	document.getElementById("year").selectedIndex = searchByName(imageObj.year,menu['years']);
	document.getElementById("month").selectedIndex = searchByName(imageObj.month,menu['months']);
	document.getElementById("day").selectedIndex = searchByName(imageObj.day,menu['days']);
	document.getElementById("hour").selectedIndex = searchByName(imageObj.hour,menu['hours']);
	document.getElementById("domain").selectedIndex = searchByName(imageObj.domain,menu['domains']);
	document.getElementById("variable").selectedIndex = searchByName(imageObj.variable,menu['variables']);
	
	//Update URL in address bar
	generate_url();
}

//Format integer as a string by number of characters
function formatString(i,val){
	if(val==3){
		if(i<10){return "00"+i;}
		if(i<100){return "0"+i;}
		return i;
	}
}

//Preload images for the current run, year & projection
function preload(obj){
	return;
	
	/*
	TOMER EDITS
	Since we're no longer preloading images, I simply added a "return" statement at the beginning of the function
	so it doesn't execute any of the code below. You can then remove any references to "preload()" on your own time.
	*/
	
	//Year index
	var idx_var = searchByName(obj.year,menu['years']);
	
	//alert(obj.year);
	//alert(idx_var);
	
	//years[idx_var].images[i] = [];
        //years[idx_var].images[i] = [];
	//years[idx_var].images[i] = [];
	
/*	//Arrange list of hour indices to loop through
	var frameidx = frames.indexOf(imageObj.frame);
	var hrs_loop = [frameidx];
	
	for(i=1; i<frames.length; i++){
		
		var idx_up = frameidx + i;
		var idx_down = frameidx - i;
		
		if(idx_up<=frames.indexOf(maxFrame)){hrs_loop.push(idx_up);}
		if(idx_down>=frames.indexOf(minFrame)){hrs_loop.push(idx_down);}
	}
*/	
	//Loop through all forecast hours & pre-load image
	for (var i1=0; i1<frames.length; i1++){
		var i = frames[i1];

		var urls = getURL(obj.variable,obj.domain,obj.hour,obj.day,obj.month,obj.year,i);
		
		years[idx_var].images[i] = new Image();
		years[idx_var].images[i].loaded = false;
		years[idx_var].images[i].id = i;
		years[idx_var].images[i].onload = function(){this.loaded = true; remove_loading(this.varid,this.id);};
		years[idx_var].images[i].onerror = function(){remove_loading(this.varid,this.id);};
		years[idx_var].images[i].src = urls;
		years[idx_var].images[i].year = obj.year;
		years[idx_var].images[i].varid = idx_var;
    }
}

//Remove sign of loading image
function remove_loading(idx_var,idx_frame){
	check1a = parseInt(idx_var);
	check1b = searchByName(imageObj.year,years);
	check2a = frames.indexOf(parseInt(idx_frame));
	check2b = frames.indexOf(parseInt(imageObj.frame));
	
	//Remove if the image just loaded for the currently displayed image
	if((check1a == check1b) && (check2a == check2b)){
		document.getElementById('loading').style.display = "none";
		document.map.src = years[idx_var].images[imageObj.frame].src;
	}
}

/* ============================================================================================================= */
/* Dropdown menu functions */
/* ============================================================================================================= */

//Change the year from dropdown menu
function changeYear(id){
	imageObj.year = id;
	preload(imageObj);
	showImage();
	document.getElementById("year").blur();
}

// Adds a zero in front of the integer
function NumToString(i){
    if(i < 10){return "0"+String(i);}
    return String(i);
}

//Change the month from dropdown menu
function changeMonth(id){
        imageObj.month = id;
        preload(imageObj);
        showImage();
        document.getElementById("month").blur();

        //Create 2 arrays with an entry for each month and correspondingly the number of days in that month
        var arr_months = ["01","02","03","04","05","06","07","08","09","10","11","12"];
        var arr_days = [31,28,31,30,31,30,31,31,30,31,30,31];

        //Get the selected month from the dropdown menu
        var selected_month = document.getElementById("month").value; //if it's November, this will be "11"

        //This gives the position in the "arr_months" array where "selected_month" is contained.
        //If selected_month == "11", then using a 0-based index notation, this will be position number 10.
        var idx = arr_months.indexOf(selected_month);

        //Get the number of days in the selected month
        var month_days = arr_days[idx]; //the 10th position of "arr_days" corresponding with November = 30 days

        //Get the day that's already selected (as an integer), before we clear the dropdown menu content
        var currently_selected_day = parseInt(document.getElementById("day").value);

        //Clear dropdown menu content now that we've saved the current day
        var element = document.getElementById("day");
        for(i = element.options.length - 1 ; i >= 0 ; i--){element.remove(i);}

        //Add an option for each day of the month
        for(i=1; i<=month_days; i++){
                var option = document.createElement("option");
                option.text = String(i); //formerly days[i].displayName;
                option.value = NumToString(i); //formerly days[i].name;
                element.add(option);
        }

        //Now that we populated the dropdown menu, let's try to select the day that was previously selected if it's
        //contained in this month.
        if(currently_selected_day <= month_days){
        //remember Javascript uses 0-based indexing, so we want to subtract the day by 1 to get its position in the array
        element.options[currently_selected_day - 1].selected = true;
        element.onchange();
        }
}

//Change the day from dropdown menu
function changeDay(id){
        imageObj.day = id;
        preload(imageObj);
        showImage();
        document.getElementById("day").blur();
}

//Change the hour from dropdown menu
function changeHour(id){
        imageObj.hour = id;
	preload(imageObj);
	showImage();
	document.getElementById("hour").blur();
}

//Change the domain from dropdown menu
function changeDomain(id){
        imageObj.domain = id;
	preload(imageObj);
	showImage();
	document.getElementById("domain").blur();
}

//Change the variable from dropdown menu
function changeVariable(id){
        imageObj.variable = id;
	preload(imageObj);
	showImage();
	document.getElementById("variable").blur();
}


/* ============================================================================================================= */
/* Keyboard controls */
/* ============================================================================================================= */

function keys(e){
	//Left
	if(e.keyCode == 37){
		prevFrame();
		return !(e.keyCode);
	}
	//Up
	else if(e.keyCode == 38){
		pressUp();
		return !(e.keyCode);
	}
	//Right
	else if(e.keyCode == 39){
		nextFrame();
		return !(e.keyCode);
	}
	//Down
	else if(e.keyCode == 40){
		pressDown();
		return !(e.keyCode);
	}
}

function updateDate(hourIncrement){
	//Get current date
	let year = imageObj['year']
	let month = imageObj['month']
	let day = imageObj['day']
	let hour = imageObj['hour']
	const origMonth = imageObj['month']
	
	//Convert to date object
	let stringDate = `${year}${month}${day}${hour}`
	let objectDate = strptime(stringDate,'%Y%m%d%H')
	console.log(objectDate)
	
	//Subtract 6 hours from date
	objectDate = add_hours(objectDate,hourIncrement)
	
	//Convert back to string
	year = strftime(objectDate,'%Y')
	month = strftime(objectDate,'%M')
	day = strftime(objectDate,'%D')
	hour = strftime(objectDate,'%H')
	
	//update month dropdown menu
	if(origMonth != month){changeMonth(month)}
	
	//Set back to imageObj
	imageObj['year'] = year
	imageObj['month'] = month
	imageObj['day'] = day
	imageObj['hour'] = hour
	console.log(hour)
	
	//update image display
	showImage()
}

function prevFrame(){
    updateDate(hourIncrement=-6)
} 

function nextFrame(){
    updateDate(hourIncrement=6)
}

function pressDown(){
        var curVar = searchByName(imageObj.variable,menu['variables']);
	if(curVar < menu['variables'].length-1){curVar += 1; changeVariable(menu['variables'][curVar].name);}
}

function pressUp(){
	var curVar = searchByName(imageObj.variable,menu['variables']);
	if(curVar > 0){curVar = curVar - 1; changeVariable(menu['variables'][curVar].name);}
}

/* ============================================================================================================= */
/* Additional functions */
/* ============================================================================================================= */

//Update the URL in the address bar by the current month and year
function generate_url(){
	
	var url = window.location.href.split('?')[0] + "?";
	var append = "";

	//Add year
	append += "&year=" + imageObj.year;

	//Add month
	append += "&month=" + imageObj.month;

        //Add day
	append += "&day=" + imageObj.day;

        //Add hour
	append += "&hour=" + imageObj.hour;

        //Add domain
	append += "&domain=" + imageObj.domain;

        //Add variable
	append += "&variable=" + imageObj.variable;

	//Get new URL
	var total = url + append;
	
	//Update in address bar without reloading page
	var pagename = window.location.href.split('/');
	pagename = pagename[pagename.length-1];
	pagename = pagename.split(".php")[0];
	var stateObj = { foo: "bar" };
	history.replaceState(stateObj, "", pagename+".php?"+append);
	
	//Update selected menu item based on this
//	document.getElementById('maptype').selectedIndex = searchByName(pagename,maptypes);

	return total;
}

function updateMobile(){
	if( navigator.userAgent.match(/Android/i)
	|| navigator.userAgent.match(/webOS/i)
	|| navigator.userAgent.match(/iPhone/i)
	|| navigator.userAgent.match(/iPod/i)
	//|| navigator.userAgent.match(/iPad/i)
	|| navigator.userAgent.match(/BlackBerry/i)
	|| navigator.userAgent.match(/Windows Phone/i)
	){
		document.getElementById('page-middle').innerHTML = "GFS Archive begins at 0000 UTC 1 August 2022";
	}


	//Swipe for mobile devices only when focused on image
	var element = document.getElementsByName("map")[0];
	element.addEventListener("touchstart", touchStart, false);
	element.addEventListener("touchend", touchEnd, false);
	element.addEventListener("touchmove", touchMove, false);

}

function touchStart(e){
    xInit = e.touches[0].clientX;
    yInit = e.touches[0].clientY;
};

function touchMove(e){
	e.preventDefault();
    xPos = e.touches[0].clientX;
    yPos = e.touches[0].clientY;
};

function touchEnd() {
    if ( ! xPos || ! yPos ) {
        return;
    }
	
    //Get difference in x & y positions
    var xDiff = xInit - xPos;
    var yDiff = yInit - yPos;
	
	//Determine whether swipe was vertical or horizontal
    if ( Math.abs(xDiff) > Math.abs(yDiff) ){
        if( xDiff > 0 ){
            //Left swipe
			nextFrame();
        }
		else{
            //Right swipe
			prevFrame();
        }                       
    }
	else{
        if ( yDiff > 0 ){
            //Up swipe
			pressDown();
        }
		else{ 
            //Down swipe
			pressUp();
        }                                                                 
    }
	
    //reset values
    xInit = null;
    yInit = null;  
	xPos = null;
	yPos = null;

};

/* ============================================================================================================= */
/* Date & time functionality */
/* ============================================================================================================= */

function strptime(str, format) {
  /*
	Converts a string to a date, given a format.

	Parameters
	----------
	str : string
		String representing the date.
	format : string
		String representing the expected format of str.
	*/

  // Split format string into elements
  var format_array = format.split(`%`)

  // Create hard copy of original argument
  var strdate = `${str}`

  // Iterate over each element to convert from original string date
  var date_obj = new Date(2020, 1, 1, 0, 0, 0)
  for (i = 0; i < format_array.length; i++) {
    var fmt = format_array[i]

    // Check for full year
    if (fmt == `Y`) {
      date_obj.setFullYear(strdate.substring(0, 4))
      strdate = strdate.substring(4, strdate.length)
    }

    // Check for month
    if (fmt == `m`) {
      date_obj.setMonth(parseInt(strdate.substring(0, 2), 10) - 1)
      strdate = strdate.substring(2, strdate.length)
    }

    // Check for date
    if (fmt == `d`) {
      date_obj.setDate(parseInt(strdate.substring(0, 2), 10))
      strdate = strdate.substring(2, strdate.length)
    }

    // Check for hours
    if (fmt == `H`) {
      date_obj.setHours(parseInt(strdate.substring(0, 2), 10))
      strdate = strdate.substring(2, strdate.length)
    }

    // Check for minutes
    if (fmt == `M`) {
      date_obj.setMinutes(parseInt(strdate.substring(0, 2), 10))
      strdate = strdate.substring(2, strdate.length)
    }
  }

  Date.prototype.stdTimezoneOffset = function () {
    var jan = new Date(this.getFullYear(), 0, 1)
    var jul = new Date(this.getFullYear(), 6, 1)
    return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset())
  }

  // If DST is observed, change hour
  function isDstObserved(check_date) {
    return check_date.getTimezoneOffset() < check_date.stdTimezoneOffset()
  }

  if (isDstObserved(date_obj) == false) {
    date_obj = add_hours(date_obj, -1)
  }

  // Return date object
  return date_obj
}

function strftime(date_obj, format) {
  /*
	Converts a date to a string, given a format.

	Parameters
	----------
	date_obj : Date
		Date object to be converted.
	format : string
		String representing the format to convert the date to.
	*/

  var new_date = new Date()
  new_date.setTime(date_obj.getTime())

  Date.prototype.stdTimezoneOffset = function () {
    var jan = new Date(this.getFullYear(), 0, 1)
    var jul = new Date(this.getFullYear(), 6, 1)
    return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset())
  }

  // If DST is observed, change hour
  function isDstObserved(check_date) {
    return check_date.getTimezoneOffset() < check_date.stdTimezoneOffset()
  }

  if (isDstObserved(new_date) == false) {
    new_date = add_hours(new_date, 1)
  }

  // Iterate over each element to convert from date
  var strdate = ``
  for (i = 0; i < format.length; i++) {
    // Check if this is a format or another character
    if (format[i] != `%`) {
      strdate += format[i]
      continue
    }

    // Otherwise, retrieve format
    var fmt = format[i + 1]

    // Check for full year
    if (fmt == `Y`) {
      strdate += String(new_date.getFullYear())
    }

    // Check for month (string)
    if (fmt == `M`) {
      month = parseInt(new_date.getMonth(), 10) + 1
      if (month < 10) {
        month = `0${month}`
      }

      strdate += String(month)
    }

    // Check for month (number)
    if (fmt == `m`) {
      month = parseInt(new_date.getMonth(), 10) + 1
      strdate += String(month)
    }

    // Check for short name month
    if (fmt == `b`) {
      month = parseInt(new_date.getMonth(), 10)
      var months = [
        `Jan`,
        `Feb`,
        `Mar`,
        `Apr`,
        `May`,
        `Jun`,
        `Jul`,
        `Aug`,
        `Sep`,
        `Oct`,
        `Nov`,
        `Dec`,
      ]
      strdate += months[month]
    }

    // Check for long name month
    if (fmt == `B`) {
      month = parseInt(new_date.getMonth(), 10)
      var months = [
        `January`,
        `February`,
        `March`,
        `April`,
        `May`,
        `June`,
        `July`,
        `August`,
        `September`,
        `October`,
        `November`,
        `December`,
      ]
      strdate += months[month]
    }

    // Check for date (string)
    if (fmt == `D`) {
      date = parseInt(new_date.getDate(), 10)
      if (date < 10) {
        date = `0${date}`
      }

      strdate += String(date)
    }

    // Check for date (number)
    if (fmt == `d`) {
      date = parseInt(new_date.getDate(), 10)
      strdate += String(date)
    }

    // Check for weekday string (short)
    if (fmt == `a`) {
      day = parseInt(new_date.getDay(), 10)
      var days = [`Sun`, `Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`]
      strdate += days[day]
    }

    // Check for hours
    if (fmt == `H`) {
      hours = parseInt(new_date.getHours(), 10)
      if (hours < 10) {
        hours = `0${hours}`
      }

      strdate += String(hours)
    }

    // Check for minutes
    if (fmt == `S`) {
      minutes = parseInt(new_date.getMinutes(), 10)
      if (minutes < 10) {
        minutes = `0${minutes}`
      }

      strdate += String(minutes)
    }

    // Increment formatter
    i += 1
  }

  // Return date object
  return String(strdate)
}

function add_days(date_obj, days) {
  /*
	Adds hours to a Date object.

	Parameters
	----------
	date_obj : Date
		Object representing the date.
	days : int
		Integers to add to the date object.
	*/

  // Create a hard copy of the original date object
  const new_date = new Date()
  new_date.setTime(date_obj.getTime())

  // Update by hour increments
  new_date.setTime(new_date.getTime() + days * 24 * 60 * 60 * 1000)

  // Return new date object
  return new_date
}

function add_hours(date_obj, hours) {
  /*
	Adds hours to a Date object.

	Parameters
	----------
	date_obj : Date
		Object representing the date.
	hours : int
		Integers to add to the date object.
	*/

  // Create a hard copy of the original date object
  const new_date = new Date()
  new_date.setTime(date_obj.getTime())

  // Update by hour increments
  new_date.setTime(new_date.getTime() + hours * 60 * 60 * 1000)

  // Return new date object
  return new_date
}

function add_minutes(date_obj, minutes) {
  /*
	Adds minutes to a Date object.

	Parameters
	----------
	date_obj : Date
		Object representing the date.
	minutes : int
		Integers to add to the date object.
	*/

  // Create a hard copy of the original date object
  const new_date = new Date()
  new_date.setTime(date_obj.getTime())

  // Update by hour increments
  new_date.setTime(new_date.getTime() + minutes * 60 * 1000)

  // Return new date object
  return new_date
}

function timedelta(date1, date2, format) {
  /*
	Subtracts two dates (date1 - date2).

	Parameters
	----------
	date1 : Date
	date2 : Date
	format : str
		String for format to convert to (e.g., "seconds", "minutes", "hours", "days").

	Returns
	-------
	int
		Time difference in the requested format.
	*/

  var diff_time = date1 - date2

  if (format == `seconds`) {
    return Math.ceil(diff_time / 1000)
  }
  if (format == `minutes`) {
    return Math.ceil(diff_time / (1000 * 60))
  }
  if (format == `hours`) {
    return Math.ceil(diff_time / (1000 * 60 * 60))
  }
  if (format == `days`) {
    return Math.ceil(diff_time / (1000 * 60 * 60 * 24))
  }
}

-->
