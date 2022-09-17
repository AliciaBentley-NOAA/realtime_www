<!DOCTYPE html
<html>
<head>
<meta charset="UTF-8">
<title>GFS Archive | Alicia M. Bentley</title>
<link rel="stylesheet" type="text/css" href="style_gefs.css">
<script src="jquery-3.1.1.min.js"></script>
<script type="text/javascript" src="functions_archive.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body>

<?php
//Read in passed url parameter(s)
$year = $_GET['year'];
$month = $_GET['month'];
$day = $_GET['day'];
$hour = $_GET['hour'];
$domain = $_GET['domain'];
$variable = $_GET['variable'];
?>

<!-- Head element -->
<div class="page-top">
	<span><a href="http://www.atmos.albany.edu/student/abentley/realtime.html" style="color:#000000">Real-time GFS Maps</a></span>
</div>

<!-- Top menu -->
<div class="page-menu"><div class="table">
        <div class="element">
                <span class="bold" style="color:#FF0000">Select Archived Map: </span><span class="bold">Year:</span>
                <select id="year" onchange="changeYear(this.value);"></select>
        </div>
        <div class="element">
                <span class="bold">Month:</span>
                <select id="month" onchange="changeMonth(this.value)"></select>
        </div>
	<div class="element">
		<span class="bold">Day:</span>
		<select id="day" onchange="changeDay(this.value)"></select>
	</div>
        <div class="element">
	        <span class="bold">Hour:</span>
		<select id="hour" onchange="changeHour(this.value)"></select>
	</div>
        <div class="element">
                <span class="bold">Domain:</span>
                <select id="domain" onchange="changeDomain(this.value);"></select>
	</div>
	<div class="element">
		<span class="bold">Variable:</span>
		<select id="variable" onchange="changeVariable(this.value)"></select>
	</div>
</div></div>
<!-- /Top menu -->


<!-- Middle menu -->
<div class="page-middle" id="page-middle">
GFS Archive begins at 0000 UTC 1 August 2022
<!-- /Middle menu -->
</div>


<!-- Image -->
<div id="page-map">
	<image name="map" style="width:100%">
</div>


<!-- /Footer -->
<div class="page-footer">
        <span></div>


<script type="text/javascript">
//====================================================================================================
//User-defined years
//====================================================================================================

var url = "https://www.atmos.albany.edu/student/abentley/realtime/archive/images/YYY/MMM/DDD/HHH/OOO/VVV.png";

//====================================================================================================
//Add years & months
//====================================================================================================

let menu = {
	'years':[],
	'months':[],
	'days':[],
	'hours':[],
	'domains':[],
	'variables':[],
}

menu['years'].push({
        displayName: "2022",
        name: "2022",
});


menu['months'].push({
        displayName: "January",
        name: "01",
});
menu['months'].push({
        displayName: "February",
        name: "02",
});
menu['months'].push({
        displayName: "March",
        name: "03",
});
menu['months'].push({
        displayName: "April",
        name: "04",
});
menu['months'].push({
        displayName: "May",
        name: "05",
});
menu['months'].push({
        displayName: "June",
        name: "06",
});
menu['months'].push({
        displayName: "July",
        name: "07",
});
menu['months'].push({
        displayName: "August",
        name: "08",
});
menu['months'].push({
        displayName: "September",
        name: "09",
});
menu['months'].push({
        displayName: "October",
        name: "10",
});
menu['months'].push({
        displayName: "November",
        name: "11",
});
menu['months'].push({
        displayName: "December",
        name: "12",
});





menu['days'].push({
        displayName: "1",
        name: "01",
});
menu['days'].push({
        displayName: "2",
        name: "02",
});
menu['days'].push({
        displayName: "3",
        name: "03",
});
menu['days'].push({
        displayName: "4",
        name: "04",
});
menu['days'].push({
        displayName: "5",
        name: "05",
});
menu['days'].push({
        displayName: "6",
        name: "06",
});
menu['days'].push({
        displayName: "7",
        name: "07",
});
menu['days'].push({
        displayName: "8",
        name: "08",
});
menu['days'].push({
        displayName: "9",
        name: "09",
});
menu['days'].push({
        displayName: "10",
        name: "10",
});
menu['days'].push({
        displayName: "11",
        name: "11",
});
menu['days'].push({
        displayName: "12",
        name: "12",
});
menu['days'].push({
        displayName: "13",
        name: "13",
});
menu['days'].push({
        displayName: "14",
        name: "14",
});
menu['days'].push({
        displayName: "15",
        name: "15",
});
menu['days'].push({
        displayName: "16",
        name: "16",
});
menu['days'].push({
        displayName: "17",
        name: "17",
});
menu['days'].push({
        displayName: "18",
        name: "18",
});
menu['days'].push({
        displayName: "19",
        name: "19",
});
menu['days'].push({
        displayName: "20",
        name: "20",
});
menu['days'].push({
        displayName: "21",
        name: "21",
});
menu['days'].push({
        displayName: "22",
        name: "22",
});
menu['days'].push({
        displayName: "23",
        name: "23",
});
menu['days'].push({
        displayName: "24",
        name: "24",
});
menu['days'].push({
        displayName: "25",
        name: "25",
});
menu['days'].push({
        displayName: "26",
        name: "26",
});
menu['days'].push({
        displayName: "27",
        name: "27",
});
menu['days'].push({
        displayName: "28",
        name: "28",
});
menu['days'].push({
        displayName: "29",
        name: "29",
});
menu['days'].push({
        displayName: "30",
        name: "30",
});
menu['days'].push({
        displayName: "31",
        name: "31",
});


