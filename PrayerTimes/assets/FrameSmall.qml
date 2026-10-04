import bb.cascades 1.4


Container {
    
    layout: StackLayout {
        orientation: LayoutOrientation.TopToBottom
    
    }
    
    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill
    layoutProperties: StackLayoutProperties {
        spaceQuota: 100
    }
    
    
    
    
    Container {
        id:actionTakvim
        layout: StackLayout {
        
        }
        //background: Color.White
        layoutProperties: StackLayoutProperties {
            spaceQuota: 100
        }
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        Container {
            layout: DockLayout {
            
            }
            
            preferredHeight: Infinity
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            Container {
                layout: StackLayout {
                orientation: LayoutOrientation.LeftToRight
                }
                
                horizontalAlignment: HorizontalAlignment.Left
                verticalAlignment: VerticalAlignment.Center
                
                Container {layout: DockLayout {
                    
                }
                bottomPadding: 10
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                Label {
                    
                    id: actionDay
                    text: hDay
                    textStyle.color: Color.White
                    textStyle.fontSize: FontSize.PointValue
                    textStyle.fontSizeValue: 21.0
                        horizontalAlignment: HorizontalAlignment.Center
                        verticalAlignment: VerticalAlignment.Center
                        
                    }
            
            
            
                }
                
                
                Container {
                    layout: StackLayout {
                    orientation: LayoutOrientation.TopToBottom
                    }
                    //topPadding:ui.sdu(-1.2)
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    leftPadding: 30
                    bottomPadding: 7
                    Label {
                        text:hMonth
                        textStyle.color: Color.White
                        textStyle.fontWeight: FontWeight.W300
                        //verticalAlignment: VerticalAlignment.Bottom
                        horizontalAlignment: HorizontalAlignment.Left
                        
                        textStyle.fontSize: FontSize.PointValue
                        textStyle.fontSizeValue: 6.0

                    }
                    
                    Label {
                        //text:kalanDakika
                        text:"<span style='font-size:6pt'>"+currentPray+"  </span> <span style='font-size:6pt'>"+kalanDakika+"</span>"
                        textStyle.color: Color.Yellow
                        textStyle.fontWeight: FontWeight.W500
                        //verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Left
                        textFormat: TextFormat.Html

                        textStyle.fontSize: FontSize.PointValue
                        textStyle.fontSizeValue: 6.0
                        topMargin: -10
                    
                    
                    }
                    
                    
                
                
                
                
                
                }
            
            
            
            
            
            }
        
        
        
        
        
        }
    
    
    
    
    
    
    }
    
    

    
    
    

    background: back.imagePaint
    
    attachedObjects: [
        ImagePaintDefinition {
            id: back
            repeatPattern: RepeatPattern.X
            imageSource: "asset:///images/bluegradientline.amd"
        
        }
    ]

}


