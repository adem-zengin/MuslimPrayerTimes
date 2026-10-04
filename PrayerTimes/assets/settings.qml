import bb.cascades 1.4
import com.myapi.web 1.0

Page {
    property variant api
    // C++'dan kayıtlı ID'leri çekiyoruz
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
        title: "Ayarlar"
        acceptAction: ActionItem {
            title: "Kaydet"
            onTriggered: {
                // Verileri bir paket (Map) haline getiriyoruz
                var r0 = { "imsak": tempImsak, "gunes": tempGunes, "ogle": tempOgle, "ikindi": tempIkindi, "aksam": tempAksam, "yatsi": tempYatsi };
                var r1 = { "imsak": remImsak, "gunes": remGunes, "ogle": remOgle, "ikindi": remIkindi, "aksam": remAksam, "yatsi": remYatsi };
                var dur = { "imsak": durImsak, "gunes": durGunes, "ogle": durOgle, "ikindi": durIkindi, "aksam": durAksam, "yatsi": durYatsi };
                
                var cId = countryDrop.selectedValue;
                var cyId = cityDrop.selectedValue;
                var dId = districtDrop.selectedValue;
                var dName = districtDrop.selectedOption.text;
                
                // ANA SAYFADAKİ ZAMANLAYICIYI TETİKLE
                // NavigationPane her zaman hayattadır.
                navigationPane.triggerBackgroundSave(r0, r1, dur, cId, cyId, dId, dName);
                
                // Ayarlar sayfasını güvenle kapat
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
                     // Cascades ArrayDataModel için alternatif indeksleme formatı
                     var data = countryModel.value(i); // veya countryModel.data([i])                  
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
                initialLoad = false; // Zincirleme seçim bitti
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
            
            Header { title: "Konum Bilgileri" }
            
            Container {
                leftPadding: 30; rightPadding: 30; topPadding: 20; bottomPadding: 20
                Label { text: "Ülke Seçin"; textStyle.base: SystemDefaults.TextStyles.SubtitleText }
                DropDown {
                    id: countryDrop
                    title: "Ülke Listesi"
                    onSelectedOptionChanged: { if (selectedOption) api.fetchCities(selectedOption.value); }
                }
                Label { text: "Şehir Seçin"; textStyle.base: SystemDefaults.TextStyles.SubtitleText; topMargin: 20 }
                DropDown {
                    id: cityDrop
                    title: "Şehir Listesi"
                    enabled: false
                    onSelectedOptionChanged: { if (selectedOption) api.fetchDistricts(selectedOption.value); }
                }
                Label { text: "İlçe Seçin"; textStyle.base: SystemDefaults.TextStyles.SubtitleText; topMargin: 20 }
                DropDown {
                    id: districtDrop
                    title: "İlçe Listesi"
                    enabled: false
                }
            }
            
            Header { title: "Bildirim Ayarları"; topMargin: 20 }
            
            Container {
                leftPadding: 30; rightPadding: 30; topPadding: 20; bottomPadding: 40
                
                // --- VAKİT SATIRLARI ---
                // İmsak
                Container {
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: "İmsak"; verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } }
                    ToggleButton { 
                        checked: tempImsak
                        onCheckedChanged: { tempImsak = checked } // Doğrudan C++'a gitmiyor
                    }
                }
                // Güneş
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: "Güneş"; verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } }
                    ToggleButton { 
                        checked: tempGunes
                        onCheckedChanged: { tempGunes = checked } // Doğrudan C++'a gitmiyor
                    }
                }
                // Öğle
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: "Öğle"; verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } }
                    ToggleButton { 
                        checked: tempOgle
                        onCheckedChanged: { tempOgle = checked } // Doğrudan C++'a gitmiyor
                    }
                }
                // İkindi
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: "İkindi"; verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } }
                    ToggleButton { 
                        checked: tempIkindi
                        onCheckedChanged: { tempIkindi = checked } // Doğrudan C++'a gitmiyor
                    }
                }
                // Akşam
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: "Akşam"; verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } }
                    ToggleButton { 
                        checked: tempAksam
                        onCheckedChanged: { tempAksam = checked } // Doğrudan C++'a gitmiyor
                    }
                }
                // Yatsı
                Container {
                    topMargin: 15
                    layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                    Label { text: "Yatsı"; verticalAlignment: VerticalAlignment.Center; layoutProperties: StackLayoutProperties { spaceQuota: 1 } }
                    ToggleButton { 
                        checked: tempYatsi
                        onCheckedChanged: { tempYatsi= checked } // Doğrudan C++'a gitmiyor
                    }
                }
            }
            
            Header {
                title: "Öncül Bildirimler"
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "İmsak"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: remImsakField
                    text: remImsak.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            remImsak = val;
                        } else {
                            remImsak = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Güneş"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: remGunesField
                    text: remGunes.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            remGunes = val;
                        } else {
                            remGunes = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Öğle"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: remOgleField
                    text: remOgle.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            remOgle = val;
                        } else {
                            remOgle = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "İkindi"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: remIkındiField
                    text: remIkindi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            remIkindi = val;
                        } else {
                            remIkindi = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Akşam"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: remAksamField
                    text: remAksam.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            remAksam = val;
                        } else {
                            remAksam = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Yatsı"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: remYatsiField
                    text: remYatsi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            remYatsi = val;
                        } else {
                            remYatsi = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Header {
                title: "Namaz Süresi"
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "İmsak"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: durImsakField
                    text: durImsak.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            durImsak = val;
                        } else {
                            durImsak = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Güneş"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: durGunesField
                    text: durGunes.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            durGunes = val;
                        } else {
                            durGunes = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Öğle"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: durOgleField
                    text: durOgle.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            durOgle = val;
                        } else {
                            durOgle = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "İkindi"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: durIkindiField
                    text: durIkindi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            durIkindi = val;
                        } else {
                            durIkindi = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Akşam"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: durAksamField
                    text: durAksam.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            durAksam = val;
                        } else {
                            durAksam = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
                    verticalAlignment: VerticalAlignment.Center
                    leftMargin: 10.0
                }
            }
            
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                leftPadding: 20.0; rightPadding: 20.0; topPadding: 10.0
                verticalAlignment: VerticalAlignment.Center
                
                Label {
                    text: "Yatsı"
                    verticalAlignment: VerticalAlignment.Center
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 } // Etiket alanı kaplasın
                }
                
                TextField {
                    id: durYatsiField
                    text: durYatsi.toString()
                    inputMode: TextFieldInputMode.NumbersAndPunctuation
                    maximumLength: 2
                    
                    // GENİŞLİK AYARI BURADA:
                    preferredWidth: 200.0 // Kutuyu küçültür
                    horizontalAlignment: HorizontalAlignment.Right // Sağa yaslar
                    textStyle.textAlign: TextAlign.Center // İçindeki rakamı ortalar
                    
                    onTextChanging: {
                        var val = parseInt(text);
                        if (!isNaN(val)) {
                            durYatsi = val;
                        } else {
                            durYatsi = 0;
                        }
                    }
                }
                
                Label {
                    text: "dk." // Yanına bir birim eklemek şık durur
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