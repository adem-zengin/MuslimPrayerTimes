import bb.cascades 1.4

Container {
    property alias baslik: baslikLabel.text
    property alias vakit: vakitLabel.text
    // Aktif vakit olup olmadığını kontrol eden yeni property
    property bool isCurrent: false 
    
    horizontalAlignment: HorizontalAlignment.Fill
    verticalAlignment: VerticalAlignment.Fill
    layout: DockLayout {}
    
    // Aktif vakit ise satırın arkasına çok hafif bir renk verebilirsin (Opsiyonel)
    background: isCurrent ? Color.create("#0500AEEF") : Color.Transparent
    
    Container {
        verticalAlignment: VerticalAlignment.Center
        horizontalAlignment: HorizontalAlignment.Fill
        layout: StackLayout { orientation: LayoutOrientation.LeftToRight }
        
        Label {
            //text:"İmsak"
            id: baslikLabel
            layoutProperties: StackLayoutProperties { spaceQuota: 1.0 }
            textStyle.fontSize: FontSize.Medium
            verticalAlignment: VerticalAlignment.Center
            textStyle.textAlign: TextAlign.Left
            // Aktif vakit ise başlığı kalın ve mavi yap
            textStyle.fontWeight: isCurrent ? FontWeight.Bold : FontWeight.Normal
            textStyle.color: isCurrent ? Color.create("#00AEEF") : Color.Default
        }
        Label {
            //text:"05:00"
            id: vakitLabel
            textStyle.fontSize: FontSize.Medium
            textStyle.fontWeight: isCurrent ? FontWeight.Bold : FontWeight.Normal
            textStyle.color: isCurrent ? Color.create("#00AEEF") : Color.Default
            verticalAlignment: VerticalAlignment.Center
        }
    }
    
    Divider {
        verticalAlignment: VerticalAlignment.Bottom
        //visible: !isCurrent // Aktif vakitte çizgiyi gizleyebilirsin veya rengini değiştirebilirsin
    }
}