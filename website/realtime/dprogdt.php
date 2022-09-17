<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>d(prog)/dt | Alicia M. Bentley</title>
<link rel="stylesheet" type="text/css" href="style_test.css">
<script type="text/javascript" src="functions_test.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>

<?php
//Read in latest run
$curRun = file_get_contents('http://www.atmos.albany.edu/student/abentley/test/lastdate.txt');

//Read in passed url parameter(s)
$domain = $_GET['domain'];
$variable = $_GET['variable'];
?>

<!-- Head element -->
<div class="page-top">
	<span><a href="http://www.atmos.albany.edu/student/abentley/realtime.html" style="color:#000000">GFS Forecast Trends | dprog/dt</a></span>
</div>

<!-- Top menu -->
<div class="page-menu"><div class="table">
	
	<div class="element">
		<span class="bold">Variable:</span>
		<select id="variable" onchange="changeVariable(this.value)">
		</select>
	</div>
	<div class="element">
		<span class="bold">Initialized:</span>
		<select id="init" onchange="changeInit(this.value);">
		</select>
	</div>
	<div class="element">
		<span class="bold">Valid:</span>
		<select id="valid" onchange="changeValid(this.value)">
		</select>
	</div>
	<div class="element">
		<span class="bold">Domain:</span>
		<select id="domain" onchange="changeDomain(this.value)">
		</select>
	</div>
	<div class="element">
		<span class="bold">Map Type:</span>
		<select id="maptype" onchange="changeMaptype(this.value);">
		</select>
	</div>

<!-- /Top menu -->
</div></div>

<!-- Middle menu -->
<div class="page-middle" id="page-middle">
Up/Down arrow keys = Change initialization time | Left/Right arrow keys = Change valid time
<!-- /Middle menu -->
</div>

<div id="loading"><img style="width:100%" src="loading.png"></div>

<!-- Image -->
<div id="page-map">
	<image name="map" style="width:100%">
</div>

<!-- /Footer -->
<div class="page-footer">
<!--	<span>This webpage is experimental and data may occasionally be missing.  Contact Alicia.Bentley@noaa.gov with any questions.</span>
--></div>

<script type="text/javascript">
//====================================================================================================
//User-defined variables
//====================================================================================================

//Global variables
var minFrame = 0; //Minimum frame for every variable
var maxFrame = 32; //Maximum frame for every variable
var incrementFrame = 1; //Increment for every frame

var minRun = 0; //Latest run (should be zero)
var maxRun = 192; //Number of hours difference between the last available run & current run
var incrementRun = 6; //Interval between each run (6 hours)

var startFrame = 0; //Starting frame
var startRun = 0; //Starting run

/*
When constructing the URL below, DDD = domain, VVV = variable, XXX = hours difference between latest run and this run, Y = frame number.
For X and Y, labeling one X or Y represents an integer (e.g. 0, 10, 20). Multiple of these represent a string
format (e.g. XX = 00, 06, 12 --- XXX = 000, 006, 012).
*/
var url = "http://www.atmos.albany.edu/student/abentley/realtime/dprogdt/images/DDD/VVV/pXXX/image_Y.png";

//====================================================================================================
//Add variables & domains
//====================================================================================================

var variables = [];
var domains = [];
var maptypes = [];

variables.push({
	displayName: "MSLP, Thickness, 250-hPa Jet",
	name: "mslp_jet",
});
variables.push({
	displayName: "DT Potential Temp and Wind",
	name: "dt_2pvu",
});
variables.push({
	displayName: "500-hPa Relative Vorticity",
	name: "rel_vort",
});
variables.push({
	displayName: "850-hPa Equiv. Potential Temp",
	name: "850_thetae",
});
variables.push({
	displayName: "Precip, 850-hPa Temp, MSLP",
	name: "6hprecip",
});





domains.push({
	displayName: "N. Pacific",
	name: "pacific",
});
domains.push({
	displayName: "N. America",
	name: "northamer",
});
domains.push({
	displayName: "CONUS",
	name: "conus",
});
domains.push({
	displayName: "N. Atlantic",
	name: "atlantic",
});



