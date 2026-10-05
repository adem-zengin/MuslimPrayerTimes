import bb.cascades 1.4
import com.myapi.web 1.0

Page {
    property variant api
    // Fetching saved IDs from C++
    property string savedCountryId: api.getSavedValue("location/country_id")
    property string savedCityId: api.getSavedValue("location/city_id")
    property string savedDistrictId: api.getSavedValue("location/district_id")
    property bool initialLoad: true 
    property bool tempImsak: api.getNotificationSetting("imsak", false)
    property bool tempGunes: api.getNotificationSetting("gunes", false)
    property bool tempOgle: api.getNotificationSetting("ogle", false)
    property bool tempIkindi: api.getNotificationSetting("ikindi", false)
    property bool tempAksam: api.getNotificationSetting("aksam", true)
    property bool tempYatsi: api.getNotificationSetting("yatsi", false)
    
    property int remImsak: api.getSavedValue("reminders/imsak") || 15
    property int remGunes: api.getSavedValue("reminders/gunes") || 15
    property int remOgle: api.getSavedValue("reminders/ogle") || 15
    property int remIkindi: api.getSavedValue("reminders/ikindi") || 15
    property int remAksam: api.getSavedValue("reminders/aksam") || 15
    property int remYatsi: api.getSavedValue("reminders/yatsi") || 15
    
    property int durImsak: api.getSavedValue("durations/imsak") || 15
    property int durGunes: api.getSavedValue("durations/gunes") || 15
    property int durOgle: api.getSavedValue("durations/ogle") || 15
    property int durIkindi: api.getSavedValue("durations/ikindi") || 15
    property int durAksam: api.getSavedValue("durations/aksam") || 15
    property int durYatsi: api.getSavedValue("durations/yatsi") || 15
    
    titleBar: TitleBar {
        title: qsTr("Settings")
        acceptAction: ActionItem {
            title: qsTr("Save")
            onTriggered: {
                // Bundling data into a map
                var r0 = { "imsak": tempImsak, "gunes": tempGunes, "ogle": tempOgle, "ikindi": tempIkindi, "aksam": tempAksam, "yatsi": tempYatsi };
                var r1 = { "imsak": remImsak, "gunes": remGunes, "ogle": remOgle, "ikindi": remIkindi, "aksam": remAksam, "yatsi": remYatsi };
                var dur = { "imsak": durImsak, "gunes": durGunes, "ogle": durOgle, "ikindi": durIkindi, "aksam": durAksam, "yatsi": durYatsi };
                
                var cId = countryDrop.selectedValue;
                var cyId = cityDrop.selectedValue;
                var dId = districtDrop.selectedValue;
                var dName = districtDrop.selectedOption.text;
                
                // TRIGGER TIMER ON MAIN PAGE
                navigationPane.triggerBackgroundSave(r0, r1, dur, cId, cyId, dId, dName);
                
                // Safely close settings page
                navigationPane.pop();
            }
        }
    }
    
    attachedObjects: [
        WebServices {
            id: api
            onCountryModelChanged: {
                countryDrop.removeAll();
                for (var i = 0; i < countryModel.size(); i++) {
                    var data = countryModel.value(i);                
                    if (data) {
                        var opt = optionComponent.createObject();
                        opt.text = data["name_en"]; 
                        opt.value = data["_id"];
                        if (initialLoad && opt.value === savedCountryId) opt.selected = true;
                        countryDrop.add(opt);
                    }
                }
            }
            onCityModelChanged: {
                cityDrop.removeAll();
                for (var j = 0; j < cityModel.size(); j++) {
                    var cData = cityModel.data([j]);
                    var cOpt = optionComponent.createObject();
                    cOpt.text = cData["name"];
                    cOpt.value = cData["_id"];
                    if (initialLoad && cOpt.value === savedCityId) cOpt.selected = true;
                    cityDrop.add(cOpt);
                }
                cityDrop.enabled = (cityDrop.count() > 0);
            }
            onDistrictModelChanged: {
                districtDrop.removeAll();
                for (var k = 0; k < districtModel.size(); k++) {
                    var dData = districtModel.data([k]);
                    var dOpt = optionComponent.createObject();
                    dOpt.text = dData["name"];
                    dOpt.value = dData["_id"];
                    if (initialLoad && dOpt.value === savedDistrictId) dOpt.selected = true;
                    districtDrop.add(dOpt);
                }
                districtDrop.enabled = (districtDrop.count() > 0);
                initialLoad = false; 
            }
        },
        ComponentDefinition {
            id: optionComponent
            Option {}
        }
    ]
    
    ScrollView {
        Container {
            horizontalAlignment: HorizontalAlignment.Fill
            
            Header { title: qsTr("Location Info") }
            
            Container {
                leftPadding: 30; rightPadding: 30; topPadding: 20; bottomPadding: 20
                Label { text: qsTr("Select Country"); textStyle.base: SystemDefaults.TextStyles.SubtitleText }
                DropDown {
                    id: countryDrop
                    title: qsTr("Country List")
                    onSelectedOptionChanged: { if (selectedOption) api.fetchCities(selectedOption.value); }
                }
                Label { text: qsTr("Select City"); textStyle.base: SystemDefaults.TextStyles.SubtitleText; topMargin: 20 }
                DropDown {
                    id: cityDrop
                    title: qsTr("City List")
                    enabled: false
                    onSelectedOptionChanged: { if (selectedOption) api.fetchDistricts(selectedOption.value); }
                }
                Label { text: qsTr("Select District"); textStyle.base: SystemDefaults.TextStyles.SubtitleText; topMargin: 20 }
                DropDown {
                    id: districtDrop
                    title: qsTr("District List")
                    enabled: false
                }
            }
            
            Header { title: qsTr("On-Time Notifications"); topMargin: 40 }
            
            Container {
                leftPadding: 30; rightPadding: 30; topPadding: 20; bottomPadding: 40
                
                // Fajr
                Container {
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: qsTr("Fajr"); verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } textStyle.textAlign: TextAlign.Left }
                    ToggleButton { 
                        checked: tempImsak
                        onCheckedChanged: { tempImsak = checked } 
                    }
                }
                // Sunrise
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: qsTr("Sunrise"); verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } textStyle.textAlign: TextAlign.Left}
                    ToggleButton { 
                        checked: tempGunes
                        onCheckedChanged: { tempGunes = checked } 
                    }
                }
                // Dhuhr
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: qsTr("Dhuhr"); verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } textStyle.textAlign: TextAlign.Left}
                    ToggleButton { 
                        checked: tempOgle
                        onCheckedChanged: { tempOgle = checked } 
                    }
                }
                // Asr
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: qsTr("Asr"); verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } textStyle.textAlign: TextAlign.Left}
                    ToggleButton { 
                        checked: tempIkindi
                        onCheckedChanged: { tempIkindi = checked } 
                    }
                }
                // Maghrib
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: qsTr("Maghrib"); verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } textStyle.textAlign: TextAlign.Left}
                    ToggleButton { 
                        checked: tempAksam
                        onCheckedChanged: { tempAksam = checked } 
                    }
                }
                // Isha
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: qsTr("Isha"); verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } textStyle.textAlign: TextAlign.Left}
                    ToggleButton { 
                        checked: tempYatsi
                        onCheckedChanged: { tempYatsi = checked } 
                    }
                }
            }
            
            Header {
                title: qsTr("Notifications Before Time")
                topMargin: 40
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 20.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Fajr")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } 
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: remImsakField
                    text: remImsak.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { remImsak = val; } else { remImsak = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Sunrise")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: remGunesField
                    text: remGunes.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { remGunes = val; } else { remGunes = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Dhuhr")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: remOgleField
                    text: remOgle.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { remOgle = val; } else { remOgle = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Asr")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: remIkındiField
                    text: remIkindi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { remIkindi = val; } else { remIkindi = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Maghrib")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left 
                }
                
                TextField {
                    id: remAksamField
                    text: remAksam.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { remAksam = val; } else { remAksam = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Isha")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: remYatsiField
                    text: remYatsi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { remYatsi = val; } else { remYatsi = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Header {
                title: qsTr("Prayer Duration")
                topMargin: 40
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 20.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Fajr")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: durImsakField
                    text: durImsak.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { durImsak = val; } else { durImsak = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Sunrise")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: durGunesField
                    text: durGunes.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { durGunes = val; } else { durGunes = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Dhuhr")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: durOgleField
                    text: durOgle.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { durOgle = val; } else { durOgle = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Asr")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: durIkindiField
                    text: durIkindi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { durIkindi = val; } else { durIkindi = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Maghrib")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: durAksamField
                    text: durAksam.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { durAksam = val; } else { durAksam = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: qsTr("Isha")
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    textStyle.textAlign: TextAlign.Left
                }
                
                TextField {
                    id: durYatsiField
                    text: durYatsi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    preferredWidth: 200.0 
                    horizontalAlignment: HorizontalAlignment.Right 
                    textStyle.textAlign: TextAlign.Center 
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) { durYatsi = val; } else { durYatsi = 0; }
                    }
                }
                
                Label {
                    text: qsTr("min.")
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
        
        }
    
    }
    
    
    onCreationCompleted: {
        api.fetchCountries();
    }
}