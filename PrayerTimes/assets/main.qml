import bb.cascades 1.4
import com.myapi.web 1.0

NavigationPane {
    id: navigationPane
    
    onTopChanged: {
        if (page == navigationPane.at(0)) { 
            console.log("Returned from settings, refreshing data...");
            
            // 1. Fetch prayer times according to new location (updates prayerTimes)
            api.fetchPrayerTimes(); 
            
            // 2. Confirm location name update
            api.selectedDistrictNameChanged();
            
            // 3. (Optional) If 'prayerTimesChanged' signal is not automatically triggered in C++:
            // api.prayerTimesChanged();
        }
    }
    
    
    function getMiladiAy(ayNo) {
        var aylar = [
        "", 
        qsTr("January"), qsTr("February"), qsTr("March"), qsTr("April"), 
        qsTr("May"), qsTr("June"), qsTr("July"), qsTr("August"), 
        qsTr("September"), qsTr("October"), qsTr("November"), qsTr("December")
        ];
        return aylar[ayNo] || "";
    }
    
    function getHicriAy(ayNo) {
        var aylar = [
        "", 
        qsTr("Muharram"), qsTr("Safar"), qsTr("Rabi' al-Awwal"), qsTr("Rabi' al-Thani"), 
            qsTr("Jumada al-Awwal"), qsTr("Jumada al-Thani"), qsTr("Rajab"), qsTr("Sha'ban"), 
            qsTr("Ramadan"), qsTr("Shawwal"), qsTr("Dhu al-Qi'dah"), qsTr("Dhu al-Hijjah")
            ];
        return aylar[ayNo] || "";
    }
    
    // DELAYED SAVE FUNCTION CALLED FROM SETTINGS PAGE
    function triggerBackgroundSave(r0, r1, dur, cId, cyId, dId, dName) {
        // Calling async method using singleShot timer on C++ side.
        // This avoids blocking the QML thread and pops the page instantly.
        api.saveAllSettingsAsync(r0, r1, dur, cId, cyId, dId, dName);
    }

    Page {
        titleBar: TitleBar {
            kind: TitleBarKind.FreeForm
            kindProperties: FreeFormTitleBarKindProperties {
                Container {
                    layout: DockLayout {}
                    leftPadding: 20.0 
                    rightPadding: 20.0
                    
                    Label {
                        text: api.selectedDistrictName.toUpperCase()
                        verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Left
                        textStyle.fontWeight: FontWeight.W500
                        textFit.minFontSizeValue: 10.0
                    
                    }
                    
                    // Right container inside TitleBar:
                    Container {
                        id: settingsButtonContainer
                        horizontalAlignment: HorizontalAlignment.Right
                        verticalAlignment: VerticalAlignment.Center
                        
                        // Variable holding click status
                        property bool isPressed: false
                        
                        // Expand touch area (important for UX)
                        leftPadding: 10.0
                        rightPadding: 10.0
                        
                        onTouch: {
                            if (event.isDown()) {
                                // Turn blue upon touch
                                isPressed = true;
                            } 
                            else if (event.isUp()) {
                                // Upon release (if still over the button)
                                if (isPressed) {
                                    isPressed = false;
                                    
                                    // Page opening action
                                    var settingsPage = settingsDef.createObject();
                                    settingsPage.api = api; 
                                    navigationPane.push(settingsPage);
                                
                                }
                            } 
                            else if (event.isCancel()) {
                                // Cancel effect if dragged outside
                                isPressed = false;
                            }
                        }
                        
                        ImageView {
                            id: settingsIcon
                            imageSource: "asset:///images/ic_settings_light.png"
                            
                            // Color overlay
                            filterColor: {
                                if (settingsButtonContainer.isPressed) {
                                    return Color.create("#00AEEF"); // Bright blue when pressed
                                } else {
                                    // Normal state: White in dark theme, black in light theme
                                    return (Application.themeSupport.theme.colorTheme.style == VisualStyle.Dark) 
                                    ? Color.White : Color.Black;
                                }
                            }
                            
                            opacity: settingsButtonContainer.isPressed ? 0.6 : 1.0
                            
                            preferredWidth: 80.0
                            preferredHeight: 80.0
                            accessibility.name: "Settings"
                        }
                    }
                }
            }
        }
        
        Container {
            layout: StackLayout {}
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            background: Color.White // For a clean look
            
            // TOP SECTION: Date Panel (35% of screen)
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                layoutProperties: StackLayoutProperties { spaceQuota: 3.0 }
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                topPadding: 40; bottomPadding: 40
                
                // 1. GREGORIAN SECTION (Left side - Black)
                Container {
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    verticalAlignment: VerticalAlignment.Center
                    
                    Label {
                        // "2026-03-27" -> "27"
                        text: api.prayerTimes.date ? api.prayerTimes.date.substring(8, 10) : "--"
                        horizontalAlignment: HorizontalAlignment.Center
                        textFit.minFontSizeValue: 30.0
                        // RESET OR MAKE BOTTOM MARGIN NEGATIVE
                        bottomMargin: 0 
                    }
                    Label {
                        // Fetching month name from function
                        text: {
                            if (api.prayerTimes.date) {
                                var ayNo = parseInt(api.prayerTimes.date.substring(5, 7));
                                return navigationPane.getMiladiAy(ayNo);
                            }
                            return "";
                        }
                        textStyle.fontSize: FontSize.Large
                        horizontalAlignment: HorizontalAlignment.Center
                        topMargin: -10.0
                    }
                }
                
                // Vertical Divider Line
                Container {
                    preferredWidth: 2
                    background: Color.LightGray
                    verticalAlignment: VerticalAlignment.Fill
                    topMargin: 40; bottomMargin: 40
                }
                
                // 2. HIJRI SECTION (Right side - Blue)
                Container {
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    verticalAlignment: VerticalAlignment.Center
                    
                    Label {
                        text: api.prayerTimes.hijri_date ? api.prayerTimes.hijri_date.day : "--"                        
                        textStyle.color: Color.create("#00AEEF")
                        horizontalAlignment: HorizontalAlignment.Center
                        textFit.minFontSizeValue: 30.0
                        
                        // RESET OR MAKE BOTTOM MARGIN NEGATIVE
                        bottomMargin: 0 
                    }
                    Label {
                        text: {
                            if (api.prayerTimes.hijri_date) {
                                var h = api.prayerTimes.hijri_date;
                                var ayNo = parseInt(h.month);
                                // Get translation if numeric month, else print text directly
                                return navigationPane.getHicriAy(ayNo) || h.month;
                            }
                            return "";
                        }
                        textStyle.fontSize: FontSize.Large
                        textStyle.color: Color.create("#00AEEF")
                        horizontalAlignment: HorizontalAlignment.Center
                        topMargin: -10.0
                    }
                }
            } // End of Date Panel
            
            // BOTTOM SECTION: Prayer Times List (65% of screen)
            Container {
                layout: StackLayout {} 
                layoutProperties: StackLayoutProperties { spaceQuota: 7.0 }
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                leftPadding: 100; rightPadding: 100; bottomPadding: 10
                
                // Prayer Times (6 items)
                VakitSatiri { 
                    baslik: qsTr("Fajr") 
                    vakit: api.prayerTimes.imsak || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    // NOTE: Even if "Fajr" is displayed on screen, background matching uses the Turkish word from the API.
                    isCurrent: api.currentVakit === "İmsak" 
                }
                VakitSatiri { 
                    baslik: qsTr("Sunrise")
                    vakit: api.prayerTimes.gunes || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Güneş"
                }
                VakitSatiri { 
                    baslik: qsTr("Dhuhr")
                    vakit: api.prayerTimes.ogle || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Öğle"
                }
                VakitSatiri { 
                    baslik: qsTr("Asr")
                    vakit: api.prayerTimes.ikindi || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "İkindi"
                }
                VakitSatiri { 
                    baslik: qsTr("Maghrib")
                    vakit: api.prayerTimes.aksam || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Akşam"
                }
                VakitSatiri { 
                    baslik: qsTr("Isha")
                    vakit: api.prayerTimes.yatsi || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Yatsı"
                }
                
                // BOTTOM ROW (Time remaining indicator)
                // Wrapped in a Container to match height with others
                Container {
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                    layout: DockLayout {}
                    
                    Label {
                        // m_remainingTime data coming from C++
                        text: api.remainingTime || "-- : --" 
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Center
                        textStyle.fontSize: FontSize.XLarge
                        textStyle.fontWeight: FontWeight.W400
                        textStyle.color: Color.create("#00AEEF") // Remaining time can also be blue
                    }
                }
            }
        }
    }
    
    attachedObjects: [
        WebServices { id: api },
        ComponentDefinition {
            id: settingsDef
            source: "settings.qml"
        },
        SceneCover {
            id: activeFrame
            content: ActiveFrame { api: api }
        }
    ]
    
    onCreationCompleted: {
        Application.setCover(activeFrame); 
        
        if (!api.hasSavedLocation()) {
            navigationPane.push(settingsDef.createObject());
        } else {
            // 1. Fetch critical data (prayer times) immediately (lightweight)
            api.fetchPrayerTimes(); 

        }
    }


}