menu['hours'].push({
        displayName: "00",
	name: "00",
});
menu['hours'].push({
        displayName: "06",
	name: "06",
});   
menu['hours'].push({
        displayName: "12",
	name: "12",
});     
menu['hours'].push({
	displayName: "18",
	name: "18",
});    



menu['domains'].push({
        displayName: "North Pacific",
        name: "pacific",
});
menu['domains'].push({
        displayName: "North America",
	name: "northamer",
});
menu['domains'].push({
        displayName: "North Atlantic",
	name: "atlantic",
});
menu['domains'].push({
	displayName: "Europe",
	name: "europe",
});
menu['domains'].push({
        displayName: "South America",
	name: "southamer",
});     
menu['domains'].push({
	displayName: "Australia",
	name: "australia",
});  



menu['variables'].push({
	displayName: "250-hPa Jet, Thickness, MSLP",
	name: "mslp_jet",
});
menu['variables'].push({
	displayName: "300-200-hPa PV & Irro. Wind",
	name: "irro_wind",
});
menu['variables'].push({
	displayName: "DT Potential Temp. & Wind",
	name: "dt_2pvu",
});
menu['variables'].push({
	displayName: "500-hPa Geo. Height, Vort.",
	name: "rel_vort",
});
menu['variables'].push({
        displayName: "500-hPa Geo. Height Anom.",
	name: "500g_anom",
});
menu['variables'].push({
	displayName: "700-hPa Geo. Height, PW",
	name: "700wind_pw",
});
menu['variables'].push({
      	displayName: "700-hPa Wind; PW Anom.",
      	name: "pw_anom",
});
menu['variables'].push({
	displayName: "700-hPa Geo. Height; IVT",
	name: "IVT_conv",
});
menu['variables'].push({
      displayName: "850-hPa Temperature Anom.",
      name: "850t_anom",
});
menu['variables'].push({
	displayName: "925-hPa Wind Speed Anom.",
	name: "925wind_anom",
});
menu['variables'].push({
	displayName: "MSLP Anomaly; 10-m Wind",
	name: "mslp_anom",
});
menu['variables'].push({
        displayName: "Precip., MSLP, 850-hPa Temp.",
	name: "6hprecip",
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


//Initialize the page
function initialize(){
	
	//Set image object based on default years
	imageObj = {
		year: "2022",
		month: "09",
        	day: "17",            // Make sure this is an integer: "5" 
		hour: "00",
		domain: "northamer",
		variable: "mslp_jet",
	};


        //Change year based on passed argument, if any
        var passed_year = "<?echo $year;?>";
        if(passed_year!=""){
                if(searchByName(passed_year,menu['years'])>=0){
                        imageObj.year = passed_year;
                }
        }

        //Change month based on passed argument, if any
        var passed_month = "<?echo $month;?>";
        if(passed_month!=""){
                if(searchByName(passed_month,menu['months'])>=0){
                        imageObj.month = passed_month;
                }
        }

        //Change day based on passed argument, if any
        var passed_day = "<?echo $day;?>";
        if(passed_day!=""){
                if(searchByName(passed_day,menu['days'])>=0){
                        imageObj.day = passed_day;
                }
        }

        //Change hour based on passed argument, if any
	var passed_hour = "<?echo $hour;?>";
	if(passed_hour!=""){
		if(searchByName(passed_hour,menu['hours'])>=0){
			imageObj.hour = passed_hour;
		}
	}

        //Change domain based on passed argument, if any
	var passed_domain = "<?echo $domain;?>";
	if(passed_domain!=""){
		if(searchByName(passed_domain,menu['domains'])>=0){
			imageObj.domain = passed_domain;
		}
	}

        //Change variable based on passed argument, if any
	var passed_variable = "<?echo $variable;?>";
	if(passed_variable!=""){
		if(searchByName(passed_variable,menu['variables'])>=0){
			imageObj.variable = passed_variable;
		}
	}

	//Populate forecast hour and dprog/dt arrays for this run and frame
	populateMenu('year');
	populateMenu('month');
    populateMenu('day');
    populateMenu('hour');
    populateMenu('domain');	
    populateMenu('variable'); 

    changeMonth(imageObj.month);
    changeHour(imageObj.hour);

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

</body></html>
