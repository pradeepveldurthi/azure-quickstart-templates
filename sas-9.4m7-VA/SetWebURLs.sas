/*************************************************************/
/*    SetWebURLs.sas                                         */
/*                                                           */
/*    Changes metadata in the Configuration Manager plug-in  */
/*    Fields that can be changed are:                        */
/*       HostName (machine name)                             */
/*       Port                                                */
/*       Communication Protocol (http or https)              */
/*                                                           */
/*   Used for setting up proxy server, or ssl                */
/*   updated for SAS 9.4 by Erwan Granger                    */
/*                                                           */
/*************************************************************/
/*                                                           */
/*   todo: add exceptions for environment manager stuff      */
/*         add options for a more limited set of updates:    */
/*           - just the Transport Service                    */
/*           - just for viewer (and required services)       */
/*           - both transport and viewer                     */
/*           - All except the EVM exceptions                 */
/*                                                           */
/*************************************************************/

options metaserver="metaserver.customer.com" metaport=8561 metauser="sasadm@saspw" metapass="lnxsas";
options  symbolgen;

* remember exceptions (EVM, etc..);

%Macro SetWebURLs(mode=dryrun,debug=1,IntHost=,IntPort=,IntProtocol=,ExtHost=,ExtPort=,ExtProtocol=);
%***  dryrun only reports on findings. no changes made **;
%***  alternative is update ***;
%***  debug shows the messages in the log **;

%if "&mode"="dryrun" %then %do;
    %let debug=1;
%end;

