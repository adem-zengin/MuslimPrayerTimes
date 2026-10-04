import bb.cascades 1.4
import com.myapi.web 1.0

NavigationPane {
    id: navigationPane
    
    onTopChanged: {
        if (page == navigationPane.at(0)) { 
            console.log("Ayarlardan dönüldü, veriler tazeleniyor...");
            
            // 1. Yeni konuma göre vakitleri çek (Bu işlem prayerTimes'ı günceller)
            api.fetchPrayerTimes(); 
            
            // 2. Konum isminin güncellendiğini teyit et
            api.selectedDistrictNameChanged();
            
            // 3. (Opsiyonel) Eğer C++ tarafında 'prayerTimesChanged' sinyali 
            // otomatik tetiklenmiyorsa manuel tetiklemek gerekebilir:
            // api.prayerTimesChanged();
        }
    }
    
    // AY İSİMLERİ TANIMLAMALARI (Tüm sayfa erişebilir)
    property variant miladiAylar: [
    "", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", 
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ]
    property variant hicriAylar: [
    "", "Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", 
    "Cemaziyelevvel", "Cemaziyelahir", "Recep", "Şaban", 
        "Ramazan", "Şevval", "Zilkade", "Zilhicce"
        ]
    
    // AYARLAR SAYFASINDAN ÇAĞRILAN GECİKMELİ KAYIT FONKSİYONU
    function triggerBackgroundSave(r0, r1, dur, cId, cyId, dId, dName) {
        // C++ tarafında singleShot timer kullanan asenkron metodu çağırıyoruz.
        // Bu sayede QML thread'i bloke olmaz, sayfa anında 'pop' edilir.
        api.saveAllSettingsAsync(r0, r1, dur, cId, cyId, dId, dName);
    }
    
    // AÇILIŞTAKİ DONMAYI ÖNLEYEN FONKSİYON
    function delayedStartup() {
        console.log("Uygulama açıldı, ağır işlemler 2 saniye sonra başlayacak...");
        // API içindeki asenkron yükleme metodunu çağırıyoruz
        api.loadDataAndScheduleAsync(2000); 
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
                    
                    // TitleBar içindeki sağdaki Container:
                    Container {
                        id: settingsButtonContainer
                        horizontalAlignment: HorizontalAlignment.Right
                        verticalAlignment: VerticalAlignment.Center
                        
                        // Tıklama durumunu tutan değişken
                        property bool isPressed: false
                        
                        // Tıklama alanını genişletmek için (UX için önemli)
                        leftPadding: 10.0
                        rightPadding: 10.0
                        
                        onTouch: {
                            if (event.isDown()) {
                                // Parmak dokunduğu an mavi yap
                                isPressed = true;
                            } 
                            else if (event.isUp()) {
                                // Parmak çekildiği an (Eğer hala butonun üzerindeyse)
                                if (isPressed) {
                                    isPressed = false;
                                    
                                    // Sayfa açma işlemi
                                    var settingsPage = settingsDef.createObject();
                                    settingsPage.api = api; 
                                    navigationPane.push(settingsPage);
                                    
                                }
                            } 
                            else if (event.isCancel()) {
                                // Sürükleyip dışarı çıktıysa efekti iptal et
                                isPressed = false;
                            }
                        }
                        
                        ImageView {
                            id: settingsIcon
                            imageSource: "asset:///images/ic_settings_light.png"
                            
                            // Renk değişimi (Overlay)
                            filterColor: {
                                if (settingsButtonContainer.isPressed) {
                                    return Color.create("#00AEEF"); // Basılınca Parlak Mavi
                                } else {
                                    // Normal durum: Koyu temada beyaz, açık temada siyah
                                    return (Application.themeSupport.theme.colorTheme.style == VisualStyle.Dark) 
                                    ? Color.White : Color.Black;
                                }
                            }
                            
                            opacity: settingsButtonContainer.isPressed ? 0.6 : 1.0
                            
                            preferredWidth: 80.0
                            preferredHeight: 80.0
                            accessibility.name: "Ayarlar"
                        }
                    }
                }
            }
        }
        
        Container {
            layout: StackLayout {}
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            background: Color.White // Temiz bir görünüm için
            
            // ÜST KISIM: Tarih Paneli (Ekranın %35'i)
            Container {
                layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
                layoutProperties: StackLayoutProperties { spaceQuota: 3.0 }
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                topPadding: 40; bottomPadding: 40
                
                // 1. MİLANİ KISIM (Sol taraf - Siyah)
                Container {
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    verticalAlignment: VerticalAlignment.Center
                    
                    Label {
                        // "2026-03-27" -> "27"
                        text: api.prayerTimes.date ? api.prayerTimes.date.substring(8, 10) : "--"
                        horizontalAlignment: HorizontalAlignment.Center
                        textFit.minFontSizeValue: 30.0
                        // ALT BOŞLUĞU SIFIRLA VEYA NEGATİF YAP
                        bottomMargin: 0 
                    }
                    Label {
                        // Ay ismini diziden çekiyoruz
                        text: {
                            if (api.prayerTimes.date) {
                                var ayNo = parseInt(api.prayerTimes.date.substring(5, 7));
                                return navigationPane.miladiAylar[ayNo] || "";
                            }
                            return "";
                        }
                        textStyle.fontSize: FontSize.Large
                        horizontalAlignment: HorizontalAlignment.Center
                        // ÜST BOŞLUĞU SIFIRLA VEYA NEGATİF YAP
                        topMargin: -10.0 // Mesafeyi daha da kapatmak için negatif değer kullanabilirsin
                    }
                }
                
                // Dikey Ayırıcı Çizgi
                Container {
                    preferredWidth: 2
                    background: Color.LightGray
                    verticalAlignment: VerticalAlignment.Fill
                    topMargin: 40; bottomMargin: 40
                }
                
                // 2. HİCRİ KISIM (Sağ taraf - Mavi)
                Container {
                    layoutProperties: StackLayoutProperties { spaceQuota: 1 }
                    verticalAlignment: VerticalAlignment.Center
                    
                    Label {
                        text: api.prayerTimes.hijri_date ? api.prayerTimes.hijri_date.day : "--"                        
                        textStyle.color: Color.create("#00AEEF")
                        horizontalAlignment: HorizontalAlignment.Center
                        textFit.minFontSizeValue: 30.0
                        
                        // ALT BOŞLUĞU SIFIRLA VEYA NEGATİF YAP
                        bottomMargin: 0 
                    }
                    Label {
                        text: {
                            if (api.prayerTimes.hijri_date) {
                                var h = api.prayerTimes.hijri_date;
                                return navigationPane.hicriAylar[parseInt(h.month)] || h.month;
                            }
                            return "";
                        }
                        textStyle.fontSize: FontSize.Large
                        textStyle.color: Color.create("#00AEEF")
                        horizontalAlignment: HorizontalAlignment.Center
                        
                        // ÜST BOŞLUĞU SIFIRLA VEYA NEGATİF YAP
                        topMargin: -10.0 // Mesafeyi daha da kapatmak için negatif değer kullanabilirsin
                    }
                }
            } // Tarih Paneli Sonu
            
            // ALT KISIM: Vakit Listesi (Ekranın %65'i)
            // ALT KISIM: Vakit Listesi
            Container {
                layout: StackLayout {} 
                layoutProperties: StackLayoutProperties { spaceQuota: 7.0 }
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                leftPadding: 100; rightPadding: 100; bottomPadding: 10
                
                // Vakitler (6 adet)
                VakitSatiri { 
                    baslik: "İmsak"; vakit: api.prayerTimes.imsak || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "İmsak" 
                }
                VakitSatiri { 
                    baslik: "Güneş"; vakit: api.prayerTimes.gunes || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Güneş"
                }
                VakitSatiri { 
                    baslik: "Öğle"; vakit: api.prayerTimes.ogle || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Öğle"
                }
                VakitSatiri { 
                    baslik: "İkindi"; vakit: api.prayerTimes.ikindi || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "İkindi"
                }
                VakitSatiri { 
                    baslik: "Akşam"; vakit: api.prayerTimes.aksam || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Akşam"
                }
                VakitSatiri { 
                    baslik: "Yatsı"; vakit: api.prayerTimes.yatsi || "--:--"
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 } 
                    isCurrent: api.currentVakit === "Yatsı"
                }
                                
                // EN ALT SATIR (Süre göstergesi)
                // Bunu da bir Container'a alıyoruz ki yüksekliği diğerleriyle aynı olsun
                Container {
                    layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                    layout: DockLayout {}
                    
                    Label {
                        // C++'dan gelen m_remainingTime verisi
                        text: api.remainingTime || "-- : --" 
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Center
                        textStyle.fontSize: FontSize.XLarge
                        textStyle.fontWeight: FontWeight.W400
                        textStyle.color: Color.create("#00AEEF") // Kalan süreyi de mavi yapabiliriz
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
            // 1. Kritik veriyi (vakitler) hemen çek (Hafif işlem)
            api.fetchPrayerTimes(); 
            
            // 2. Takvim yazma gibi ağır işlemleri geciktirerek başlat
            delayedStartup();
        }
    }
    

}
