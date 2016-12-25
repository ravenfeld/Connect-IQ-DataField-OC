
using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Math;

class OCDataFieldView extends Ui.DataField
{   
    hidden var SIZE_DATAFIELD_1= 218;
    hidden var SIZE_DATAFIELD_2=108;
    hidden var SIZE_DATAFIELD_3=70; 
    hidden var heading_rad = null;
    hidden var distance_start = 0;
    hidden var distance_lap = 0; 
    hidden var isMetric = false;
    hidden var location_current = null;
    hidden var location_lap = null;
    hidden var northStr="";
    hidden var eastStr="";
    hidden var southStr="";
    hidden var westStr="";
    
	function initialize() {
		isMetric = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
		northStr = Ui.loadResource(Rez.Strings.north);
		eastStr = Ui.loadResource(Rez.Strings.east);
		southStr = Ui.loadResource(Rez.Strings.south);
		westStr = Ui.loadResource(Rez.Strings.west);
    
		DataField.initialize();
	}
    
	function compute(info) {
		heading_rad = info.currentHeading;
		distance_start = info.elapsedDistance;
		location_current = info.currentLocation;
		location_lap = info.startLocation;
	}
    
	function onUpdate(dc) {   
		var center_x = dc.getWidth() / 2;
		var center_y = dc.getHeight() / 2;
		var size_max = dc.getWidth() > dc.getHeight() ? dc.getHeight() : dc.getWidth();
		
		var flag = getObscurityFlags();
		if( flag == OBSCURE_BOTTOM|OBSCURE_RIGHT
			||flag == OBSCURE_BOTTOM|OBSCURE_LEFT
			||flag == OBSCURE_TOP|OBSCURE_RIGHT
			||flag == OBSCURE_TOP|OBSCURE_LEFT){
			size_max = size_max/1.25;
		}
		if( dc.getWidth() == dc.getHeight() ) {
			if( ( flag & OBSCURE_BOTTOM ) == OBSCURE_BOTTOM ) {
				center_y = center_y-10;
			}                
			if( ( flag & OBSCURE_RIGHT ) == OBSCURE_RIGHT ) {
				center_x = center_x-10;
			} 
			if( ( flag & OBSCURE_TOP ) == OBSCURE_TOP ) {
				center_y = center_y+10;
			}
			if( ( flag & OBSCURE_LEFT ) == OBSCURE_LEFT ) {
				center_x = center_x+10;
			}
		}
        
        var return_start_location = App.getApp().getProperty("return_start_location");
		var return_lap_location = App.getApp().getProperty("return_lap_location");
			
		if( heading_rad != null) {
			var map_declination =  App.getApp().getProperty("map_declination");
			if (map_declination != null ) {	
				heading_rad= heading_rad+map_declination*Math.PI/180;
			}
			
			if( heading_rad < 0 ) {
				heading_rad = 2*Math.PI+heading_rad;
			}
            				
			var orientation = null;	
			if( location_current !=null && location_lap != null ) {
				var	latitude_point_start;
				var	longitude_point_start;
				var latitude_point_arrive;
				var longitude_point_arrive;
				
				if( return_start_location || return_lap_location ){
					latitude_point_arrive = location_lap.toRadians()[0];
					longitude_point_arrive = location_lap.toRadians()[1];
				
					latitude_point_start = location_current.toRadians()[0];
					longitude_point_start = location_current.toRadians()[1];
				}else{
					latitude_point_start = location_lap.toRadians()[0];
					longitude_point_start = location_lap.toRadians()[1];
				
					latitude_point_arrive = location_current.toRadians()[0];
					longitude_point_arrive = location_current.toRadians()[1];
				}
					
				var distance = Math.acos(Math.sin(latitude_point_start)*Math.sin(latitude_point_arrive) + Math.cos(latitude_point_start)*Math.cos(latitude_point_arrive)*Math.cos(longitude_point_start-longitude_point_arrive));
    		
				if( distance > 0) {
					orientation = Math.acos((Math.sin(latitude_point_arrive)-Math.sin(latitude_point_start)*Math.cos(distance))/(Math.sin(distance)*Math.cos(latitude_point_start)));
    		
					if( Math.sin(longitude_point_arrive-longitude_point_start) <= 0 ) {
						orientation = 2*Math.PI-orientation;
					}
				}
			}
			
			var display_logo_orientation = App.getApp().getProperty("display_logo_orientation");
			
            if( display_logo_orientation ){
            	if( orientation != null && ( return_start_location || return_lap_location ) ){
					drawLogoOrientation(dc, center_x, center_y, size_max, -orientation);
				}else{
					drawLogoOrientation(dc, center_x, center_y, size_max, heading_rad);
				}
			}
			
			if( orientation !=null ){
				drawTextOrientation(dc, center_x, center_y, size_max, orientation);
			}else{
				drawTextOrientation(dc, center_x, center_y, size_max, heading_rad);
			}

			if( distance_start != null ) {   
				if( distance_lap != null) { 
					drawTextDistance(dc, center_x, center_y, size_max, distance_start-distance_lap);
				}else{
					drawTextDistance(dc, center_x, center_y, size_max, distance_start);
				}
			}else{
				drawTextDistance(dc, center_x, center_y, size_max, 0);
			}

			var display_compass = App.getApp().getProperty("display_compass");
			if( display_compass ){
				drawCompass(dc, center_x, center_y, size_max);
			}
		}
	}
                
