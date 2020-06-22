
    function showCookieWarning() {
        if ( testCookies() ) {
            var para = document.getElementById('testcookies');
            if (! typeof variable === 'undefined') {
                para.style.display = 'none';
            }
        }
    }

    function capLock(e){
        kc = e.keyCode?e.keyCode:e.which;
        sk = e.shiftKey?e.shiftKey:((kc == 16)?true:false);
        if(((kc >= 65 && kc <= 90) && !sk)||((kc >= 97 && kc <= 122) && sk))
            document.getElementById('divCapsLock').style.visibility = 'visible';
        else
            document.getElementById('divCapsLock').style.visibility = 'hidden';
    }

    window.onbeforeunload = function () {
        // This function does nothing.  Just by defining it, IE will not cache the page and Turing
    }

    function reenableform() {
        $("#submit1").val("Log In");
        $("#submit1").attr('disabled', false)
        $('#login').find('input').each(function () {
            $(this).attr('readonly', false);
        });
    }

    function submittedform() {
        $("#submit1").val("Processing ...");
        $("#submit1").attr('disabled', 'disabled');
        $('#login').find('input').each(function () {
            $(this).attr('readonly', 'readonly');
        });
        var timeoutID = window.setTimeout( reenableform, 3500);
        return true;
    }


    (function($) {
        $.QueryString = (function(a) {
            if (a == "") return {};
            var b = {};
            for (var i = 0; i < a.length; ++i)
            {
                var p=a[i].split('=');
                if (p.length != 2) continue;
                b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
            }
           return b;
        })(window.location.search.substr(1).split('&'))
    })(jQuery);


$.QueryString["param"]

    $(document).ready(function(){
        prefillForm();
        showCookieWarning();
        if (! $.QueryString["framed"] ) {
            // if (top.frames.length!=0) { top.location=self.document.location; }
        }
        $("#login").submit( function(){
            submittedform();
            saveForm(document.login);
        });
        $("#login").on('keypress', function(e){
            capLock(e);
        });

    });


