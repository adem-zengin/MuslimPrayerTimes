import bb.cascades 1.4

Container {
    property variant api
    
    // 1. Function to safely translate dynamic prayer time names coming from C++
    function getVakitIsmi(vakit) {
        if (!vakit) return "";
        if (vakit === "İmsak") return qsTr("Fajr");
        if (vakit === "Güneş") return qsTr("Sunrise");
        if (vakit === "Öğle") return qsTr("Dhuhr");
        if (vakit === "İkindi") return qsTr("Asr");
        if (vakit === "Akşam") return qsTr("Maghrib");
        if (vakit === "Yatsı") return qsTr("Isha");
        return vakit;
    }
    
    // 2. Function translating Hijri month names (to prevent QML syntax errors)
    function getHicriAy(ayNo) {
        var aylar = [
        "", 
        qsTr("Muharram"), qsTr("Safar"), qsTr("Rabi' al-Awwal"), qsTr("Rabi' al-Thani"), 
            qsTr("Jumada al-Awwal"), qsTr("Jumada al-Thani"), qsTr("Rajab"), qsTr("Sha'ban"), 
            qsTr("Ramadan"), qsTr("Shawwal"), qsTr("Dhu al-Qi'dah"), qsTr("Dhu al-Hijjah")
            ];
        return aylar[ayNo] || "";
    }
    
    background: Color.Black
    layout: DockLayout {} 
    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill
    
    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        layout: StackLayout {}
        
        Label {
            // Outputting through the translation function
            text: getVakitIsmi(api.currentVakit)
            textStyle.color: Color.create("#ff00c3ff")
            textStyle.fontSize: FontSize.Large
            horizontalAlignment: HorizontalAlignment.Center
        }
        
        Label {
            text: api.remainingTime || "00:00"
            textStyle.color: Color.White
            textStyle.fontWeight: FontWeight.Bold
            textStyle.fontSize: FontSize.XLarge
            horizontalAlignment: HorizontalAlignment.Center
        }
        
        Divider { topMargin: 10; bottomMargin: 10 }
        
        Label {
            text: {
                if (api.prayerTimes.hijri_date) {
                    var h = api.prayerTimes.hijri_date;
                    
                    // Directly calling our translation function
                    var ayIsmi = getHicriAy(parseInt(h.month)) || h.month;
                    
                    return h.day + " " + ayIsmi + " " + h.year;
                }
                return "";
            }
            
            textStyle.color: Color.Gray
            horizontalAlignment: HorizontalAlignment.Center
        }
    }
}