data _null_;
    %*Declare text vars:;
    length uri uri2 conuri conuri10 conuri20  conuri30 HostName port communicationprotocol name service ExtHostName
    ExtPort ExtCommunicationprotocol    ExtService Extname $256;
    %*declare Numeric variables;
    length  n NumApps   8.;

    NumApps=0;
    n=0;
    uri="";
    uri2="";
    conuri="";
    conuri10="";
    conuri20="";
    conuri30="";
    HostName ="";
    port ="";
    communicationprotocol ="";
    name ="";
    extname="";
    service ="";
    ExtHostName="";
    ExtPort ="";
    ExtCommunicationprotocol    ="";
    ExtService="";


    do while (NumApps >= 0);
        %* this loop works because NumApps becomes (-4) when I have found all the things I was looking for. (n becomes too high) *;

        n++1;
        NumApps=metadata_getnobj("omsobj:DeployedComponent?@Name='Registered SAS Application' or @Name='Registered SAS Solution' or @Name='SAS Presentation Theme'",n,uri);
        If n=1 then put "there are " numapps " applications";
        if (numapps ne -4  ) then do;

            rc1=metadata_getnasn(uri,"SourceConnections",1,conuri10);
            %*put conuri10=;
            if (rc1 >= 0) then do;
                rc11=metadata_getattr(conuri10,"Name",Name);
                rc12=metadata_getattr(conuri10,"Hostname",HostName);
                rc13=metadata_getattr(conuri10,"Service",Service);
                rc14=metadata_getattr(conuri10,"Port",port);
                rc15=metadata_getattr(conuri10,"CommunicationProtocol",CommunicationProtocol);

                %if &debug=1 %then %do;
                    put '------------------------------------';
                    put 'at n=' n @@ ;
                    put 'the Web App is ' service;
                    put @4 'The Internal URL is   ' CommunicationProtocol +(-1) '://' HostName +(-1) ':' port +(-1) service;
                %end;

                %* updates to the Internal parameters *;
                    %* hostname *;
                    if Hostname ne "&inthost" and "&inthost" ne "" then do;
                        %if &debug=1 %then %do;
                            put @8 'but the host is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 '+Updating internal hostname from "' hostname '" to "' "&IntHost" '"';
                            rc=metadata_setattr(conuri10,"Hostname",compress("&IntHost"));
                            if rc >=0 then put @12 'change successful';
                        %end;
                    end;

                    %* port *;
                    if port ne "&intport" and  "&intport" ne "" then do;
                        %if &debug=1 %then %do;
                            put @8 'but the port is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 '+Updating Internal port from "' port '" to "' "&intport" '"';
                            rc=metadata_setattr(conuri10,"Port",compress("&intport"));
                            if rc >=0 then put @12 'change successful';
                        %end;
                    end;

                    * protocol *;
                    if CommunicationProtocol ne "&intprotocol" and "&intprotocol" ne "" then do;
                        %if &debug=1 %then %do;
                            put @8 'but the protocol is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 '+Updating Internal protocol from "' CommunicationProtocol '" to "' "&intprotocol" '"';
                            rc=metadata_setattr(conuri10,"CommunicationProtocol",compress("&intprotocol"));
                            if rc >=0 then put @12 'change successful';
                        %end;
                    end;
                %* end of internal updates *;



                rc2=metadata_getnasn(uri,"SourceConnections",2,conuri20);
                *put rc2=;
                %*put conuri20=;
                if rc2>=0 then do;
                    %* There is an external connection defined *;
                    rc21=metadata_getattr(conuri20,"Name",ExtName);
                    rc22=metadata_getattr(conuri20,"Hostname",ExtHostName);
                    rc23=metadata_getattr(conuri20,"Service",ExtService);
                    rc24=metadata_getattr(conuri20,"Port",ExtPort);
                    rc25=metadata_getattr(conuri20,"CommunicationProtocol",ExtCommunicationProtocol);
                    %*put name=;
                    %if &debug=1 %then %do;
                        put @4 'The External URL is   ' ExtCommunicationProtocol +(-1) '://' ExtHostName +(-1) ':' ExtPort +(-1) ExtService;
                    %end;

                    %* updating host if needed *;
                    if ExtHostname ne "&exthost" and "&exthost" ne "" then do;
                        %if &debug=1 %then %do;
                            put @8 'but the host is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 'changing it from "' ExtHostname '" to "' "&ExtHost" '"';
                            rc=metadata_setattr(conuri20,"Hostname",compress("&extHost"));
                            if rc >=0 then put @6 'change successful';
                        %end;
                    end;

                    %* updating port if needed *;
                    if ExtPort ne "&extport" and "&extport" ne "" then do;
                        %if &debug=1 %then %do;
                            put @8 'but the port is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 'changing it from "' ExtPort '" to "' "&Extport" '"';
                            rc=metadata_setattr(conuri20,"Port",compress("&extport"));
                            if rc >=0 then put @6 'change successful';
                        %end;
                    end;

                    %* updating protocol if needed *;
                    if ExtCommunicationProtocol ne "&extprotocol" and "&extprotocol" ne "" then do;
                        %if &debug=1 %then %do;
                            put @8 'but the protocol is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 'changing it from "' ExtCommunicationProtocol '" to "' "&extprotocol" '"';
                            rc=metadata_setattr(conuri20,"CommunicationProtocol",compress("&extprotocol"));
                            if rc >=0 then put @6 'change successful';
                        %end;
                    end;

                    %* updating service if needed *;
                    if ExtService ne Service  then do;
                        %if &debug=1 %then %do;
                            put @8 'but the Service is wrong';
                        %end;
                        %if "&mode"="update" %then %do;
                            put @8 'changing it from "' ExtService  '" to "' Service '"';
                            rc=metadata_setattr(conuri20,"Service",compress(service));
                            if rc >=0 then put @6 'change successful';
                        %end;
                    end;

                end;

                else if rc2=-4 then do;
                    %if &debug=1 %then %do;
                        put @4 'The External URL is not defined (same as internal)';
                    %end;

                    %if "&extprotocol" ne "" and "&ExtHost" ne "" and "&ExtPort" ne "" %then %do;
                        %if &debug=1 %then %do;
                            put @6 'Since you specified an external host, port and protocol, we will create the External URL';
                            put @6 'The External URL will be  ' "&extprotocol"  '://' "&exthost"  ':' "&extport"  service;
                        %end;


                        %if "&mode"="update" %then %do;

                            %* this line creates it *;
                            rc=metadata_newobj("TCPIPConnection",uri2,"External URI","Foundation",uri,"SourceConnections");
                            %if &debug=1 %then %do;
                                if rc >=0 then put @8 'The new connection has been successfully created';
                            %end;
                        %end;


                        %if "&mode"="update" %then %do;

                            rc=metadata_getnasn(uri,"SourceConnections",1,conuri);
                            rc=metadata_getattr(conuri,"Service",service);
                            rc=metadata_getnasn(uri,"SourceConnections",2,conuri30);

                            if (rc >= 0) then do;
                                rc=metadata_setattr(conuri30,"HostName",compress("&ExtHost"));
                                if rc >=0 then put @8 'Confirmed: New Host:' "&ExtHost";
                                rc=metadata_setattr(conuri30,"Port","&ExtPort");
                                if rc >=0 then put @8 'Confirmed: New Port:' "&ExtPort";
                                rc=metadata_setattr(conuri30,"CommunicationProtocol",compress("&ExtProtocol"));
                                if rc >=0 then put @8 'Confirmed: New Communiction Protocol:' "&ExtProtocol";
                                rc=metadata_setattr(conuri30,"Service",compress(service));
                                if rc >=0 then put @8 'Confirmed: New Service:' service;
                                put @8 "New External URL:"  "&ExtProtocol"  '://' "&ExtHost"  ':' "&ExtPort"  Service;;
                            end;
                        %end;
                    %end;
                end;
            end;
       end;
    end;
run;

%mend;

*now, we execute the macro in dryrun mode first.;
    %SetWebURLs(mode=dryrun,debug=1,IntHost=,IntPort=,IntProtocol=http,ExtHost=Proxy.ext.hostname.com,ExtPort=443,ExtProtocol=https);

*If that looked ok, we un-comment the following line, to run in the update mode. ;
    /* %SetWebURLs(mode=update,debug=1,IntHost=,IntPort=,IntProtocol=http,ExtHost=Proxy.ext.hostname.com,ExtPort=443,ExtProtocol=https); */

