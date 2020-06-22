var IE4 = (document.all) ? 1 : 0; 
var ns4 = (document.layers) ? 1 : 0; 
var fieldnum = 0;


function showTag(type,id,action) {
    var i;
    var a;

    for(i=0; (a = document.getElementsByTagName(type)[i]); i++) {
        if(a.getAttribute("id") && a.getAttribute("id").indexOf(id) != -1) {
            if (IE4) {
                if (action == null) {
                    if (a.style.display == "none") {
                        action = "show";
                    } else {
                        action = "hide";
                    }
                }
                if (action == "show") {
                    a.style.display = "block";
                } else {
                    a.style.display = "none";
                }
            }
            else {
                if (action == null) {
                    if ( (a.style.display == "none") || (a.display == "none") ) {
                        action = "show";
                    } else {
                        action = "hide";
                    }
                }
                if (action == "show") {
                    a.display = "block";
                    a.style.display = "block";
                } else {
                    a.display = "none";
                    a.style.display = "none";
                }
            }
        }
    }
    setCookie("showTag:" + type + ":" + id, action);
}







function showNextField () {
    fieldnum = fieldnum + 1;
    var fieldname="addon" + fieldnum;
    showTag("div", fieldname);
}


