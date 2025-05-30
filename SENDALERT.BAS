' Version: 1.0
100 'SAVE"ALERT.BAS"
110    CLEAR 800
120    DQ$=CHR$(&H22):NL$=CHR$(13)+CHR$(10)  'newline character
130 'user setting
140    CH$="xxxxx"
150    WK$="xxxxx"
160    WT=300            'wait time
170    RB=0              'reboot or wait
180    GA$="xxx.xxx.xxx.xxx" 'Google Home Notifier Server Address
182    DB=0              'debug mode (1=test Google Home Notifier only)
185    PA$="msx/me/if/NET0/"  'path
190    IF CH$="xxxxx" THEN PRINT "please change the value CH$ and WK$ and GA$ to your enviroment.":PRINT:LIST 130-180:END
195    IF DB=1 THEN PRINT "DEBUG MODE: Testing Google Home Notifier Only":D1=28:D2=60:GOTO 460
200 'connet
210    _IOTPUT(PA$+ "conf/addr","54.65.206.59")
220    _IOTPUT(PA$+ "conf/port",80)
230    _IOTPUT(PA$+ "connect",1)
240 'check connect status
250    FOR I=0 TO 100:NEXT
260    _IOTGET(PA$+ "connect",S)
270    IF S<>1 THEN PRINT "connect fail":GOTO 580
280 'get sensor value
290    _IOTGET("device/dht/temperature", D1)
300    _IOTGET("device/dht/humidity", D2)
310    _IOTGET("host/battery/level", D3)
320 'create message for Ambient
330    CN$="{"+DQ$+"writeKey"+DQ$+":"+DQ$+WK$+DQ$+","
340    CN$=CN$+DQ$+"d1"+DQ$+":"+DQ$+STR$(D1)+DQ$+","
350    CN$=CN$+DQ$+"d2"+DQ$+":"+DQ$+STR$(D2)+DQ$+","
360    CN$=CN$+DQ$+"d3"+DQ$+":"+DQ$+STR$(D3)+DQ$
370    CN$=CN$+"}"+NL$
380    SM$(0)="POST /api/v2/channels/"+CH$+"/data HTTP/1.1"+NL$
390    SM$(1)="Host: 54.65.206.59"+NL$
400    SM$(2)="Content-Length:"+STR$(LEN(CN$))+NL$
410    SM$(3)="Content-Type: application/json"+NL$
420    SM$(4)=""+NL$
430    SM$(5)=CN$
440    SM$(6)=""
441    'send message to Ambient
442    PRINT NL$+"---- Send Message to Ambient ----"
443    I=0
444    IF SM$(I)<>"" THEN PRINT SM$(I);:_IOTPUT(PA$+ "msg",SM$(I)):I=I+1:GOTO 444
445    FOR I=0 TO 1000:NEXT
447    'receive Ambient response
448    PRINT NL$+"---- Receive Message from Ambient ----"
449    FOR J=0 TO 10
450      _IOTGET(PA$+ "msg",RM$)
451      PRINTRM$;
452      FOR I=0 TO 100:NEXT
453    NEXT
455    'disconnect from Ambient
456    _IOTPUT(PA$+ "connect",0)
457    FOR I=0 TO 100:NEXT
459    'check conditions for Google Home Notifier alert
460    IF D1 < 28 OR D2 < 60 THEN 530 'Temperature and Humidity conditions below threshold, skip Google Home notification
461        'make a message - using Japanese text
462        PRINT NL$+"---- Preparing Google Home Alert ----"
463        GM$="ondo wa "+STR$(D1)+" de, shitsudo wa "+STR$(D2)+"% desu. Ne-chuushou ni chuui shite kudasai."
464        'Message with Japanese characters - ensure proper URL parameter format
465        GP$="text="+GM$
466        PRINT "POST body: "; GP$
467        'make http headers and bodies for Google Home Notifier - ASCII only
468        GS$(0)="POST /google-home-notifier HTTP/1.1"+NL$
469        GS$(1)="Host: "+GA$+":8091"+NL$
470        'Content-Length must be exact
471        L=LEN(GP$) 'measure POST body length
472        GS$(2)="Content-Length: "+STR$(L)+NL$
473        GS$(3)="Content-Type: application/x-www-form-urlencoded"+NL$
474        GS$(4)="Accept: */*"+NL$
475        GS$(5)="Connection: close"+NL$
476        GS$(6)=NL$ 'Empty line between header and body (CRITICAL)
477        GS$(7)=GP$
478        GS$(8)="" 'end loop
480        'connect to Google Home Notifier
481        PRINT NL$+"---- Connecting to Google Home Notifier ----"
482        PRINT "Address: "; GA$; ":8091"
483        _IOTPUT(PA$+ "connect", 0) 'disconnect first
484        FOR I=0 TO 200:NEXT
485        _IOTPUT(PA$+ "conf/addr", GA$)
486        _IOTPUT(PA$+ "conf/port", 8091)
487        PRINT "Connecting..."
488        _IOTPUT(PA$+ "connect", 1)
489        'connection check to Google Home Notifier
490        FOR K=1 TO 3 'retry connection
491          PRINT K; "times trying to connect to "; GA$; ":8091..."
492          FOR I=0 TO 500:NEXT 'wait for connection
493          _IOTGET(PA$+ "connect", SG)
494          PRINT "Google Home Connection Status: "; SG
495          IF SG=1 THEN GOTO 501 'connected
496          FOR I=0 TO 300:NEXT 'wait before retry
497        NEXT K
498        'if connection failed
499        PRINT "Google Home Notifier connect fail - check your address"
500        GOTO 530 'continue when failed
501        'connected successfully
501        'send message to Google Home Notifier
502        PRINT NL$+"---- Send Message to Google Home Notifier ----"
503        PRINT "Message: "; GM$
504        PRINT "Address: "; GA$; ":8091"
505        PRINT "POST Body (actual): "; GP$
506        I=0
507        IF GS$(I)<>"" THEN PRINT GS$(I);:_IOTPUT(PA$+ "msg",GS$(I)):I=I+1:GOTO 507
508        FOR I=0 TO 1000:NEXT
509        'response from Google Home Notifier
510        PRINT NL$+"---- Google Home Notifier Response ----"
511        FC=0 'Flag for successful response
512        FOR J=0 TO 10
513          _IOTGET(PA$+ "msg",RM$)
514          PRINT RM$;
515          'Check for success in response
516          IF INSTR(RM$,"200 OK")>0 THEN FC=1
517          FOR I=0 TO 100:NEXT
518        NEXT
519        IF FC=1 THEN PRINT NL$+"Google Home notification sent successfully" ELSE PRINT NL$+"Google Home notification might have failed"
520        'Terminate Google Home connection
521        _IOTPUT(PA$+ "connect",0)
522        FOR I=0 TO 100:NEXT
523 'end of Google Home Notifier section
530 'end of sending to google home notifier
600 'loop
610    IF RB=1 THEN 700 ELSE 620
620 'wait
630    PRINT NL$+"---- Wait (" + STR$(WT) + " sec ) ----"
640    TIME=0
650    IF TIME<WT*60 THEN GOTO 650
660    GOTO 200
700 'system reboot
710    PRINT NL$+"---- Sleep (" + STR$(WT) + " sec ) & Reboot ----"
720    _IOTPUT("host/power/wait", WT)
730    _IOTPUT("host/power/reboot",1)
