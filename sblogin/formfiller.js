
function prefillForm() {
    if (typeof document.login.pword.value != "undefined") {
        if (document.login.pword.value == "") {
            document.login.pword.value = passwd_value;
        }
    }
    if (document.login.uname.value == "") {
        document.login.uname.value = name_value;
    }
    if ( readCookie("savepassword") == 1 ) {
        document.login.savepassword.checked = true;
    } else {
        document.login.savepassword.checked = false;
    }
}


function prefillElem(elem) {
    switch (elem.name) {
        case "uname" : 
          elem.value = name_value;;
          break;
        case "pword" : 
          elem.value = passwd_value;;
          break;
    }
}


function saveForm(which) {
    createCookie("sbuser", document.login.uname.value, 3650);
    if (typeof document.login.pword.value != "undefined") {
        if (document.login.savepassword.checked) {
            createCookie("sbpasswd", document.login.pword.value, 3650);
            createCookie("savepassword", "1", 3650);
        } else {
            createCookie("sbpasswd", "", 3650);
            createCookie("savepassword", "0", 3650);
        }
    }
}


function createCookie(name,value,days) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();
  }
  else expires = "";
  document.cookie = name+"="+value+expires+"; path=/; domain="+location.host.replace('www.', '');
}


function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}


var namefield;
var passwdfield;
var name_value = readCookie("sbuser");
if (name_value == null) {
    name_value = "";
}

var passwd_value = readCookie("sbpasswd");
if (passwd_value == null) {
    passwd_value = "";
}

