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
        layout: DockLayout {
        
        }
        horizontalAlignment: HorizontalAlignment.Fill
        //background: Color.create("#eeeeee")
        background: Color.create("#0092cc")
        //preferredHeight: 62
        
        layoutProperties: StackLayoutProperties {
            spaceQuota: 18
        }
        
        Container {
            horizontalAlignment: HorizontalAlignment.Left
            verticalAlignment: VerticalAlignment.Center
            leftPadding: 15
            Label {
                
                text: currentPray
                textStyle.fontSize: FontSize.Medium
                textStyle.color: Color.White
                verticalAlignment: VerticalAlignment.Center
                horizontalAlignment: HorizontalAlignment.Fill
            
            
            
            }
        }
        
        Container {
            horizontalAlignment: HorizontalAlignment.Right
            verticalAlignment: VerticalAlignment.Center
            rightPadding: 15
            //ImageView {
            //    imageSource: "asset:///images/hcA.png"
            //}
            
            Label {
                text: dayMonth
                textStyle.color: Color.White
                textStyle.fontWeight: FontWeight.Bold
            }
        }
        
        
        
        
        Container {
            
            layout: StackLayout {}
            
            
            
            
            //background: Color.create("#0480b0")
            background: Color.create("#075a7b")
            //background: Color.Black
            preferredHeight: 3
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Bottom
        
        }
    
    }
    
    
    
    
    
    
    

    
    
    
    Container {
        id:actionTakvim
        layout: StackLayout {
        
        }
        background: Color.White
        layoutProperties: StackLayoutProperties {
            spaceQuota: 64
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
                
                }
                
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                
                Container {layout: DockLayout {
                    
                }
                
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                //topMargin: 30
                topPadding:ui.sdu(-4)
                Label {
                    
                    id: actionDay
                    text:"<span style='font-size:32pt'>"+hDay+"</span>"
                    //text:gunSize1
                    //text:"<span style='font-size:32pt'>23</span>"
                    //"+gunSize1+"
                    //textStyle.fontSize: FontSize.XXLarge
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Top
                    textFormat: TextFormat.Html
                
                
                
                
                }
            
            
            
                }
                
                
                Container {
                    layout: DockLayout {
                    
                    }
                    topPadding:ui.sdu(-1.2)
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    Label {
                        text:"<span style='font-size:8pt'>"+hMonth+"</span>"
                        //text:"<span style='font-size:8pt'>Rajab</span>"
                        //text: locale;//textStyle.fontSize: FontSize.XXLarge
                        horizontalAlignment: HorizontalAlignment.Center
                        //verticalAlignment: VerticalAlignment.Bottom
                        textFormat: TextFormat.Html
                    
                    }
                
                
                
                
                
                }
            
            
            
            
            
            }
            
            
            
            
            
        }
        
        
        
        
     
    
    }
    
    
    Container {
        layout: DockLayout {
        
        }
        
        layoutProperties: StackLayoutProperties {
            spaceQuota: 18
        }
        horizontalAlignment: HorizontalAlignment.Fill
        
        //preferredHeight: 62
        //background: Color.create("#d5e9ef")
        background: Color.create("#e0e0e0")
        verticalAlignment: VerticalAlignment.Bottom
        
        Container {
            
            layout: StackLayout {}
            
            
            //background: Color.create("#0480b0")
            preferredHeight: 3
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Top
        
        }
        
        
        Label {
            text:kalanDakika
            textStyle.fontSize: FontSize.Large
            textStyle.color: Color.Red
            textStyle.fontWeight: FontWeight.W500
            verticalAlignment: VerticalAlignment.Center
            horizontalAlignment: HorizontalAlignment.Center
        
        
        }
    
    
    
    }
    
    
    Container {
        
        layout: StackLayout {}
        
        
        background: Color.create("#0480b0")
        preferredHeight: 3
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Bottom
    
    }



}