maptypes.push({
	url: "standard.php",
	displayName: "Standard/Severe Wx",
	name: "standard",
});
maptypes.push({
	url: "subtrop.php",
	displayName: "Tropical Transition",
	name: "subtrop",
});
maptypes.push({
	url: "anom.php",
	displayName: "Standardized Anomalies",
	name: "anom",
});
maptypes.push({
	url: "dprogdt.php",
	displayName: "Forecast Trends (dprog/dt)",
	name: "dprogdt",
});
maptypes.push({
        url: "archive.php",
	displayName: "*NEW* GFS Analysis Archive",
	name: "archive",
}); 

//====================================================================================================
//Initialize the page
//====================================================================================================

//function for keyboard controls
document.onkeydown = keys;

//Decare object containing data about the currently displayed map
imageObj = {};

//Initialize the page
initialize();

//Format initialized run date & return in requested format
function formatDate(offset,format){
	var newdate = String(<?echo $curRun;?>);
	var yyyy = newdate.slice(0,4);
	var mm = newdate.slice(4,6);
	var dd = newdate.slice(6,8);
	var hh = newdate.slice(8,10);
	var curdate = new Date(yyyy,parseInt(mm)-1,dd,hh);
	
	//Offset by run
	var newOffset = curdate.getHours() + offset;
	curdate.setHours(newOffset);
	
	var yy = String(curdate.getFullYear()).slice(2,4);
	yyyy = curdate.getFullYear();
	mm = curdate.getMonth()+1;
	dd = curdate.getDate();
	if(dd < 10){dd = "0" + dd;}
	hh = curdate.getHours();
	if(hh < 10){hh = "0" + hh;}
	
	var wkday = curdate.getDay();
	var day_str = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
	
	//Return in requested format
	if(format == 'valid'){
		//06Z Thu 03/22/18 (90 h)
		var txt = hh + "Z " + day_str[wkday] + " " + mm + "/" + dd + "/" + yy;
		return txt;
	}
	if(format == 'init'){
		//06Z Thu 03/22/18
		var txt = hh + "Z " + day_str[wkday] + " " + mm + "/" + dd + "/" + yy;
		return txt;
	}
}

//Initialize the page
function initialize(){
	
	//Set image object based on default variables
	imageObj = {
		variable: "mslp_jet",
		domain: "northamer",
		run: startRun,
		frame: startFrame,
	};
	
	//Change domain based on passed argument, if any
	var passed_domain = "<?echo $domain;?>";
	if(passed_domain!=""){
		if(searchByName(passed_domain,domains)>=0){
			imageObj.domain = passed_domain;
		}
	}
	
	//Change variable based on passed argument, if any
	var passed_variable = "<?echo $variable;?>";
	if(passed_variable!=""){
		if(searchByName(passed_variable,variables)>=0){
			imageObj.variable = passed_variable;
		}
	}
	
	//Populate forecast hour and dprog/dt arrays for this run and frame
	populateMenu('init');
	populateMenu('valid');
	populateMenu('domain');
	populateMenu('variable');
	populateMenu('maptype');
	
	//Populate the frames and runs arrays
	frames = [];
	runs = [];
	for(i=minFrame;i<=maxFrame;i=i+incrementFrame){frames.push(i);}
	for(i=minRun;i<=maxRun;i=i+incrementRun){runs.push(i);}
	
	//Preload images and display map
	preload(imageObj);
	showImage();
	
	//Update mobile display for swiping
	updateMobile();

}

var xInit = null;                                                        
var yInit = null;                  
var xPos = null;
var yPos = null;

</script>

<script src="//static.getclicky.com/js" type="text/javascript"></script>
<script type="text/javascript">try{ clicky.init(100786126); }catch(e){}</script>
<noscript><p><img alt="Clicky" width="1" height="1" src="//in.getclicky.com/100786126ns.gif" /></p></noscript>

</body>
</html>
