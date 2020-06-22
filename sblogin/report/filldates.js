
function filldates(){
    var mydate=new Date();
    with (mydate) setDate(getDate()+1); // Server time may be ahead of local
    var theyear=mydate.getYear();
    if (theyear < 1000)
        theyear+=1900;
    var theday=mydate.getDay();
    var themonth=mydate.getMonth()+1;
    if (themonth<10)
        themonth="0"+themonth;
    var theday=mydate.getDate();
    if (theday<10)
        theday="0"+theday;


    var dateBegin = new Date();
    with (dateBegin) setDate(getDate()-7);
    var beginyear=dateBegin.getYear();
    if (beginyear < 1000)
                beginyear+=1900;
        var beginday=dateBegin.getDay();
        var beginmonth=dateBegin.getMonth()+1;
        if (beginmonth<10)
                beginmonth="0"+beginmonth;
        var beginday=dateBegin.getDate();
        if (beginday<10)
                beginday="0"+beginday;

    var dateNextMonth = new Date();
    with (dateNextMonth) setDate(getDate()+30);
    var NextMonthyear=dateNextMonth.getYear();
    if (NextMonthyear < 1000)
                NextMonthyear+=1900;
        var NextMonthday=dateNextMonth.getDay();
        var NextMonthmonth=dateNextMonth.getMonth()+1;
        if (NextMonthmonth<10)
                NextMonthmonth="0"+NextMonthmonth;
        var NextMonthday=dateNextMonth.getDate();
        if (NextMonthday<10)
                NextMonthday="0"+NextMonthday;


    document.activity_report.begin_day.value=beginday;
    document.activity_report.begin_month.value=beginmonth;
    document.activity_report.begin_year.value=beginyear;
    document.activity_report.end_day.value=theday;
    document.activity_report.end_month.value=themonth;
    document.activity_report.end_year.value=theyear;
    document.adduser.exp_day.value=NextMonthday;
    document.adduser.exp_month.value=NextMonthmonth;
    document.adduser.exp_year.value=NextMonthyear;

    document.disabled.begin_day.value=beginday;
    document.disabled.begin_month.value=beginmonth;
    document.disabled.begin_year.value=beginyear;

    dateBegin = new Date();
    with (dateBegin) setDate(getDate()-1);
    var beginyear=dateBegin.getYear();
    if (beginyear < 1000)
                beginyear+=1900;
    var beginday=dateBegin.getDay();
    var beginmonth=dateBegin.getMonth()+1;
    if (beginmonth<10)
        beginmonth="0"+beginmonth;
    var beginday=dateBegin.getDate();
    if (beginday<10)
            beginday="0"+beginday;

    document.raw_log.begin_day.value=beginday;
    document.raw_log.begin_month.value=beginmonth;
    document.raw_log.begin_year.value=beginyear;
    document.raw_log.end_day.value=theday;
    document.raw_log.end_month.value=themonth;
    document.raw_log.end_year.value=theyear;

}

