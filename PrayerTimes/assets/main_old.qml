import bb.cascades 1.4
import CustomTimer 1.0
import bb.device 1.3
import bb.data 1.0
import bb.system 1.2
import bb.platform 1.2

            NavigationPane {
                
                id:nP
                onNavigateToTransitionEnded: {
                    
                }
                onPopTransitionEnded	: {
                    page.destroy();
                    
                }
                
                property int dWith:displayInfo.pixelSize.width 
                property int dHeight:displayInfo.pixelSize.height
                
                property string locale:LocaleType.Messages
                
                
               
               
                
                



                property string chosenLocationLabel:"Undefined"
                property int refreshDay;

                property variant vakitler:["-","-","-","-","-","-","-","-"];
                property string kalanDakika:"--:--";
                property string currentPray:'SSSS';
                property int currentPrayCode;
                property int pDiff;
                property string day;
                property string month;
                property string year;
                property string dayMonth:'--/--';
                property string notifPlus:qsTr("Reminder") + Retranslate.onLanguageChanged
                
                
        
                


                property bool isFirst:true;
                property bool isFirst2:true;
                property bool isNotify:_app.isHere
                
                property string hDay:"DD";
                property string hMonth0;
                property string hMonth:"MM";
                property string hYear:"YYYY";

                property string appName0:"Ezan"
                property string supportURI0:"mailto:support@karecode.com?subject="+appName0
                property string shareData10:qsTr(" - A BlackBerry 10 application to follow hijri date and prayer times. Download from \n ") + Retranslate.onLanguageChanged
                property string shareData20:"http://appworld.blackberry.com/webstore/content/59998572/"
                property string shareData0:appName0+shareData10+shareData20
                
                
             
               
               
                
                function hicriAy (asd){
                  
                    
                    var hicriAylar = [''
                    ,'Muharram'
                    , 'Safar'
                    , 'Rabi\' al-Awwal'
                    , 'Rabi\' al-Thani'
                    , 'Jumada al-Ula'
                    , 'Jumada al-Akhirah'
                    , 'Rajab'
                    , 'Sha’ban'
                    , 'Ramadhan'
                    , 'Shawwal'
                    , 'Thul-Qi’dah'
                    , 'Thul-Hijjah'
                    ];
                    
                    if(locale=="tr"){
                        hicriAylar = [''
                        ,'Muharrem'
                        , 'Safer'
                        , 'Rebiul Evvel'
                        , 'Rebiul Âhir'
                        , 'Cemaziyel Evvel'
                        , 'Cemaziyel Âhir'
                        , 'Recep'
                        , 'Şâban'
                        , 'Ramazan'
                        , 'Şevval'
                        , 'Zilkâde'
                        , 'Zilhicce'
                        ];
                    }
                    
                    
                    return hicriAylar[asd];
                }
                
               
                
                    function asd(isOld){
                    
                    
                    var d = new Date();
                    var curr_date = d.getDate();
                    var curr_month = d.getMonth() + 1; //Months are zero based
                    var curr_year = d.getFullYear();
                    var curr_hour = d.getHours();
                    var curr_minute = d.getMinutes();
                    var curr_second = d.getSeconds();
                    
                    var monthNames = ["January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"
                    ];
                    
                    if(locale=="tr"){
                        monthNames = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
                        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
                        ];
                    }
                    
                    day=curr_date;
                    year=curr_year;
                    month=monthNames[curr_month-1];
                    dayMonth=day+"/"+curr_month
                    
                    var vakit=[];
                    vakit[0]=nP.vakitler[0];
                    vakit[1]=nP.vakitler[1];
                    vakit[2]=nP.vakitler[2];
                    vakit[3]=nP.vakitler[3];
                    vakit[4]=nP.vakitler[4];
                    vakit[5]=nP.vakitler[5];
                    
                    
                    
                    
                    var s0 = curr_year+"/"+curr_month+"/"+curr_date+" "+vakit[0]+":00",
                    s1 = curr_year+"/"+curr_month+"/"+curr_date+" "+vakit[1]+":00",
                    s2 = curr_year+"/"+curr_month+"/"+curr_date+" "+vakit[2]+":00",
                    s3 = curr_year+"/"+curr_month+"/"+curr_date+" "+vakit[3]+":00",
                    s4 = curr_year+"/"+curr_month+"/"+curr_date+" "+vakit[4]+":00",
                    s5 = curr_year+"/"+curr_month+"/"+curr_date+" "+vakit[5]+":00";
                    
                    var simdi=d;
                    var dates = [
                    simdi,
                    new Date(s0),
                    new Date(s1),
                    new Date(s2),
                    new Date(s3),
                    new Date(s4),
                    new Date(s5)];
                    
                    dates.sort();
                    
                    
                    
                    // variables for time units
                    
                    var diff;
                    var fark;
                    if (simdi==dates[6]){diff= new Date(s0)-simdi+ (24 * 60 * 60 * 1000);}
                    else {diff= new Date(s0)-simdi;}
                    
                    currentPray=qsTr("Isha")+ Retranslate.onLanguageChanged
                    currentPrayCode=6;
                    //yatsi.textStyle.color=Color.Red
                    
                    for (var i=1; i<6; i++){
                        fark=dates[i]-simdi;
                        if (fark==0) { 
                            diff=dates[i+1]-new Date();
                            if(i==1){
                                currentPray=qsTr("Fajr")+ Retranslate.onLanguageChanged
                                currentPrayCode=i;
                            }
                            if(i==2){
                                currentPray=qsTr("Shuruq")+ Retranslate.onLanguageChanged
                                currentPrayCode=i;
                            }
                            if(i==3){
                                currentPray=qsTr("Dhuhr")+ Retranslate.onLanguageChanged
                            }
                            if(i==4){
                                currentPray=qsTr("Asr")+ Retranslate.onLanguageChanged
                                currentPrayCode=i;
                            }
                            if(i==5){
                                currentPray=qsTr("Magrib")+ Retranslate.onLanguageChanged
                                currentPrayCode=i;
                                if(isOld){onlineCont.reload();}
                            }
                            break;}
                    }
                    
                    nP.pDiff=diff;
                    lightTimer.start();
                    myActivity.stop();
                    
                }
                
                Menu.definition: MenuDefinition {
                    
                    // Specify the actions that should be included in the menu
                    actions: [
                        ActionItem {
                            id:menuAbout
                            title: qsTr("About") + Retranslate.onLanguageChanged
                            imageSource: "asset:///images/ic_info1.png"
                            
                            onTriggered: {
                                var page = aboutPage.createObject();
                                nP.push(page);
                            }
                        },
                        
                        
                        
                        
                        
                        
                        ActionItem {
                            id:menuSettings
                            title: qsTr("Settings") + Retranslate.onLanguageChanged
                            imageSource: "asset:///images/ic_settings.png"
                            
                            onTriggered: {
                                var page = settingsPage.createObject();
                                nP.push(page);
                            }
                        },
                        
                        
                        /*
                          
                         
                        
                        ActionItem {
                            id: bugAction
                            title: qsTr("Bug Report") + Retranslate.onLanguageChanged
                            imageSource: "asset:///images/bug.png"
                            onTriggered: {
                                invokeBug.trigger("bb.action.SENDEMAIL");
                            }
                            
                            attachedObjects: [
                                Invocation {
                                    id: invokeBug
                                    query {
                                        invokeTargetId: "sys.pim.uib.email.hybridcomposer"
                                        uri: supportURI0
                                    }
                                }
                            ]
                        },
                        
                        */
                        ActionItem {
                            id: bbWorldAction
                            title: qsTr("More Apps") + Retranslate.onLanguageChanged
                            imageSource: "asset:///images/bbWorld.png"
                            onTriggered: {
                                invokeAppWorld.trigger("bb.action.OPEN");
                            }
                            
                            attachedObjects: [
                                Invocation {
                                    id: invokeAppWorld
                                    query {
                                        uri: "appworld://vendor/94377"
                                        invokeTargetId: "sys.appworld"
                                    }
                                }
                            ]
                        },
                        
                        ActionItem {
                                        id: shareAction
                                        title:qsTr("Share App") + Retranslate.onLanguageChanged
                                        imageSource: "asset:///images/ic_share.png"
                                        onTriggered: {
                                            invokeShare.trigger("bb.action.SHARE");
                                        }
                                        
                                        attachedObjects: [
                                            Invocation {
                                                id: invokeShare
                                                query {
                                                    mimeType: "text/plain"
                                                    data:shareData0
                                                }
                                            }
                                        ]
                        },
                        
                        ActionItem {
                            id: rateAction
                            title: qsTr("Rate App") + Retranslate.onLanguageChanged
                            imageSource: "asset:///images/ic_favorite.png"
                            onTriggered: {
                                invokeRate.trigger("bb.action.OPEN");
                            }
                            
                            attachedObjects: [
                                Invocation {
                                    id: invokeRate
                                    query {
                                        invokeTargetId: "sys.appworld"
                                        
                                        uri: "appworld://content/59998572"
                                    }
                                }
                            ]
                        }
                        
                        
                    ] // end of actions list
                } // end of MenuDefinition
                
                

                Page {
                    
                    actionBarVisibility: ChromeVisibility.Hidden
                    id: mP 
                    
                   
                    
                    Container {
            layout: AbsoluteLayout {
            }

            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill

            attachedObjects: LayoutUpdateHandler {
                onLayoutFrameChanged: {
                    onlineCont.preferredHeight = layoutFrame.height;
                }
            }
            Timer {
                id: myTimer
                // Specify a timeout interval of 1 second
                interval: 800
                onTimeout: {
                    myTimer.stop();
                    fade.play();
                } // end of onTimeout signal handler
            }
            Timer {
                id: lightTimer
                // Specify a timeout interval of 1 second
                interval: 1000
                onTimeout: {
                    if (pDiff < 1000) {
                        lightTimer.stop();
                        var isFirst1 = true;
                        asd(isFirst1);
                        
                        if(isNotify){
                            
                            if (currentPrayCode == 2) {
                                if (locale == 'tr') {
                                    alert.title = 'Gün Doğumu';
                                } else {
                                    alert.title = currentPray + ' ' + notifPlus;
                                }
                            } else {
                                alert.title = currentPray + ' ' + notifPlus;
                            }
                            alert.body = appName0;
                            alert.notify(); 
                        }
                        
                    }
                    var hours, minutes;
                    var seconds_left = (pDiff) / 1000; // do some time calculations
                    seconds_left = seconds_left % 86400;
                    hours = parseInt(seconds_left / 3600);
                    seconds_left = seconds_left % 3600;
                    minutes = parseInt(seconds_left / 60); 
                    kalanDakika = hours + ":" + minutes;
                    pDiff = pDiff - 1000;
                } // end of onTimeout signal handler
            }
            ScrollView {
                scrollViewProperties {
                    scrollMode: ScrollMode.Vertical
                }
                WebView {
                    id: onlineCont
                    url: "http://ezan.app/index.php?OS=BB"
                    onLoadingChanged: {
                        if (loadRequest.status == WebLoadStatus.Started) {
                            myActivity.start();
                        } else if (loadRequest.status == WebLoadStatus.Succeeded) {
                            myActivity.stop();
                        } else if (loadRequest.status == WebLoadStatus.Failed) {
                            myActivity.stop();
                        }
                    }
                    onMessageReceived: {
                        if (message.data.substring(0, 10) == "vakitArray") {
                            var res = message.data.split("vakitArray");
                            vakitler = JSON.parse(res[1]); //vakitler=JSON.parse(message.data);
                            var d = new Date();
                            if (isFirst) {
                                isFirst = false;
                                asd(isFirst);
                                refreshDay = d.getDate();
                            } else {
                                if (refreshDay != d.getDate()) {
                                    asd(isFirst);
                                    refreshDay = d.getDate();
                                }
                            }
                        }
                        if (message.data.substring(0, 8) == "strArray") {
                            var res2 = message.data.split("strArray");
                            var strArray = JSON.parse(res2[1]);
                            hDay = strArray[0];
                            hMonth = hicriAy(strArray[1]);
                            hYear = strArray[2];
                            
                        }
                        if (message.data.substring(0, 12) == "currentPlace") {
                            var res3 = message.data.split("currentPlace");
                            chosenLocationLabel=res3[1];
                        }
                    }

                    copyLinkAction.enabled: false
                    shareLinkAction.enabled: false
                    openLinkInNewTabAction.enabled: false
                    shareImageAction.enabled: false
                    saveImageAction.enabled: false

                }
            }
            ActivityIndicator {
                id: myActivity
                layoutProperties: AbsoluteLayoutProperties {
                    positionX: (dWith / 2) - ui.sdu(15)
                    positionY: (dHeight / 2) - ui.sdu(15)
                }
                preferredWidth: ui.sdu(30)
                preferredHeight: ui.sdu(30)
                verticalAlignment: VerticalAlignment.Center
                horizontalAlignment: HorizontalAlignment.Center
            }
            ImageView {
                id: splashImage
                imageSource: "asset:///1440_1440.png"
                visible: true
                onCreationCompleted: { //var gunArray=[];
                    
                    if (dHeight == 1280 && dWith == 768) {
                        setImageSource("asset:///1280_768.png");
                        Application.setCover(multiCover);
                    }
                    if (dHeight == 1280 && dWith == 720) {
                        setImageSource("asset:///1280_720.png");
                        Application.setCover(multiCover);
                    }
                    if (dHeight == 1440 && dWith == 1440) {
                        setImageSource("asset:///1440_1440.png");
                        Application.setCover(multiCover);
                    }
                    if (dHeight == 720 && dWith == 720) {
                        setImageSource("asset:///720_720.png");
                        Application.setCover(littleCover);
                    }
                }
                animations: [
                    FadeTransition {
                        id: fade
                        duration: 300
                        easingCurve: StockCurve.CubicOut
                        fromOpacity: 1.0
                        toOpacity: 0.0
                        onEnded: {
                            splashImage.visible = false;
                        }
                    }
                ]
            }

        }

        attachedObjects: [

            DisplayInfo {
                id: displayInfo
            },

            HardwareInfo {
                id: hardwareInfo
            },

            ComponentDefinition {
                id: aboutPage
                source: "about.qml"
            },
            ComponentDefinition {
                id: settingsPage
                source: "settings.qml"
            }

        ]

    }

    attachedObjects: [
        Notification {
            id: alert
        },
        SystemDialog {
            id: errorDialog
            title: qsTr("No Internet Connection!")
            confirmButton.label: qsTr("Launch Settings")

            onFinished: {
                myActivity.stop();
                if (value == SystemUiResult.ConfirmButtonSelection) {
                    invokeSettings.trigger("bb.action.OPEN");
                }

            }
        },

        Invocation {
            id: invokeSettings
            query {
                invokeTargetId: "sys.settings.card"
                mimeType: "settings/view"
            }
        },
        
        MultiCover {
            id: multiCover
            
            SceneCover {
                id: bigCover
                // Use this cover when a large cover is required
                MultiCover.level: CoverDetailLevel.High
                content: Frame {
                }
            
                function update() {
                    // Update the large cover dynamically
                }
            } // sceneCover HIGH
            
            SceneCover {
                id: smallCover
                // Use this cover when a small cover is required
                MultiCover.level: CoverDetailLevel.Medium
                content: FrameSmall {
                }
                function update() {
                    // Update the small cover dynamically
                }
            } // sceneCover MEDIUM
            
            function update() {
                bigCover.update()
                smallCover.update()
            }

        }, //MultiCover
        
        SceneCover {
            id: littleCover
            // Use this cover when a large cover is required
            MultiCover.level: CoverDetailLevel.High
            content: Frame2 {
            }
            
            function update() {
                // Update the large cover dynamically
            }
        } // sceneCover HIGH

    ]
    onCreationCompleted: {
        myTimer.start();

        if (menuAbout.title == "Hakkında") {
            locale = "tr"
        }

        if (menuAbout.title == "About") {
            locale = "en"
        }

        
        
        //Application.asleep.connect(onAsleep)
        
        Application.fullscreen.connect(onFullscreen);

    }
    

    function onFullscreen() {
        if (!isFirst2) {
            onlineCont.reload();
        }
        isFirst2=false;
    }
    
    //function onAsleep() {
    //    alert.notify();
    //}
    
    onChosenLocationLabelChanged: {
        var ff=false;
        asd(ff);
    }

}
