import bb.cascades 1.4

Container {
    property variant api
    
    background: Color.Black
    layout: DockLayout {} // İçeriği merkeze almak için en iyisi
    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill
    
    Container {
        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Center
        layout: StackLayout {}
        
        Label {
            // Türkçe karakter sorunu devam ederse C++ tarafında solve edeceğiz
            text: api.currentVakit || ""
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
            // Hicri ayları dizi olarak tanımlıyoruz
            property variant hicriAylar: [
            "", "Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", 
            "Cemaziyelevvel", "Cemaziyelahir", "Recep", "Şaban", 
            "Ramazan", "Şevval", "Zilkade", "Zilhicce"
            ]
            
            text: {
                if (api.prayerTimes.hijri_date) {
                    var h = api.prayerTimes.hijri_date;
                    
                    // Eğer ay bilgisi rakam olarak geliyorsa (Örn: 10)
                    // h.month değerini sayıya çevirip diziden ismini alıyoruz
                    var ayIsmi = hicriAylar[parseInt(h.month)] || h.month;
                    
                    return h.day + " " + ayIsmi + " " + h.year;
                }
                return "";
            }
            
            
            textStyle.color: Color.Gray
            horizontalAlignment: HorizontalAlignment.Center
        }
    }
}