	function onTimerLap(){
		if( !App.getApp().getProperty("return_start_location") ) {
			distance_lap=distance_start;
			location_lap=location_current;
		}               
	}        
    
	function drawTextDistance(dc, center_x, center_y, size, distance) {  
		var color = getColor(App.getApp().getProperty("color_text_distance"), getTextColor());
		var fontDist;          
		var fontMetric = Graphics.FONT_SMALL ;
		var display_metric = false;
		var distanceStr;
		var metricStr;
		
		if( size >= SIZE_DATAFIELD_1 ) {
			fontDist = Graphics.FONT_NUMBER_HOT ;
			display_metric=true;
		}else if( size >= SIZE_DATAFIELD_2 ){
			fontDist = Graphics.FONT_NUMBER_MILD ;
		}else{
			fontDist = Graphics.FONT_XTINY;
		}
       
		if ( isMetric ) {
			if( distance/1000.0 >= 1 ){
				metricStr="km";
				if( distance/100000.0 >= 1 ){
					distanceStr=(distance/1000.0).format("%d");
				}else if(distance/10000.0>=1){
					distanceStr=(distance/1000.0).format("%.1f");
				}else{
					distanceStr=(distance/1000.0).format("%.2f");
				}
			}else{
				metricStr="m";
				distanceStr=distance.format("%d");
			}
		}else{
			if( distance/1609.34 >= 1 ){
				metricStr="M";
				if( distance/160934.0 >= 1 ){
					distanceStr=(distance/1609.34).format("%d");
				}else if(distance/16093.4>=1){
					distanceStr=(distance/1609.34).format("%.1f");
				}else{
					distanceStr=(distance/1609.34).format("%.2f");
				}
			}else{
				metricStr="ft";
				distanceStr=(distance/3.042).format("%d");
			}
		}
		
		var text_width = dc.getTextWidthInPixels(distanceStr, fontDist);
		var text_height =dc.getFontHeight(fontDist);
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(center_x, center_y+size/4-12, fontDist, distanceStr, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		if( display_metric ){
			dc.drawText(center_x+text_width/2, center_y+size/4-12+text_height/4+2, fontMetric, metricStr, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}
    
	function drawTextOrientation(dc, center_x, center_y, size, orientation){
		var color = getColor(App.getApp().getProperty("color_text_orientation"), getTextColor());
		var fontDir;
		var fontMetric = Graphics.FONT_TINY;
		var dirStr=Lang.format("$1$", [(orientation*180/Math.PI).format("%d")]);
       	
		var display_metric = false;
		if(size >= SIZE_DATAFIELD_1) {
			fontDir = Graphics.FONT_NUMBER_THAI_HOT ;
			display_metric=true;
		}else if( size >= SIZE_DATAFIELD_2 ) {
			fontDir = Graphics.FONT_NUMBER_MILD ;
		}else{
			fontDir = Graphics.FONT_XTINY;
		}
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(center_x, center_y-size/4+12, fontDir, dirStr, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		if( display_metric ){
			var text_width = dc.getTextWidthInPixels(dirStr, fontDir);
			var text_height =dc.getFontHeight(fontDir);
			dc.drawText(center_x+text_width/2+2, center_y-size/4+12-text_height/4+2, fontMetric, "o", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}
        
	function drawCompass(dc, center_x, center_y, size) {
		var colorText = getColor(App.getApp().getProperty("color_text_compass"), getTextColor());
		var colorTextNorth = getColor(App.getApp().getProperty("color_text_north"), getTextColor());
		var colorCompass = getColor(App.getApp().getProperty("color_compass"), Graphics.COLOR_RED);
		var radius = size/2-12;
		var font;
		var penWidth = 0;
		var step = 0;
		var circle = false;
		
		if( size >= SIZE_DATAFIELD_1 ) {
			penWidth=8;
			step=12;
			font = Graphics.FONT_MEDIUM;
			circle=true;
		}else if( size >= SIZE_DATAFIELD_2 ) {
			penWidth=6;
			step=20;
			font = Graphics.FONT_TINY;
		}else{
			penWidth=5;
			step=25;
			font = Graphics.FONT_XTINY;
		}

		dc.setColor(colorTextNorth, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad, radius, font, northStr);
             
		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad + 3*Math.PI/2, radius, font, eastStr);
        
		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad+ Math.PI, radius, font, southStr);

		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad+ Math.PI / 2, radius, font, westStr);
        
		var startAngle = heading_rad*180/Math.PI - step;
		var endAngle = heading_rad*180/Math.PI + 90+ step;
       	dc.setColor(colorCompass, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(penWidth);
		for ( var i = 0; i < 4; i++ ) {
			dc.drawArc(center_x, center_y, radius, Gfx.ARC_CLOCKWISE, 90+startAngle-i*90, (360-90+endAngle.toLong()-i*90)%360 );
		}       
	}
    
	function drawLogoOrientation(dc, center_x, center_y, size, orientation){
		var color = getColor(App.getApp().getProperty("color_orientation_logo"), Graphics.COLOR_LT_GRAY);
		var radius;
		
		if( size >= SIZE_DATAFIELD_1 ) {
			radius=size/3.10;
		}else if( size >= SIZE_DATAFIELD_2 ) {
			radius=size/3;
		}else{
			radius=size/2-12;
		}
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
	
		var xy1 = pol2Cart(center_x, center_y, orientation, radius);
		var xy2 = pol2Cart(center_x, center_y, orientation+135*Math.PI/180, radius);
		var xy3 = pol2Cart(center_x, center_y, orientation+171*Math.PI/180, radius/2.5);
		var xy4 = pol2Cart(center_x, center_y, orientation, radius/3);
		var xy5 = pol2Cart(center_x, center_y, orientation+189*Math.PI/180, radius/2.5);
		var xy6 = pol2Cart(center_x, center_y, orientation+225*Math.PI/180, radius);
		dc.fillPolygon([xy1, xy2, xy3, xy4, xy5, xy6]);
	}
    
	function drawTextPolar(dc, center_x, center_y, radian, radius, font, text) {
		var xy = pol2Cart(center_x, center_y, radian, radius);
		dc.drawText(xy[0], xy[1], font, text, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	}
    
	function pol2Cart(center_x, center_y, radian, radius) {
		var x = center_x - radius * Math.sin(radian);
		var y = center_y - radius * Math.cos(radian);
		 
		return [Math.ceil(x), Math.ceil(y)];
	}
     
   	function getColor(color_property, color_default){
        if (color_property == 1) {
        	return Gfx.COLOR_BLUE;
        }else if (color_property == 2) {
        	return Gfx.COLOR_DK_BLUE;
        }else if (color_property == 3) {
        	return Gfx.COLOR_GREEN;
        }else if (color_property == 4) {
        	return Gfx.COLOR_DK_GREEN;
        }else if (color_property == 5) {
        	return Gfx.COLOR_LT_GRAY;
        }else if (color_property == 6) {
        	return Gfx.COLOR_DK_GRAY;
        }else if (color_property == 7) {
        	return Gfx.COLOR_ORANGE;
        }else if (color_property == 8) {
        	return Gfx.COLOR_PINK;
        }else if (color_property == 9) {
        	return Gfx.COLOR_PURPLE;
        }else if (color_property == 10) {
        	return Gfx.COLOR_RED;
        }else if (color_property == 11) {
        	return Gfx.COLOR_DK_RED;
        }else if (color_property == 12) {
        	return Gfx.COLOR_YELLOW;
        }
        return color_default;
    }  
        
    function getTextColor(){
    	return (getBackgroundColor() == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }    
}
