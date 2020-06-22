// Puts a date in local time format in a HTML element
function convert_to_local(element,time) {
	var old_value = element.innerHTML;
	d = new Date(time * 1000);
	var new_date = d.toLocaleString();
	element.innerHTML = new_date;
}
function statushelp(code) {
	PageURL="/sblogin/codes.html#" + code;
	WindowName="statuscodes";
	settings=
	"toolbar=no,location=no,directories=no,"+
	"status=no,menubar=no,scrollbars=yes,"+
	"resizable=yes,width=350,height=150";
	MyNewWindow=
	window.open(PageURL,WindowName,settings);
}
function countryhelp(code) {
    PageURL="/sblogin/countries.html#" + code;
    WindowName="countrycodes";
    settings=
    "toolbar=no,location=no,directories=no,"+
    "status=no,menubar=no,scrollbars=yes,"+
    "resizable=yes,width=350,height=150";
    MyNewWindow=
    window.open(PageURL,WindowName,settings);
}
