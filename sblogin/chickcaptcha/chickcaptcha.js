/* Client side code for chickcaptcha, to highlight user select images and submit them to the server.
 * For server side efficiency, selections are submitted as a string in the variable "chickcaptcha_txt".
 * Variable format: MMFMFMMFMF 
 * The data is also submitted as checkboxes for potential future use. Checkbox code should be removed 
 * if unused on 2012-09-01
 */

       var picsclicked = 0;
       function toggleselection(pic) {
            var letters = $("#chickcaptcha_txt").val().split("");
            $('input[name=chickcaptcha]').each(
                function(idx, item) {  
                    if (item.value == pic.name) {
                        $(item).attr('checked', $(item).attr('checked') ? false : true);
                        $(pic).parent().parent().css('outline', $(item).attr('checked') ? '#fd67df solid 3px' : 'none');
                        $(pic).css('opacity', $(item).attr('checked') ? '1' : '0.7');
                        if ( $(item).attr('checked') ) {
                             letters[pic.name] = 'F';
                             picsclicked++;
                        } else {
                             letters[pic.name] = 'M';
                        }
                    }
                }
            );
            $("#chickcaptcha_txt").val(letters.join(''));
        }

        function create_checkboxes() {
           var chickcaptcha_checkboxes = document.getElementById("chickcaptcha_checkboxes");
           var i=0;
           for (i=0;i<=8;i++) {
               var element = document.createElement("input");
               element.setAttribute("type", 'checkbox');
               element.setAttribute("name", 'chickcaptcha');
               element.setAttribute("value", i);
 
               chickcaptcha_checkboxes.appendChild(element);
            }
        }


        $(document).ready(function(){
            create_checkboxes();
            $("img.chickcaptcha").click(function(event){
                toggleselection(this);
            });
            $('#login').submit(function() {
                if (picsclicked < 4) {
                    reenableform();
                    alert('Please click on the four pictures of women to prove you are a human.');
                    return false;
                }
            });
        });

