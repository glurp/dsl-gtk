# encoding: utf-8
# Usage:
#   update $authors list, and LOCAL_HDOCS (where to put html file generated)
#   run this on time by hour/days
#   it create mstat directory and memorise commits counts by project (one file by project)
#   it create the html file withe webglcode, jquiry code,  3d matrix data (no dependency) ...
#
$authors= %w{wycats markbates jimweirich} # seems the most productives...
$authors1= %w{rdaubarede}

LOCAL_HTDOCS="d:/usr/"
RUBYGEMS="http://rubygems.org" 


require 'thread'
require 'json'
require 'nokogiri'
require 'open-uri'


Thread.abort_on_exception=true

############################################################################
###########################################################################
###########################################################################
###########################################################################

############### Html complete :  SurfacePlot + JQuery + scpecific code ##################

$html=<<'EEND'
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8">
  <title>GEMS</title>
  <script>
/*
 * SurfacePlot.js
 * Written by Greg Ross
 */
SurfacePlot = function(container){
    this.containerElement = container;
    
    this.redraw = function(){
        this.surfacePlot.init();
        this.surfacePlot.redraw();
    }
};


SurfacePlot.prototype.draw = function(data, options, basicPlotOptions, glOptions){
    var xPos = options.xPos;
    var yPos = options.yPos;
    var w = options.width;
    var h = options.height;
    var colourGradient = options.colourGradient;
    
    var fillPolygons = basicPlotOptions.fillPolygons;
    var tooltips = basicPlotOptions.tooltips;
    var renderPoints = basicPlotOptions.renderPoints;
    
    var xTitle = options.xTitle;
    var yTitle = options.yTitle;
    var zTitle = options.zTitle;
    var backColour = options.backColour;
    var axisTextColour = options.axisTextColour;
    var hideFlatMinPolygons = options.hideFlatMinPolygons;
    var tooltipColour = options.tooltipColour;
    var origin = options.origin;
    var startXAngle_canvas = options.startXAngle;
    var startZAngle_canvas = options.startZAngle;
    var zAxisTextPosition = options.zAxisTextPosition;
    
    if (this.surfacePlot) {
		
  		var isOpenGL = function() {
  			var openGLSelected = true;
  			if (glOptions.chkControlId && document.getElementById(glOptions.chkControlId)) 
                  openGLSelected = document.getElementById(glOptions.chkControlId).checked;
  				
  			return openGLSelected;
  		}
  		
  		if (glOptions.animate && isOpenGL()) //{
  			var data = this.createFrames(data, glOptions);
  //			this.surfacePlot.reRender(data, glOptions);
  //			return;
  //		}
  //		else {
  			this.surfacePlot.cleanUp();
  			this.containerElement.innerHTML = "";
  //		}
  
      startXAngle_canvas = this.surfacePlot.currentXAngle_canvas;
      startZAngle_canvas = this.surfacePlot.currentZAngle_canvas;
      var rotationMatrix = this.surfacePlot.rotationMatrix;
  
	}
   
    this.surfacePlot = new JSSurfacePlot(xPos, yPos, w, h, colourGradient, this.containerElement, 
      fillPolygons, tooltips, xTitle, yTitle, zTitle, renderPoints, backColour, axisTextColour, 
      hideFlatMinPolygons, tooltipColour, origin, startXAngle_canvas, startZAngle_canvas, rotationMatrix, zAxisTextPosition, 
      glOptions, data);
    
    this.surfacePlot.redraw();
};

Array.prototype.clone = function() {
    var arr = this.slice(0);
    for( var i = 0; i < this.length; i++ ) {
        if( this[i].clone ) {
            arr[i] = this[i].clone();
        }
    }
    return arr;
}
SurfacePlot.prototype.createFrames = function(newData, glOptions) {
	
	var currentData = this.surfacePlot.data;
	var numRows = newData.nRows;
    var numCols = newData.nCols;
	var currentValues = this.originalFormattedValues ? this.originalFormattedValues : currentData.formattedValues;
    var newValues = newData.formattedValues;
	this.originalFormattedValues = newValues.clone();
	var self = this;
	
	var canInterpolateFrames = function() {
		return currentData.nRows == newData.nRows && currentData.nCols == newData.nCols &&
		  currentValues.length == newValues.length;
	};
	
	var getDiff = function(value1, value2) {
		if (value1 == 0)
            diff = value2;
        else if (value2 == 0)
            diff = value1;
        else if (value2 > value1)
            diff = value2 / value1;
        else if (value1 > value2)
            diff = value1 / value2;
        else
            diff = 0;
            
        if (diff < 0)
            diff *= -1;
            
        diff -= 1;
		
		return diff;
	};
	
	var getMaxZvalueDiff = function() {
		
		var maxDiff = 0;
		var diff = 0;
		var currentValue, newValue;
		
		for (var i = 0; i < numRows; i++) {
			for (var j = 0; j < numCols; j++) {
				
				currentValue = currentValues[i][j];
				newValue = newValues[i][j];
				
				var diff = getDiff(newValue, currentValue);
				
				if (diff > maxDiff) 
					maxDiff = diff;
			}
		}
		
		return maxDiff;
		
	};
	
	if (canInterpolateFrames) {
		
		var maxDiff = getMaxZvalueDiff();
		
		if (maxDiff <= 0) 
		  return newData;
		  
		var numFrames = Math.min(10, Math.floor( maxDiff ));
		
		if (numFrames == 0)
		  return newData;
		  
		var rows = [];
		var cols = [];
		var frames = [];
		  
		for (var f = 0; f < numFrames; f++) {
			
			rows = [];
			
			for (var i = 0; i < numRows; i++) {
				
				cols = [];
				
				for (var j = 0; j < numCols; j++) {
				
				    currentValue = currentValues[i][j];
                    newValue = newValues[i][j];
					
					var diff = newValue - currentValue;
					
					if (diff == 0) 
						cols.push(newValue);
					else {
						var increment = (diff / numFrames) * (f+1);
						var interpolatedValue = currentValue + increment;
						cols.push(interpolatedValue);
					}
				
				}
				
				rows.push(cols);
				
			}
			
			frames.push(rows);
			
		}
		
		var dataCopy = JSON.parse(JSON.stringify(newData));
		
		dataCopy.frames = true;
		dataCopy.formattedValues = frames;
		glOptions.framesPerSecond = 60;
		
		return dataCopy;
		
	}
	
	return newData;
	
}

SurfacePlot.prototype.getChart = function(){
    return this.surfacePlot;
}

SurfacePlot.prototype.cleanUp = function(){
    if (this.surfacePlot == null) 
        return;
    
    this.surfacePlot.cleanUp();
    this.surfacePlot = null;
}
JSSurfacePlot = function(x, y, width, height, colourGradient, targetElement, fillRegions, tooltips, xTitle, yTitle, zTitle, renderPoints, backColour,
   axisTextColour, hideFlatMinPolygons, tooltipColour, origin, startXAngle_canvas, startZAngle_canvas, rotationMatrix, zAxisTextPosition, glOptions, data){
    this.xTitle = xTitle;
    this.yTitle = yTitle;
    this.zTitle = zTitle;
    this.backColour = backColour;
    this.axisTextColour = axisTextColour;
    this.glOptions = glOptions;
    var targetDiv;
    var id;
    var canvas;
    var canvasContext = null;
    this.context2D = null;
    var scale = JSSurfacePlot.DEFAULT_SCALE;
    var zTextPosition = 0.5;
    
    if (startXAngle_canvas != null && startXAngle_canvas != void 0) 
        this.currentXAngle_canvas = startXAngle_canvas;
    else
      this.currentXAngle_canvas = JSSurfacePlot.DEFAULT_X_ANGLE_CANVAS;
    
    if (startZAngle_canvas != null && startZAngle_canvas != void 0) 
        this.currentZAngle_canvas = startZAngle_canvas;
    else
        this.currentZAngle_canvas = JSSurfacePlot.DEFAULT_Z_ANGLE_CANVAS;
        
    if (rotationMatrix != null && rotationMatrix != void 0) 
      this.rotationMatrix = rotationMatrix;
    else { 
      this.rotationMatrix = mat4.create();
      mat4.identity(this.rotationMatrix);
      mat4.rotate(this.rotationMatrix, degToRad(JSSurfacePlot.DEFAULT_X_ANGLE_WEBGL), [1, 0, 0]);
      mat4.rotate(this.rotationMatrix, degToRad(JSSurfacePlot.DEFAULT_Y_ANGLE_WEBGL), [0, 0, 1]);
    }
      
    if (zAxisTextPosition != null && zAxisTextPosition != void 0) 
        zTextPosition = zAxisTextPosition;
    
    this.data = data;
    var data3ds = null;
    var dataframes = null;
    var displayValues = null;
    this.numXPoints = 0;
    this.numYPoints = 0;
    var transformation;
    var cameraPosition;
    var colourGradient;
    
    var mouseDown1 = false;
    var mouseDown3 = false;
    var mousePosX = null;
    var mousePosY = null;
    var lastMousePos = new Point(0, 0);
    var mouseButton1Up = null;
    var mouseButton3Up = null;
    var mouseButton1Down = new Point(0, 0);
    var mouseButton3Down = new Point(0, 0);
    var closestPointToMouse = null;
    var xAxisHeader = "";
    var yAxisHeader = "";
    var zAxisHeader = "";
    var xAxisTitleLabel = new Tooltip(true);
    var yAxisTitleLabel = new Tooltip(true);
    var zAxisTitleLabel = new Tooltip(true);
    var tTip = new Tooltip(false, tooltipColour);
    
    this.glSurface = null;
    this.glAxes = null;
    this.useWebGL = false;
    this.gl = null;
    this.shaderProgram = null;
    this.shaderTextureProgram = null;
    this.mvMatrix = mat4.create();
    this.mvMatrixStack = [];
    this.pMatrix = mat4.create();
    var mouseDown = false;
    var lastMouseX = null;
    var lastMouseY = null;
    var canvas_support_checked = false;
    var canvas_supported = true;
    
	this.reRender = function(data, glOptions) {
		
		this.bail = true;
		this.glOptions = glOptions;
		this.data = data;
		this.dataToRender = this.data.formattedValues;
        this.frames = this.data.frames;
        this.determineMinMaxZValues();
        
        if (!this.useWebGL) {
            var maxAxisValue = this.nice_num(this.maxZValue);
            this.scaleAndNormalise(this.maxZValue / maxAxisValue);
        }
        else {
            if (this.glOptions.autoCalcZScale) 
                this.calculateZScale();
            
            this.glOptions.xTicksNum = this.glOptions.xLabels.length - 1;
            this.glOptions.yTicksNum = this.glOptions.yLabels.length - 1;
            this.glOptions.zTicksNum = this.glOptions.zLabels.length - 1;
        }
		
		var cGradient;
        
        if (colourGradient) 
            cGradient = colourGradient;
        else 
            cGradient = getDefaultColourRamp();
        
        this.colourGradientObject = new ColourGradient(this.minZValue, this.maxZValue, cGradient);
        
        var canvasWidth = width;
        var canvasHeight = height;
        
        var minMargin = 20;
        var drawingDim = canvasWidth - minMargin * 2;
        var marginX = minMargin;
        var marginY = minMargin;
        
        if (canvasWidth > canvasHeight) {
            drawingDim = canvasHeight - minMargin * 2;
            marginX = (canvasWidth - drawingDim) / 2;
        }
        else 
            if (canvasWidth < canvasHeight) {
                drawingDim = canvasWidth - minMargin * 2;
                marginY = (canvasHeight - drawingDim) / 2;
            }
        
        var xDivision = 1 / (this.numXPoints - 1);
        var yDivision = 1 / (this.numYPoints - 1);
        var xPos, yPos;
        var i, j;
        var numPoints = this.numXPoints * this.numYPoints;
        data3ds = new Array();
        dataframe = new Array();
        var index = 0;
        var colIndex;
        
        if (this.frames) {
            for (var k = 0; k < this.numFrames; k++) {
                index = 0;
                dataframe = new Array();
                for (i = 0, xPos = -0.5; i < this.numXPoints; i++, xPos += xDivision) {
                    for (j = 0, yPos = 0.5; j < this.numYPoints; j++, yPos -= yDivision) {
                        var x = xPos;
                        var y = yPos;
                        
                        if (this.useWebGL) 
                            colIndex = this.numYPoints - 1 - j;
                        else 
                            colIndex = j;
                        
                        dataframe[index] = new Point3D(x, y, this.dataToRender[k][i][colIndex]); // Reverse the y-axis to match the non-webGL surface.
                        index++;
                    }
                }
                data3ds.push(dataframe);
            }
        }
        else {
            for (i = 0, xPos = -0.5; i < this.numXPoints; i++, xPos += xDivision) {
                for (j = 0, yPos = 0.5; j < this.numYPoints; j++, yPos -= yDivision) {
                    var x = xPos;
                    var y = yPos;
                    
                    if (this.useWebGL) 
                        colIndex = this.numYPoints - 1 - j;
                    else 
                        colIndex = j;
                    
                    data3ds[index] = new Point3D(x, y, this.dataToRender[i][colIndex]); // Reverse the y-axis to match the non-webGL surface.
                    index++;
                }
            }
        }
		
		var r = hexToR(this.backColour) / 255;
        var g = hexToG(this.backColour) / 255;
        var b = hexToB(this.backColour) / 255;
        
        this.initWorldObjects(data3ds);
		
		this.gl.clearColor(r, g, b, 0); // Set the background colour.
        this.gl.enable(this.gl.DEPTH_TEST);
			
	   this.allFramesRendered = false;
	   this.bail = false;
	   this.tick();
		
	}
	
    function getInternetExplorerVersion() // Returns the version of Internet Explorer or a -1
    // (indicating the use of another browser).
    {
        var rv = -1; // Return value assumes failure.
        if (navigator.appName == 'Microsoft Internet Explorer') {
            var ua = navigator.userAgent;
            var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
            if (re.exec(ua) != null) 
                rv = parseFloat(RegExp.$1);
        }
        return rv;
    }
    
    function supports_canvas(){
        if (canvas_support_checked) 
            return canvas_supported;
        
        canvas_support_checked = true;
        canvas_supported = !!document.createElement('canvas').getContext;
        return canvas_supported;
    }
    
    this.init = function(){
        if (id) 
            targetElement.removeChild(targetDiv);
        
        id = this.allocateId();
        
        transformation = new Th3dtran();
        
        this.createTargetDiv();
        
        if (!targetDiv) 
            return;
        
        this.dataToRender = this.data.formattedValues;
        this.frames = this.data.frames;
        this.determineMinMaxZValues();
        this.createCanvas();
        
        if (!this.useWebGL) {
            var maxAxisValue = this.nice_num(this.maxZValue);
            this.scaleAndNormalise(this.maxZValue / maxAxisValue);
        }
        else {
            if (this.glOptions.autoCalcZScale) 
                this.calculateZScale();
            
            this.glOptions.xTicksNum = this.glOptions.xLabels.length - 1;
            this.glOptions.yTicksNum = this.glOptions.yLabels.length - 1;
            this.glOptions.zTicksNum = this.glOptions.zLabels.length - 1;
        }
    };
    
    this.determineMinMaxZValues = function(){
        this.numXPoints = this.data.nRows;
        this.numYPoints = this.data.nCols;
        this.minZValue = Number.MAX_VALUE;
        this.maxZValue = Number.MIN_VALUE;
        
        if (this.frames) {
            this.numFrames = this.dataToRender.length;
            for (var k = 0; k < this.numFrames; k++) {
                for (var i = 0; i < this.numXPoints; i++) {
                    for (var j = 0; j < this.numYPoints; j++) {
                        var value = this.dataToRender[k][i][j];
                        
                        if (value < this.minZValue) 
                            this.minZValue = value;
                        
                        if (value > this.maxZValue) 
                            this.maxZValue = value;
                    }
                }
            }
        }
        else {
            for (var i = 0; i < this.numXPoints; i++) {
                for (var j = 0; j < this.numYPoints; j++) {
                    var value = this.dataToRender[i][j];
                    
                    if (value < this.minZValue) 
                        this.minZValue = value;
                    
                    if (value > this.maxZValue) 
                        this.maxZValue = value;
                }
            }
        }
    }
    
    this.cleanUp = function(){
        this.gl = null;
        
        canvas.onmousedown = null;
        document.onmouseup = null;
        document.onmousemove = null;
        
        this.numXPoints = 0;
        this.numYPoints = 0;
        canvas = null;
        canvasContext = null;
        this.data = null;
        this.colourGradientObject = null;
        this.glSurface = null;
        this.glAxes = null;
        this.shaderProgram = null;
        this.shaderTextureProgram = null;
        this.shaderAxesProgram = null;
        this.mvMatrix = null;
        this.mvMatrixStack = null;
        this.pMatrix = null;
    }
    
    function hideTooltip(){
        tTip.hide();
    }
    
    function displayTooltip(e){
        var position = new Point(e.x, e.y);
        tTip.show(tooltips[closestPointToMouse], 200);
    }
    
    this.render = function(){
    
        if (this.useWebGL) // Render shiny WebGL surface plot.
        {
            var r = hexToR(this.backColour) / 255;
            var g = hexToG(this.backColour) / 255;
            var b = hexToB(this.backColour) / 255;
            
            this.initWorldObjects(data3ds);
            this.gl.clearColor(r, g, b, 0); // Set the background colour.
            this.gl.enable(this.gl.DEPTH_TEST);
            this.tick();
            
            return;
        }
        else // Render not quite so shiny non-GL surface-plot.
        {
            canvasContext.clearRect(0, 0, canvas.width, canvas.height);
            canvasContext.fillStyle = this.backColour;
            canvasContext.fillRect(0, 0, canvas.width, canvas.height);
            
            var canvasWidth = width;
            var canvasHeight = height;
            
            var minMargin = 20;
            var drawingDim = canvasWidth - minMargin * 2;
            var marginX = minMargin;
            var marginY = minMargin;
            
            transformation.init();
            transformation.rotate(this.currentXAngle_canvas, 0.0, this.currentZAngle_canvas);
            transformation.scale(scale);
            
            if (origin != null && origin != void 0) 
                transformation.translate(origin.x, origin.y, 0.0);
            else 
                transformation.translate(drawingDim / 2.0 + marginX, drawingDim / 2.0 + marginY, 0.0);
            
            cameraPosition = new Point3D(drawingDim / 2.0 + marginX, drawingDim / 2.0 + marginY, -1000.0);
            
            if (renderPoints) {
                for (i = 0; i < data3ds.length; i++) {
                    var point3d = data3ds[i];
                    canvasContext.fillStyle = '#ff2222';
                    var transformedPoint = transformation.ChangeObjectPoint(point3d);
                    transformedPoint.dist = distance({
                        x: transformedPoint.ax,
                        y: transformedPoint.ay
                    }, {
                        x: cameraPosition.ax,
                        y: cameraPosition.ay
                    });
                    
                    var x = transformedPoint.ax;
                    var y = transformedPoint.ay;
                    
                    canvasContext.beginPath();
                    var dotSize = JSSurfacePlot.DATA_DOT_SIZE;
                    
                    canvasContext.arc((x - (dotSize / 2)), (y - (dotSize / 2)), 1, 0, self.Math.PI * 2, true);
                    canvasContext.fill();
                }
            }
            
            var axes = this.createAxes();
            var polygons = this.createPolygons(data3ds);
            
            for (i = 0; i < axes.length; i++) 
                polygons[polygons.length] = axes[i];
            
            // Sort the polygons so that the closest ones are rendered last
            // and therefore are not occluded by those behind them.
            // This is really Painter's algorithm.
            polygons.sort(PolygonComaparator);
            
            canvasContext.lineWidth = 1;
            canvasContext.strokeStyle = '#888';
            canvasContext.lineJoin = "round";
            
            for (i = 0; i < polygons.length; i++) {
                var polygon = polygons[i];
                
                if (polygon.isAnAxis()) {
                    var p1 = polygon.getPoint(0);
                    var p2 = polygon.getPoint(1);
                    
                    canvasContext.beginPath();
                    canvasContext.moveTo(p1.ax, p1.ay);
                    canvasContext.lineTo(p2.ax, p2.ay);
                    canvasContext.stroke();
                }
                else {
                    var p1 = polygon.getPoint(0);
                    var p2 = polygon.getPoint(1);
                    var p3 = polygon.getPoint(2);
                    var p4 = polygon.getPoint(3);
                    
                    var colourValue = (p1.lz * 1.0 + p2.lz * 1.0 + p3.lz * 1.0 + p4.lz * 1.0) / 4.0;
                    
                    var rgbColour = this.colourGradientObject.getColour(colourValue);
                    var colr = "rgb(" + rgbColour.red + "," + rgbColour.green + "," + rgbColour.blue + ")";
                    canvasContext.fillStyle = colr;
                    
                    canvasContext.beginPath();
                    canvasContext.moveTo(p1.ax, p1.ay);
                    canvasContext.lineTo(p2.ax, p2.ay);
                    canvasContext.lineTo(p3.ax, p3.ay);
                    canvasContext.lineTo(p4.ax, p4.ay);
                    canvasContext.lineTo(p1.ax, p1.ay);
                    
                    if (fillRegions) 
                        canvasContext.fill();
                    else 
                        canvasContext.stroke();
                }
            }
            
            if (supports_canvas()) 
                this.renderAxisText(axes);
        }
    };
    
    this.renderAxisText = function(axes){
        var xLabelPoint = new Point3D(0.0, 0.5, 0.0);
        var yLabelPoint = new Point3D(-0.5, 0.0, 0.0);
        var zLabelPoint = new Point3D(-0.5, 0.5, zTextPosition);
        
        var transformedxLabelPoint = transformation.ChangeObjectPoint(xLabelPoint);
        var transformedyLabelPoint = transformation.ChangeObjectPoint(yLabelPoint);
        var transformedzLabelPoint = transformation.ChangeObjectPoint(zLabelPoint);
        
        var xAxis = axes[0];
        var yAxis = axes[1];
        var zAxis = axes[2];
        
        canvasContext.fillStyle = this.axisTextColour;
        
        if (xAxis.distanceFromCamera > yAxis.distanceFromCamera) {
            var xAxisLabelPosX = transformedxLabelPoint.ax;
            var xAxisLabelPosY = transformedxLabelPoint.ay;
            canvasContext.fillText(xTitle, xAxisLabelPosX, xAxisLabelPosY);
        }
        
        if (xAxis.distanceFromCamera < yAxis.distanceFromCamera) {
            var yAxisLabelPosX = transformedyLabelPoint.ax;
            var yAxisLabelPosY = transformedyLabelPoint.ay;
            canvasContext.fillText(yTitle, yAxisLabelPosX, yAxisLabelPosY);
        }
        
        if (xAxis.distanceFromCamera < zAxis.distanceFromCamera) {
            var zAxisLabelPosX = transformedzLabelPoint.ax;
            var zAxisLabelPosY = transformedzLabelPoint.ay;
            canvasContext.fillText(zTitle, zAxisLabelPosX, zAxisLabelPosY);
        }
    };
    
    var sort = function(array){
        var len = array.length;
        
        if (len < 2) {
            return array;
        }
        
        var pivot = Math.ceil(len / 2);
        return merge(sort(array.slice(0, pivot)), sort(array.slice(pivot)));
    };
    
    var merge = function(left, right){
        var result = [];
        while ((left.length > 0) && (right.length > 0)) {
            if (left[0].distanceFromCamera < right[0].distanceFromCamera) {
                result.push(left.shift());
            }
            else {
                result.push(right.shift());
            }
        }
        
        result = result.concat(left, right);
        return result;
    };
    
    
    this.createAxes = function(){
        var axisOrigin = new Point3D(-0.5, 0.5, 0);
        var xAxisEndPoint = new Point3D(0.5, 0.5, 0);
        var yAxisEndPoint = new Point3D(-0.5, -0.5, 0);
        var zAxisEndPoint = new Point3D(-0.5, 0.5, 1);
        
        var transformedAxisOrigin = transformation.ChangeObjectPoint(axisOrigin);
        var transformedXAxisEndPoint = transformation.ChangeObjectPoint(xAxisEndPoint);
        var transformedYAxisEndPoint = transformation.ChangeObjectPoint(yAxisEndPoint);
        var transformedZAxisEndPoint = transformation.ChangeObjectPoint(zAxisEndPoint);
        
        var axes = new Array();
        
        var xAxis = new Polygon(cameraPosition, true);
        xAxis.addPoint(transformedAxisOrigin);
        xAxis.addPoint(transformedXAxisEndPoint);
        xAxis.calculateCentroid();
        xAxis.calculateDistance();
        axes[axes.length] = xAxis;
        
        var yAxis = new Polygon(cameraPosition, true);
        yAxis.addPoint(transformedAxisOrigin);
        yAxis.addPoint(transformedYAxisEndPoint);
        yAxis.calculateCentroid();
        yAxis.calculateDistance();
        axes[axes.length] = yAxis;
        
        var zAxis = new Polygon(cameraPosition, true);
        zAxis.addPoint(transformedAxisOrigin);
        zAxis.addPoint(transformedZAxisEndPoint);
        zAxis.calculateCentroid();
        zAxis.calculateDistance();
        axes[axes.length] = zAxis;
        
        return axes;
    };
    
    this.createPolygons = function(data3D){
        var i;
        var j;
        var polygons = new Array();
        var index = 0;
        
        for (i = 0; i < this.numXPoints - 1; i++) {
            for (j = 0; j < this.numYPoints - 1; j++) {
                var polygon = new Polygon(cameraPosition, false);
                
                var rawP1 = data3D[j + (i * this.numYPoints)];
                var rawP2 = data3D[j + (i * this.numYPoints) + this.numYPoints];
                var rawP3 = data3D[j + (i * this.numYPoints) + this.numYPoints + 1];
                var rawP4 = data3D[j + (i * this.numYPoints) + 1];
                
                if (hideFlatMinPolygons &&
                (rawP2.lz == this.minZValue || (rawP1.lz == this.minZValue && rawP4.lz == this.minZValue) ||
                ((rawP4.lz == this.minZValue || rawP3.lz == this.minZValue) && i > 1 && j > 0))) 
                    continue;
                
                var p1 = transformation.ChangeObjectPoint(rawP1);
                var p2 = transformation.ChangeObjectPoint(rawP2);
                var p3 = transformation.ChangeObjectPoint(rawP3);
                var p4 = transformation.ChangeObjectPoint(rawP4);
                
                polygon.addPoint(p1);
                polygon.addPoint(p2);
                polygon.addPoint(p3);
                polygon.addPoint(p4);
                polygon.calculateCentroid();
                polygon.calculateDistance();
                
                polygons[index] = polygon;
                index++;
            }
        }
        
        return polygons;
    };
    
    this.getDefaultColourRamp = function(){
        var colour1 = {
            red: 0,
            green: 0,
            blue: 255
        };
        var colour2 = {
            red: 0,
            green: 255,
            blue: 255
        };
        var colour3 = {
            red: 0,
            green: 255,
            blue: 0
        };
        var colour4 = {
            red: 255,
            green: 255,
            blue: 0
        };
        var colour5 = {
            red: 255,
            green: 0,
            blue: 0
        };
        return [colour1, colour2, colour3, colour4, colour5];
    };
    
    this.redraw = function(){
        var cGradient;
        
        if (colourGradient) 
            cGradient = colourGradient;
        else 
            cGradient = getDefaultColourRamp();
        
        this.colourGradientObject = new ColourGradient(this.minZValue, this.maxZValue, cGradient);
        
        var canvasWidth = width;
        var canvasHeight = height;
        
        var minMargin = 20;
        var drawingDim = canvasWidth - minMargin * 2;
        var marginX = minMargin;
        var marginY = minMargin;
        
        if (canvasWidth > canvasHeight) {
            drawingDim = canvasHeight - minMargin * 2;
            marginX = (canvasWidth - drawingDim) / 2;
        }
        else 
            if (canvasWidth < canvasHeight) {
                drawingDim = canvasWidth - minMargin * 2;
                marginY = (canvasHeight - drawingDim) / 2;
            }
        
        var xDivision = 1 / (this.numXPoints - 1);
        var yDivision = 1 / (this.numYPoints - 1);
        var xPos, yPos;
        var i, j;
        var numPoints = this.numXPoints * this.numYPoints;
        data3ds = new Array();
        dataframe = new Array();
        var index = 0;
        var colIndex;
        
        if (this.frames) {
            for (var k = 0; k < this.numFrames; k++) {
                index = 0;
                dataframe = new Array();
                for (i = 0, xPos = -0.5; i < this.numXPoints; i++, xPos += xDivision) {
                    for (j = 0, yPos = 0.5; j < this.numYPoints; j++, yPos -= yDivision) {
                        var x = xPos;
                        var y = yPos;
                        
                        if (this.useWebGL) 
                            colIndex = this.numYPoints - 1 - j;
                        else 
                            colIndex = j;
                        
                        dataframe[index] = new Point3D(x, y, this.dataToRender[k][i][colIndex]); // Reverse the y-axis to match the non-webGL surface.
                        index++;
                    }
                }
                data3ds.push(dataframe);
            }
        }
        else {
            for (i = 0, xPos = -0.5; i < this.numXPoints; i++, xPos += xDivision) {
                for (j = 0, yPos = 0.5; j < this.numYPoints; j++, yPos -= yDivision) {
                    var x = xPos;
                    var y = yPos;
                    
                    if (this.useWebGL) 
                        colIndex = this.numYPoints - 1 - j;
                    else 
                        colIndex = j;
                    
                    data3ds[index] = new Point3D(x, y, this.dataToRender[i][colIndex]); // Reverse the y-axis to match the non-webGL surface.
                    index++;
                }
            }
        }
        
        this.render();
    };
    
    this.allocateId = function(){
        var count = 0;
        var name = "surfacePlot";
        
        do {
            count++;
        }
        while (document.getElementById(name + count))
        return name + count;
    };
    
    this.createTargetDiv = function(){
        targetDiv = document.createElement("div");
        targetDiv.id = id;
        targetDiv.className = "surfaceplot";
        targetDiv.style.background = '#ffffff';
        targetDiv.style.position = 'absolute';
        
        if (!targetElement) 
            return;//document.body.appendChild(this.targetDiv);
        else {
            targetDiv.style.position = 'relative';
            targetElement.appendChild(targetDiv);
        }
        
        targetDiv.style.left = x + "px";
        targetDiv.style.top = y + "px";
    };
    
    this.getShader = function(id){
        var shaderScript = document.getElementById(id);
        
        if (!shaderScript) {
            return null;
        }
        
        var str = "";
        var k = shaderScript.firstChild;
        
        while (k) {
            if (k.nodeType == 3) {
                str += k.textContent;
            }
            
            k = k.nextSibling;
        }
        
        var shader;
        
        if (shaderScript.type == "x-shader/x-fragment") {
            shader = this.gl.createShader(this.gl.FRAGMENT_SHADER);
        }
        else 
            if (shaderScript.type == "x-shader/x-vertex") {
                shader = this.gl.createShader(this.gl.VERTEX_SHADER);
            }
            else {
                return null;
            }
        
        this.gl.shaderSource(shader, str);
        this.gl.compileShader(shader);
        
        if (!this.gl.getShaderParameter(shader, this.gl.COMPILE_STATUS)) {
            alert(this.gl.getShaderInfoLog(shader));
            return null;
        }
        
        return shader;
    };
    
    this.createProgram = function(fragmentShaderID, vertexShaderID){
        if (this.gl == null) 
            return null;
        
        var fragmentShader = this.getShader(fragmentShaderID);
        var vertexShader = this.getShader(vertexShaderID);
        
        if (fragmentShader == null || vertexShader == null) 
            return null;
        
        var program = this.gl.createProgram();
        this.gl.attachShader(program, vertexShader);
        this.gl.attachShader(program, fragmentShader);
        this.gl.linkProgram(program);
        
        program.pMatrixUniform = this.gl.getUniformLocation(program, "uPMatrix");
        program.mvMatrixUniform = this.gl.getUniformLocation(program, "uMVMatrix");
        
        program.nMatrixUniform = this.gl.getUniformLocation(program, "uNMatrix");
        program.axesColour = this.gl.getUniformLocation(program, "uAxesColour");
        program.ambientColorUniform = this.gl.getUniformLocation(program, "uAmbientColor");
        program.lightingDirectionUniform = this.gl.getUniformLocation(program, "uLightingDirection");
        program.directionalColorUniform = this.gl.getUniformLocation(program, "uDirectionalColor");
        
        return program;
    };
    
    
    this.initShaders = function(){
        if (this.gl == null) 
            return false;
        
        // Non-texture shaders
        this.shaderProgram = this.createProgram("shader-fs", "shader-vs");
        
        // Texture shaders
        this.shaderTextureProgram = this.createProgram("texture-shader-fs", "texture-shader-vs");
        
        // Axes shaders
        this.shaderAxesProgram = this.createProgram("axes-shader-fs", "axes-shader-vs");
        
        if (!this.gl.getProgramParameter(this.shaderProgram, this.gl.LINK_STATUS)) {
            return false;
        }
        
        return true;
    };
    
    this.mvPushMatrix = function(surfacePlot){
        var copy = mat4.create();
        mat4.set(surfacePlot.mvMatrix, copy);
        surfacePlot.mvMatrixStack.push(copy);
    };
    
    this.mvPopMatrix = function(surfacePlot){
        if (surfacePlot.mvMatrixStack.length == 0) {
            throw "Invalid popMatrix!";
        }
        
        surfacePlot.mvMatrix = surfacePlot.mvMatrixStack.pop();
    };
    
    this.setMatrixUniforms = function(program, pMatrix, mvMatrix){
        this.gl.uniformMatrix4fv(program.pMatrixUniform, false, pMatrix);
        this.gl.uniformMatrix4fv(program.mvMatrixUniform, false, mvMatrix);
        
        var normalMatrix = mat3.create();
        mat4.toInverseMat3(mvMatrix, normalMatrix);
        mat3.transpose(normalMatrix);
        this.gl.uniformMatrix3fv(program.nMatrixUniform, false, normalMatrix);
    };
    
    this.initWorldObjects = function(data3D){
        if (this.frames) {
            this.glSurface = new GLSurface(data3D[0], this);
            this.glAxes = new GLAxes(data3D[0], this);
        }
        else {
            this.glSurface = new GLSurface(data3D, this);
            this.glAxes = new GLAxes(data3D, this);
        }
    };
    
    // WebGL mouse handlers:
    var shiftPressed = false;
    
    this.handleMouseUp = function(event){
        mouseDown = false;
    };
    
    this.drawScene = function(){
        this.mvPushMatrix(this);
        
        this.gl.useProgram(this.shaderProgram);
        
        // Enable the vertex arrays for the current shader.
        this.shaderProgram.vertexPositionAttribute = this.gl.getAttribLocation(this.shaderProgram, "aVertexPosition");
        this.gl.enableVertexAttribArray(this.shaderProgram.vertexPositionAttribute);
        this.shaderProgram.vertexNormalAttribute = this.gl.getAttribLocation(this.shaderProgram, "aVertexNormal");
        this.gl.enableVertexAttribArray(this.shaderProgram.vertexNormalAttribute);
        this.shaderProgram.vertexColorAttribute = this.gl.getAttribLocation(this.shaderProgram, "aVertexColor");
        this.gl.enableVertexAttribArray(this.shaderProgram.vertexColorAttribute);
        
        this.gl.viewport(0, 0, this.gl.viewportWidth, this.gl.viewportHeight);
        this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
        mat4.perspective(5, this.gl.viewportWidth / this.gl.viewportHeight, 0.1, 100.0, this.pMatrix);
        mat4.identity(this.mvMatrix);
        
        mat4.translate(this.mvMatrix, [0.0, -0.3, -19.0]);
        
        mat4.multiply(this.mvMatrix, this.rotationMatrix);
        
        var useLighting = true;
        
        if (useLighting) {
            this.gl.uniform3f(this.shaderProgram.ambientColorUniform, 0.2, 0.2, 0.2);
            
            var lightingDirection = [0.0, 0.0, 1.0];
            
            var adjustedLD = vec3.create();
            vec3.normalize(lightingDirection, adjustedLD);
            vec3.scale(adjustedLD, -1);
            this.gl.uniform3fv(this.shaderProgram.lightingDirectionUniform, adjustedLD);
            
            this.gl.uniform3f(this.shaderProgram.directionalColorUniform, 0.8, 0.8, 0.8);
        }
        
        // Disable the vertex arrays for the current shader.
        this.gl.disableVertexAttribArray(this.shaderProgram.vertexPositionAttribute);
        this.gl.disableVertexAttribArray(this.shaderProgram.vertexNormalAttribute);
        this.gl.disableVertexAttribArray(this.shaderProgram.vertexColorAttribute);
        
        this.glAxes.draw();
        
        if (this.frames && !this.allFramesRendered) {
        
            var timeNow = new Date().getTime();
            
            elapsed = timeNow - lastTime;
            
            if (elapsed > 1000/this.glOptions.framesPerSecond) {
                if (!this.currentFrame) {
                    this.currentFrame = 1;
				}
                
                this.glSurface.updateSurface(data3ds[this.currentFrame]);
                
                if (this.currentFrame < this.numFrames - 1) 
					this.currentFrame++;
				else {
					this.allFramesRendered = true;
					this.currentFrame = 0;
				}
					
				lastTime = timeNow;
            }
            
        }
        
        this.glSurface.draw();
        
        this.mvPopMatrix(this);
    };
    
    var lastTime = 0;
    var elapsed = 0;
    
    this.tick = function(){
        var self = this;
        
        if (this.gl == null) 
            return;
        
        var animator = function(){
            if (self.gl == null || self.bail) 
                return;
            
            self.drawScene();
            requestAnimFrame(animator);
        };
        
        requestAnimFrame(animator);
    };
    
    this.isWebGlEnabled = function(){
        var enabled = true;
        
        if (this.glOptions.chkControlId && document.getElementById(this.glOptions.chkControlId)) 
            enabled = document.getElementById(this.glOptions.chkControlId).checked;
        
        return enabled && this.initShaders();
    };
    
    this.rotate = function(deltaX, deltaY){
        var newRotationMatrix = mat4.create();
        mat4.identity(newRotationMatrix);
        
        mat4.rotate(newRotationMatrix, degToRad(deltaX / 2), [0, 1, 0]);
        mat4.rotate(newRotationMatrix, degToRad(deltaY / 2), [1, 0, 0]);
        mat4.multiply(newRotationMatrix, this.rotationMatrix, this.rotationMatrix);
    }
    
    this.handleMouseMove = function(event, context){
    
        if (!mouseDown) {
            return;
        }
        
        var newX = event.clientX;
        var newY = event.clientY;
        
        var deltaX = newX - lastMouseX;
        var deltaY = newY - lastMouseY;
        var newRotationMatrix = mat4.create();
        mat4.identity(newRotationMatrix);
        
        if (shiftPressed) // scale
        {
            var s = deltaY < 0 ? 1.05 : 0.95;
            mat4.scale(newRotationMatrix, [s, s, s]);
            mat4.multiply(newRotationMatrix, this.rotationMatrix, this.rotationMatrix);
        }
        else // rotate
        {
            mat4.rotate(newRotationMatrix, degToRad(deltaX / 2), [0, 1, 0]);
            mat4.rotate(newRotationMatrix, degToRad(deltaY / 2), [1, 0, 0]);
            mat4.multiply(newRotationMatrix, this.rotationMatrix, this.rotationMatrix);
            
            if (this.otherPlots) {
                var numPlots = this.otherPlots.length;
                for (var i = 0; i < numPlots; i++) {
                    this.otherPlots[i].rotate(deltaX, deltaY);
                }
            }
        }
        
        lastMouseX = newX;
        lastMouseY = newY;
    };
    
    this.initGL = function(canvas){
        var canUseWebGL = false;
        
        try {
            this.gl = canvas.getContext("experimental-webgl", {
                alpha: false
            });
            this.gl.viewportWidth = canvas.width;
            this.gl.viewportHeight = canvas.height;
        } 
        catch (e) {
        }
        
        if (this.gl) {
            canUseWebGL = this.isWebGlEnabled();
            var self = this;
            
            var handleMouseDown = function(event){
                shiftPressed = isShiftPressed(event);
                
                mouseDown = true;
                lastMouseX = event.clientX;
                lastMouseY = event.clientY;
                
                document.onmouseup = self.handleMouseUp;
                document.onmousemove = function(event){
                    self.handleMouseMove(event, self)
                };//self.handleMouseMove;
            };
            
            canvas.onmousedown = handleMouseDown;
            document.onmouseup = this.handleMouseUp;
            document.onmousemove = function(event){
                self.handleMouseMove(event, self)
            };//this.handleMouseMove;
        }
        
        return canUseWebGL;
    };
    
    this.initCanvas = function(){
        canvas.className = "surfacePlotCanvas";
        canvas.setAttribute("width", width);
        canvas.setAttribute("height", height);
        canvas.style.left = '0px';
        canvas.style.top = '0px';
        
        targetDiv.appendChild(canvas);
    };
    
    this.scaleAndNormalise = function(scaleFactor){
        if (this.frames) {
            // Need to clone the data.
            var values = this.data.formattedValues.slice(0);
            var numRows = this.data.nRows;
            
            for (var i = 0; i < this.numFrames; i++) {
                values[i] = this.data.formattedValues[i].slice(0);
                
                for (var j = 0; j < numRows; j++) 
                    values[i][j] = this.data.formattedValues[i][j].slice(0);
            }
            
            // Now, do the scaling.
            var numRows = values[0].length;
            var numCols = values[0][0].length;
            
            for (var k = 0; k < this.numFrames; k++) 
                for (var i = 0; i < numRows; i++) 
                    for (var j = 0; j < numCols; j++) 
                        values[k][i][j] = (values[k][i][j] / this.maxZValue) * scaleFactor;
            
            this.dataToRender = values;
        }
        else {
            // Need to clone the data.
            var values = this.data.formattedValues.slice(0);
            var numRows = this.data.nRows;
            
            for (var i = 0; i < numRows; i++) 
                values[i] = this.data.formattedValues[i].slice(0);
            
            // Now, do the scaling.
            var numRows = values.length;
            var numCols = values[0].length;
            
            for (var i = 0; i < numRows; i++) 
                for (var j = 0; j < numCols; j++) 
                    values[i][j] = (values[i][j] / this.maxZValue) * scaleFactor;
            
            this.dataToRender = values;
        }
        
        // Recalculate the new min and max values.
        this.determineMinMaxZValues();
    }
    
    this.log = function(base, value){
        return Math.log(value) / Math.log(base);
    }
    
    this.nice_num = function(x, round){
        var exp = Math.floor(log(10, x));
        var f = x / Math.pow(10, exp);
        var nf;
        
        if (round) {
            if (f < 1.5) 
                nf = 1;
            else 
                if (f < 3) 
                    nf = 2;
                else 
                    if (f < 7) 
                        nf = 5;
                    else 
                        nf = 10;
        }
        else {
            if (f <= 1) 
                nf = 1;
            else 
                if (f <= 2) 
                    nf = 2;
                else 
                    if (f <= 5) 
                        nf = 5;
                    else 
                        nf = 10;
        }
        
        return nf * Math.pow(10, exp);
    }
    
    this.calculateZScale = function(){
        // Calculate the z-axis labels.
        var maxAxisValue = this.nice_num(this.maxZValue);
        var labels = [];
        var ticks = 10;
        var interval = maxAxisValue / ticks;
        var rounded2dp;
        
        for (var i = 0; i <= ticks; i++) {
            rounded2dp = Math.round(i * interval * 100) / 100;
            labels.push(rounded2dp);
        }
        
        this.glOptions.zLabels = labels;
        
        // Scale the values accordingly.
        var scaleFactor = this.maxZValue / maxAxisValue;
        this.scaleAndNormalise(scaleFactor);
    }
    
    this.createCanvas = function(){
        canvas = document.createElement("canvas");
        
        if (!supports_canvas()) {
            G_vmlCanvasManager.initElement(canvas);
            canvas.style.width = width;
            canvas.style.height = height;
        }
        else {
            this.initCanvas();
            this.useWebGL = this.initGL(canvas);
        }
        
        
        if (!this.useWebGL) {
            targetDiv.removeChild(canvas);
            canvas = document.createElement("canvas");
            
            this.initCanvas();
            
            canvasContext = canvas.getContext("2d");
            canvasContext.font = "bold 18px sans-serif";
            canvasContext.clearRect(0, 0, canvas.width, canvas.height);
            
            canvasContext.fillStyle = '#000';
            
            canvasContext.fillRect(0, 0, canvas.width, canvas.height);
            
            canvasContext.beginPath();
            canvasContext.rect(0, 0, canvas.width, canvas.height);
            canvasContext.strokeStyle = '#888';
            canvasContext.stroke();
            
            canvas.owner = this;
            canvas.onmousemove = this.mouseIsMoving;
            canvas.onmouseout = hideTooltip;
            canvas.onmousedown = this.mouseDownd;
            canvas.onmouseup = this.mouseUpd;
			
			canvas.addEventListener("touchstart", this.mouseDownd, false);
	        canvas.addEventListener("touchmove", this.mouseIsMoving, false);
	        canvas.addEventListener("touchend", this.mouseUpd, false);
	        canvas.addEventListener("touchcancel", hideTooltip, false);
        }
        else 
            this.createHiddenCanvasForGLText();
    };
    
    this.createHiddenCanvasForGLText = function(){
        var hiddenCanvas = document.createElement("canvas");
        hiddenCanvas.setAttribute("width", 512);
        hiddenCanvas.setAttribute("height", 512);
        this.context2D = hiddenCanvas.getContext('2d');
        hiddenCanvas.style.display = 'none';
        targetDiv.appendChild(hiddenCanvas);
    };
    
    // Mouse events for the non-webGL version of the surface plot.
    this.mouseDownd = function(e){
        if (isShiftPressed(e)) {
            mouseDown3 = true;
            mouseButton3Down = getMousePositionFromEvent(e);
        }
        else {
            mouseDown1 = true;
            mouseButton1Down = getMousePositionFromEvent(e);
        }
    };
    
    this.mouseUpd = function(e){
        if (mouseDown1) {
            mouseButton1Up = lastMousePos;
        }
        else 
            if (mouseDown3) {
                mouseButton3Up = lastMousePos;
            }
        
        mouseDown1 = false;
        mouseDown3 = false;
    };
    
    this.mouseIsMoving = function(e){
        var self = e.target.owner;
        var currentPos = getMousePositionFromEvent(e);
        
        if (mouseDown1) {
            hideTooltip();
            self.calculateRotation(currentPos);
        }
        else 
            if (mouseDown3) {
                hideTooltip();
                self.calculateScale(currentPos);
            }
            else {
                closestPointToMouse = null;
                var closestDist = Number.MAX_VALUE;
                
                for (var i = 0; i < data3ds.length; i++) {
                    var point = data3ds[i];
                    var dist = distance({
                        x: point.ax,
                        y: point.ay
                    }, currentPos);
                    
                    if (dist < closestDist) {
                        closestDist = dist;
                        closestPointToMouse = i;
                    }
                }
                
                if (closestDist > 32) {
                    hideTooltip();
                    return;
                }
                
                displayTooltip(currentPos);
            }
			
		return false;
    };
    
    function isShiftPressed(e){
        var shiftPressed = 0;
        
        if (parseInt(navigator.appVersion) > 3) {
            var evt = navigator.appName == "Netscape" ? e : event;
            
            if (navigator.appName == "Netscape" && parseInt(navigator.appVersion) == 4) {
                // NETSCAPE 4 CODE
                var mString = (e.modifiers + 32).toString(2).substring(3, 6);
                shiftPressed = (mString.charAt(0) == "1");
            }
            else {
                // NEWER BROWSERS [CROSS-PLATFORM]
                shiftPressed = evt.shiftKey;
            }
            
            if (shiftPressed) 
                return true;
        }
        
        return false;
    }
    
    function getMousePositionFromEvent(e){
        if (getInternetExplorerVersion() > -1) {
            var e = window.event;
            
            if (e.srcElement.getAttribute('Stroked')) {
                if (mousePosX == null || mousePosY == null) 
                    return;
            }
            else {
                mousePosX = e.offsetX;
                mousePosY = e.offsetY;
            }
        }
        else 
            if (e.layerX || e.layerX == 0) // Firefox
            {
                mousePosX = e.layerX;
                mousePosY = e.layerY;
            }
            else if (e.offsetX || e.offsetX == 0) // Opera
            {
                mousePosX = e.offsetX;
                mousePosY = e.offsetY;
            }
			else if (e.touches[0].pageX || e.touches[0].pageX == 0) //touch events
            {
                mousePosX = e.touches[0].pageX;
                mousePosY = e.touches[0].pageY;
            }
        
        var currentPos = new Point(mousePosX, mousePosY);
        
        return currentPos;
    }
    
    this.calculateRotation = function(e){
        lastMousePos = new Point(this.currentZAngle_canvas, this.currentXAngle_canvas);
        
        if (mouseButton1Up == null) {
            mouseButton1Up = new Point(this.currentZAngle_canvas, this.currentXAngle_canvas);
        }
        
        if (mouseButton1Down != null) {
            lastMousePos = new Point(mouseButton1Up.x + (mouseButton1Down.x - e.x),//
 mouseButton1Up.y + (mouseButton1Down.y - e.y));
        }
        
        this.currentZAngle_canvas = lastMousePos.x % 360;
        this.currentXAngle_canvas = lastMousePos.y % 360;
        
        closestPointToMouse = null;
        this.render();
    };
    
    this.calculateScale = function(e){
        lastMousePos = new Point(0, JSSurfacePlot.DEFAULT_SCALE / JSSurfacePlot.SCALE_FACTOR);
        
        if (mouseButton3Up == null) {
            mouseButton3Up = new Point(0, JSSurfacePlot.DEFAULT_SCALE / JSSurfacePlot.SCALE_FACTOR);
        }
        
        if (mouseButton3Down != null) {
            lastMousePos = new Point(mouseButton3Up.x + (mouseButton3Down.x - e.x),//
 mouseButton3Up.y + (mouseButton3Down.y - e.y));
        }
        
        scale = lastMousePos.y * JSSurfacePlot.SCALE_FACTOR;
        
        if (scale < JSSurfacePlot.MIN_SCALE) 
            scale = JSSurfacePlot.MIN_SCALE + 1;
        else 
            if (scale > JSSurfacePlot.MAX_SCALE) 
                scale = JSSurfacePlot.MAX_SCALE - 1;
        
        lastMousePos.y = scale / JSSurfacePlot.SCALE_FACTOR;
        
        closestPointToMouse = null;
        this.render();
    };
    
    this.init();
};

GLText = function(data3D, text, pos, angle, surfacePlot, axis, align){
    this.shaderTextureProgram = surfacePlot.shaderTextureProgram;
    this.currenShader = null;
    this.gl = surfacePlot.gl;
    this.setMatrixUniforms = surfacePlot.setMatrixUniforms;
    
    this.vertexTextureCoordBuffer = null;
    this.textureVertexPositionBuffer = null;
    this.textureVertexIndexBuffer = null;
    this.context2D = surfacePlot.context2D;
    this.mvPushMatrix = surfacePlot.mvPushMatrix;
    this.mvPopMatrix = surfacePlot.mvPopMatrix;
    this.texture;
    this.text = text;
    this.angle = angle;
    this.pos = pos;
    this.surfacePlot = surfacePlot;
    this.textMetrics = null;
    this.axis = axis;
    this.align = align;
    
    this.setUpTextArea = function(){
        this.context2D.font = 'normal 28px Verdana';
        this.context2D.fillStyle = 'rgba(255,255,255,0)';
        this.context2D.fillRect(0, 0, 512, 512);
        this.context2D.lineWidth = 3;
        this.context2D.textAlign = 'left';
        this.context2D.textBaseline = 'top';
    };
    
    this.writeTextToCanvas = function(text, idx){
        this.context2D.save();
        this.context2D.clearRect(0, 0, 512, 512);
        this.context2D.fillStyle = 'rgba(255, 255, 255, 0)';
        this.context2D.fillRect(0, 0, 512, 512);
        
        var r = hexToR(this.surfacePlot.axisTextColour);
        var g = hexToG(this.surfacePlot.axisTextColour);
        var b = hexToB(this.surfacePlot.axisTextColour);
        
        this.context2D.fillStyle = 'rgba(' + r + ', ' + g + ', ' + b + ', 255)'; // Set the axis label colour.
        this.textMetrics = this.context2D.measureText(text);
        
        if (this.axis == "y" || this.align == "left") 
            this.context2D.fillText(text, 0, 0);
        else 
            if (!this.align) 
                this.context2D.fillText(text, 512 - this.textMetrics.width, 0);
        
        if (this.align == "centre") 
            this.context2D.fillText(text, 256 - this.textMetrics.width / 2, 0);
        if (this.align == "right") 
            this.context2D.fillText(text, 512 - this.textMetrics.width, 0);
        
        this.setTextureFromCanvas(this.context2D.canvas, this.texture, 0);
        
        this.context2D.restore();
    };
    
    this.setTextureFromCanvas = function(canvas, textTexture, idx){
        this.gl.activeTexture(this.gl.TEXTURE0 + idx);
        this.gl.bindTexture(this.gl.TEXTURE_2D, textTexture);
        this.gl.pixelStorei(this.gl.UNPACK_FLIP_Y_WEBGL, true);
        this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.RGBA, this.gl.RGBA, this.gl.UNSIGNED_BYTE, canvas);
        
        if (isPowerOfTwo(canvas.width) && isPowerOfTwo(canvas.height)) {
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.NEAREST);
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.NEAREST);
        }
        else {
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR);
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE);
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE);
        }
        
        this.gl.bindTexture(this.gl.TEXTURE_2D, textTexture);
    };
    
    function isPowerOfTwo(value){
        return ((value & (value - 1)) == 0);
    }
    
    this.initTextBuffers = function(){
    
        // Text texture vertices
        this.textureVertexPositionBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.textureVertexPositionBuffer);
        this.textureVertexPositionBuffer.itemSize = 3;
        this.textureVertexPositionBuffer.numItems = 4;
        this.shaderTextureProgram.textureCoordAttribute = this.gl.getAttribLocation(this.shaderTextureProgram, "aTextureCoord");
        this.gl.vertexAttribPointer(this.shaderTextureProgram.textureCoordAttribute, this.textureVertexPositionBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
        
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.textureVertexPositionBuffer);
        
        // Where we render the text.
        var texturePositionCoords = [-0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5];
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(texturePositionCoords), this.gl.STATIC_DRAW);
        
        // Texture index buffer.
        this.textureVertexIndexBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.textureVertexIndexBuffer);
        
        var textureVertexIndices = [0, 1, 2, 0, 2, 3];
        
        this.gl.bufferData(this.gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(textureVertexIndices), this.gl.STATIC_DRAW);
        this.textureVertexIndexBuffer.itemSize = 1;
        this.textureVertexIndexBuffer.numItems = 6;
        
        // Text textures
        this.vertexTextureCoordBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexTextureCoordBuffer);
        this.vertexTextureCoordBuffer.itemSize = 2;
        this.vertexTextureCoordBuffer.numItems = 4;
        this.gl.vertexAttribPointer(this.shaderTextureProgram.textureCoordAttribute, this.vertexTextureCoordBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
        
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexTextureCoordBuffer);
        
        var textureCoords = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0];
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(textureCoords), this.gl.STATIC_DRAW);
    };
    
    this.initTextBuffers();
    this.setUpTextArea();
    
    this.texture = this.gl.createTexture();
    this.writeTextToCanvas(this.text, this.idx);
};

GLText.prototype.draw = function(){
    this.mvPushMatrix(this.surfacePlot);
    
    var rotationMatrix = mat4.create();
    mat4.identity(rotationMatrix);
    
    if (this.axis == "y") {
        mat4.translate(rotationMatrix, [0.0, 0.5, 0.5]);
        mat4.translate(rotationMatrix, [this.pos.x + 0.53, this.pos.y + 0.6, this.pos.z - 0.5]);
        mat4.rotate(rotationMatrix, degToRad(this.angle), [1, 0, 0]);
        mat4.translate(rotationMatrix, [0.0, -0.5, -0.5]);
    }
    else 
        if (this.axis == "x") {
            mat4.translate(rotationMatrix, [0.5, 0.5, 0.0]);
            mat4.translate(rotationMatrix, [this.pos.x - 0.5, this.pos.y + 0.47, this.pos.z - 0.5]);
            mat4.rotate(rotationMatrix, degToRad(this.angle), [0, 0, 1]);
            mat4.translate(rotationMatrix, [-0.5, -0.5, 0]);
        }
        else 
            if (this.axis == "z" && this.align == "centre") // Main Z-axis label.
            {
                mat4.translate(rotationMatrix, [0.0, 0.5, 0.5]);
                mat4.translate(rotationMatrix, [this.pos.x - 0.3, this.pos.y + 0.5, this.pos.z - 0.5]);
                mat4.rotate(rotationMatrix, degToRad(this.angle), [1, 0, 0]);
                mat4.rotate(rotationMatrix, degToRad(this.angle), [0, 0, 1]);
                mat4.translate(rotationMatrix, [0.0, -0.5, -0.5]);
            }
            else 
                if (this.axis == "z" && !this.align) {
                    mat4.translate(rotationMatrix, [0.0, 0.5, 0.5]);
                    mat4.translate(rotationMatrix, [this.pos.x - 0.53, this.pos.y + 0.5, this.pos.z - 0.5]);
                    mat4.rotate(rotationMatrix, degToRad(this.angle), [1, 0, 0]);
                    mat4.translate(rotationMatrix, [0.0, -0.5, -0.5]);
                }
    
    mat4.multiply(this.surfacePlot.mvMatrix, rotationMatrix);
    
    // Enable blending for transparency.
    this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
    this.gl.enable(this.gl.BLEND);
    this.gl.disable(this.gl.DEPTH_TEST);
    
    // Text
    this.currentShader = this.shaderTextureProgram;
    this.gl.useProgram(this.currentShader);
    
    // Enable the vertex arrays for the current shader.
    this.currentShader.vertexPositionAttribute = this.gl.getAttribLocation(this.currentShader, "aVertexPosition");
    this.gl.enableVertexAttribArray(this.currentShader.vertexPositionAttribute);
    this.currentShader.textureCoordAttribute = this.gl.getAttribLocation(this.currentShader, "aTextureCoord");
    this.gl.enableVertexAttribArray(this.currentShader.textureCoordAttribute);
    
    this.shaderTextureProgram.samplerUniform = this.gl.getUniformLocation(this.shaderTextureProgram, "uSampler");
    
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.textureVertexPositionBuffer);
    this.gl.vertexAttribPointer(this.currentShader.vertexPositionAttribute, this.textureVertexPositionBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.vertexTextureCoordBuffer);
    this.gl.vertexAttribPointer(this.currentShader.textureCoordAttribute, this.vertexTextureCoordBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.bindTexture(this.gl.TEXTURE_2D, this.texture);
    this.gl.uniform1i(this.currentShader.samplerUniform, 0);
    
    this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.textureVertexIndexBuffer);
    
    this.setMatrixUniforms(this.currentShader, this.surfacePlot.pMatrix, this.surfacePlot.mvMatrix);
    
    this.gl.drawElements(this.gl.TRIANGLES, this.textureVertexIndexBuffer.numItems, this.gl.UNSIGNED_SHORT, 0);
    
    // Disable blending for transparency.
    this.gl.disable(this.gl.BLEND);
    this.gl.enable(this.gl.DEPTH_TEST);
    
    // Disable the vertex arrays for the current shader.
    this.gl.disableVertexAttribArray(this.currentShader.vertexPositionAttribute);
    this.gl.disableVertexAttribArray(this.currentShader.textureCoordAttribute);
    
    this.mvPopMatrix(this.surfacePlot);
};

/*
 * This class represents the axes for the webGL plot.
 */
GLAxes = function(data3D, surfacePlot){
    this.shaderProgram = surfacePlot.shaderAxesProgram;
    this.currenShader = null;
    this.gl = surfacePlot.gl;
    this.numXPoints = surfacePlot.numXPoints;
    this.numYPoints = surfacePlot.numYPoints;
    this.data3D = data3D;
    this.setMatrixUniforms = surfacePlot.setMatrixUniforms;
    this.axesVertexPositionBuffer = null;
    this.axesMinorVertexPositionBuffer = null;
    this.surfaceVertexColorBuffer = null;
    this.surfacePlot = surfacePlot;
    
    this.labels = [];
    
    this.initAxesBuffers = function(){
        var vertices = [];
        var minorVertices = [];
        var axisExtent = 0.5;
        
        var axisOrigin = [-axisExtent, axisExtent, 0];
        var xAxisEndPoint = [axisExtent, axisExtent, 0];
        var yAxisEndPoint = [-axisExtent, -axisExtent, 0];
        var zAxisEndPoint = [-axisExtent, axisExtent, axisExtent * 2];
        
        var xAxisEndPoint2 = [axisExtent, -axisExtent, 0];
        var zAxisEndPoint2 = [-axisExtent, -axisExtent, axisExtent * 2];
        
        // X
        vertices = vertices.concat(yAxisEndPoint);
        vertices = vertices.concat(xAxisEndPoint2);
        
        // Y
        vertices = vertices.concat(xAxisEndPoint2);
        vertices = vertices.concat(xAxisEndPoint);
        
        // Z2
        vertices = vertices.concat(yAxisEndPoint);
        vertices = vertices.concat(zAxisEndPoint2);
        
        // Major axis lines.
        this.axesVertexPositionBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.axesVertexPositionBuffer);
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(vertices), this.gl.DYNAMIC_DRAW);
        this.axesVertexPositionBuffer.itemSize = 3;
        this.axesVertexPositionBuffer.numItems = vertices.length / 3;
        
        // Minor axis lines
        var lineIntervalX = axisExtent / (this.surfacePlot.glOptions.xTicksNum / 2);
        var lineIntervalY = axisExtent / (this.surfacePlot.glOptions.yTicksNum / 2);
        var lineIntervalZ = axisExtent / (this.surfacePlot.glOptions.zTicksNum / 2);
        
        var i = 0;
        
        // X-axis division lines
        for (var count = 0; count <= this.surfacePlot.glOptions.xTicksNum; i += lineIntervalX, count++) {
            // X-axis labels.
            var labels = this.surfacePlot.glOptions.xLabels;
            var label = labels[count];
            
            labelPos = {
                x: yAxisEndPoint[0] + i - 0.02,
                y: yAxisEndPoint[1] - 1,
                z: yAxisEndPoint[2]
            };
            glText = new GLText(data3D, label, labelPos, 90, surfacePlot, "x");
            this.labels.push(glText);
            
            // X-axis divisions.
            minorVertices = minorVertices.concat([axisOrigin[0] + i, axisOrigin[1], axisOrigin[2]]);
            minorVertices = minorVertices.concat([yAxisEndPoint[0] + i, yAxisEndPoint[1], yAxisEndPoint[2]]);
            
            // back wall x-axis divisions.
            minorVertices = minorVertices.concat([axisOrigin[0] + i, axisOrigin[1], 0]);
            minorVertices = minorVertices.concat([axisOrigin[0] + i, axisOrigin[1], axisExtent * 2]);
        }
        
        i = 0;
        
        // Y-axis division lines
        for (var count = 0; count <= this.surfacePlot.glOptions.yTicksNum; i += lineIntervalY, count++) {
            // Y-axis labels.
            var labels = this.surfacePlot.glOptions.yLabels;
            var label = labels[this.surfacePlot.glOptions.yTicksNum - count];
            
            labelPos = {
                x: xAxisEndPoint[0],
                y: xAxisEndPoint[1] - i - 1.06,
                z: xAxisEndPoint[2]
            };
            glText = new GLText(data3D, label, labelPos, 0, surfacePlot, "y");
            this.labels.push(glText);
            
            // y-axis divisions
            minorVertices = minorVertices.concat([axisOrigin[0], axisOrigin[1] - i, axisOrigin[2]]);
            minorVertices = minorVertices.concat([xAxisEndPoint[0], xAxisEndPoint[1] - i, xAxisEndPoint[2]]);
            
            // left wall y-axis divisions.
            minorVertices = minorVertices.concat([axisOrigin[0], axisOrigin[1] - i, 0]);
            minorVertices = minorVertices.concat([axisOrigin[0], axisOrigin[1] - i, axisExtent * 2]);
        }
        
        i = 0;
        
        // Z-axis division lines
        for (var count = 0; count <= this.surfacePlot.glOptions.zTicksNum; i += lineIntervalZ, count++) {
            // Z-axis labels.
            var labels = this.surfacePlot.glOptions.zLabels;
            var label = labels[count];
            
            var labelPos = {
                x: yAxisEndPoint[0],
                y: yAxisEndPoint[1] - 1,
                z: yAxisEndPoint[2] + i + 0.03
            };
            var glText = new GLText(data3D, label, labelPos, 90, surfacePlot, "z");
            this.labels.push(glText);
            
            // Z-axis divisions
            minorVertices = minorVertices.concat([axisOrigin[0], axisOrigin[1], axisOrigin[2] + i]);
            minorVertices = minorVertices.concat([yAxisEndPoint[0], yAxisEndPoint[1], yAxisEndPoint[2] + i]);
            
            // back wall z-axis divisions
            minorVertices = minorVertices.concat([axisOrigin[0], axisOrigin[1], axisOrigin[2] + i]);
            minorVertices = minorVertices.concat([xAxisEndPoint[0], xAxisEndPoint[1], xAxisEndPoint[2] + i]);
            
        }
        
        // Set up the main X-axis label.
        var labelPos = {
            x: 0.5,
            y: yAxisEndPoint[1] - 1.35,
            z: yAxisEndPoint[2]
        };
        var glText = new GLText(data3D, this.surfacePlot.xTitle, labelPos, 0, surfacePlot, "x", "centre");
        this.labels.push(glText);
        
        // Set up the main Y-axis label.
        labelPos = {
            x: xAxisEndPoint[0] + 0.2,
            y: -0.5,
            z: xAxisEndPoint[2]
        };
        glText = new GLText(data3D, this.surfacePlot.yTitle, labelPos, 90, surfacePlot, "x", "centre");
        this.labels.push(glText);
        
        // Set up the main Z-axis label.
        labelPos = {
            x: yAxisEndPoint[0],
            y: yAxisEndPoint[1] - 1,
            z: 0.5
        };
        glText = new GLText(data3D, this.surfacePlot.zTitle, labelPos, 90, surfacePlot, "z", "centre");
        this.labels.push(glText);
        
        // Set up the minor axis grid lines.
        this.axesMinorVertexPositionBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.axesMinorVertexPositionBuffer);
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(minorVertices), this.gl.DYNAMIC_DRAW);
        this.axesMinorVertexPositionBuffer.itemSize = 3;
        this.axesMinorVertexPositionBuffer.numItems = minorVertices.length / 3;
    };
    
    this.initAxesBuffers();
};

GLAxes.prototype.draw = function(){
    this.currentShader = this.shaderProgram;
    this.gl.useProgram(this.currentShader);
    
    // Enable the vertex array for the current shader.
    this.currentShader.vertexPositionAttribute = this.gl.getAttribLocation(this.currentShader, "aVertexPosition");
    this.gl.enableVertexAttribArray(this.currentShader.vertexPositionAttribute);
    
    this.gl.uniform3f(this.currentShader.axesColour, 0.0, 0.0, 0.0); // Set the colour of the Major axis lines.
    // Major axis lines
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.axesVertexPositionBuffer);
    this.gl.vertexAttribPointer(this.currentShader.vertexPositionAttribute, this.axesVertexPositionBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.lineWidth(2);
    this.setMatrixUniforms(this.currentShader, this.surfacePlot.pMatrix, this.surfacePlot.mvMatrix);
    this.gl.drawArrays(this.gl.LINES, 0, this.axesVertexPositionBuffer.numItems);
    
    // Minor axis lines
    this.gl.uniform3f(this.currentShader.axesColour, 0.3, 0.3, 0.3); // Set the colour of the minor axis grid lines.
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.axesMinorVertexPositionBuffer);
    this.gl.vertexAttribPointer(this.currentShader.vertexPositionAttribute, this.axesMinorVertexPositionBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.lineWidth(1);
    this.gl.drawArrays(this.gl.LINES, 0, this.axesMinorVertexPositionBuffer.numItems);
    
    // Render the axis labels.
    var numLabels = this.labels.length;
    
    // Enable the vertex array for the current shader.
    this.gl.disableVertexAttribArray(this.currentShader.vertexPositionAttribute);
    
    for (var i = 0; i < numLabels; i++) 
        this.labels[i].draw();
};

/*
 * A webGL surface without axes nor any other decoration.
 */
GLSurface = function(data3D, surfacePlot){
    this.shaderProgram = surfacePlot.shaderProgram;
    this.currentShader = null;
    this.gl = surfacePlot.gl;
    this.numXPoints = surfacePlot.numXPoints;
    this.numYPoints = surfacePlot.numYPoints;
    this.data3D = data3D;
    this.colourGradientObject = surfacePlot.colourGradientObject;
    this.setMatrixUniforms = surfacePlot.setMatrixUniforms;
    
    this.surfaceVertexPositionBuffer = null;
    this.surfaceVertexColorBuffer = null;
    this.surfaceVertexNormalBuffer = null;
    this.surfaceVertexIndexBuffer = null;
    this.surfacePlot = surfacePlot;
    
    this.initSurfaceBuffers = function(){
        var i;
        var j;
        var vertices = [];
        var colors = [];
        var vertexNormals = [];
        
        for (i = 0; i < this.numXPoints - 1; i++) {
            for (j = 0; j < this.numYPoints - 1; j++) {
                // Create surface vertices.
                var rawP1 = this.data3D[j + (i * this.numYPoints)];
                var rawP2 = this.data3D[j + (i * this.numYPoints) + this.numYPoints];
                var rawP3 = this.data3D[j + (i * this.numYPoints) + this.numYPoints + 1];
                var rawP4 = this.data3D[j + (i * this.numYPoints) + 1];
                
                vertices.push(rawP1.ax);
                vertices.push(rawP1.ay);
                vertices.push(rawP1.az);
                
                vertices.push(rawP2.ax);
                vertices.push(rawP2.ay);
                vertices.push(rawP2.az);
                
                vertices.push(rawP3.ax);
                vertices.push(rawP3.ay);
                vertices.push(rawP3.az);
                
                vertices.push(rawP4.ax);
                vertices.push(rawP4.ay);
                vertices.push(rawP4.az);
                
                // Surface colours.
                var rgb1 = this.colourGradientObject.getColour(rawP1.lz * 1.0);
                var rgb2 = this.colourGradientObject.getColour(rawP2.lz * 1.0);
                var rgb3 = this.colourGradientObject.getColour(rawP3.lz * 1.0);
                var rgb4 = this.colourGradientObject.getColour(rawP4.lz * 1.0);
                
                colors.push(rgb1.red / 255);
                colors.push(rgb1.green / 255);
                colors.push(rgb1.blue / 255, 1.0);
                colors.push(rgb2.red / 255);
                colors.push(rgb2.green / 255);
                colors.push(rgb2.blue / 255, 1.0);
                colors.push(rgb3.red / 255);
                colors.push(rgb3.green / 255);
                colors.push(rgb3.blue / 255, 1.0);
                colors.push(rgb4.red / 255);
                colors.push(rgb4.green / 255);
                colors.push(rgb4.blue / 255, 1.0);
                
                // Normal of triangle 1.
                var v1 = [rawP2.ax - rawP1.ax, rawP2.ay - rawP1.ay, rawP2.az - rawP1.az];
                var v2 = [rawP3.ax - rawP1.ax, rawP3.ay - rawP1.ay, rawP3.az - rawP1.az];
                var cp1 = vec3.create();
                cp1 = vec3.cross(v1, v2);
                cp1 = vec3.normalize(v1, v2);
                
                // Normal of triangle 2.
                v1 = [rawP3.ax - rawP1.ax, rawP3.ay - rawP1.ay, rawP3.az - rawP1.az];
                v2 = [rawP4.ax - rawP1.ax, rawP4.ay - rawP1.ay, rawP4.az - rawP1.az];
                var cp2 = vec3.create();
                cp2 = vec3.cross(v1, v2);
                cp2 = vec3.normalize(v1, v2);
                
                // Store normals for lighting.
                vertexNormals.push(cp1[0]);
                vertexNormals.push(cp1[1]);
                vertexNormals.push(cp1[2]);
                vertexNormals.push(cp1[0]);
                vertexNormals.push(cp1[1]);
                vertexNormals.push(cp1[2]);
                vertexNormals.push(cp2[0]);
                vertexNormals.push(cp2[1]);
                vertexNormals.push(cp2[2]);
                vertexNormals.push(cp2[0]);
                vertexNormals.push(cp2[1]);
                vertexNormals.push(cp2[2]);
            }
        }
        
        this.surfaceVertexPositionBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexPositionBuffer);
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(vertices), this.gl.DYNAMIC_DRAW);
        this.surfaceVertexPositionBuffer.itemSize = 3;
        this.surfaceVertexPositionBuffer.numItems = vertices.length / 3;
        
        this.surfaceVertexNormalBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexNormalBuffer);
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(vertexNormals), this.gl.DYNAMIC_DRAW);
        this.surfaceVertexNormalBuffer.itemSize = 3;
        this.surfaceVertexNormalBuffer.numItems = vertices.length / 3;
        
        this.surfaceVertexColorBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexColorBuffer);
        
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(colors), this.gl.DYNAMIC_DRAW);
        this.surfaceVertexColorBuffer.itemSize = 4;
        this.surfaceVertexColorBuffer.numItems = vertices.length / 3;
        
        this.surfaceVertexIndexBuffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.surfaceVertexIndexBuffer);
        
        var numQuads = ((this.numXPoints - 1) * (this.numYPoints - 1)) / 2;
        var surfaceVertexIndices = [];
        
        for (var i = 0; i < (numQuads * 8); i += 4) {
            surfaceVertexIndices.push(i);
            surfaceVertexIndices.push(i + 1);
            surfaceVertexIndices.push(i + 2);
            surfaceVertexIndices.push(i);
            surfaceVertexIndices.push(i + 2);
            surfaceVertexIndices.push(i + 3);
        }
        
        this.gl.bufferData(this.gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(surfaceVertexIndices), this.gl.DYNAMIC_DRAW);
        this.surfaceVertexIndexBuffer.itemSize = 1;
        this.surfaceVertexIndexBuffer.numItems = surfaceVertexIndices.length;
    };
    
    this.updateSurface = function(data){
        var i;
        var j;
        var vertices = [];
        var colors = [];
        var vertexNormals = [];
        
        for (i = 0; i < this.numXPoints - 1; i++) {
            for (j = 0; j < this.numYPoints - 1; j++) {
                // Create surface vertices.
                var rawP1 = data[j + (i * this.numYPoints)];
                var rawP2 = data[j + (i * this.numYPoints) + this.numYPoints];
                var rawP3 = data[j + (i * this.numYPoints) + this.numYPoints + 1];
                var rawP4 = data[j + (i * this.numYPoints) + 1];
                
                //rawP1.az = Math.random();
                
                vertices.push(rawP1.ax);
                vertices.push(rawP1.ay);
                vertices.push(rawP1.az);
                
                vertices.push(rawP2.ax);
                vertices.push(rawP2.ay);
                vertices.push(rawP2.az);
                
                vertices.push(rawP3.ax);
                vertices.push(rawP3.ay);
                vertices.push(rawP3.az);
                
                vertices.push(rawP4.ax);
                vertices.push(rawP4.ay);
                vertices.push(rawP4.az);
                
                // Surface colours.
                var rgb1 = this.colourGradientObject.getColour(rawP1.lz * 1.0);
                var rgb2 = this.colourGradientObject.getColour(rawP2.lz * 1.0);
                var rgb3 = this.colourGradientObject.getColour(rawP3.lz * 1.0);
                var rgb4 = this.colourGradientObject.getColour(rawP4.lz * 1.0);
                
                colors.push(rgb1.red / 255);
                colors.push(rgb1.green / 255);
                colors.push(rgb1.blue / 255, 1.0);
                colors.push(rgb2.red / 255);
                colors.push(rgb2.green / 255);
                colors.push(rgb2.blue / 255, 1.0);
                colors.push(rgb3.red / 255);
                colors.push(rgb3.green / 255);
                colors.push(rgb3.blue / 255, 1.0);
                colors.push(rgb4.red / 255);
                colors.push(rgb4.green / 255);
                colors.push(rgb4.blue / 255, 1.0);
                
                // Normal of triangle 1.
                var v1 = [rawP2.ax - rawP1.ax, rawP2.ay - rawP1.ay, rawP2.az - rawP1.az];
                var v2 = [rawP3.ax - rawP1.ax, rawP3.ay - rawP1.ay, rawP3.az - rawP1.az];
                var cp1 = vec3.create();
                cp1 = vec3.cross(v1, v2);
                cp1 = vec3.normalize(v1, v2);
                
                // Normal of triangle 2.
                v1 = [rawP3.ax - rawP1.ax, rawP3.ay - rawP1.ay, rawP3.az - rawP1.az];
                v2 = [rawP4.ax - rawP1.ax, rawP4.ay - rawP1.ay, rawP4.az - rawP1.az];
                var cp2 = vec3.create();
                cp2 = vec3.cross(v1, v2);
                cp2 = vec3.normalize(v1, v2);
                
                // Store normals for lighting.
                vertexNormals.push(cp1[0]);
                vertexNormals.push(cp1[1]);
                vertexNormals.push(cp1[2]);
                vertexNormals.push(cp1[0]);
                vertexNormals.push(cp1[1]);
                vertexNormals.push(cp1[2]);
                vertexNormals.push(cp2[0]);
                vertexNormals.push(cp2[1]);
                vertexNormals.push(cp2[2]);
                vertexNormals.push(cp2[0]);
                vertexNormals.push(cp2[1]);
                vertexNormals.push(cp2[2]);
            }
        }
        
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexPositionBuffer);
        this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, new Float32Array(vertices));
        
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexNormalBuffer);
        this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, new Float32Array(vertexNormals));
        
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexColorBuffer);
        this.gl.bufferSubData(this.gl.ARRAY_BUFFER, 0, new Float32Array(colors));
        
        this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.surfaceVertexIndexBuffer);
        
        var numQuads = ((this.numXPoints - 1) * (this.numYPoints - 1)) / 2;
        var surfaceVertexIndices = [];
        
        for (var i = 0; i < (numQuads * 8); i += 4) {
            surfaceVertexIndices.push(i);
            surfaceVertexIndices.push(i + 1);
            surfaceVertexIndices.push(i + 2);
            surfaceVertexIndices.push(i);
            surfaceVertexIndices.push(i + 2);
            surfaceVertexIndices.push(i + 3);
        }
        
        this.gl.bufferSubData(this.gl.ELEMENT_ARRAY_BUFFER, 0, new Uint16Array(surfaceVertexIndices));
    };
    
    this.initSurfaceBuffers();
};

GLSurface.prototype.draw = function(){
    this.currentShader = this.shaderProgram;
    this.gl.useProgram(this.currentShader);
    
    // Enable the vertex arrays for the current shader.
    this.currentShader.vertexPositionAttribute = this.gl.getAttribLocation(this.currentShader, "aVertexPosition");
    this.gl.enableVertexAttribArray(this.currentShader.vertexPositionAttribute);
    this.currentShader.vertexNormalAttribute = this.gl.getAttribLocation(this.currentShader, "aVertexNormal");
    this.gl.enableVertexAttribArray(this.currentShader.vertexNormalAttribute);
    this.currentShader.vertexColorAttribute = this.gl.getAttribLocation(this.currentShader, "aVertexColor");
    this.gl.enableVertexAttribArray(this.currentShader.vertexColorAttribute);
    
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexPositionBuffer);
    this.gl.vertexAttribPointer(this.currentShader.vertexPositionAttribute, this.surfaceVertexPositionBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexColorBuffer);
    this.gl.vertexAttribPointer(this.currentShader.vertexColorAttribute, this.surfaceVertexColorBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.surfaceVertexNormalBuffer);
    this.gl.vertexAttribPointer(this.currentShader.vertexNormalAttribute, this.surfaceVertexNormalBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    
    this.gl.bindBuffer(this.gl.ELEMENT_ARRAY_BUFFER, this.surfaceVertexIndexBuffer);
    
    this.setMatrixUniforms(this.currentShader, this.surfacePlot.pMatrix, this.surfacePlot.mvMatrix);
    
    this.gl.drawElements(this.gl.TRIANGLES, this.surfaceVertexIndexBuffer.numItems, this.gl.UNSIGNED_SHORT, 0);
    
    // Disable the vertex arrays for the current shader.
    this.gl.disableVertexAttribArray(this.currentShader.vertexPositionAttribute);
    this.gl.disableVertexAttribArray(this.currentShader.vertexNormalAttribute);
    this.gl.disableVertexAttribArray(this.currentShader.vertexColorAttribute);
};

/**
 * Given two coordinates, return the Euclidean distance
 * between them
 */
function distance(p1, p2){
    return Math.sqrt(((p1.x - p2.x) *
    (p1.x -
    p2.x)) +
    ((p1.y - p2.y) * (p1.y - p2.y)));
}

/*
 * Matrix3d: This class represents a 3D matrix.
 * ********************************************
 */
Matrix3d = function(){
    this.matrix = new Array();
    this.numRows = 4;
    this.numCols = 4;
    
    this.init = function(){
        this.matrix = new Array();
        
        for (var i = 0; i < this.numRows; i++) {
            this.matrix[i] = new Array();
        }
    };
    
    this.getMatrix = function(){
        return this.matrix;
    };
    
    this.matrixReset = function(){
        for (var i = 0; i < this.numRows; i++) {
            for (var j = 0; j < this.numCols; j++) {
                this.matrix[i][j] = 0;
            }
        }
    };
    
    this.matrixIdentity = function(){
        this.matrixReset();
        this.matrix[0][0] = this.matrix[1][1] = this.matrix[2][2] = this.matrix[3][3] = 1;
    };
    
    this.matrixCopy = function(newM){
        var temp = new Matrix3d();
        var i, j;
        
        for (i = 0; i < this.numRows; i++) {
            for (j = 0; j < this.numCols; j++) {
                temp.getMatrix()[i][j] = (this.matrix[i][0] * newM.getMatrix()[0][j]) + (this.matrix[i][1] * newM.getMatrix()[1][j]) + (this.matrix[i][2] * newM.getMatrix()[2][j]) + (this.matrix[i][3] * newM.getMatrix()[3][j]);
            }
        }
        
        for (i = 0; i < this.numRows; i++) {
            this.matrix[i][0] = temp.getMatrix()[i][0];
            this.matrix[i][1] = temp.getMatrix()[i][1];
            this.matrix[i][2] = temp.getMatrix()[i][2];
            this.matrix[i][3] = temp.getMatrix()[i][3];
        }
    };
    
    this.matrixMult = function(m1, m2){
        var temp = new Matrix3d();
        var i, j;
        
        for (i = 0; i < this.numRows; i++) {
            for (j = 0; j < this.numCols; j++) {
                temp.getMatrix()[i][j] = (m2.getMatrix()[i][0] * m1.getMatrix()[0][j]) + (m2.getMatrix()[i][1] * m1.getMatrix()[1][j]) + (m2.getMatrix()[i][2] * m1.getMatrix()[2][j]) + (m2.getMatrix()[i][3] * m1.getMatrix()[3][j]);
            }
        }
        
        for (i = 0; i < this.numRows; i++) {
            m1.getMatrix()[i][0] = temp.getMatrix()[i][0];
            m1.getMatrix()[i][1] = temp.getMatrix()[i][1];
            m1.getMatrix()[i][2] = temp.getMatrix()[i][2];
            m1.getMatrix()[i][3] = temp.getMatrix()[i][3];
        }
    };
    
    this.toString = function(){
        return this.matrix.toString();
    }
    
    this.init();
};

/*
 * Point3D: This class represents a 3D point.
 * ******************************************
 */
Point3D = function(x, y, z){
    this.displayValue = "";
    
    this.lx;
    this.ly;
    this.lz;
    this.lt;
    
    this.wx;
    this.wy;
    this.wz;
    this.wt;
    
    this.ax;
    this.ay;
    this.az;
    this.at;
    
    this.dist;
    
    this.initPoint = function(){
        this.lx = this.ly = this.lz = this.ax = this.ay = this.az = this.at = this.wx = this.wy = this.wz = 0;
        this.lt = this.wt = 1;
    };
    
    this.init = function(x, y, z){
        this.initPoint();
        this.lx = x;
        this.ly = y;
        this.lz = z;
        
        this.ax = this.lx;
        this.ay = this.ly;
        this.az = this.lz;
    };
    
    this.init(x, y, z);
};

/*
 * Polygon: This class represents a polygon on the surface plot.
 * ************************************************************
 */
Polygon = function(cameraPosition, isAxis){
    this.points = new Array();
    this.cameraPosition = cameraPosition;
    this.isAxis = isAxis;
    this.centroid = null;
    this.distanceFromCamera = null;
    
    this.isAnAxis = function(){
        return this.isAxis;
    };
    
    this.addPoint = function(point){
        this.points[this.points.length] = point;
    };
    
    this.distance = function(){
        return this.distance2(this.cameraPosition, this.centroid);
    };
    
    this.calculateDistance = function(){
        this.distanceFromCamera = this.distance();
    };
    
    this.calculateCentroid = function(){
        var xCentre = 0;
        var yCentre = 0;
        var zCentre = 0;
        
        var numPoints = this.points.length * 1.0;
        
        for (var i = 0; i < numPoints; i++) {
            xCentre += this.points[i].ax;
            yCentre += this.points[i].ay;
            zCentre += this.points[i].az;
        }
        
        xCentre /= numPoints;
        yCentre /= numPoints;
        zCentre /= numPoints;
        
        this.centroid = new Point3D(xCentre, yCentre, zCentre);
    };
    
    this.distance2 = function(p1, p2){
        return ((p1.ax - p2.ax) * (p1.ax - p2.ax)) + ((p1.ay - p2.ay) * (p1.ay - p2.ay)) + ((p1.az - p2.az) * (p1.az - p2.az));
    };
    
    this.getPoint = function(i){
        return this.points[i];
    };
};

/*
 * PolygonComaparator: Class used to sort arrays of polygons.
 * ************************************************************
 */
PolygonComaparator = function(p1, p2){
    var diff = p1.distanceFromCamera - p2.distanceFromCamera;
    
    if (diff == 0) 
        return 0;
    else 
        if (diff < 0) 
            return -1;
        else 
            if (diff > 0) 
                return 1;
    
    return 0;
};

/*
 * Th3dtran: Class for matrix manipuation.
 * ************************************************************
 */
Th3dtran = function(){
    this.rMat;
    this.rMatrix;
    this.objectMatrix;
    
    this.init = function(){
        this.rMat = new Matrix3d();
        this.rMatrix = new Matrix3d();
        this.objectMatrix = new Matrix3d();
        
        this.initMatrix();
    };
    
    this.initMatrix = function(){
        this.objectMatrix.matrixIdentity();
    };
    
    this.translate = function(x, y, z){
        this.rMat.matrixIdentity();
        this.rMat.getMatrix()[3][0] = x;
        this.rMat.getMatrix()[3][1] = y;
        this.rMat.getMatrix()[3][2] = z;
        
        this.objectMatrix.matrixCopy(this.rMat);
    };
    
    this.rotate = function(x, y, z){
        var rx = x * (Math.PI / 180.0);
        var ry = y * (Math.PI / 180.0);
        var rz = z * (Math.PI / 180.0);
        
        this.rMatrix.matrixIdentity();
        this.rMat.matrixIdentity();
        this.rMat.getMatrix()[1][1] = Math.cos(rx);
        this.rMat.getMatrix()[1][2] = Math.sin(rx);
        this.rMat.getMatrix()[2][1] = -(Math.sin(rx));
        this.rMat.getMatrix()[2][2] = Math.cos(rx);
        this.rMatrix.matrixMult(this.rMatrix, this.rMat);
        
        this.rMat.matrixIdentity();
        this.rMat.getMatrix()[0][0] = Math.cos(ry);
        this.rMat.getMatrix()[0][2] = -(Math.sin(ry));
        this.rMat.getMatrix()[2][0] = Math.sin(ry);
        this.rMat.getMatrix()[2][2] = Math.cos(ry);
        this.rMat.matrixMult(this.rMatrix, this.rMat);
        
        this.rMat.matrixIdentity();
        this.rMat.getMatrix()[0][0] = Math.cos(rz);
        this.rMat.getMatrix()[0][1] = Math.sin(rz);
        this.rMat.getMatrix()[1][0] = -(Math.sin(rz));
        this.rMat.getMatrix()[1][1] = Math.cos(rz);
        this.rMat.matrixMult(this.rMatrix, this.rMat);
        
        this.objectMatrix.matrixCopy(this.rMatrix);
    };
    
    this.scale = function(scale){
        this.rMat.matrixIdentity();
        this.rMat.getMatrix()[0][0] = scale;
        this.rMat.getMatrix()[1][1] = scale;
        this.rMat.getMatrix()[2][2] = scale;
        
        this.objectMatrix.matrixCopy(this.rMat);
    };
    
    this.ChangeObjectPoint = function(p){
        p.ax = (p.lx * this.objectMatrix.getMatrix()[0][0] + p.ly * this.objectMatrix.getMatrix()[1][0] + p.lz * this.objectMatrix.getMatrix()[2][0] + this.objectMatrix.getMatrix()[3][0]);
        p.ay = (p.lx * this.objectMatrix.getMatrix()[0][1] + p.ly * this.objectMatrix.getMatrix()[1][1] + p.lz * this.objectMatrix.getMatrix()[2][1] + this.objectMatrix.getMatrix()[3][1]);
        p.az = (p.lx * this.objectMatrix.getMatrix()[0][2] + p.ly * this.objectMatrix.getMatrix()[1][2] + p.lz * this.objectMatrix.getMatrix()[2][2] + this.objectMatrix.getMatrix()[3][2]);
        
        return p;
    };
    
    this.init();
};

/*
 * Point: A simple 2D point.
 * ************************************************************
 */
Point = function(x, y){
    this.x = x;
    this.y = y;
};

/*
 * This function displays tooltips and was adapted from original code by Michael Leigeber.
 * See http://www.leigeber.com/
 */
Tooltip = function(useExplicitPositions, tooltipColour){
    var top = 3;
    var left = 3;
    var maxw = 300;
    var speed = 10;
    var timer = 20;
    var endalpha = 95;
    var alpha = 0;
    var tt, t, c, b, h;
    var ie = document.all ? true : false;
    
    this.show = function(v, w){
        if (tt == null) {
            tt = document.createElement('div');
            tt.style.color = tooltipColour;
            
            tt.style.position = 'absolute';
            tt.style.display = 'block';
            
            t = document.createElement('div');
            
            t.style.display = 'block';
            t.style.height = '5px';
            t.style.marginleft = '5px';
            t.style.overflow = 'hidden';
            
            c = document.createElement('div');
            
            b = document.createElement('div');
            
            tt.appendChild(t);
            tt.appendChild(c);
            tt.appendChild(b);
            document.body.appendChild(tt);
            
            if (!ie) {
                tt.style.opacity = 0;
                tt.style.filter = 'alpha(opacity=0)';
            }
            else 
                tt.style.opacity = 1;
            
            
        }
        
        if (!useExplicitPositions) 
            document.onmousemove = this.pos;
        
        tt.style.display = 'block';
        c.innerHTML = '<span style="font-weight:bold; font-family: arial;">' + v + '</span>';
        tt.style.width = w ? w + 'px' : 'auto';
        
        if (!w && ie) {
            t.style.display = 'none';
            b.style.display = 'none';
            tt.style.width = tt.offsetWidth;
            t.style.display = 'block';
            b.style.display = 'block';
        }
        
        if (tt.offsetWidth > maxw) {
            tt.style.width = maxw + 'px';
        }
        
        h = parseInt(tt.offsetHeight) + top;
        
        if (!ie) {
            clearInterval(tt.timer);
            tt.timer = setInterval(function(){
                fade(1)
            }, timer);
        }
    };
    
    this.setPos = function(e){
        tt.style.top = e.y + 'px';
        tt.style.left = e.x + 'px';
    };
    
    this.pos = function(e){
        var u = ie ? event.clientY + document.documentElement.scrollTop : e.pageY;
        var l = ie ? event.clientX + document.documentElement.scrollLeft : e.pageX;
        tt.style.top = (u - h) + 'px';
        tt.style.left = (l + left) + 'px';
        tt.style.zIndex = 999999999999;
    };
    
    function fade(d){
        var a = alpha;
        
        if ((a != endalpha && d == 1) || (a != 0 && d == -1)) {
            var i = speed;
            
            if (endalpha - a < speed && d == 1) {
                i = endalpha - a;
            }
            else 
                if (alpha < speed && d == -1) {
                    i = a;
                }
            
            alpha = a + (i * d);
            tt.style.opacity = alpha * .01;
            tt.style.filter = 'alpha(opacity=' + alpha + ')';
        }
        else {
            clearInterval(tt.timer);
            
            if (d == -1) {
                tt.style.display = 'none';
            }
        }
    }
    
    this.hide = function(){
        if (tt == null) 
            return;
        
        if (!ie) {
            clearInterval(tt.timer);
            tt.timer = setInterval(function(){
                fade(-1)
            }, timer);
        }
        else {
            tt.style.display = 'none';
        }
    };
};

degToRad = function(degrees){
    return degrees * Math.PI / 180;
};

function hexToR(h){
    return parseInt((cutHex(h)).substring(0, 2), 16)
}

function hexToG(h){
    return parseInt((cutHex(h)).substring(2, 4), 16)
}

function hexToB(h){
    return parseInt((cutHex(h)).substring(4, 6), 16)
}

function cutHex(h){
    return (h.charAt(0) == "#") ? h.substring(1, 7) : h
}

log = function(base, value){
    return Math.log(value) / Math.log(base);
};

JSSurfacePlot.DEFAULT_X_ANGLE_CANVAS = 47;
JSSurfacePlot.DEFAULT_Z_ANGLE_CANVAS = 47;
JSSurfacePlot.DEFAULT_X_ANGLE_WEBGL = -70;
JSSurfacePlot.DEFAULT_Y_ANGLE_WEBGL = -42;
JSSurfacePlot.DATA_DOT_SIZE = 5;
JSSurfacePlot.DEFAULT_SCALE = 350;
JSSurfacePlot.MIN_SCALE = 50;
JSSurfacePlot.MAX_SCALE = 1100;
JSSurfacePlot.SCALE_FACTOR = 1.4;

/*
 * ColourGradient.js
 *
 * Written by Greg Ross
 
 */
ColourGradient = function(minValue, maxValue, rgbColourArray)
{
  /**
     * Return a colour from a position on the path in RGB space that is proportioal to
     * the number specified in relation to the minimum and maximum values from which the
     * bounds of the path are derived.
     * @member ColourGradient
     * @param value
     */
    this.getColour = function (value) {
        if (isNaN(value))
            return rgbColourArray[0];

        if (value < minValue || rgbColourArray.length == 1)
            return rgbColourArray[0];
        else if (value < minValue || value > maxValue || rgbColourArray.length == 1) {
            return rgbColourArray[rgbColourArray.length - 1];
        }

        var scaledValue = mapValueToZeroOneInterval(value, minValue, maxValue);

        return getPointOnColourRamp(scaledValue);
    };
  
  function getPointOnColourRamp(value)
  {
    var numberOfColours = rgbColourArray.length;
    var scaleWidth = 1 / (numberOfColours - 1);
    var index = (value / scaleWidth);
    var index = parseInt(index + "");
        
    index = index ==  (numberOfColours - 1) ? index - 1 : index;
    
    var rgb1 = rgbColourArray[index];
    var rgb2 = rgbColourArray[index + 1];
    
    if (rgb1 == void 0 || rgb2 == void 0)
      return rgbColourArray[0];
    
    var closestToOrigin, furthestFromOrigin;
    
    if (distanceFromRgbOrigin(rgb1) > distanceFromRgbOrigin(rgb2))
    {
      closestToOrigin = rgb2;
      furthestFromOrigin = rgb1;
    }
    else
    {
      closestToOrigin = rgb1;
      furthestFromOrigin = rgb2;
    }
    
    var t;
    
    if (closestToOrigin == rgb2)
      t = 1 - mapValueToZeroOneInterval(value, index * scaleWidth, (index + 1) * scaleWidth);
    else
      t = mapValueToZeroOneInterval(value, index * scaleWidth, (index + 1) * scaleWidth);
      
    var diff = [
      t * (furthestFromOrigin.red - closestToOrigin.red),
      t * (furthestFromOrigin.green - closestToOrigin.green), 
      t * (furthestFromOrigin.blue - closestToOrigin.blue)];
    
    var r = closestToOrigin.red + diff[0];
    var g = closestToOrigin.green + diff[1];
    var b = closestToOrigin.blue + diff[2];
    
    r = parseInt(r);
    g = parseInt(g);
    b = parseInt(b);
    
    var colr = {
      red:r,
      green:g,
      blue:b
    };
    
    return colr;
  }

  function distanceFromRgbOrigin(rgb)
  {
    return (rgb.red * rgb.red) + (rgb.green * rgb.green) + (rgb.blue * rgb.blue);
  }

  function mapValueToZeroOneInterval(value, minValue, maxValue)
  {
    if (minValue == maxValue) return 0;
    
    var factor = (value - minValue) / (maxValue - minValue);
    return factor;
  }
};// glMatrix v0.9.5
glMatrixArrayType=typeof Float32Array!="undefined"?Float32Array:typeof WebGLFloatArray!="undefined"?WebGLFloatArray:Array;var vec3={};vec3.create=function(a){var b=new glMatrixArrayType(3);if(a){b[0]=a[0];b[1]=a[1];b[2]=a[2]}return b};vec3.set=function(a,b){b[0]=a[0];b[1]=a[1];b[2]=a[2];return b};vec3.add=function(a,b,c){if(!c||a==c){a[0]+=b[0];a[1]+=b[1];a[2]+=b[2];return a}c[0]=a[0]+b[0];c[1]=a[1]+b[1];c[2]=a[2]+b[2];return c};
vec3.subtract=function(a,b,c){if(!c||a==c){a[0]-=b[0];a[1]-=b[1];a[2]-=b[2];return a}c[0]=a[0]-b[0];c[1]=a[1]-b[1];c[2]=a[2]-b[2];return c};vec3.negate=function(a,b){b||(b=a);b[0]=-a[0];b[1]=-a[1];b[2]=-a[2];return b};vec3.scale=function(a,b,c){if(!c||a==c){a[0]*=b;a[1]*=b;a[2]*=b;return a}c[0]=a[0]*b;c[1]=a[1]*b;c[2]=a[2]*b;return c};
vec3.normalize=function(a,b){b||(b=a);var c=a[0],d=a[1],e=a[2],g=Math.sqrt(c*c+d*d+e*e);if(g){if(g==1){b[0]=c;b[1]=d;b[2]=e;return b}}else{b[0]=0;b[1]=0;b[2]=0;return b}g=1/g;b[0]=c*g;b[1]=d*g;b[2]=e*g;return b};vec3.cross=function(a,b,c){c||(c=a);var d=a[0],e=a[1];a=a[2];var g=b[0],f=b[1];b=b[2];c[0]=e*b-a*f;c[1]=a*g-d*b;c[2]=d*f-e*g;return c};vec3.length=function(a){var b=a[0],c=a[1];a=a[2];return Math.sqrt(b*b+c*c+a*a)};vec3.dot=function(a,b){return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]};
vec3.direction=function(a,b,c){c||(c=a);var d=a[0]-b[0],e=a[1]-b[1];a=a[2]-b[2];b=Math.sqrt(d*d+e*e+a*a);if(!b){c[0]=0;c[1]=0;c[2]=0;return c}b=1/b;c[0]=d*b;c[1]=e*b;c[2]=a*b;return c};vec3.lerp=function(a,b,c,d){d||(d=a);d[0]=a[0]+c*(b[0]-a[0]);d[1]=a[1]+c*(b[1]-a[1]);d[2]=a[2]+c*(b[2]-a[2]);return d};vec3.str=function(a){return"["+a[0]+", "+a[1]+", "+a[2]+"]"};var mat3={};
mat3.create=function(a){var b=new glMatrixArrayType(9);if(a){b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3];b[4]=a[4];b[5]=a[5];b[6]=a[6];b[7]=a[7];b[8]=a[8];b[9]=a[9]}return b};mat3.set=function(a,b){b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3];b[4]=a[4];b[5]=a[5];b[6]=a[6];b[7]=a[7];b[8]=a[8];return b};mat3.identity=function(a){a[0]=1;a[1]=0;a[2]=0;a[3]=0;a[4]=1;a[5]=0;a[6]=0;a[7]=0;a[8]=1;return a};
mat3.transpose=function(a,b){if(!b||a==b){var c=a[1],d=a[2],e=a[5];a[1]=a[3];a[2]=a[6];a[3]=c;a[5]=a[7];a[6]=d;a[7]=e;return a}b[0]=a[0];b[1]=a[3];b[2]=a[6];b[3]=a[1];b[4]=a[4];b[5]=a[7];b[6]=a[2];b[7]=a[5];b[8]=a[8];return b};mat3.toMat4=function(a,b){b||(b=mat4.create());b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=0;b[4]=a[3];b[5]=a[4];b[6]=a[5];b[7]=0;b[8]=a[6];b[9]=a[7];b[10]=a[8];b[11]=0;b[12]=0;b[13]=0;b[14]=0;b[15]=1;return b};
mat3.str=function(a){return"["+a[0]+", "+a[1]+", "+a[2]+", "+a[3]+", "+a[4]+", "+a[5]+", "+a[6]+", "+a[7]+", "+a[8]+"]"};var mat4={};mat4.create=function(a){var b=new glMatrixArrayType(16);if(a){b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3];b[4]=a[4];b[5]=a[5];b[6]=a[6];b[7]=a[7];b[8]=a[8];b[9]=a[9];b[10]=a[10];b[11]=a[11];b[12]=a[12];b[13]=a[13];b[14]=a[14];b[15]=a[15]}return b};
mat4.set=function(a,b){b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3];b[4]=a[4];b[5]=a[5];b[6]=a[6];b[7]=a[7];b[8]=a[8];b[9]=a[9];b[10]=a[10];b[11]=a[11];b[12]=a[12];b[13]=a[13];b[14]=a[14];b[15]=a[15];return b};mat4.identity=function(a){a[0]=1;a[1]=0;a[2]=0;a[3]=0;a[4]=0;a[5]=1;a[6]=0;a[7]=0;a[8]=0;a[9]=0;a[10]=1;a[11]=0;a[12]=0;a[13]=0;a[14]=0;a[15]=1;return a};
mat4.transpose=function(a,b){if(!b||a==b){var c=a[1],d=a[2],e=a[3],g=a[6],f=a[7],h=a[11];a[1]=a[4];a[2]=a[8];a[3]=a[12];a[4]=c;a[6]=a[9];a[7]=a[13];a[8]=d;a[9]=g;a[11]=a[14];a[12]=e;a[13]=f;a[14]=h;return a}b[0]=a[0];b[1]=a[4];b[2]=a[8];b[3]=a[12];b[4]=a[1];b[5]=a[5];b[6]=a[9];b[7]=a[13];b[8]=a[2];b[9]=a[6];b[10]=a[10];b[11]=a[14];b[12]=a[3];b[13]=a[7];b[14]=a[11];b[15]=a[15];return b};
mat4.determinant=function(a){var b=a[0],c=a[1],d=a[2],e=a[3],g=a[4],f=a[5],h=a[6],i=a[7],j=a[8],k=a[9],l=a[10],o=a[11],m=a[12],n=a[13],p=a[14];a=a[15];return m*k*h*e-j*n*h*e-m*f*l*e+g*n*l*e+j*f*p*e-g*k*p*e-m*k*d*i+j*n*d*i+m*c*l*i-b*n*l*i-j*c*p*i+b*k*p*i+m*f*d*o-g*n*d*o-m*c*h*o+b*n*h*o+g*c*p*o-b*f*p*o-j*f*d*a+g*k*d*a+j*c*h*a-b*k*h*a-g*c*l*a+b*f*l*a};
mat4.inverse=function(a,b){b||(b=a);var c=a[0],d=a[1],e=a[2],g=a[3],f=a[4],h=a[5],i=a[6],j=a[7],k=a[8],l=a[9],o=a[10],m=a[11],n=a[12],p=a[13],r=a[14],s=a[15],A=c*h-d*f,B=c*i-e*f,t=c*j-g*f,u=d*i-e*h,v=d*j-g*h,w=e*j-g*i,x=k*p-l*n,y=k*r-o*n,z=k*s-m*n,C=l*r-o*p,D=l*s-m*p,E=o*s-m*r,q=1/(A*E-B*D+t*C+u*z-v*y+w*x);b[0]=(h*E-i*D+j*C)*q;b[1]=(-d*E+e*D-g*C)*q;b[2]=(p*w-r*v+s*u)*q;b[3]=(-l*w+o*v-m*u)*q;b[4]=(-f*E+i*z-j*y)*q;b[5]=(c*E-e*z+g*y)*q;b[6]=(-n*w+r*t-s*B)*q;b[7]=(k*w-o*t+m*B)*q;b[8]=(f*D-h*z+j*x)*q;
b[9]=(-c*D+d*z-g*x)*q;b[10]=(n*v-p*t+s*A)*q;b[11]=(-k*v+l*t-m*A)*q;b[12]=(-f*C+h*y-i*x)*q;b[13]=(c*C-d*y+e*x)*q;b[14]=(-n*u+p*B-r*A)*q;b[15]=(k*u-l*B+o*A)*q;return b};mat4.toRotationMat=function(a,b){b||(b=mat4.create());b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3];b[4]=a[4];b[5]=a[5];b[6]=a[6];b[7]=a[7];b[8]=a[8];b[9]=a[9];b[10]=a[10];b[11]=a[11];b[12]=0;b[13]=0;b[14]=0;b[15]=1;return b};
mat4.toMat3=function(a,b){b||(b=mat3.create());b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[4];b[4]=a[5];b[5]=a[6];b[6]=a[8];b[7]=a[9];b[8]=a[10];return b};mat4.toInverseMat3=function(a,b){var c=a[0],d=a[1],e=a[2],g=a[4],f=a[5],h=a[6],i=a[8],j=a[9],k=a[10],l=k*f-h*j,o=-k*g+h*i,m=j*g-f*i,n=c*l+d*o+e*m;if(!n)return null;n=1/n;b||(b=mat3.create());b[0]=l*n;b[1]=(-k*d+e*j)*n;b[2]=(h*d-e*f)*n;b[3]=o*n;b[4]=(k*c-e*i)*n;b[5]=(-h*c+e*g)*n;b[6]=m*n;b[7]=(-j*c+d*i)*n;b[8]=(f*c-d*g)*n;return b};
mat4.multiply=function(a,b,c){c||(c=a);var d=a[0],e=a[1],g=a[2],f=a[3],h=a[4],i=a[5],j=a[6],k=a[7],l=a[8],o=a[9],m=a[10],n=a[11],p=a[12],r=a[13],s=a[14];a=a[15];var A=b[0],B=b[1],t=b[2],u=b[3],v=b[4],w=b[5],x=b[6],y=b[7],z=b[8],C=b[9],D=b[10],E=b[11],q=b[12],F=b[13],G=b[14];b=b[15];c[0]=A*d+B*h+t*l+u*p;c[1]=A*e+B*i+t*o+u*r;c[2]=A*g+B*j+t*m+u*s;c[3]=A*f+B*k+t*n+u*a;c[4]=v*d+w*h+x*l+y*p;c[5]=v*e+w*i+x*o+y*r;c[6]=v*g+w*j+x*m+y*s;c[7]=v*f+w*k+x*n+y*a;c[8]=z*d+C*h+D*l+E*p;c[9]=z*e+C*i+D*o+E*r;c[10]=z*
g+C*j+D*m+E*s;c[11]=z*f+C*k+D*n+E*a;c[12]=q*d+F*h+G*l+b*p;c[13]=q*e+F*i+G*o+b*r;c[14]=q*g+F*j+G*m+b*s;c[15]=q*f+F*k+G*n+b*a;return c};mat4.multiplyVec3=function(a,b,c){c||(c=b);var d=b[0],e=b[1];b=b[2];c[0]=a[0]*d+a[4]*e+a[8]*b+a[12];c[1]=a[1]*d+a[5]*e+a[9]*b+a[13];c[2]=a[2]*d+a[6]*e+a[10]*b+a[14];return c};
mat4.multiplyVec4=function(a,b,c){c||(c=b);var d=b[0],e=b[1],g=b[2];b=b[3];c[0]=a[0]*d+a[4]*e+a[8]*g+a[12]*b;c[1]=a[1]*d+a[5]*e+a[9]*g+a[13]*b;c[2]=a[2]*d+a[6]*e+a[10]*g+a[14]*b;c[3]=a[3]*d+a[7]*e+a[11]*g+a[15]*b;return c};
mat4.translate=function(a,b,c){var d=b[0],e=b[1];b=b[2];if(!c||a==c){a[12]=a[0]*d+a[4]*e+a[8]*b+a[12];a[13]=a[1]*d+a[5]*e+a[9]*b+a[13];a[14]=a[2]*d+a[6]*e+a[10]*b+a[14];a[15]=a[3]*d+a[7]*e+a[11]*b+a[15];return a}var g=a[0],f=a[1],h=a[2],i=a[3],j=a[4],k=a[5],l=a[6],o=a[7],m=a[8],n=a[9],p=a[10],r=a[11];c[0]=g;c[1]=f;c[2]=h;c[3]=i;c[4]=j;c[5]=k;c[6]=l;c[7]=o;c[8]=m;c[9]=n;c[10]=p;c[11]=r;c[12]=g*d+j*e+m*b+a[12];c[13]=f*d+k*e+n*b+a[13];c[14]=h*d+l*e+p*b+a[14];c[15]=i*d+o*e+r*b+a[15];return c};
mat4.scale=function(a,b,c){var d=b[0],e=b[1];b=b[2];if(!c||a==c){a[0]*=d;a[1]*=d;a[2]*=d;a[3]*=d;a[4]*=e;a[5]*=e;a[6]*=e;a[7]*=e;a[8]*=b;a[9]*=b;a[10]*=b;a[11]*=b;return a}c[0]=a[0]*d;c[1]=a[1]*d;c[2]=a[2]*d;c[3]=a[3]*d;c[4]=a[4]*e;c[5]=a[5]*e;c[6]=a[6]*e;c[7]=a[7]*e;c[8]=a[8]*b;c[9]=a[9]*b;c[10]=a[10]*b;c[11]=a[11]*b;c[12]=a[12];c[13]=a[13];c[14]=a[14];c[15]=a[15];return c};
mat4.rotate=function(a,b,c,d){var e=c[0],g=c[1];c=c[2];var f=Math.sqrt(e*e+g*g+c*c);if(!f)return null;if(f!=1){f=1/f;e*=f;g*=f;c*=f}var h=Math.sin(b),i=Math.cos(b),j=1-i;b=a[0];f=a[1];var k=a[2],l=a[3],o=a[4],m=a[5],n=a[6],p=a[7],r=a[8],s=a[9],A=a[10],B=a[11],t=e*e*j+i,u=g*e*j+c*h,v=c*e*j-g*h,w=e*g*j-c*h,x=g*g*j+i,y=c*g*j+e*h,z=e*c*j+g*h;e=g*c*j-e*h;g=c*c*j+i;if(d){if(a!=d){d[12]=a[12];d[13]=a[13];d[14]=a[14];d[15]=a[15]}}else d=a;d[0]=b*t+o*u+r*v;d[1]=f*t+m*u+s*v;d[2]=k*t+n*u+A*v;d[3]=l*t+p*u+B*
v;d[4]=b*w+o*x+r*y;d[5]=f*w+m*x+s*y;d[6]=k*w+n*x+A*y;d[7]=l*w+p*x+B*y;d[8]=b*z+o*e+r*g;d[9]=f*z+m*e+s*g;d[10]=k*z+n*e+A*g;d[11]=l*z+p*e+B*g;return d};mat4.rotateX=function(a,b,c){var d=Math.sin(b);b=Math.cos(b);var e=a[4],g=a[5],f=a[6],h=a[7],i=a[8],j=a[9],k=a[10],l=a[11];if(c){if(a!=c){c[0]=a[0];c[1]=a[1];c[2]=a[2];c[3]=a[3];c[12]=a[12];c[13]=a[13];c[14]=a[14];c[15]=a[15]}}else c=a;c[4]=e*b+i*d;c[5]=g*b+j*d;c[6]=f*b+k*d;c[7]=h*b+l*d;c[8]=e*-d+i*b;c[9]=g*-d+j*b;c[10]=f*-d+k*b;c[11]=h*-d+l*b;return c};
mat4.rotateY=function(a,b,c){var d=Math.sin(b);b=Math.cos(b);var e=a[0],g=a[1],f=a[2],h=a[3],i=a[8],j=a[9],k=a[10],l=a[11];if(c){if(a!=c){c[4]=a[4];c[5]=a[5];c[6]=a[6];c[7]=a[7];c[12]=a[12];c[13]=a[13];c[14]=a[14];c[15]=a[15]}}else c=a;c[0]=e*b+i*-d;c[1]=g*b+j*-d;c[2]=f*b+k*-d;c[3]=h*b+l*-d;c[8]=e*d+i*b;c[9]=g*d+j*b;c[10]=f*d+k*b;c[11]=h*d+l*b;return c};
mat4.rotateZ=function(a,b,c){var d=Math.sin(b);b=Math.cos(b);var e=a[0],g=a[1],f=a[2],h=a[3],i=a[4],j=a[5],k=a[6],l=a[7];if(c){if(a!=c){c[8]=a[8];c[9]=a[9];c[10]=a[10];c[11]=a[11];c[12]=a[12];c[13]=a[13];c[14]=a[14];c[15]=a[15]}}else c=a;c[0]=e*b+i*d;c[1]=g*b+j*d;c[2]=f*b+k*d;c[3]=h*b+l*d;c[4]=e*-d+i*b;c[5]=g*-d+j*b;c[6]=f*-d+k*b;c[7]=h*-d+l*b;return c};
mat4.frustum=function(a,b,c,d,e,g,f){f||(f=mat4.create());var h=b-a,i=d-c,j=g-e;f[0]=e*2/h;f[1]=0;f[2]=0;f[3]=0;f[4]=0;f[5]=e*2/i;f[6]=0;f[7]=0;f[8]=(b+a)/h;f[9]=(d+c)/i;f[10]=-(g+e)/j;f[11]=-1;f[12]=0;f[13]=0;f[14]=-(g*e*2)/j;f[15]=0;return f};mat4.perspective=function(a,b,c,d,e){a=c*Math.tan(a*Math.PI/360);b=a*b;return mat4.frustum(-b,b,-a,a,c,d,e)};
mat4.ortho=function(a,b,c,d,e,g,f){f||(f=mat4.create());var h=b-a,i=d-c,j=g-e;f[0]=2/h;f[1]=0;f[2]=0;f[3]=0;f[4]=0;f[5]=2/i;f[6]=0;f[7]=0;f[8]=0;f[9]=0;f[10]=-2/j;f[11]=0;f[12]=-(a+b)/h;f[13]=-(d+c)/i;f[14]=-(g+e)/j;f[15]=1;return f};
mat4.lookAt=function(a,b,c,d){d||(d=mat4.create());var e=a[0],g=a[1];a=a[2];var f=c[0],h=c[1],i=c[2];c=b[1];var j=b[2];if(e==b[0]&&g==c&&a==j)return mat4.identity(d);var k,l,o,m;c=e-b[0];j=g-b[1];b=a-b[2];m=1/Math.sqrt(c*c+j*j+b*b);c*=m;j*=m;b*=m;k=h*b-i*j;i=i*c-f*b;f=f*j-h*c;if(m=Math.sqrt(k*k+i*i+f*f)){m=1/m;k*=m;i*=m;f*=m}else f=i=k=0;h=j*f-b*i;l=b*k-c*f;o=c*i-j*k;if(m=Math.sqrt(h*h+l*l+o*o)){m=1/m;h*=m;l*=m;o*=m}else o=l=h=0;d[0]=k;d[1]=h;d[2]=c;d[3]=0;d[4]=i;d[5]=l;d[6]=j;d[7]=0;d[8]=f;d[9]=
o;d[10]=b;d[11]=0;d[12]=-(k*e+i*g+f*a);d[13]=-(h*e+l*g+o*a);d[14]=-(c*e+j*g+b*a);d[15]=1;return d};mat4.str=function(a){return"["+a[0]+", "+a[1]+", "+a[2]+", "+a[3]+", "+a[4]+", "+a[5]+", "+a[6]+", "+a[7]+", "+a[8]+", "+a[9]+", "+a[10]+", "+a[11]+", "+a[12]+", "+a[13]+", "+a[14]+", "+a[15]+"]"};quat4={};quat4.create=function(a){var b=new glMatrixArrayType(4);if(a){b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3]}return b};quat4.set=function(a,b){b[0]=a[0];b[1]=a[1];b[2]=a[2];b[3]=a[3];return b};
quat4.calculateW=function(a,b){var c=a[0],d=a[1],e=a[2];if(!b||a==b){a[3]=-Math.sqrt(Math.abs(1-c*c-d*d-e*e));return a}b[0]=c;b[1]=d;b[2]=e;b[3]=-Math.sqrt(Math.abs(1-c*c-d*d-e*e));return b};quat4.inverse=function(a,b){if(!b||a==b){a[0]*=1;a[1]*=1;a[2]*=1;return a}b[0]=-a[0];b[1]=-a[1];b[2]=-a[2];b[3]=a[3];return b};quat4.length=function(a){var b=a[0],c=a[1],d=a[2];a=a[3];return Math.sqrt(b*b+c*c+d*d+a*a)};
quat4.normalize=function(a,b){b||(b=a);var c=a[0],d=a[1],e=a[2],g=a[3],f=Math.sqrt(c*c+d*d+e*e+g*g);if(f==0){b[0]=0;b[1]=0;b[2]=0;b[3]=0;return b}f=1/f;b[0]=c*f;b[1]=d*f;b[2]=e*f;b[3]=g*f;return b};quat4.multiply=function(a,b,c){c||(c=a);var d=a[0],e=a[1],g=a[2];a=a[3];var f=b[0],h=b[1],i=b[2];b=b[3];c[0]=d*b+a*f+e*i-g*h;c[1]=e*b+a*h+g*f-d*i;c[2]=g*b+a*i+d*h-e*f;c[3]=a*b-d*f-e*h-g*i;return c};
quat4.multiplyVec3=function(a,b,c){c||(c=b);var d=b[0],e=b[1],g=b[2];b=a[0];var f=a[1],h=a[2];a=a[3];var i=a*d+f*g-h*e,j=a*e+h*d-b*g,k=a*g+b*e-f*d;d=-b*d-f*e-h*g;c[0]=i*a+d*-b+j*-h-k*-f;c[1]=j*a+d*-f+k*-b-i*-h;c[2]=k*a+d*-h+i*-f-j*-b;return c};quat4.toMat3=function(a,b){b||(b=mat3.create());var c=a[0],d=a[1],e=a[2],g=a[3],f=c+c,h=d+d,i=e+e,j=c*f,k=c*h;c=c*i;var l=d*h;d=d*i;e=e*i;f=g*f;h=g*h;g=g*i;b[0]=1-(l+e);b[1]=k-g;b[2]=c+h;b[3]=k+g;b[4]=1-(j+e);b[5]=d-f;b[6]=c-h;b[7]=d+f;b[8]=1-(j+l);return b};
quat4.toMat4=function(a,b){b||(b=mat4.create());var c=a[0],d=a[1],e=a[2],g=a[3],f=c+c,h=d+d,i=e+e,j=c*f,k=c*h;c=c*i;var l=d*h;d=d*i;e=e*i;f=g*f;h=g*h;g=g*i;b[0]=1-(l+e);b[1]=k-g;b[2]=c+h;b[3]=0;b[4]=k+g;b[5]=1-(j+e);b[6]=d-f;b[7]=0;b[8]=c-h;b[9]=d+f;b[10]=1-(j+l);b[11]=0;b[12]=0;b[13]=0;b[14]=0;b[15]=1;return b};quat4.slerp=function(a,b,c,d){d||(d=a);var e=c;if(a[0]*b[0]+a[1]*b[1]+a[2]*b[2]+a[3]*b[3]<0)e=-1*c;d[0]=1-c*a[0]+e*b[0];d[1]=1-c*a[1]+e*b[1];d[2]=1-c*a[2]+e*b[2];d[3]=1-c*a[3]+e*b[3];return d};
quat4.str=function(a){return"["+a[0]+", "+a[1]+", "+a[2]+", "+a[3]+"]"};/*
 * Copyright 2010, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @fileoverview This file contains functions every webgl program will need
 * a version of one way or another.
 *
 * Instead of setting up a context manually it is recommended to
 * use. This will check for success or failure. On failure it
 * will attempt to present an approriate message to the user.
 *
 *       gl = WebGLUtils.setupWebGL(canvas);
 *
 * For animated WebGL apps use of setTimeout or setInterval are
 * discouraged. It is recommended you structure your rendering
 * loop like this.
 *
 *       function render() {
 *         window.requestAnimFrame(render, canvas);
 *
 *         // do rendering
 *         ...
 *       }
 *       render();
 *
 * This will call your rendering function up to the refresh rate
 * of your display but will stop rendering if your app is not
 * visible.
 */

WebGLUtils = function() {

/**
 * Creates the HTLM for a failure message
 * @param {string} canvasContainerId id of container of th
 *        canvas.
 * @return {string} The html.
 */
var makeFailHTML = function(msg) {
  return '' +
    '<table style="background-color: #8CE; width: 100%; height: 100%;"><tr>' +
    '<td align="center">' +
    '<div style="display: table-cell; vertical-align: middle;">' +
    '<div style="">' + msg + '</div>' +
    '</div>' +
    '</td></tr></table>';
};

/**
 * Mesasge for getting a webgl browser
 * @type {string}
 */
var GET_A_WEBGL_BROWSER = '' +
  'This page requires a browser that supports WebGL.<br/>' +
  '<a href="http://get.webgl.org">Click here to upgrade your browser.</a>';

/**
 * Mesasge for need better hardware
 * @type {string}
 */
var OTHER_PROBLEM = '' +
  "It doesn't appear your computer can support WebGL.<br/>" +
  '<a href="http://get.webgl.org/troubleshooting/">Click here for more information.</a>';

/**
 * Creates a webgl context. If creation fails it will
 * change the contents of the container of the <canvas>
 * tag to an error message with the correct links for WebGL.
 * @param {Element} canvas. The canvas element to create a
 *     context from.
 * @param {WebGLContextCreationAttirbutes} opt_attribs Any
 *     creation attributes you want to pass in.
 * @param {function:(msg)} opt_onError An function to call
 *     if there is an error during creation.
 * @return {WebGLRenderingContext} The created context.
 */
var setupWebGL = function(canvas, opt_attribs, opt_onError) {
  function handleCreationError(msg) {
    var container = canvas.parentNode;
    if (container) {
      var str = window.WebGLRenderingContext ?
           OTHER_PROBLEM :
           GET_A_WEBGL_BROWSER;
      if (msg) {
        str += "<br/><br/>Status: " + msg;
      }
      container.innerHTML = makeFailHTML(str);
    }
  };

  opt_onError = opt_onError || handleCreationError;

  if (canvas.addEventListener) {
    canvas.addEventListener("webglcontextcreationerror", function(event) {
          opt_onError(event.statusMessage);
        }, false);
  }
  var context = create3DContext(canvas, opt_attribs);
  if (!context) {
    if (!window.WebGLRenderingContext) {
      opt_onError("");
    }
  }
  return context;
};

/**
 * Creates a webgl context.
 * @param {!Canvas} canvas The canvas tag to get context
 *     from. If one is not passed in one will be created.
 * @return {!WebGLContext} The created context.
 */
var create3DContext = function(canvas, opt_attribs) {
  var names = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"];
  var context = null;
  for (var ii = 0; ii < names.length; ++ii) {
    try {
      context = canvas.getContext(names[ii], opt_attribs);
    } catch(e) {}
    if (context) {
      break;
    }
  }
  return context;
}

return {
  create3DContext: create3DContext,
  setupWebGL: setupWebGL
};
}();

/**
 * Provides requestAnimationFrame in a cross browser way.
 */
window.requestAnimFrame = (function() {
  return window.requestAnimationFrame ||
         window.webkitRequestAnimationFrame ||
         window.mozRequestAnimationFrame ||
         window.oRequestAnimationFrame ||
         window.msRequestAnimationFrame ||
         function(/* function FrameRequestCallback */ callback, /* DOMElement Element */ element) {
           window.setTimeout(callback, 1000/60);
         };
})();

/*! jQuery v1.10.2 | (c) 2005, 2013 jQuery Foundation, Inc. | jquery.org/license
//@ sourceMappingURL=jquery-1.10.2.min.map
*/
(function(e,t){var n,r,i=typeof t,o=e.location,a=e.document,s=a.documentElement,l=e.jQuery,u=e.$,c={},p=[],f="1.10.2",d=p.concat,h=p.push,g=p.slice,m=p.indexOf,y=c.toString,v=c.hasOwnProperty,b=f.trim,x=function(e,t){return new x.fn.init(e,t,r)},w=/[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/.source,T=/\S+/g,C=/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,N=/^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]*))$/,k=/^<(\w+)\s*\/?>(?:<\/\1>|)$/,E=/^[\],:{}\s]*$/,S=/(?:^|:|,)(?:\s*\[)+/g,A=/\\(?:["\\\/bfnrt]|u[\da-fA-F]{4})/g,j=/"[^"\\\r\n]*"|true|false|null|-?(?:\d+\.|)\d+(?:[eE][+-]?\d+|)/g,D=/^-ms-/,L=/-([\da-z])/gi,H=function(e,t){return t.toUpperCase()},q=function(e){(a.addEventListener||"load"===e.type||"complete"===a.readyState)&&(_(),x.ready())},_=function(){a.addEventListener?(a.removeEventListener("DOMContentLoaded",q,!1),e.removeEventListener("load",q,!1)):(a.detachEvent("onreadystatechange",q),e.detachEvent("onload",q))};x.fn=x.prototype={jquery:f,constructor:x,init:function(e,n,r){var i,o;if(!e)return this;if("string"==typeof e){if(i="<"===e.charAt(0)&&">"===e.charAt(e.length-1)&&e.length>=3?[null,e,null]:N.exec(e),!i||!i[1]&&n)return!n||n.jquery?(n||r).find(e):this.constructor(n).find(e);if(i[1]){if(n=n instanceof x?n[0]:n,x.merge(this,x.parseHTML(i[1],n&&n.nodeType?n.ownerDocument||n:a,!0)),k.test(i[1])&&x.isPlainObject(n))for(i in n)x.isFunction(this[i])?this[i](n[i]):this.attr(i,n[i]);return this}if(o=a.getElementById(i[2]),o&&o.parentNode){if(o.id!==i[2])return r.find(e);this.length=1,this[0]=o}return this.context=a,this.selector=e,this}return e.nodeType?(this.context=this[0]=e,this.length=1,this):x.isFunction(e)?r.ready(e):(e.selector!==t&&(this.selector=e.selector,this.context=e.context),x.makeArray(e,this))},selector:"",length:0,toArray:function(){return g.call(this)},get:function(e){return null==e?this.toArray():0>e?this[this.length+e]:this[e]},pushStack:function(e){var t=x.merge(this.constructor(),e);return t.prevObject=this,t.context=this.context,t},each:function(e,t){return x.each(this,e,t)},ready:function(e){return x.ready.promise().done(e),this},slice:function(){return this.pushStack(g.apply(this,arguments))},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},eq:function(e){var t=this.length,n=+e+(0>e?t:0);return this.pushStack(n>=0&&t>n?[this[n]]:[])},map:function(e){return this.pushStack(x.map(this,function(t,n){return e.call(t,n,t)}))},end:function(){return this.prevObject||this.constructor(null)},push:h,sort:[].sort,splice:[].splice},x.fn.init.prototype=x.fn,x.extend=x.fn.extend=function(){var e,n,r,i,o,a,s=arguments[0]||{},l=1,u=arguments.length,c=!1;for("boolean"==typeof s&&(c=s,s=arguments[1]||{},l=2),"object"==typeof s||x.isFunction(s)||(s={}),u===l&&(s=this,--l);u>l;l++)if(null!=(o=arguments[l]))for(i in o)e=s[i],r=o[i],s!==r&&(c&&r&&(x.isPlainObject(r)||(n=x.isArray(r)))?(n?(n=!1,a=e&&x.isArray(e)?e:[]):a=e&&x.isPlainObject(e)?e:{},s[i]=x.extend(c,a,r)):r!==t&&(s[i]=r));return s},x.extend({expando:"jQuery"+(f+Math.random()).replace(/\D/g,""),noConflict:function(t){return e.$===x&&(e.$=u),t&&e.jQuery===x&&(e.jQuery=l),x},isReady:!1,readyWait:1,holdReady:function(e){e?x.readyWait++:x.ready(!0)},ready:function(e){if(e===!0?!--x.readyWait:!x.isReady){if(!a.body)return setTimeout(x.ready);x.isReady=!0,e!==!0&&--x.readyWait>0||(n.resolveWith(a,[x]),x.fn.trigger&&x(a).trigger("ready").off("ready"))}},isFunction:function(e){return"function"===x.type(e)},isArray:Array.isArray||function(e){return"array"===x.type(e)},isWindow:function(e){return null!=e&&e==e.window},isNumeric:function(e){return!isNaN(parseFloat(e))&&isFinite(e)},type:function(e){return null==e?e+"":"object"==typeof e||"function"==typeof e?c[y.call(e)]||"object":typeof e},isPlainObject:function(e){var n;if(!e||"object"!==x.type(e)||e.nodeType||x.isWindow(e))return!1;try{if(e.constructor&&!v.call(e,"constructor")&&!v.call(e.constructor.prototype,"isPrototypeOf"))return!1}catch(r){return!1}if(x.support.ownLast)for(n in e)return v.call(e,n);for(n in e);return n===t||v.call(e,n)},isEmptyObject:function(e){var t;for(t in e)return!1;return!0},error:function(e){throw Error(e)},parseHTML:function(e,t,n){if(!e||"string"!=typeof e)return null;"boolean"==typeof t&&(n=t,t=!1),t=t||a;var r=k.exec(e),i=!n&&[];return r?[t.createElement(r[1])]:(r=x.buildFragment([e],t,i),i&&x(i).remove(),x.merge([],r.childNodes))},parseJSON:function(n){return e.JSON&&e.JSON.parse?e.JSON.parse(n):null===n?n:"string"==typeof n&&(n=x.trim(n),n&&E.test(n.replace(A,"@").replace(j,"]").replace(S,"")))?Function("return "+n)():(x.error("Invalid JSON: "+n),t)},parseXML:function(n){var r,i;if(!n||"string"!=typeof n)return null;try{e.DOMParser?(i=new DOMParser,r=i.parseFromString(n,"text/xml")):(r=new ActiveXObject("Microsoft.XMLDOM"),r.async="false",r.loadXML(n))}catch(o){r=t}return r&&r.documentElement&&!r.getElementsByTagName("parsererror").length||x.error("Invalid XML: "+n),r},noop:function(){},globalEval:function(t){t&&x.trim(t)&&(e.execScript||function(t){e.eval.call(e,t)})(t)},camelCase:function(e){return e.replace(D,"ms-").replace(L,H)},nodeName:function(e,t){return e.nodeName&&e.nodeName.toLowerCase()===t.toLowerCase()},each:function(e,t,n){var r,i=0,o=e.length,a=M(e);if(n){if(a){for(;o>i;i++)if(r=t.apply(e[i],n),r===!1)break}else for(i in e)if(r=t.apply(e[i],n),r===!1)break}else if(a){for(;o>i;i++)if(r=t.call(e[i],i,e[i]),r===!1)break}else for(i in e)if(r=t.call(e[i],i,e[i]),r===!1)break;return e},trim:b&&!b.call("\ufeff\u00a0")?function(e){return null==e?"":b.call(e)}:function(e){return null==e?"":(e+"").replace(C,"")},makeArray:function(e,t){var n=t||[];return null!=e&&(M(Object(e))?x.merge(n,"string"==typeof e?[e]:e):h.call(n,e)),n},inArray:function(e,t,n){var r;if(t){if(m)return m.call(t,e,n);for(r=t.length,n=n?0>n?Math.max(0,r+n):n:0;r>n;n++)if(n in t&&t[n]===e)return n}return-1},merge:function(e,n){var r=n.length,i=e.length,o=0;if("number"==typeof r)for(;r>o;o++)e[i++]=n[o];else while(n[o]!==t)e[i++]=n[o++];return e.length=i,e},grep:function(e,t,n){var r,i=[],o=0,a=e.length;for(n=!!n;a>o;o++)r=!!t(e[o],o),n!==r&&i.push(e[o]);return i},map:function(e,t,n){var r,i=0,o=e.length,a=M(e),s=[];if(a)for(;o>i;i++)r=t(e[i],i,n),null!=r&&(s[s.length]=r);else for(i in e)r=t(e[i],i,n),null!=r&&(s[s.length]=r);return d.apply([],s)},guid:1,proxy:function(e,n){var r,i,o;return"string"==typeof n&&(o=e[n],n=e,e=o),x.isFunction(e)?(r=g.call(arguments,2),i=function(){return e.apply(n||this,r.concat(g.call(arguments)))},i.guid=e.guid=e.guid||x.guid++,i):t},access:function(e,n,r,i,o,a,s){var l=0,u=e.length,c=null==r;if("object"===x.type(r)){o=!0;for(l in r)x.access(e,n,l,r[l],!0,a,s)}else if(i!==t&&(o=!0,x.isFunction(i)||(s=!0),c&&(s?(n.call(e,i),n=null):(c=n,n=function(e,t,n){return c.call(x(e),n)})),n))for(;u>l;l++)n(e[l],r,s?i:i.call(e[l],l,n(e[l],r)));return o?e:c?n.call(e):u?n(e[0],r):a},now:function(){return(new Date).getTime()},swap:function(e,t,n,r){var i,o,a={};for(o in t)a[o]=e.style[o],e.style[o]=t[o];i=n.apply(e,r||[]);for(o in t)e.style[o]=a[o];return i}}),x.ready.promise=function(t){if(!n)if(n=x.Deferred(),"complete"===a.readyState)setTimeout(x.ready);else if(a.addEventListener)a.addEventListener("DOMContentLoaded",q,!1),e.addEventListener("load",q,!1);else{a.attachEvent("onreadystatechange",q),e.attachEvent("onload",q);var r=!1;try{r=null==e.frameElement&&a.documentElement}catch(i){}r&&r.doScroll&&function o(){if(!x.isReady){try{r.doScroll("left")}catch(e){return setTimeout(o,50)}_(),x.ready()}}()}return n.promise(t)},x.each("Boolean Number String Function Array Date RegExp Object Error".split(" "),function(e,t){c["[object "+t+"]"]=t.toLowerCase()});function M(e){var t=e.length,n=x.type(e);return x.isWindow(e)?!1:1===e.nodeType&&t?!0:"array"===n||"function"!==n&&(0===t||"number"==typeof t&&t>0&&t-1 in e)}r=x(a),function(e,t){var n,r,i,o,a,s,l,u,c,p,f,d,h,g,m,y,v,b="sizzle"+-new Date,w=e.document,T=0,C=0,N=st(),k=st(),E=st(),S=!1,A=function(e,t){return e===t?(S=!0,0):0},j=typeof t,D=1<<31,L={}.hasOwnProperty,H=[],q=H.pop,_=H.push,M=H.push,O=H.slice,F=H.indexOf||function(e){var t=0,n=this.length;for(;n>t;t++)if(this[t]===e)return t;return-1},B="checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped",P="[\\x20\\t\\r\\n\\f]",R="(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",W=R.replace("w","w#"),$="\\["+P+"*("+R+")"+P+"*(?:([*^$|!~]?=)"+P+"*(?:(['\"])((?:\\\\.|[^\\\\])*?)\\3|("+W+")|)|)"+P+"*\\]",I=":("+R+")(?:\\(((['\"])((?:\\\\.|[^\\\\])*?)\\3|((?:\\\\.|[^\\\\()[\\]]|"+$.replace(3,8)+")*)|.*)\\)|)",z=RegExp("^"+P+"+|((?:^|[^\\\\])(?:\\\\.)*)"+P+"+$","g"),X=RegExp("^"+P+"*,"+P+"*"),U=RegExp("^"+P+"*([>+~]|"+P+")"+P+"*"),V=RegExp(P+"*[+~]"),Y=RegExp("="+P+"*([^\\]'\"]*)"+P+"*\\]","g"),J=RegExp(I),G=RegExp("^"+W+"$"),Q={ID:RegExp("^#("+R+")"),CLASS:RegExp("^\\.("+R+")"),TAG:RegExp("^("+R.replace("w","w*")+")"),ATTR:RegExp("^"+$),PSEUDO:RegExp("^"+I),CHILD:RegExp("^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\("+P+"*(even|odd|(([+-]|)(\\d*)n|)"+P+"*(?:([+-]|)"+P+"*(\\d+)|))"+P+"*\\)|)","i"),bool:RegExp("^(?:"+B+")$","i"),needsContext:RegExp("^"+P+"*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\("+P+"*((?:-\\d)?\\d*)"+P+"*\\)|)(?=[^-]|$)","i")},K=/^[^{]+\{\s*\[native \w/,Z=/^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,et=/^(?:input|select|textarea|button)$/i,tt=/^h\d$/i,nt=/'|\\/g,rt=RegExp("\\\\([\\da-f]{1,6}"+P+"?|("+P+")|.)","ig"),it=function(e,t,n){var r="0x"+t-65536;return r!==r||n?t:0>r?String.fromCharCode(r+65536):String.fromCharCode(55296|r>>10,56320|1023&r)};try{M.apply(H=O.call(w.childNodes),w.childNodes),H[w.childNodes.length].nodeType}catch(ot){M={apply:H.length?function(e,t){_.apply(e,O.call(t))}:function(e,t){var n=e.length,r=0;while(e[n++]=t[r++]);e.length=n-1}}}function at(e,t,n,i){var o,a,s,l,u,c,d,m,y,x;if((t?t.ownerDocument||t:w)!==f&&p(t),t=t||f,n=n||[],!e||"string"!=typeof e)return n;if(1!==(l=t.nodeType)&&9!==l)return[];if(h&&!i){if(o=Z.exec(e))if(s=o[1]){if(9===l){if(a=t.getElementById(s),!a||!a.parentNode)return n;if(a.id===s)return n.push(a),n}else if(t.ownerDocument&&(a=t.ownerDocument.getElementById(s))&&v(t,a)&&a.id===s)return n.push(a),n}else{if(o[2])return M.apply(n,t.getElementsByTagName(e)),n;if((s=o[3])&&r.getElementsByClassName&&t.getElementsByClassName)return M.apply(n,t.getElementsByClassName(s)),n}if(r.qsa&&(!g||!g.test(e))){if(m=d=b,y=t,x=9===l&&e,1===l&&"object"!==t.nodeName.toLowerCase()){c=mt(e),(d=t.getAttribute("id"))?m=d.replace(nt,"\\$&"):t.setAttribute("id",m),m="[id='"+m+"'] ",u=c.length;while(u--)c[u]=m+yt(c[u]);y=V.test(e)&&t.parentNode||t,x=c.join(",")}if(x)try{return M.apply(n,y.querySelectorAll(x)),n}catch(T){}finally{d||t.removeAttribute("id")}}}return kt(e.replace(z,"$1"),t,n,i)}function st(){var e=[];function t(n,r){return e.push(n+=" ")>o.cacheLength&&delete t[e.shift()],t[n]=r}return t}function lt(e){return e[b]=!0,e}function ut(e){var t=f.createElement("div");try{return!!e(t)}catch(n){return!1}finally{t.parentNode&&t.parentNode.removeChild(t),t=null}}function ct(e,t){var n=e.split("|"),r=e.length;while(r--)o.attrHandle[n[r]]=t}function pt(e,t){var n=t&&e,r=n&&1===e.nodeType&&1===t.nodeType&&(~t.sourceIndex||D)-(~e.sourceIndex||D);if(r)return r;if(n)while(n=n.nextSibling)if(n===t)return-1;return e?1:-1}function ft(e){return function(t){var n=t.nodeName.toLowerCase();return"input"===n&&t.type===e}}function dt(e){return function(t){var n=t.nodeName.toLowerCase();return("input"===n||"button"===n)&&t.type===e}}function ht(e){return lt(function(t){return t=+t,lt(function(n,r){var i,o=e([],n.length,t),a=o.length;while(a--)n[i=o[a]]&&(n[i]=!(r[i]=n[i]))})})}s=at.isXML=function(e){var t=e&&(e.ownerDocument||e).documentElement;return t?"HTML"!==t.nodeName:!1},r=at.support={},p=at.setDocument=function(e){var n=e?e.ownerDocument||e:w,i=n.defaultView;return n!==f&&9===n.nodeType&&n.documentElement?(f=n,d=n.documentElement,h=!s(n),i&&i.attachEvent&&i!==i.top&&i.attachEvent("onbeforeunload",function(){p()}),r.attributes=ut(function(e){return e.className="i",!e.getAttribute("className")}),r.getElementsByTagName=ut(function(e){return e.appendChild(n.createComment("")),!e.getElementsByTagName("*").length}),r.getElementsByClassName=ut(function(e){return e.innerHTML="<div class='a'></div><div class='a i'></div>",e.firstChild.className="i",2===e.getElementsByClassName("i").length}),r.getById=ut(function(e){return d.appendChild(e).id=b,!n.getElementsByName||!n.getElementsByName(b).length}),r.getById?(o.find.ID=function(e,t){if(typeof t.getElementById!==j&&h){var n=t.getElementById(e);return n&&n.parentNode?[n]:[]}},o.filter.ID=function(e){var t=e.replace(rt,it);return function(e){return e.getAttribute("id")===t}}):(delete o.find.ID,o.filter.ID=function(e){var t=e.replace(rt,it);return function(e){var n=typeof e.getAttributeNode!==j&&e.getAttributeNode("id");return n&&n.value===t}}),o.find.TAG=r.getElementsByTagName?function(e,n){return typeof n.getElementsByTagName!==j?n.getElementsByTagName(e):t}:function(e,t){var n,r=[],i=0,o=t.getElementsByTagName(e);if("*"===e){while(n=o[i++])1===n.nodeType&&r.push(n);return r}return o},o.find.CLASS=r.getElementsByClassName&&function(e,n){return typeof n.getElementsByClassName!==j&&h?n.getElementsByClassName(e):t},m=[],g=[],(r.qsa=K.test(n.querySelectorAll))&&(ut(function(e){e.innerHTML="<select><option selected=''></option></select>",e.querySelectorAll("[selected]").length||g.push("\\["+P+"*(?:value|"+B+")"),e.querySelectorAll(":checked").length||g.push(":checked")}),ut(function(e){var t=n.createElement("input");t.setAttribute("type","hidden"),e.appendChild(t).setAttribute("t",""),e.querySelectorAll("[t^='']").length&&g.push("[*^$]="+P+"*(?:''|\"\")"),e.querySelectorAll(":enabled").length||g.push(":enabled",":disabled"),e.querySelectorAll("*,:x"),g.push(",.*:")})),(r.matchesSelector=K.test(y=d.webkitMatchesSelector||d.mozMatchesSelector||d.oMatchesSelector||d.msMatchesSelector))&&ut(function(e){r.disconnectedMatch=y.call(e,"div"),y.call(e,"[s!='']:x"),m.push("!=",I)}),g=g.length&&RegExp(g.join("|")),m=m.length&&RegExp(m.join("|")),v=K.test(d.contains)||d.compareDocumentPosition?function(e,t){var n=9===e.nodeType?e.documentElement:e,r=t&&t.parentNode;return e===r||!(!r||1!==r.nodeType||!(n.contains?n.contains(r):e.compareDocumentPosition&&16&e.compareDocumentPosition(r)))}:function(e,t){if(t)while(t=t.parentNode)if(t===e)return!0;return!1},A=d.compareDocumentPosition?function(e,t){if(e===t)return S=!0,0;var i=t.compareDocumentPosition&&e.compareDocumentPosition&&e.compareDocumentPosition(t);return i?1&i||!r.sortDetached&&t.compareDocumentPosition(e)===i?e===n||v(w,e)?-1:t===n||v(w,t)?1:c?F.call(c,e)-F.call(c,t):0:4&i?-1:1:e.compareDocumentPosition?-1:1}:function(e,t){var r,i=0,o=e.parentNode,a=t.parentNode,s=[e],l=[t];if(e===t)return S=!0,0;if(!o||!a)return e===n?-1:t===n?1:o?-1:a?1:c?F.call(c,e)-F.call(c,t):0;if(o===a)return pt(e,t);r=e;while(r=r.parentNode)s.unshift(r);r=t;while(r=r.parentNode)l.unshift(r);while(s[i]===l[i])i++;return i?pt(s[i],l[i]):s[i]===w?-1:l[i]===w?1:0},n):f},at.matches=function(e,t){return at(e,null,null,t)},at.matchesSelector=function(e,t){if((e.ownerDocument||e)!==f&&p(e),t=t.replace(Y,"='$1']"),!(!r.matchesSelector||!h||m&&m.test(t)||g&&g.test(t)))try{var n=y.call(e,t);if(n||r.disconnectedMatch||e.document&&11!==e.document.nodeType)return n}catch(i){}return at(t,f,null,[e]).length>0},at.contains=function(e,t){return(e.ownerDocument||e)!==f&&p(e),v(e,t)},at.attr=function(e,n){(e.ownerDocument||e)!==f&&p(e);var i=o.attrHandle[n.toLowerCase()],a=i&&L.call(o.attrHandle,n.toLowerCase())?i(e,n,!h):t;return a===t?r.attributes||!h?e.getAttribute(n):(a=e.getAttributeNode(n))&&a.specified?a.value:null:a},at.error=function(e){throw Error("Syntax error, unrecognized expression: "+e)},at.uniqueSort=function(e){var t,n=[],i=0,o=0;if(S=!r.detectDuplicates,c=!r.sortStable&&e.slice(0),e.sort(A),S){while(t=e[o++])t===e[o]&&(i=n.push(o));while(i--)e.splice(n[i],1)}return e},a=at.getText=function(e){var t,n="",r=0,i=e.nodeType;if(i){if(1===i||9===i||11===i){if("string"==typeof e.textContent)return e.textContent;for(e=e.firstChild;e;e=e.nextSibling)n+=a(e)}else if(3===i||4===i)return e.nodeValue}else for(;t=e[r];r++)n+=a(t);return n},o=at.selectors={cacheLength:50,createPseudo:lt,match:Q,attrHandle:{},find:{},relative:{">":{dir:"parentNode",first:!0}," ":{dir:"parentNode"},"+":{dir:"previousSibling",first:!0},"~":{dir:"previousSibling"}},preFilter:{ATTR:function(e){return e[1]=e[1].replace(rt,it),e[3]=(e[4]||e[5]||"").replace(rt,it),"~="===e[2]&&(e[3]=" "+e[3]+" "),e.slice(0,4)},CHILD:function(e){return e[1]=e[1].toLowerCase(),"nth"===e[1].slice(0,3)?(e[3]||at.error(e[0]),e[4]=+(e[4]?e[5]+(e[6]||1):2*("even"===e[3]||"odd"===e[3])),e[5]=+(e[7]+e[8]||"odd"===e[3])):e[3]&&at.error(e[0]),e},PSEUDO:function(e){var n,r=!e[5]&&e[2];return Q.CHILD.test(e[0])?null:(e[3]&&e[4]!==t?e[2]=e[4]:r&&J.test(r)&&(n=mt(r,!0))&&(n=r.indexOf(")",r.length-n)-r.length)&&(e[0]=e[0].slice(0,n),e[2]=r.slice(0,n)),e.slice(0,3))}},filter:{TAG:function(e){var t=e.replace(rt,it).toLowerCase();return"*"===e?function(){return!0}:function(e){return e.nodeName&&e.nodeName.toLowerCase()===t}},CLASS:function(e){var t=N[e+" "];return t||(t=RegExp("(^|"+P+")"+e+"("+P+"|$)"))&&N(e,function(e){return t.test("string"==typeof e.className&&e.className||typeof e.getAttribute!==j&&e.getAttribute("class")||"")})},ATTR:function(e,t,n){return function(r){var i=at.attr(r,e);return null==i?"!="===t:t?(i+="","="===t?i===n:"!="===t?i!==n:"^="===t?n&&0===i.indexOf(n):"*="===t?n&&i.indexOf(n)>-1:"$="===t?n&&i.slice(-n.length)===n:"~="===t?(" "+i+" ").indexOf(n)>-1:"|="===t?i===n||i.slice(0,n.length+1)===n+"-":!1):!0}},CHILD:function(e,t,n,r,i){var o="nth"!==e.slice(0,3),a="last"!==e.slice(-4),s="of-type"===t;return 1===r&&0===i?function(e){return!!e.parentNode}:function(t,n,l){var u,c,p,f,d,h,g=o!==a?"nextSibling":"previousSibling",m=t.parentNode,y=s&&t.nodeName.toLowerCase(),v=!l&&!s;if(m){if(o){while(g){p=t;while(p=p[g])if(s?p.nodeName.toLowerCase()===y:1===p.nodeType)return!1;h=g="only"===e&&!h&&"nextSibling"}return!0}if(h=[a?m.firstChild:m.lastChild],a&&v){c=m[b]||(m[b]={}),u=c[e]||[],d=u[0]===T&&u[1],f=u[0]===T&&u[2],p=d&&m.childNodes[d];while(p=++d&&p&&p[g]||(f=d=0)||h.pop())if(1===p.nodeType&&++f&&p===t){c[e]=[T,d,f];break}}else if(v&&(u=(t[b]||(t[b]={}))[e])&&u[0]===T)f=u[1];else while(p=++d&&p&&p[g]||(f=d=0)||h.pop())if((s?p.nodeName.toLowerCase()===y:1===p.nodeType)&&++f&&(v&&((p[b]||(p[b]={}))[e]=[T,f]),p===t))break;return f-=i,f===r||0===f%r&&f/r>=0}}},PSEUDO:function(e,t){var n,r=o.pseudos[e]||o.setFilters[e.toLowerCase()]||at.error("unsupported pseudo: "+e);return r[b]?r(t):r.length>1?(n=[e,e,"",t],o.setFilters.hasOwnProperty(e.toLowerCase())?lt(function(e,n){var i,o=r(e,t),a=o.length;while(a--)i=F.call(e,o[a]),e[i]=!(n[i]=o[a])}):function(e){return r(e,0,n)}):r}},pseudos:{not:lt(function(e){var t=[],n=[],r=l(e.replace(z,"$1"));return r[b]?lt(function(e,t,n,i){var o,a=r(e,null,i,[]),s=e.length;while(s--)(o=a[s])&&(e[s]=!(t[s]=o))}):function(e,i,o){return t[0]=e,r(t,null,o,n),!n.pop()}}),has:lt(function(e){return function(t){return at(e,t).length>0}}),contains:lt(function(e){return function(t){return(t.textContent||t.innerText||a(t)).indexOf(e)>-1}}),lang:lt(function(e){return G.test(e||"")||at.error("unsupported lang: "+e),e=e.replace(rt,it).toLowerCase(),function(t){var n;do if(n=h?t.lang:t.getAttribute("xml:lang")||t.getAttribute("lang"))return n=n.toLowerCase(),n===e||0===n.indexOf(e+"-");while((t=t.parentNode)&&1===t.nodeType);return!1}}),target:function(t){var n=e.location&&e.location.hash;return n&&n.slice(1)===t.id},root:function(e){return e===d},focus:function(e){return e===f.activeElement&&(!f.hasFocus||f.hasFocus())&&!!(e.type||e.href||~e.tabIndex)},enabled:function(e){return e.disabled===!1},disabled:function(e){return e.disabled===!0},checked:function(e){var t=e.nodeName.toLowerCase();return"input"===t&&!!e.checked||"option"===t&&!!e.selected},selected:function(e){return e.parentNode&&e.parentNode.selectedIndex,e.selected===!0},empty:function(e){for(e=e.firstChild;e;e=e.nextSibling)if(e.nodeName>"@"||3===e.nodeType||4===e.nodeType)return!1;return!0},parent:function(e){return!o.pseudos.empty(e)},header:function(e){return tt.test(e.nodeName)},input:function(e){return et.test(e.nodeName)},button:function(e){var t=e.nodeName.toLowerCase();return"input"===t&&"button"===e.type||"button"===t},text:function(e){var t;return"input"===e.nodeName.toLowerCase()&&"text"===e.type&&(null==(t=e.getAttribute("type"))||t.toLowerCase()===e.type)},first:ht(function(){return[0]}),last:ht(function(e,t){return[t-1]}),eq:ht(function(e,t,n){return[0>n?n+t:n]}),even:ht(function(e,t){var n=0;for(;t>n;n+=2)e.push(n);return e}),odd:ht(function(e,t){var n=1;for(;t>n;n+=2)e.push(n);return e}),lt:ht(function(e,t,n){var r=0>n?n+t:n;for(;--r>=0;)e.push(r);return e}),gt:ht(function(e,t,n){var r=0>n?n+t:n;for(;t>++r;)e.push(r);return e})}},o.pseudos.nth=o.pseudos.eq;for(n in{radio:!0,checkbox:!0,file:!0,password:!0,image:!0})o.pseudos[n]=ft(n);for(n in{submit:!0,reset:!0})o.pseudos[n]=dt(n);function gt(){}gt.prototype=o.filters=o.pseudos,o.setFilters=new gt;function mt(e,t){var n,r,i,a,s,l,u,c=k[e+" "];if(c)return t?0:c.slice(0);s=e,l=[],u=o.preFilter;while(s){(!n||(r=X.exec(s)))&&(r&&(s=s.slice(r[0].length)||s),l.push(i=[])),n=!1,(r=U.exec(s))&&(n=r.shift(),i.push({value:n,type:r[0].replace(z," ")}),s=s.slice(n.length));for(a in o.filter)!(r=Q[a].exec(s))||u[a]&&!(r=u[a](r))||(n=r.shift(),i.push({value:n,type:a,matches:r}),s=s.slice(n.length));if(!n)break}return t?s.length:s?at.error(e):k(e,l).slice(0)}function yt(e){var t=0,n=e.length,r="";for(;n>t;t++)r+=e[t].value;return r}function vt(e,t,n){var r=t.dir,o=n&&"parentNode"===r,a=C++;return t.first?function(t,n,i){while(t=t[r])if(1===t.nodeType||o)return e(t,n,i)}:function(t,n,s){var l,u,c,p=T+" "+a;if(s){while(t=t[r])if((1===t.nodeType||o)&&e(t,n,s))return!0}else while(t=t[r])if(1===t.nodeType||o)if(c=t[b]||(t[b]={}),(u=c[r])&&u[0]===p){if((l=u[1])===!0||l===i)return l===!0}else if(u=c[r]=[p],u[1]=e(t,n,s)||i,u[1]===!0)return!0}}function bt(e){return e.length>1?function(t,n,r){var i=e.length;while(i--)if(!e[i](t,n,r))return!1;return!0}:e[0]}function xt(e,t,n,r,i){var o,a=[],s=0,l=e.length,u=null!=t;for(;l>s;s++)(o=e[s])&&(!n||n(o,r,i))&&(a.push(o),u&&t.push(s));return a}function wt(e,t,n,r,i,o){return r&&!r[b]&&(r=wt(r)),i&&!i[b]&&(i=wt(i,o)),lt(function(o,a,s,l){var u,c,p,f=[],d=[],h=a.length,g=o||Nt(t||"*",s.nodeType?[s]:s,[]),m=!e||!o&&t?g:xt(g,f,e,s,l),y=n?i||(o?e:h||r)?[]:a:m;if(n&&n(m,y,s,l),r){u=xt(y,d),r(u,[],s,l),c=u.length;while(c--)(p=u[c])&&(y[d[c]]=!(m[d[c]]=p))}if(o){if(i||e){if(i){u=[],c=y.length;while(c--)(p=y[c])&&u.push(m[c]=p);i(null,y=[],u,l)}c=y.length;while(c--)(p=y[c])&&(u=i?F.call(o,p):f[c])>-1&&(o[u]=!(a[u]=p))}}else y=xt(y===a?y.splice(h,y.length):y),i?i(null,a,y,l):M.apply(a,y)})}function Tt(e){var t,n,r,i=e.length,a=o.relative[e[0].type],s=a||o.relative[" "],l=a?1:0,c=vt(function(e){return e===t},s,!0),p=vt(function(e){return F.call(t,e)>-1},s,!0),f=[function(e,n,r){return!a&&(r||n!==u)||((t=n).nodeType?c(e,n,r):p(e,n,r))}];for(;i>l;l++)if(n=o.relative[e[l].type])f=[vt(bt(f),n)];else{if(n=o.filter[e[l].type].apply(null,e[l].matches),n[b]){for(r=++l;i>r;r++)if(o.relative[e[r].type])break;return wt(l>1&&bt(f),l>1&&yt(e.slice(0,l-1).concat({value:" "===e[l-2].type?"*":""})).replace(z,"$1"),n,r>l&&Tt(e.slice(l,r)),i>r&&Tt(e=e.slice(r)),i>r&&yt(e))}f.push(n)}return bt(f)}function Ct(e,t){var n=0,r=t.length>0,a=e.length>0,s=function(s,l,c,p,d){var h,g,m,y=[],v=0,b="0",x=s&&[],w=null!=d,C=u,N=s||a&&o.find.TAG("*",d&&l.parentNode||l),k=T+=null==C?1:Math.random()||.1;for(w&&(u=l!==f&&l,i=n);null!=(h=N[b]);b++){if(a&&h){g=0;while(m=e[g++])if(m(h,l,c)){p.push(h);break}w&&(T=k,i=++n)}r&&((h=!m&&h)&&v--,s&&x.push(h))}if(v+=b,r&&b!==v){g=0;while(m=t[g++])m(x,y,l,c);if(s){if(v>0)while(b--)x[b]||y[b]||(y[b]=q.call(p));y=xt(y)}M.apply(p,y),w&&!s&&y.length>0&&v+t.length>1&&at.uniqueSort(p)}return w&&(T=k,u=C),x};return r?lt(s):s}l=at.compile=function(e,t){var n,r=[],i=[],o=E[e+" "];if(!o){t||(t=mt(e)),n=t.length;while(n--)o=Tt(t[n]),o[b]?r.push(o):i.push(o);o=E(e,Ct(i,r))}return o};function Nt(e,t,n){var r=0,i=t.length;for(;i>r;r++)at(e,t[r],n);return n}function kt(e,t,n,i){var a,s,u,c,p,f=mt(e);if(!i&&1===f.length){if(s=f[0]=f[0].slice(0),s.length>2&&"ID"===(u=s[0]).type&&r.getById&&9===t.nodeType&&h&&o.relative[s[1].type]){if(t=(o.find.ID(u.matches[0].replace(rt,it),t)||[])[0],!t)return n;e=e.slice(s.shift().value.length)}a=Q.needsContext.test(e)?0:s.length;while(a--){if(u=s[a],o.relative[c=u.type])break;if((p=o.find[c])&&(i=p(u.matches[0].replace(rt,it),V.test(s[0].type)&&t.parentNode||t))){if(s.splice(a,1),e=i.length&&yt(s),!e)return M.apply(n,i),n;break}}}return l(e,f)(i,t,!h,n,V.test(e)),n}r.sortStable=b.split("").sort(A).join("")===b,r.detectDuplicates=S,p(),r.sortDetached=ut(function(e){return 1&e.compareDocumentPosition(f.createElement("div"))}),ut(function(e){return e.innerHTML="<a href='#'></a>","#"===e.firstChild.getAttribute("href")})||ct("type|href|height|width",function(e,n,r){return r?t:e.getAttribute(n,"type"===n.toLowerCase()?1:2)}),r.attributes&&ut(function(e){return e.innerHTML="<input/>",e.firstChild.setAttribute("value",""),""===e.firstChild.getAttribute("value")})||ct("value",function(e,n,r){return r||"input"!==e.nodeName.toLowerCase()?t:e.defaultValue}),ut(function(e){return null==e.getAttribute("disabled")})||ct(B,function(e,n,r){var i;return r?t:(i=e.getAttributeNode(n))&&i.specified?i.value:e[n]===!0?n.toLowerCase():null}),x.find=at,x.expr=at.selectors,x.expr[":"]=x.expr.pseudos,x.unique=at.uniqueSort,x.text=at.getText,x.isXMLDoc=at.isXML,x.contains=at.contains}(e);var O={};function F(e){var t=O[e]={};return x.each(e.match(T)||[],function(e,n){t[n]=!0}),t}x.Callbacks=function(e){e="string"==typeof e?O[e]||F(e):x.extend({},e);var n,r,i,o,a,s,l=[],u=!e.once&&[],c=function(t){for(r=e.memory&&t,i=!0,a=s||0,s=0,o=l.length,n=!0;l&&o>a;a++)if(l[a].apply(t[0],t[1])===!1&&e.stopOnFalse){r=!1;break}n=!1,l&&(u?u.length&&c(u.shift()):r?l=[]:p.disable())},p={add:function(){if(l){var t=l.length;(function i(t){x.each(t,function(t,n){var r=x.type(n);"function"===r?e.unique&&p.has(n)||l.push(n):n&&n.length&&"string"!==r&&i(n)})})(arguments),n?o=l.length:r&&(s=t,c(r))}return this},remove:function(){return l&&x.each(arguments,function(e,t){var r;while((r=x.inArray(t,l,r))>-1)l.splice(r,1),n&&(o>=r&&o--,a>=r&&a--)}),this},has:function(e){return e?x.inArray(e,l)>-1:!(!l||!l.length)},empty:function(){return l=[],o=0,this},disable:function(){return l=u=r=t,this},disabled:function(){return!l},lock:function(){return u=t,r||p.disable(),this},locked:function(){return!u},fireWith:function(e,t){return!l||i&&!u||(t=t||[],t=[e,t.slice?t.slice():t],n?u.push(t):c(t)),this},fire:function(){return p.fireWith(this,arguments),this},fired:function(){return!!i}};return p},x.extend({Deferred:function(e){var t=[["resolve","done",x.Callbacks("once memory"),"resolved"],["reject","fail",x.Callbacks("once memory"),"rejected"],["notify","progress",x.Callbacks("memory")]],n="pending",r={state:function(){return n},always:function(){return i.done(arguments).fail(arguments),this},then:function(){var e=arguments;return x.Deferred(function(n){x.each(t,function(t,o){var a=o[0],s=x.isFunction(e[t])&&e[t];i[o[1]](function(){var e=s&&s.apply(this,arguments);e&&x.isFunction(e.promise)?e.promise().done(n.resolve).fail(n.reject).progress(n.notify):n[a+"With"](this===r?n.promise():this,s?[e]:arguments)})}),e=null}).promise()},promise:function(e){return null!=e?x.extend(e,r):r}},i={};return r.pipe=r.then,x.each(t,function(e,o){var a=o[2],s=o[3];r[o[1]]=a.add,s&&a.add(function(){n=s},t[1^e][2].disable,t[2][2].lock),i[o[0]]=function(){return i[o[0]+"With"](this===i?r:this,arguments),this},i[o[0]+"With"]=a.fireWith}),r.promise(i),e&&e.call(i,i),i},when:function(e){var t=0,n=g.call(arguments),r=n.length,i=1!==r||e&&x.isFunction(e.promise)?r:0,o=1===i?e:x.Deferred(),a=function(e,t,n){return function(r){t[e]=this,n[e]=arguments.length>1?g.call(arguments):r,n===s?o.notifyWith(t,n):--i||o.resolveWith(t,n)}},s,l,u;if(r>1)for(s=Array(r),l=Array(r),u=Array(r);r>t;t++)n[t]&&x.isFunction(n[t].promise)?n[t].promise().done(a(t,u,n)).fail(o.reject).progress(a(t,l,s)):--i;return i||o.resolveWith(u,n),o.promise()}}),x.support=function(t){var n,r,o,s,l,u,c,p,f,d=a.createElement("div");if(d.setAttribute("className","t"),d.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",n=d.getElementsByTagName("*")||[],r=d.getElementsByTagName("a")[0],!r||!r.style||!n.length)return t;s=a.createElement("select"),u=s.appendChild(a.createElement("option")),o=d.getElementsByTagName("input")[0],r.style.cssText="top:1px;float:left;opacity:.5",t.getSetAttribute="t"!==d.className,t.leadingWhitespace=3===d.firstChild.nodeType,t.tbody=!d.getElementsByTagName("tbody").length,t.htmlSerialize=!!d.getElementsByTagName("link").length,t.style=/top/.test(r.getAttribute("style")),t.hrefNormalized="/a"===r.getAttribute("href"),t.opacity=/^0.5/.test(r.style.opacity),t.cssFloat=!!r.style.cssFloat,t.checkOn=!!o.value,t.optSelected=u.selected,t.enctype=!!a.createElement("form").enctype,t.html5Clone="<:nav></:nav>"!==a.createElement("nav").cloneNode(!0).outerHTML,t.inlineBlockNeedsLayout=!1,t.shrinkWrapBlocks=!1,t.pixelPosition=!1,t.deleteExpando=!0,t.noCloneEvent=!0,t.reliableMarginRight=!0,t.boxSizingReliable=!0,o.checked=!0,t.noCloneChecked=o.cloneNode(!0).checked,s.disabled=!0,t.optDisabled=!u.disabled;try{delete d.test}catch(h){t.deleteExpando=!1}o=a.createElement("input"),o.setAttribute("value",""),t.input=""===o.getAttribute("value"),o.value="t",o.setAttribute("type","radio"),t.radioValue="t"===o.value,o.setAttribute("checked","t"),o.setAttribute("name","t"),l=a.createDocumentFragment(),l.appendChild(o),t.appendChecked=o.checked,t.checkClone=l.cloneNode(!0).cloneNode(!0).lastChild.checked,d.attachEvent&&(d.attachEvent("onclick",function(){t.noCloneEvent=!1}),d.cloneNode(!0).click());for(f in{submit:!0,change:!0,focusin:!0})d.setAttribute(c="on"+f,"t"),t[f+"Bubbles"]=c in e||d.attributes[c].expando===!1;d.style.backgroundClip="content-box",d.cloneNode(!0).style.backgroundClip="",t.clearCloneStyle="content-box"===d.style.backgroundClip;for(f in x(t))break;return t.ownLast="0"!==f,x(function(){var n,r,o,s="padding:0;margin:0;border:0;display:block;box-sizing:content-box;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;",l=a.getElementsByTagName("body")[0];l&&(n=a.createElement("div"),n.style.cssText="border:0;width:0;height:0;position:absolute;top:0;left:-9999px;margin-top:1px",l.appendChild(n).appendChild(d),d.innerHTML="<table><tr><td></td><td>t</td></tr></table>",o=d.getElementsByTagName("td"),o[0].style.cssText="padding:0;margin:0;border:0;display:none",p=0===o[0].offsetHeight,o[0].style.display="",o[1].style.display="none",t.reliableHiddenOffsets=p&&0===o[0].offsetHeight,d.innerHTML="",d.style.cssText="box-sizing:border-box;-moz-box-sizing:border-box;-webkit-box-sizing:border-box;padding:1px;border:1px;display:block;width:4px;margin-top:1%;position:absolute;top:1%;",x.swap(l,null!=l.style.zoom?{zoom:1}:{},function(){t.boxSizing=4===d.offsetWidth}),e.getComputedStyle&&(t.pixelPosition="1%"!==(e.getComputedStyle(d,null)||{}).top,t.boxSizingReliable="4px"===(e.getComputedStyle(d,null)||{width:"4px"}).width,r=d.appendChild(a.createElement("div")),r.style.cssText=d.style.cssText=s,r.style.marginRight=r.style.width="0",d.style.width="1px",t.reliableMarginRight=!parseFloat((e.getComputedStyle(r,null)||{}).marginRight)),typeof d.style.zoom!==i&&(d.innerHTML="",d.style.cssText=s+"width:1px;padding:1px;display:inline;zoom:1",t.inlineBlockNeedsLayout=3===d.offsetWidth,d.style.display="block",d.innerHTML="<div></div>",d.firstChild.style.width="5px",t.shrinkWrapBlocks=3!==d.offsetWidth,t.inlineBlockNeedsLayout&&(l.style.zoom=1)),l.removeChild(n),n=d=o=r=null)}),n=s=l=u=r=o=null,t
}({});var B=/(?:\{[\s\S]*\}|\[[\s\S]*\])$/,P=/([A-Z])/g;function R(e,n,r,i){if(x.acceptData(e)){var o,a,s=x.expando,l=e.nodeType,u=l?x.cache:e,c=l?e[s]:e[s]&&s;if(c&&u[c]&&(i||u[c].data)||r!==t||"string"!=typeof n)return c||(c=l?e[s]=p.pop()||x.guid++:s),u[c]||(u[c]=l?{}:{toJSON:x.noop}),("object"==typeof n||"function"==typeof n)&&(i?u[c]=x.extend(u[c],n):u[c].data=x.extend(u[c].data,n)),a=u[c],i||(a.data||(a.data={}),a=a.data),r!==t&&(a[x.camelCase(n)]=r),"string"==typeof n?(o=a[n],null==o&&(o=a[x.camelCase(n)])):o=a,o}}function W(e,t,n){if(x.acceptData(e)){var r,i,o=e.nodeType,a=o?x.cache:e,s=o?e[x.expando]:x.expando;if(a[s]){if(t&&(r=n?a[s]:a[s].data)){x.isArray(t)?t=t.concat(x.map(t,x.camelCase)):t in r?t=[t]:(t=x.camelCase(t),t=t in r?[t]:t.split(" ")),i=t.length;while(i--)delete r[t[i]];if(n?!I(r):!x.isEmptyObject(r))return}(n||(delete a[s].data,I(a[s])))&&(o?x.cleanData([e],!0):x.support.deleteExpando||a!=a.window?delete a[s]:a[s]=null)}}}x.extend({cache:{},noData:{applet:!0,embed:!0,object:"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"},hasData:function(e){return e=e.nodeType?x.cache[e[x.expando]]:e[x.expando],!!e&&!I(e)},data:function(e,t,n){return R(e,t,n)},removeData:function(e,t){return W(e,t)},_data:function(e,t,n){return R(e,t,n,!0)},_removeData:function(e,t){return W(e,t,!0)},acceptData:function(e){if(e.nodeType&&1!==e.nodeType&&9!==e.nodeType)return!1;var t=e.nodeName&&x.noData[e.nodeName.toLowerCase()];return!t||t!==!0&&e.getAttribute("classid")===t}}),x.fn.extend({data:function(e,n){var r,i,o=null,a=0,s=this[0];if(e===t){if(this.length&&(o=x.data(s),1===s.nodeType&&!x._data(s,"parsedAttrs"))){for(r=s.attributes;r.length>a;a++)i=r[a].name,0===i.indexOf("data-")&&(i=x.camelCase(i.slice(5)),$(s,i,o[i]));x._data(s,"parsedAttrs",!0)}return o}return"object"==typeof e?this.each(function(){x.data(this,e)}):arguments.length>1?this.each(function(){x.data(this,e,n)}):s?$(s,e,x.data(s,e)):null},removeData:function(e){return this.each(function(){x.removeData(this,e)})}});function $(e,n,r){if(r===t&&1===e.nodeType){var i="data-"+n.replace(P,"-$1").toLowerCase();if(r=e.getAttribute(i),"string"==typeof r){try{r="true"===r?!0:"false"===r?!1:"null"===r?null:+r+""===r?+r:B.test(r)?x.parseJSON(r):r}catch(o){}x.data(e,n,r)}else r=t}return r}function I(e){var t;for(t in e)if(("data"!==t||!x.isEmptyObject(e[t]))&&"toJSON"!==t)return!1;return!0}x.extend({queue:function(e,n,r){var i;return e?(n=(n||"fx")+"queue",i=x._data(e,n),r&&(!i||x.isArray(r)?i=x._data(e,n,x.makeArray(r)):i.push(r)),i||[]):t},dequeue:function(e,t){t=t||"fx";var n=x.queue(e,t),r=n.length,i=n.shift(),o=x._queueHooks(e,t),a=function(){x.dequeue(e,t)};"inprogress"===i&&(i=n.shift(),r--),i&&("fx"===t&&n.unshift("inprogress"),delete o.stop,i.call(e,a,o)),!r&&o&&o.empty.fire()},_queueHooks:function(e,t){var n=t+"queueHooks";return x._data(e,n)||x._data(e,n,{empty:x.Callbacks("once memory").add(function(){x._removeData(e,t+"queue"),x._removeData(e,n)})})}}),x.fn.extend({queue:function(e,n){var r=2;return"string"!=typeof e&&(n=e,e="fx",r--),r>arguments.length?x.queue(this[0],e):n===t?this:this.each(function(){var t=x.queue(this,e,n);x._queueHooks(this,e),"fx"===e&&"inprogress"!==t[0]&&x.dequeue(this,e)})},dequeue:function(e){return this.each(function(){x.dequeue(this,e)})},delay:function(e,t){return e=x.fx?x.fx.speeds[e]||e:e,t=t||"fx",this.queue(t,function(t,n){var r=setTimeout(t,e);n.stop=function(){clearTimeout(r)}})},clearQueue:function(e){return this.queue(e||"fx",[])},promise:function(e,n){var r,i=1,o=x.Deferred(),a=this,s=this.length,l=function(){--i||o.resolveWith(a,[a])};"string"!=typeof e&&(n=e,e=t),e=e||"fx";while(s--)r=x._data(a[s],e+"queueHooks"),r&&r.empty&&(i++,r.empty.add(l));return l(),o.promise(n)}});var z,X,U=/[\t\r\n\f]/g,V=/\r/g,Y=/^(?:input|select|textarea|button|object)$/i,J=/^(?:a|area)$/i,G=/^(?:checked|selected)$/i,Q=x.support.getSetAttribute,K=x.support.input;x.fn.extend({attr:function(e,t){return x.access(this,x.attr,e,t,arguments.length>1)},removeAttr:function(e){return this.each(function(){x.removeAttr(this,e)})},prop:function(e,t){return x.access(this,x.prop,e,t,arguments.length>1)},removeProp:function(e){return e=x.propFix[e]||e,this.each(function(){try{this[e]=t,delete this[e]}catch(n){}})},addClass:function(e){var t,n,r,i,o,a=0,s=this.length,l="string"==typeof e&&e;if(x.isFunction(e))return this.each(function(t){x(this).addClass(e.call(this,t,this.className))});if(l)for(t=(e||"").match(T)||[];s>a;a++)if(n=this[a],r=1===n.nodeType&&(n.className?(" "+n.className+" ").replace(U," "):" ")){o=0;while(i=t[o++])0>r.indexOf(" "+i+" ")&&(r+=i+" ");n.className=x.trim(r)}return this},removeClass:function(e){var t,n,r,i,o,a=0,s=this.length,l=0===arguments.length||"string"==typeof e&&e;if(x.isFunction(e))return this.each(function(t){x(this).removeClass(e.call(this,t,this.className))});if(l)for(t=(e||"").match(T)||[];s>a;a++)if(n=this[a],r=1===n.nodeType&&(n.className?(" "+n.className+" ").replace(U," "):"")){o=0;while(i=t[o++])while(r.indexOf(" "+i+" ")>=0)r=r.replace(" "+i+" "," ");n.className=e?x.trim(r):""}return this},toggleClass:function(e,t){var n=typeof e;return"boolean"==typeof t&&"string"===n?t?this.addClass(e):this.removeClass(e):x.isFunction(e)?this.each(function(n){x(this).toggleClass(e.call(this,n,this.className,t),t)}):this.each(function(){if("string"===n){var t,r=0,o=x(this),a=e.match(T)||[];while(t=a[r++])o.hasClass(t)?o.removeClass(t):o.addClass(t)}else(n===i||"boolean"===n)&&(this.className&&x._data(this,"__className__",this.className),this.className=this.className||e===!1?"":x._data(this,"__className__")||"")})},hasClass:function(e){var t=" "+e+" ",n=0,r=this.length;for(;r>n;n++)if(1===this[n].nodeType&&(" "+this[n].className+" ").replace(U," ").indexOf(t)>=0)return!0;return!1},val:function(e){var n,r,i,o=this[0];{if(arguments.length)return i=x.isFunction(e),this.each(function(n){var o;1===this.nodeType&&(o=i?e.call(this,n,x(this).val()):e,null==o?o="":"number"==typeof o?o+="":x.isArray(o)&&(o=x.map(o,function(e){return null==e?"":e+""})),r=x.valHooks[this.type]||x.valHooks[this.nodeName.toLowerCase()],r&&"set"in r&&r.set(this,o,"value")!==t||(this.value=o))});if(o)return r=x.valHooks[o.type]||x.valHooks[o.nodeName.toLowerCase()],r&&"get"in r&&(n=r.get(o,"value"))!==t?n:(n=o.value,"string"==typeof n?n.replace(V,""):null==n?"":n)}}}),x.extend({valHooks:{option:{get:function(e){var t=x.find.attr(e,"value");return null!=t?t:e.text}},select:{get:function(e){var t,n,r=e.options,i=e.selectedIndex,o="select-one"===e.type||0>i,a=o?null:[],s=o?i+1:r.length,l=0>i?s:o?i:0;for(;s>l;l++)if(n=r[l],!(!n.selected&&l!==i||(x.support.optDisabled?n.disabled:null!==n.getAttribute("disabled"))||n.parentNode.disabled&&x.nodeName(n.parentNode,"optgroup"))){if(t=x(n).val(),o)return t;a.push(t)}return a},set:function(e,t){var n,r,i=e.options,o=x.makeArray(t),a=i.length;while(a--)r=i[a],(r.selected=x.inArray(x(r).val(),o)>=0)&&(n=!0);return n||(e.selectedIndex=-1),o}}},attr:function(e,n,r){var o,a,s=e.nodeType;if(e&&3!==s&&8!==s&&2!==s)return typeof e.getAttribute===i?x.prop(e,n,r):(1===s&&x.isXMLDoc(e)||(n=n.toLowerCase(),o=x.attrHooks[n]||(x.expr.match.bool.test(n)?X:z)),r===t?o&&"get"in o&&null!==(a=o.get(e,n))?a:(a=x.find.attr(e,n),null==a?t:a):null!==r?o&&"set"in o&&(a=o.set(e,r,n))!==t?a:(e.setAttribute(n,r+""),r):(x.removeAttr(e,n),t))},removeAttr:function(e,t){var n,r,i=0,o=t&&t.match(T);if(o&&1===e.nodeType)while(n=o[i++])r=x.propFix[n]||n,x.expr.match.bool.test(n)?K&&Q||!G.test(n)?e[r]=!1:e[x.camelCase("default-"+n)]=e[r]=!1:x.attr(e,n,""),e.removeAttribute(Q?n:r)},attrHooks:{type:{set:function(e,t){if(!x.support.radioValue&&"radio"===t&&x.nodeName(e,"input")){var n=e.value;return e.setAttribute("type",t),n&&(e.value=n),t}}}},propFix:{"for":"htmlFor","class":"className"},prop:function(e,n,r){var i,o,a,s=e.nodeType;if(e&&3!==s&&8!==s&&2!==s)return a=1!==s||!x.isXMLDoc(e),a&&(n=x.propFix[n]||n,o=x.propHooks[n]),r!==t?o&&"set"in o&&(i=o.set(e,r,n))!==t?i:e[n]=r:o&&"get"in o&&null!==(i=o.get(e,n))?i:e[n]},propHooks:{tabIndex:{get:function(e){var t=x.find.attr(e,"tabindex");return t?parseInt(t,10):Y.test(e.nodeName)||J.test(e.nodeName)&&e.href?0:-1}}}}),X={set:function(e,t,n){return t===!1?x.removeAttr(e,n):K&&Q||!G.test(n)?e.setAttribute(!Q&&x.propFix[n]||n,n):e[x.camelCase("default-"+n)]=e[n]=!0,n}},x.each(x.expr.match.bool.source.match(/\w+/g),function(e,n){var r=x.expr.attrHandle[n]||x.find.attr;x.expr.attrHandle[n]=K&&Q||!G.test(n)?function(e,n,i){var o=x.expr.attrHandle[n],a=i?t:(x.expr.attrHandle[n]=t)!=r(e,n,i)?n.toLowerCase():null;return x.expr.attrHandle[n]=o,a}:function(e,n,r){return r?t:e[x.camelCase("default-"+n)]?n.toLowerCase():null}}),K&&Q||(x.attrHooks.value={set:function(e,n,r){return x.nodeName(e,"input")?(e.defaultValue=n,t):z&&z.set(e,n,r)}}),Q||(z={set:function(e,n,r){var i=e.getAttributeNode(r);return i||e.setAttributeNode(i=e.ownerDocument.createAttribute(r)),i.value=n+="","value"===r||n===e.getAttribute(r)?n:t}},x.expr.attrHandle.id=x.expr.attrHandle.name=x.expr.attrHandle.coords=function(e,n,r){var i;return r?t:(i=e.getAttributeNode(n))&&""!==i.value?i.value:null},x.valHooks.button={get:function(e,n){var r=e.getAttributeNode(n);return r&&r.specified?r.value:t},set:z.set},x.attrHooks.contenteditable={set:function(e,t,n){z.set(e,""===t?!1:t,n)}},x.each(["width","height"],function(e,n){x.attrHooks[n]={set:function(e,r){return""===r?(e.setAttribute(n,"auto"),r):t}}})),x.support.hrefNormalized||x.each(["href","src"],function(e,t){x.propHooks[t]={get:function(e){return e.getAttribute(t,4)}}}),x.support.style||(x.attrHooks.style={get:function(e){return e.style.cssText||t},set:function(e,t){return e.style.cssText=t+""}}),x.support.optSelected||(x.propHooks.selected={get:function(e){var t=e.parentNode;return t&&(t.selectedIndex,t.parentNode&&t.parentNode.selectedIndex),null}}),x.each(["tabIndex","readOnly","maxLength","cellSpacing","cellPadding","rowSpan","colSpan","useMap","frameBorder","contentEditable"],function(){x.propFix[this.toLowerCase()]=this}),x.support.enctype||(x.propFix.enctype="encoding"),x.each(["radio","checkbox"],function(){x.valHooks[this]={set:function(e,n){return x.isArray(n)?e.checked=x.inArray(x(e).val(),n)>=0:t}},x.support.checkOn||(x.valHooks[this].get=function(e){return null===e.getAttribute("value")?"on":e.value})});var Z=/^(?:input|select|textarea)$/i,et=/^key/,tt=/^(?:mouse|contextmenu)|click/,nt=/^(?:focusinfocus|focusoutblur)$/,rt=/^([^.]*)(?:\.(.+)|)$/;function it(){return!0}function ot(){return!1}function at(){try{return a.activeElement}catch(e){}}x.event={global:{},add:function(e,n,r,o,a){var s,l,u,c,p,f,d,h,g,m,y,v=x._data(e);if(v){r.handler&&(c=r,r=c.handler,a=c.selector),r.guid||(r.guid=x.guid++),(l=v.events)||(l=v.events={}),(f=v.handle)||(f=v.handle=function(e){return typeof x===i||e&&x.event.triggered===e.type?t:x.event.dispatch.apply(f.elem,arguments)},f.elem=e),n=(n||"").match(T)||[""],u=n.length;while(u--)s=rt.exec(n[u])||[],g=y=s[1],m=(s[2]||"").split(".").sort(),g&&(p=x.event.special[g]||{},g=(a?p.delegateType:p.bindType)||g,p=x.event.special[g]||{},d=x.extend({type:g,origType:y,data:o,handler:r,guid:r.guid,selector:a,needsContext:a&&x.expr.match.needsContext.test(a),namespace:m.join(".")},c),(h=l[g])||(h=l[g]=[],h.delegateCount=0,p.setup&&p.setup.call(e,o,m,f)!==!1||(e.addEventListener?e.addEventListener(g,f,!1):e.attachEvent&&e.attachEvent("on"+g,f))),p.add&&(p.add.call(e,d),d.handler.guid||(d.handler.guid=r.guid)),a?h.splice(h.delegateCount++,0,d):h.push(d),x.event.global[g]=!0);e=null}},remove:function(e,t,n,r,i){var o,a,s,l,u,c,p,f,d,h,g,m=x.hasData(e)&&x._data(e);if(m&&(c=m.events)){t=(t||"").match(T)||[""],u=t.length;while(u--)if(s=rt.exec(t[u])||[],d=g=s[1],h=(s[2]||"").split(".").sort(),d){p=x.event.special[d]||{},d=(r?p.delegateType:p.bindType)||d,f=c[d]||[],s=s[2]&&RegExp("(^|\\.)"+h.join("\\.(?:.*\\.|)")+"(\\.|$)"),l=o=f.length;while(o--)a=f[o],!i&&g!==a.origType||n&&n.guid!==a.guid||s&&!s.test(a.namespace)||r&&r!==a.selector&&("**"!==r||!a.selector)||(f.splice(o,1),a.selector&&f.delegateCount--,p.remove&&p.remove.call(e,a));l&&!f.length&&(p.teardown&&p.teardown.call(e,h,m.handle)!==!1||x.removeEvent(e,d,m.handle),delete c[d])}else for(d in c)x.event.remove(e,d+t[u],n,r,!0);x.isEmptyObject(c)&&(delete m.handle,x._removeData(e,"events"))}},trigger:function(n,r,i,o){var s,l,u,c,p,f,d,h=[i||a],g=v.call(n,"type")?n.type:n,m=v.call(n,"namespace")?n.namespace.split("."):[];if(u=f=i=i||a,3!==i.nodeType&&8!==i.nodeType&&!nt.test(g+x.event.triggered)&&(g.indexOf(".")>=0&&(m=g.split("."),g=m.shift(),m.sort()),l=0>g.indexOf(":")&&"on"+g,n=n[x.expando]?n:new x.Event(g,"object"==typeof n&&n),n.isTrigger=o?2:3,n.namespace=m.join("."),n.namespace_re=n.namespace?RegExp("(^|\\.)"+m.join("\\.(?:.*\\.|)")+"(\\.|$)"):null,n.result=t,n.target||(n.target=i),r=null==r?[n]:x.makeArray(r,[n]),p=x.event.special[g]||{},o||!p.trigger||p.trigger.apply(i,r)!==!1)){if(!o&&!p.noBubble&&!x.isWindow(i)){for(c=p.delegateType||g,nt.test(c+g)||(u=u.parentNode);u;u=u.parentNode)h.push(u),f=u;f===(i.ownerDocument||a)&&h.push(f.defaultView||f.parentWindow||e)}d=0;while((u=h[d++])&&!n.isPropagationStopped())n.type=d>1?c:p.bindType||g,s=(x._data(u,"events")||{})[n.type]&&x._data(u,"handle"),s&&s.apply(u,r),s=l&&u[l],s&&x.acceptData(u)&&s.apply&&s.apply(u,r)===!1&&n.preventDefault();if(n.type=g,!o&&!n.isDefaultPrevented()&&(!p._default||p._default.apply(h.pop(),r)===!1)&&x.acceptData(i)&&l&&i[g]&&!x.isWindow(i)){f=i[l],f&&(i[l]=null),x.event.triggered=g;try{i[g]()}catch(y){}x.event.triggered=t,f&&(i[l]=f)}return n.result}},dispatch:function(e){e=x.event.fix(e);var n,r,i,o,a,s=[],l=g.call(arguments),u=(x._data(this,"events")||{})[e.type]||[],c=x.event.special[e.type]||{};if(l[0]=e,e.delegateTarget=this,!c.preDispatch||c.preDispatch.call(this,e)!==!1){s=x.event.handlers.call(this,e,u),n=0;while((o=s[n++])&&!e.isPropagationStopped()){e.currentTarget=o.elem,a=0;while((i=o.handlers[a++])&&!e.isImmediatePropagationStopped())(!e.namespace_re||e.namespace_re.test(i.namespace))&&(e.handleObj=i,e.data=i.data,r=((x.event.special[i.origType]||{}).handle||i.handler).apply(o.elem,l),r!==t&&(e.result=r)===!1&&(e.preventDefault(),e.stopPropagation()))}return c.postDispatch&&c.postDispatch.call(this,e),e.result}},handlers:function(e,n){var r,i,o,a,s=[],l=n.delegateCount,u=e.target;if(l&&u.nodeType&&(!e.button||"click"!==e.type))for(;u!=this;u=u.parentNode||this)if(1===u.nodeType&&(u.disabled!==!0||"click"!==e.type)){for(o=[],a=0;l>a;a++)i=n[a],r=i.selector+" ",o[r]===t&&(o[r]=i.needsContext?x(r,this).index(u)>=0:x.find(r,this,null,[u]).length),o[r]&&o.push(i);o.length&&s.push({elem:u,handlers:o})}return n.length>l&&s.push({elem:this,handlers:n.slice(l)}),s},fix:function(e){if(e[x.expando])return e;var t,n,r,i=e.type,o=e,s=this.fixHooks[i];s||(this.fixHooks[i]=s=tt.test(i)?this.mouseHooks:et.test(i)?this.keyHooks:{}),r=s.props?this.props.concat(s.props):this.props,e=new x.Event(o),t=r.length;while(t--)n=r[t],e[n]=o[n];return e.target||(e.target=o.srcElement||a),3===e.target.nodeType&&(e.target=e.target.parentNode),e.metaKey=!!e.metaKey,s.filter?s.filter(e,o):e},props:"altKey bubbles cancelable ctrlKey currentTarget eventPhase metaKey relatedTarget shiftKey target timeStamp view which".split(" "),fixHooks:{},keyHooks:{props:"char charCode key keyCode".split(" "),filter:function(e,t){return null==e.which&&(e.which=null!=t.charCode?t.charCode:t.keyCode),e}},mouseHooks:{props:"button buttons clientX clientY fromElement offsetX offsetY pageX pageY screenX screenY toElement".split(" "),filter:function(e,n){var r,i,o,s=n.button,l=n.fromElement;return null==e.pageX&&null!=n.clientX&&(i=e.target.ownerDocument||a,o=i.documentElement,r=i.body,e.pageX=n.clientX+(o&&o.scrollLeft||r&&r.scrollLeft||0)-(o&&o.clientLeft||r&&r.clientLeft||0),e.pageY=n.clientY+(o&&o.scrollTop||r&&r.scrollTop||0)-(o&&o.clientTop||r&&r.clientTop||0)),!e.relatedTarget&&l&&(e.relatedTarget=l===e.target?n.toElement:l),e.which||s===t||(e.which=1&s?1:2&s?3:4&s?2:0),e}},special:{load:{noBubble:!0},focus:{trigger:function(){if(this!==at()&&this.focus)try{return this.focus(),!1}catch(e){}},delegateType:"focusin"},blur:{trigger:function(){return this===at()&&this.blur?(this.blur(),!1):t},delegateType:"focusout"},click:{trigger:function(){return x.nodeName(this,"input")&&"checkbox"===this.type&&this.click?(this.click(),!1):t},_default:function(e){return x.nodeName(e.target,"a")}},beforeunload:{postDispatch:function(e){e.result!==t&&(e.originalEvent.returnValue=e.result)}}},simulate:function(e,t,n,r){var i=x.extend(new x.Event,n,{type:e,isSimulated:!0,originalEvent:{}});r?x.event.trigger(i,null,t):x.event.dispatch.call(t,i),i.isDefaultPrevented()&&n.preventDefault()}},x.removeEvent=a.removeEventListener?function(e,t,n){e.removeEventListener&&e.removeEventListener(t,n,!1)}:function(e,t,n){var r="on"+t;e.detachEvent&&(typeof e[r]===i&&(e[r]=null),e.detachEvent(r,n))},x.Event=function(e,n){return this instanceof x.Event?(e&&e.type?(this.originalEvent=e,this.type=e.type,this.isDefaultPrevented=e.defaultPrevented||e.returnValue===!1||e.getPreventDefault&&e.getPreventDefault()?it:ot):this.type=e,n&&x.extend(this,n),this.timeStamp=e&&e.timeStamp||x.now(),this[x.expando]=!0,t):new x.Event(e,n)},x.Event.prototype={isDefaultPrevented:ot,isPropagationStopped:ot,isImmediatePropagationStopped:ot,preventDefault:function(){var e=this.originalEvent;this.isDefaultPrevented=it,e&&(e.preventDefault?e.preventDefault():e.returnValue=!1)},stopPropagation:function(){var e=this.originalEvent;this.isPropagationStopped=it,e&&(e.stopPropagation&&e.stopPropagation(),e.cancelBubble=!0)},stopImmediatePropagation:function(){this.isImmediatePropagationStopped=it,this.stopPropagation()}},x.each({mouseenter:"mouseover",mouseleave:"mouseout"},function(e,t){x.event.special[e]={delegateType:t,bindType:t,handle:function(e){var n,r=this,i=e.relatedTarget,o=e.handleObj;return(!i||i!==r&&!x.contains(r,i))&&(e.type=o.origType,n=o.handler.apply(this,arguments),e.type=t),n}}}),x.support.submitBubbles||(x.event.special.submit={setup:function(){return x.nodeName(this,"form")?!1:(x.event.add(this,"click._submit keypress._submit",function(e){var n=e.target,r=x.nodeName(n,"input")||x.nodeName(n,"button")?n.form:t;r&&!x._data(r,"submitBubbles")&&(x.event.add(r,"submit._submit",function(e){e._submit_bubble=!0}),x._data(r,"submitBubbles",!0))}),t)},postDispatch:function(e){e._submit_bubble&&(delete e._submit_bubble,this.parentNode&&!e.isTrigger&&x.event.simulate("submit",this.parentNode,e,!0))},teardown:function(){return x.nodeName(this,"form")?!1:(x.event.remove(this,"._submit"),t)}}),x.support.changeBubbles||(x.event.special.change={setup:function(){return Z.test(this.nodeName)?(("checkbox"===this.type||"radio"===this.type)&&(x.event.add(this,"propertychange._change",function(e){"checked"===e.originalEvent.propertyName&&(this._just_changed=!0)}),x.event.add(this,"click._change",function(e){this._just_changed&&!e.isTrigger&&(this._just_changed=!1),x.event.simulate("change",this,e,!0)})),!1):(x.event.add(this,"beforeactivate._change",function(e){var t=e.target;Z.test(t.nodeName)&&!x._data(t,"changeBubbles")&&(x.event.add(t,"change._change",function(e){!this.parentNode||e.isSimulated||e.isTrigger||x.event.simulate("change",this.parentNode,e,!0)}),x._data(t,"changeBubbles",!0))}),t)},handle:function(e){var n=e.target;return this!==n||e.isSimulated||e.isTrigger||"radio"!==n.type&&"checkbox"!==n.type?e.handleObj.handler.apply(this,arguments):t},teardown:function(){return x.event.remove(this,"._change"),!Z.test(this.nodeName)}}),x.support.focusinBubbles||x.each({focus:"focusin",blur:"focusout"},function(e,t){var n=0,r=function(e){x.event.simulate(t,e.target,x.event.fix(e),!0)};x.event.special[t]={setup:function(){0===n++&&a.addEventListener(e,r,!0)},teardown:function(){0===--n&&a.removeEventListener(e,r,!0)}}}),x.fn.extend({on:function(e,n,r,i,o){var a,s;if("object"==typeof e){"string"!=typeof n&&(r=r||n,n=t);for(a in e)this.on(a,n,r,e[a],o);return this}if(null==r&&null==i?(i=n,r=n=t):null==i&&("string"==typeof n?(i=r,r=t):(i=r,r=n,n=t)),i===!1)i=ot;else if(!i)return this;return 1===o&&(s=i,i=function(e){return x().off(e),s.apply(this,arguments)},i.guid=s.guid||(s.guid=x.guid++)),this.each(function(){x.event.add(this,e,i,r,n)})},one:function(e,t,n,r){return this.on(e,t,n,r,1)},off:function(e,n,r){var i,o;if(e&&e.preventDefault&&e.handleObj)return i=e.handleObj,x(e.delegateTarget).off(i.namespace?i.origType+"."+i.namespace:i.origType,i.selector,i.handler),this;if("object"==typeof e){for(o in e)this.off(o,n,e[o]);return this}return(n===!1||"function"==typeof n)&&(r=n,n=t),r===!1&&(r=ot),this.each(function(){x.event.remove(this,e,r,n)})},trigger:function(e,t){return this.each(function(){x.event.trigger(e,t,this)})},triggerHandler:function(e,n){var r=this[0];return r?x.event.trigger(e,n,r,!0):t}});var st=/^.[^:#\[\.,]*$/,lt=/^(?:parents|prev(?:Until|All))/,ut=x.expr.match.needsContext,ct={children:!0,contents:!0,next:!0,prev:!0};x.fn.extend({find:function(e){var t,n=[],r=this,i=r.length;if("string"!=typeof e)return this.pushStack(x(e).filter(function(){for(t=0;i>t;t++)if(x.contains(r[t],this))return!0}));for(t=0;i>t;t++)x.find(e,r[t],n);return n=this.pushStack(i>1?x.unique(n):n),n.selector=this.selector?this.selector+" "+e:e,n},has:function(e){var t,n=x(e,this),r=n.length;return this.filter(function(){for(t=0;r>t;t++)if(x.contains(this,n[t]))return!0})},not:function(e){return this.pushStack(ft(this,e||[],!0))},filter:function(e){return this.pushStack(ft(this,e||[],!1))},is:function(e){return!!ft(this,"string"==typeof e&&ut.test(e)?x(e):e||[],!1).length},closest:function(e,t){var n,r=0,i=this.length,o=[],a=ut.test(e)||"string"!=typeof e?x(e,t||this.context):0;for(;i>r;r++)for(n=this[r];n&&n!==t;n=n.parentNode)if(11>n.nodeType&&(a?a.index(n)>-1:1===n.nodeType&&x.find.matchesSelector(n,e))){n=o.push(n);break}return this.pushStack(o.length>1?x.unique(o):o)},index:function(e){return e?"string"==typeof e?x.inArray(this[0],x(e)):x.inArray(e.jquery?e[0]:e,this):this[0]&&this[0].parentNode?this.first().prevAll().length:-1},add:function(e,t){var n="string"==typeof e?x(e,t):x.makeArray(e&&e.nodeType?[e]:e),r=x.merge(this.get(),n);return this.pushStack(x.unique(r))},addBack:function(e){return this.add(null==e?this.prevObject:this.prevObject.filter(e))}});function pt(e,t){do e=e[t];while(e&&1!==e.nodeType);return e}x.each({parent:function(e){var t=e.parentNode;return t&&11!==t.nodeType?t:null},parents:function(e){return x.dir(e,"parentNode")},parentsUntil:function(e,t,n){return x.dir(e,"parentNode",n)},next:function(e){return pt(e,"nextSibling")},prev:function(e){return pt(e,"previousSibling")},nextAll:function(e){return x.dir(e,"nextSibling")},prevAll:function(e){return x.dir(e,"previousSibling")},nextUntil:function(e,t,n){return x.dir(e,"nextSibling",n)},prevUntil:function(e,t,n){return x.dir(e,"previousSibling",n)},siblings:function(e){return x.sibling((e.parentNode||{}).firstChild,e)},children:function(e){return x.sibling(e.firstChild)},contents:function(e){return x.nodeName(e,"iframe")?e.contentDocument||e.contentWindow.document:x.merge([],e.childNodes)}},function(e,t){x.fn[e]=function(n,r){var i=x.map(this,t,n);return"Until"!==e.slice(-5)&&(r=n),r&&"string"==typeof r&&(i=x.filter(r,i)),this.length>1&&(ct[e]||(i=x.unique(i)),lt.test(e)&&(i=i.reverse())),this.pushStack(i)}}),x.extend({filter:function(e,t,n){var r=t[0];return n&&(e=":not("+e+")"),1===t.length&&1===r.nodeType?x.find.matchesSelector(r,e)?[r]:[]:x.find.matches(e,x.grep(t,function(e){return 1===e.nodeType}))},dir:function(e,n,r){var i=[],o=e[n];while(o&&9!==o.nodeType&&(r===t||1!==o.nodeType||!x(o).is(r)))1===o.nodeType&&i.push(o),o=o[n];return i},sibling:function(e,t){var n=[];for(;e;e=e.nextSibling)1===e.nodeType&&e!==t&&n.push(e);return n}});function ft(e,t,n){if(x.isFunction(t))return x.grep(e,function(e,r){return!!t.call(e,r,e)!==n});if(t.nodeType)return x.grep(e,function(e){return e===t!==n});if("string"==typeof t){if(st.test(t))return x.filter(t,e,n);t=x.filter(t,e)}return x.grep(e,function(e){return x.inArray(e,t)>=0!==n})}function dt(e){var t=ht.split("|"),n=e.createDocumentFragment();if(n.createElement)while(t.length)n.createElement(t.pop());return n}var ht="abbr|article|aside|audio|bdi|canvas|data|datalist|details|figcaption|figure|footer|header|hgroup|mark|meter|nav|output|progress|section|summary|time|video",gt=/ jQuery\d+="(?:null|\d+)"/g,mt=RegExp("<(?:"+ht+")[\\s/>]","i"),yt=/^\s+/,vt=/<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:]+)[^>]*)\/>/gi,bt=/<([\w:]+)/,xt=/<tbody/i,wt=/<|&#?\w+;/,Tt=/<(?:script|style|link)/i,Ct=/^(?:checkbox|radio)$/i,Nt=/checked\s*(?:[^=]|=\s*.checked.)/i,kt=/^$|\/(?:java|ecma)script/i,Et=/^true\/(.*)/,St=/^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,At={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],area:[1,"<map>","</map>"],param:[1,"<object>","</object>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],_default:x.support.htmlSerialize?[0,"",""]:[1,"X<div>","</div>"]},jt=dt(a),Dt=jt.appendChild(a.createElement("div"));At.optgroup=At.option,At.tbody=At.tfoot=At.colgroup=At.caption=At.thead,At.th=At.td,x.fn.extend({text:function(e){return x.access(this,function(e){return e===t?x.text(this):this.empty().append((this[0]&&this[0].ownerDocument||a).createTextNode(e))},null,e,arguments.length)},append:function(){return this.domManip(arguments,function(e){if(1===this.nodeType||11===this.nodeType||9===this.nodeType){var t=Lt(this,e);t.appendChild(e)}})},prepend:function(){return this.domManip(arguments,function(e){if(1===this.nodeType||11===this.nodeType||9===this.nodeType){var t=Lt(this,e);t.insertBefore(e,t.firstChild)}})},before:function(){return this.domManip(arguments,function(e){this.parentNode&&this.parentNode.insertBefore(e,this)})},after:function(){return this.domManip(arguments,function(e){this.parentNode&&this.parentNode.insertBefore(e,this.nextSibling)})},remove:function(e,t){var n,r=e?x.filter(e,this):this,i=0;for(;null!=(n=r[i]);i++)t||1!==n.nodeType||x.cleanData(Ft(n)),n.parentNode&&(t&&x.contains(n.ownerDocument,n)&&_t(Ft(n,"script")),n.parentNode.removeChild(n));return this},empty:function(){var e,t=0;for(;null!=(e=this[t]);t++){1===e.nodeType&&x.cleanData(Ft(e,!1));while(e.firstChild)e.removeChild(e.firstChild);e.options&&x.nodeName(e,"select")&&(e.options.length=0)}return this},clone:function(e,t){return e=null==e?!1:e,t=null==t?e:t,this.map(function(){return x.clone(this,e,t)})},html:function(e){return x.access(this,function(e){var n=this[0]||{},r=0,i=this.length;if(e===t)return 1===n.nodeType?n.innerHTML.replace(gt,""):t;if(!("string"!=typeof e||Tt.test(e)||!x.support.htmlSerialize&&mt.test(e)||!x.support.leadingWhitespace&&yt.test(e)||At[(bt.exec(e)||["",""])[1].toLowerCase()])){e=e.replace(vt,"<$1></$2>");try{for(;i>r;r++)n=this[r]||{},1===n.nodeType&&(x.cleanData(Ft(n,!1)),n.innerHTML=e);n=0}catch(o){}}n&&this.empty().append(e)},null,e,arguments.length)},replaceWith:function(){var e=x.map(this,function(e){return[e.nextSibling,e.parentNode]}),t=0;return this.domManip(arguments,function(n){var r=e[t++],i=e[t++];i&&(r&&r.parentNode!==i&&(r=this.nextSibling),x(this).remove(),i.insertBefore(n,r))},!0),t?this:this.remove()},detach:function(e){return this.remove(e,!0)},domManip:function(e,t,n){e=d.apply([],e);var r,i,o,a,s,l,u=0,c=this.length,p=this,f=c-1,h=e[0],g=x.isFunction(h);if(g||!(1>=c||"string"!=typeof h||x.support.checkClone)&&Nt.test(h))return this.each(function(r){var i=p.eq(r);g&&(e[0]=h.call(this,r,i.html())),i.domManip(e,t,n)});if(c&&(l=x.buildFragment(e,this[0].ownerDocument,!1,!n&&this),r=l.firstChild,1===l.childNodes.length&&(l=r),r)){for(a=x.map(Ft(l,"script"),Ht),o=a.length;c>u;u++)i=l,u!==f&&(i=x.clone(i,!0,!0),o&&x.merge(a,Ft(i,"script"))),t.call(this[u],i,u);if(o)for(s=a[a.length-1].ownerDocument,x.map(a,qt),u=0;o>u;u++)i=a[u],kt.test(i.type||"")&&!x._data(i,"globalEval")&&x.contains(s,i)&&(i.src?x._evalUrl(i.src):x.globalEval((i.text||i.textContent||i.innerHTML||"").replace(St,"")));l=r=null}return this}});function Lt(e,t){return x.nodeName(e,"table")&&x.nodeName(1===t.nodeType?t:t.firstChild,"tr")?e.getElementsByTagName("tbody")[0]||e.appendChild(e.ownerDocument.createElement("tbody")):e}function Ht(e){return e.type=(null!==x.find.attr(e,"type"))+"/"+e.type,e}function qt(e){var t=Et.exec(e.type);return t?e.type=t[1]:e.removeAttribute("type"),e}function _t(e,t){var n,r=0;for(;null!=(n=e[r]);r++)x._data(n,"globalEval",!t||x._data(t[r],"globalEval"))}function Mt(e,t){if(1===t.nodeType&&x.hasData(e)){var n,r,i,o=x._data(e),a=x._data(t,o),s=o.events;if(s){delete a.handle,a.events={};for(n in s)for(r=0,i=s[n].length;i>r;r++)x.event.add(t,n,s[n][r])}a.data&&(a.data=x.extend({},a.data))}}function Ot(e,t){var n,r,i;if(1===t.nodeType){if(n=t.nodeName.toLowerCase(),!x.support.noCloneEvent&&t[x.expando]){i=x._data(t);for(r in i.events)x.removeEvent(t,r,i.handle);t.removeAttribute(x.expando)}"script"===n&&t.text!==e.text?(Ht(t).text=e.text,qt(t)):"object"===n?(t.parentNode&&(t.outerHTML=e.outerHTML),x.support.html5Clone&&e.innerHTML&&!x.trim(t.innerHTML)&&(t.innerHTML=e.innerHTML)):"input"===n&&Ct.test(e.type)?(t.defaultChecked=t.checked=e.checked,t.value!==e.value&&(t.value=e.value)):"option"===n?t.defaultSelected=t.selected=e.defaultSelected:("input"===n||"textarea"===n)&&(t.defaultValue=e.defaultValue)}}x.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(e,t){x.fn[e]=function(e){var n,r=0,i=[],o=x(e),a=o.length-1;for(;a>=r;r++)n=r===a?this:this.clone(!0),x(o[r])[t](n),h.apply(i,n.get());return this.pushStack(i)}});function Ft(e,n){var r,o,a=0,s=typeof e.getElementsByTagName!==i?e.getElementsByTagName(n||"*"):typeof e.querySelectorAll!==i?e.querySelectorAll(n||"*"):t;if(!s)for(s=[],r=e.childNodes||e;null!=(o=r[a]);a++)!n||x.nodeName(o,n)?s.push(o):x.merge(s,Ft(o,n));return n===t||n&&x.nodeName(e,n)?x.merge([e],s):s}function Bt(e){Ct.test(e.type)&&(e.defaultChecked=e.checked)}x.extend({clone:function(e,t,n){var r,i,o,a,s,l=x.contains(e.ownerDocument,e);if(x.support.html5Clone||x.isXMLDoc(e)||!mt.test("<"+e.nodeName+">")?o=e.cloneNode(!0):(Dt.innerHTML=e.outerHTML,Dt.removeChild(o=Dt.firstChild)),!(x.support.noCloneEvent&&x.support.noCloneChecked||1!==e.nodeType&&11!==e.nodeType||x.isXMLDoc(e)))for(r=Ft(o),s=Ft(e),a=0;null!=(i=s[a]);++a)r[a]&&Ot(i,r[a]);if(t)if(n)for(s=s||Ft(e),r=r||Ft(o),a=0;null!=(i=s[a]);a++)Mt(i,r[a]);else Mt(e,o);return r=Ft(o,"script"),r.length>0&&_t(r,!l&&Ft(e,"script")),r=s=i=null,o},buildFragment:function(e,t,n,r){var i,o,a,s,l,u,c,p=e.length,f=dt(t),d=[],h=0;for(;p>h;h++)if(o=e[h],o||0===o)if("object"===x.type(o))x.merge(d,o.nodeType?[o]:o);else if(wt.test(o)){s=s||f.appendChild(t.createElement("div")),l=(bt.exec(o)||["",""])[1].toLowerCase(),c=At[l]||At._default,s.innerHTML=c[1]+o.replace(vt,"<$1></$2>")+c[2],i=c[0];while(i--)s=s.lastChild;if(!x.support.leadingWhitespace&&yt.test(o)&&d.push(t.createTextNode(yt.exec(o)[0])),!x.support.tbody){o="table"!==l||xt.test(o)?"<table>"!==c[1]||xt.test(o)?0:s:s.firstChild,i=o&&o.childNodes.length;while(i--)x.nodeName(u=o.childNodes[i],"tbody")&&!u.childNodes.length&&o.removeChild(u)}x.merge(d,s.childNodes),s.textContent="";while(s.firstChild)s.removeChild(s.firstChild);s=f.lastChild}else d.push(t.createTextNode(o));s&&f.removeChild(s),x.support.appendChecked||x.grep(Ft(d,"input"),Bt),h=0;while(o=d[h++])if((!r||-1===x.inArray(o,r))&&(a=x.contains(o.ownerDocument,o),s=Ft(f.appendChild(o),"script"),a&&_t(s),n)){i=0;while(o=s[i++])kt.test(o.type||"")&&n.push(o)}return s=null,f},cleanData:function(e,t){var n,r,o,a,s=0,l=x.expando,u=x.cache,c=x.support.deleteExpando,f=x.event.special;for(;null!=(n=e[s]);s++)if((t||x.acceptData(n))&&(o=n[l],a=o&&u[o])){if(a.events)for(r in a.events)f[r]?x.event.remove(n,r):x.removeEvent(n,r,a.handle);
u[o]&&(delete u[o],c?delete n[l]:typeof n.removeAttribute!==i?n.removeAttribute(l):n[l]=null,p.push(o))}},_evalUrl:function(e){return x.ajax({url:e,type:"GET",dataType:"script",async:!1,global:!1,"throws":!0})}}),x.fn.extend({wrapAll:function(e){if(x.isFunction(e))return this.each(function(t){x(this).wrapAll(e.call(this,t))});if(this[0]){var t=x(e,this[0].ownerDocument).eq(0).clone(!0);this[0].parentNode&&t.insertBefore(this[0]),t.map(function(){var e=this;while(e.firstChild&&1===e.firstChild.nodeType)e=e.firstChild;return e}).append(this)}return this},wrapInner:function(e){return x.isFunction(e)?this.each(function(t){x(this).wrapInner(e.call(this,t))}):this.each(function(){var t=x(this),n=t.contents();n.length?n.wrapAll(e):t.append(e)})},wrap:function(e){var t=x.isFunction(e);return this.each(function(n){x(this).wrapAll(t?e.call(this,n):e)})},unwrap:function(){return this.parent().each(function(){x.nodeName(this,"body")||x(this).replaceWith(this.childNodes)}).end()}});var Pt,Rt,Wt,$t=/alpha\([^)]*\)/i,It=/opacity\s*=\s*([^)]*)/,zt=/^(top|right|bottom|left)$/,Xt=/^(none|table(?!-c[ea]).+)/,Ut=/^margin/,Vt=RegExp("^("+w+")(.*)$","i"),Yt=RegExp("^("+w+")(?!px)[a-z%]+$","i"),Jt=RegExp("^([+-])=("+w+")","i"),Gt={BODY:"block"},Qt={position:"absolute",visibility:"hidden",display:"block"},Kt={letterSpacing:0,fontWeight:400},Zt=["Top","Right","Bottom","Left"],en=["Webkit","O","Moz","ms"];function tn(e,t){if(t in e)return t;var n=t.charAt(0).toUpperCase()+t.slice(1),r=t,i=en.length;while(i--)if(t=en[i]+n,t in e)return t;return r}function nn(e,t){return e=t||e,"none"===x.css(e,"display")||!x.contains(e.ownerDocument,e)}function rn(e,t){var n,r,i,o=[],a=0,s=e.length;for(;s>a;a++)r=e[a],r.style&&(o[a]=x._data(r,"olddisplay"),n=r.style.display,t?(o[a]||"none"!==n||(r.style.display=""),""===r.style.display&&nn(r)&&(o[a]=x._data(r,"olddisplay",ln(r.nodeName)))):o[a]||(i=nn(r),(n&&"none"!==n||!i)&&x._data(r,"olddisplay",i?n:x.css(r,"display"))));for(a=0;s>a;a++)r=e[a],r.style&&(t&&"none"!==r.style.display&&""!==r.style.display||(r.style.display=t?o[a]||"":"none"));return e}x.fn.extend({css:function(e,n){return x.access(this,function(e,n,r){var i,o,a={},s=0;if(x.isArray(n)){for(o=Rt(e),i=n.length;i>s;s++)a[n[s]]=x.css(e,n[s],!1,o);return a}return r!==t?x.style(e,n,r):x.css(e,n)},e,n,arguments.length>1)},show:function(){return rn(this,!0)},hide:function(){return rn(this)},toggle:function(e){return"boolean"==typeof e?e?this.show():this.hide():this.each(function(){nn(this)?x(this).show():x(this).hide()})}}),x.extend({cssHooks:{opacity:{get:function(e,t){if(t){var n=Wt(e,"opacity");return""===n?"1":n}}}},cssNumber:{columnCount:!0,fillOpacity:!0,fontWeight:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,widows:!0,zIndex:!0,zoom:!0},cssProps:{"float":x.support.cssFloat?"cssFloat":"styleFloat"},style:function(e,n,r,i){if(e&&3!==e.nodeType&&8!==e.nodeType&&e.style){var o,a,s,l=x.camelCase(n),u=e.style;if(n=x.cssProps[l]||(x.cssProps[l]=tn(u,l)),s=x.cssHooks[n]||x.cssHooks[l],r===t)return s&&"get"in s&&(o=s.get(e,!1,i))!==t?o:u[n];if(a=typeof r,"string"===a&&(o=Jt.exec(r))&&(r=(o[1]+1)*o[2]+parseFloat(x.css(e,n)),a="number"),!(null==r||"number"===a&&isNaN(r)||("number"!==a||x.cssNumber[l]||(r+="px"),x.support.clearCloneStyle||""!==r||0!==n.indexOf("background")||(u[n]="inherit"),s&&"set"in s&&(r=s.set(e,r,i))===t)))try{u[n]=r}catch(c){}}},css:function(e,n,r,i){var o,a,s,l=x.camelCase(n);return n=x.cssProps[l]||(x.cssProps[l]=tn(e.style,l)),s=x.cssHooks[n]||x.cssHooks[l],s&&"get"in s&&(a=s.get(e,!0,r)),a===t&&(a=Wt(e,n,i)),"normal"===a&&n in Kt&&(a=Kt[n]),""===r||r?(o=parseFloat(a),r===!0||x.isNumeric(o)?o||0:a):a}}),e.getComputedStyle?(Rt=function(t){return e.getComputedStyle(t,null)},Wt=function(e,n,r){var i,o,a,s=r||Rt(e),l=s?s.getPropertyValue(n)||s[n]:t,u=e.style;return s&&(""!==l||x.contains(e.ownerDocument,e)||(l=x.style(e,n)),Yt.test(l)&&Ut.test(n)&&(i=u.width,o=u.minWidth,a=u.maxWidth,u.minWidth=u.maxWidth=u.width=l,l=s.width,u.width=i,u.minWidth=o,u.maxWidth=a)),l}):a.documentElement.currentStyle&&(Rt=function(e){return e.currentStyle},Wt=function(e,n,r){var i,o,a,s=r||Rt(e),l=s?s[n]:t,u=e.style;return null==l&&u&&u[n]&&(l=u[n]),Yt.test(l)&&!zt.test(n)&&(i=u.left,o=e.runtimeStyle,a=o&&o.left,a&&(o.left=e.currentStyle.left),u.left="fontSize"===n?"1em":l,l=u.pixelLeft+"px",u.left=i,a&&(o.left=a)),""===l?"auto":l});function on(e,t,n){var r=Vt.exec(t);return r?Math.max(0,r[1]-(n||0))+(r[2]||"px"):t}function an(e,t,n,r,i){var o=n===(r?"border":"content")?4:"width"===t?1:0,a=0;for(;4>o;o+=2)"margin"===n&&(a+=x.css(e,n+Zt[o],!0,i)),r?("content"===n&&(a-=x.css(e,"padding"+Zt[o],!0,i)),"margin"!==n&&(a-=x.css(e,"border"+Zt[o]+"Width",!0,i))):(a+=x.css(e,"padding"+Zt[o],!0,i),"padding"!==n&&(a+=x.css(e,"border"+Zt[o]+"Width",!0,i)));return a}function sn(e,t,n){var r=!0,i="width"===t?e.offsetWidth:e.offsetHeight,o=Rt(e),a=x.support.boxSizing&&"border-box"===x.css(e,"boxSizing",!1,o);if(0>=i||null==i){if(i=Wt(e,t,o),(0>i||null==i)&&(i=e.style[t]),Yt.test(i))return i;r=a&&(x.support.boxSizingReliable||i===e.style[t]),i=parseFloat(i)||0}return i+an(e,t,n||(a?"border":"content"),r,o)+"px"}function ln(e){var t=a,n=Gt[e];return n||(n=un(e,t),"none"!==n&&n||(Pt=(Pt||x("<iframe frameborder='0' width='0' height='0'/>").css("cssText","display:block !important")).appendTo(t.documentElement),t=(Pt[0].contentWindow||Pt[0].contentDocument).document,t.write("<!doctype html><html><body>"),t.close(),n=un(e,t),Pt.detach()),Gt[e]=n),n}function un(e,t){var n=x(t.createElement(e)).appendTo(t.body),r=x.css(n[0],"display");return n.remove(),r}x.each(["height","width"],function(e,n){x.cssHooks[n]={get:function(e,r,i){return r?0===e.offsetWidth&&Xt.test(x.css(e,"display"))?x.swap(e,Qt,function(){return sn(e,n,i)}):sn(e,n,i):t},set:function(e,t,r){var i=r&&Rt(e);return on(e,t,r?an(e,n,r,x.support.boxSizing&&"border-box"===x.css(e,"boxSizing",!1,i),i):0)}}}),x.support.opacity||(x.cssHooks.opacity={get:function(e,t){return It.test((t&&e.currentStyle?e.currentStyle.filter:e.style.filter)||"")?.01*parseFloat(RegExp.$1)+"":t?"1":""},set:function(e,t){var n=e.style,r=e.currentStyle,i=x.isNumeric(t)?"alpha(opacity="+100*t+")":"",o=r&&r.filter||n.filter||"";n.zoom=1,(t>=1||""===t)&&""===x.trim(o.replace($t,""))&&n.removeAttribute&&(n.removeAttribute("filter"),""===t||r&&!r.filter)||(n.filter=$t.test(o)?o.replace($t,i):o+" "+i)}}),x(function(){x.support.reliableMarginRight||(x.cssHooks.marginRight={get:function(e,n){return n?x.swap(e,{display:"inline-block"},Wt,[e,"marginRight"]):t}}),!x.support.pixelPosition&&x.fn.position&&x.each(["top","left"],function(e,n){x.cssHooks[n]={get:function(e,r){return r?(r=Wt(e,n),Yt.test(r)?x(e).position()[n]+"px":r):t}}})}),x.expr&&x.expr.filters&&(x.expr.filters.hidden=function(e){return 0>=e.offsetWidth&&0>=e.offsetHeight||!x.support.reliableHiddenOffsets&&"none"===(e.style&&e.style.display||x.css(e,"display"))},x.expr.filters.visible=function(e){return!x.expr.filters.hidden(e)}),x.each({margin:"",padding:"",border:"Width"},function(e,t){x.cssHooks[e+t]={expand:function(n){var r=0,i={},o="string"==typeof n?n.split(" "):[n];for(;4>r;r++)i[e+Zt[r]+t]=o[r]||o[r-2]||o[0];return i}},Ut.test(e)||(x.cssHooks[e+t].set=on)});var cn=/%20/g,pn=/\[\]$/,fn=/\r?\n/g,dn=/^(?:submit|button|image|reset|file)$/i,hn=/^(?:input|select|textarea|keygen)/i;x.fn.extend({serialize:function(){return x.param(this.serializeArray())},serializeArray:function(){return this.map(function(){var e=x.prop(this,"elements");return e?x.makeArray(e):this}).filter(function(){var e=this.type;return this.name&&!x(this).is(":disabled")&&hn.test(this.nodeName)&&!dn.test(e)&&(this.checked||!Ct.test(e))}).map(function(e,t){var n=x(this).val();return null==n?null:x.isArray(n)?x.map(n,function(e){return{name:t.name,value:e.replace(fn,"\r\n")}}):{name:t.name,value:n.replace(fn,"\r\n")}}).get()}}),x.param=function(e,n){var r,i=[],o=function(e,t){t=x.isFunction(t)?t():null==t?"":t,i[i.length]=encodeURIComponent(e)+"="+encodeURIComponent(t)};if(n===t&&(n=x.ajaxSettings&&x.ajaxSettings.traditional),x.isArray(e)||e.jquery&&!x.isPlainObject(e))x.each(e,function(){o(this.name,this.value)});else for(r in e)gn(r,e[r],n,o);return i.join("&").replace(cn,"+")};function gn(e,t,n,r){var i;if(x.isArray(t))x.each(t,function(t,i){n||pn.test(e)?r(e,i):gn(e+"["+("object"==typeof i?t:"")+"]",i,n,r)});else if(n||"object"!==x.type(t))r(e,t);else for(i in t)gn(e+"["+i+"]",t[i],n,r)}x.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error contextmenu".split(" "),function(e,t){x.fn[t]=function(e,n){return arguments.length>0?this.on(t,null,e,n):this.trigger(t)}}),x.fn.extend({hover:function(e,t){return this.mouseenter(e).mouseleave(t||e)},bind:function(e,t,n){return this.on(e,null,t,n)},unbind:function(e,t){return this.off(e,null,t)},delegate:function(e,t,n,r){return this.on(t,e,n,r)},undelegate:function(e,t,n){return 1===arguments.length?this.off(e,"**"):this.off(t,e||"**",n)}});var mn,yn,vn=x.now(),bn=/\?/,xn=/#.*$/,wn=/([?&])_=[^&]*/,Tn=/^(.*?):[ \t]*([^\r\n]*)\r?$/gm,Cn=/^(?:about|app|app-storage|.+-extension|file|res|widget):$/,Nn=/^(?:GET|HEAD)$/,kn=/^\/\//,En=/^([\w.+-]+:)(?:\/\/([^\/?#:]*)(?::(\d+)|)|)/,Sn=x.fn.load,An={},jn={},Dn="*/".concat("*");try{yn=o.href}catch(Ln){yn=a.createElement("a"),yn.href="",yn=yn.href}mn=En.exec(yn.toLowerCase())||[];function Hn(e){return function(t,n){"string"!=typeof t&&(n=t,t="*");var r,i=0,o=t.toLowerCase().match(T)||[];if(x.isFunction(n))while(r=o[i++])"+"===r[0]?(r=r.slice(1)||"*",(e[r]=e[r]||[]).unshift(n)):(e[r]=e[r]||[]).push(n)}}function qn(e,n,r,i){var o={},a=e===jn;function s(l){var u;return o[l]=!0,x.each(e[l]||[],function(e,l){var c=l(n,r,i);return"string"!=typeof c||a||o[c]?a?!(u=c):t:(n.dataTypes.unshift(c),s(c),!1)}),u}return s(n.dataTypes[0])||!o["*"]&&s("*")}function _n(e,n){var r,i,o=x.ajaxSettings.flatOptions||{};for(i in n)n[i]!==t&&((o[i]?e:r||(r={}))[i]=n[i]);return r&&x.extend(!0,e,r),e}x.fn.load=function(e,n,r){if("string"!=typeof e&&Sn)return Sn.apply(this,arguments);var i,o,a,s=this,l=e.indexOf(" ");return l>=0&&(i=e.slice(l,e.length),e=e.slice(0,l)),x.isFunction(n)?(r=n,n=t):n&&"object"==typeof n&&(a="POST"),s.length>0&&x.ajax({url:e,type:a,dataType:"html",data:n}).done(function(e){o=arguments,s.html(i?x("<div>").append(x.parseHTML(e)).find(i):e)}).complete(r&&function(e,t){s.each(r,o||[e.responseText,t,e])}),this},x.each(["ajaxStart","ajaxStop","ajaxComplete","ajaxError","ajaxSuccess","ajaxSend"],function(e,t){x.fn[t]=function(e){return this.on(t,e)}}),x.extend({active:0,lastModified:{},etag:{},ajaxSettings:{url:yn,type:"GET",isLocal:Cn.test(mn[1]),global:!0,processData:!0,async:!0,contentType:"application/x-www-form-urlencoded; charset=UTF-8",accepts:{"*":Dn,text:"text/plain",html:"text/html",xml:"application/xml, text/xml",json:"application/json, text/javascript"},contents:{xml:/xml/,html:/html/,json:/json/},responseFields:{xml:"responseXML",text:"responseText",json:"responseJSON"},converters:{"* text":String,"text html":!0,"text json":x.parseJSON,"text xml":x.parseXML},flatOptions:{url:!0,context:!0}},ajaxSetup:function(e,t){return t?_n(_n(e,x.ajaxSettings),t):_n(x.ajaxSettings,e)},ajaxPrefilter:Hn(An),ajaxTransport:Hn(jn),ajax:function(e,n){"object"==typeof e&&(n=e,e=t),n=n||{};var r,i,o,a,s,l,u,c,p=x.ajaxSetup({},n),f=p.context||p,d=p.context&&(f.nodeType||f.jquery)?x(f):x.event,h=x.Deferred(),g=x.Callbacks("once memory"),m=p.statusCode||{},y={},v={},b=0,w="canceled",C={readyState:0,getResponseHeader:function(e){var t;if(2===b){if(!c){c={};while(t=Tn.exec(a))c[t[1].toLowerCase()]=t[2]}t=c[e.toLowerCase()]}return null==t?null:t},getAllResponseHeaders:function(){return 2===b?a:null},setRequestHeader:function(e,t){var n=e.toLowerCase();return b||(e=v[n]=v[n]||e,y[e]=t),this},overrideMimeType:function(e){return b||(p.mimeType=e),this},statusCode:function(e){var t;if(e)if(2>b)for(t in e)m[t]=[m[t],e[t]];else C.always(e[C.status]);return this},abort:function(e){var t=e||w;return u&&u.abort(t),k(0,t),this}};if(h.promise(C).complete=g.add,C.success=C.done,C.error=C.fail,p.url=((e||p.url||yn)+"").replace(xn,"").replace(kn,mn[1]+"//"),p.type=n.method||n.type||p.method||p.type,p.dataTypes=x.trim(p.dataType||"*").toLowerCase().match(T)||[""],null==p.crossDomain&&(r=En.exec(p.url.toLowerCase()),p.crossDomain=!(!r||r[1]===mn[1]&&r[2]===mn[2]&&(r[3]||("http:"===r[1]?"80":"443"))===(mn[3]||("http:"===mn[1]?"80":"443")))),p.data&&p.processData&&"string"!=typeof p.data&&(p.data=x.param(p.data,p.traditional)),qn(An,p,n,C),2===b)return C;l=p.global,l&&0===x.active++&&x.event.trigger("ajaxStart"),p.type=p.type.toUpperCase(),p.hasContent=!Nn.test(p.type),o=p.url,p.hasContent||(p.data&&(o=p.url+=(bn.test(o)?"&":"?")+p.data,delete p.data),p.cache===!1&&(p.url=wn.test(o)?o.replace(wn,"$1_="+vn++):o+(bn.test(o)?"&":"?")+"_="+vn++)),p.ifModified&&(x.lastModified[o]&&C.setRequestHeader("If-Modified-Since",x.lastModified[o]),x.etag[o]&&C.setRequestHeader("If-None-Match",x.etag[o])),(p.data&&p.hasContent&&p.contentType!==!1||n.contentType)&&C.setRequestHeader("Content-Type",p.contentType),C.setRequestHeader("Accept",p.dataTypes[0]&&p.accepts[p.dataTypes[0]]?p.accepts[p.dataTypes[0]]+("*"!==p.dataTypes[0]?", "+Dn+"; q=0.01":""):p.accepts["*"]);for(i in p.headers)C.setRequestHeader(i,p.headers[i]);if(p.beforeSend&&(p.beforeSend.call(f,C,p)===!1||2===b))return C.abort();w="abort";for(i in{success:1,error:1,complete:1})C[i](p[i]);if(u=qn(jn,p,n,C)){C.readyState=1,l&&d.trigger("ajaxSend",[C,p]),p.async&&p.timeout>0&&(s=setTimeout(function(){C.abort("timeout")},p.timeout));try{b=1,u.send(y,k)}catch(N){if(!(2>b))throw N;k(-1,N)}}else k(-1,"No Transport");function k(e,n,r,i){var c,y,v,w,T,N=n;2!==b&&(b=2,s&&clearTimeout(s),u=t,a=i||"",C.readyState=e>0?4:0,c=e>=200&&300>e||304===e,r&&(w=Mn(p,C,r)),w=On(p,w,C,c),c?(p.ifModified&&(T=C.getResponseHeader("Last-Modified"),T&&(x.lastModified[o]=T),T=C.getResponseHeader("etag"),T&&(x.etag[o]=T)),204===e||"HEAD"===p.type?N="nocontent":304===e?N="notmodified":(N=w.state,y=w.data,v=w.error,c=!v)):(v=N,(e||!N)&&(N="error",0>e&&(e=0))),C.status=e,C.statusText=(n||N)+"",c?h.resolveWith(f,[y,N,C]):h.rejectWith(f,[C,N,v]),C.statusCode(m),m=t,l&&d.trigger(c?"ajaxSuccess":"ajaxError",[C,p,c?y:v]),g.fireWith(f,[C,N]),l&&(d.trigger("ajaxComplete",[C,p]),--x.active||x.event.trigger("ajaxStop")))}return C},getJSON:function(e,t,n){return x.get(e,t,n,"json")},getScript:function(e,n){return x.get(e,t,n,"script")}}),x.each(["get","post"],function(e,n){x[n]=function(e,r,i,o){return x.isFunction(r)&&(o=o||i,i=r,r=t),x.ajax({url:e,type:n,dataType:o,data:r,success:i})}});function Mn(e,n,r){var i,o,a,s,l=e.contents,u=e.dataTypes;while("*"===u[0])u.shift(),o===t&&(o=e.mimeType||n.getResponseHeader("Content-Type"));if(o)for(s in l)if(l[s]&&l[s].test(o)){u.unshift(s);break}if(u[0]in r)a=u[0];else{for(s in r){if(!u[0]||e.converters[s+" "+u[0]]){a=s;break}i||(i=s)}a=a||i}return a?(a!==u[0]&&u.unshift(a),r[a]):t}function On(e,t,n,r){var i,o,a,s,l,u={},c=e.dataTypes.slice();if(c[1])for(a in e.converters)u[a.toLowerCase()]=e.converters[a];o=c.shift();while(o)if(e.responseFields[o]&&(n[e.responseFields[o]]=t),!l&&r&&e.dataFilter&&(t=e.dataFilter(t,e.dataType)),l=o,o=c.shift())if("*"===o)o=l;else if("*"!==l&&l!==o){if(a=u[l+" "+o]||u["* "+o],!a)for(i in u)if(s=i.split(" "),s[1]===o&&(a=u[l+" "+s[0]]||u["* "+s[0]])){a===!0?a=u[i]:u[i]!==!0&&(o=s[0],c.unshift(s[1]));break}if(a!==!0)if(a&&e["throws"])t=a(t);else try{t=a(t)}catch(p){return{state:"parsererror",error:a?p:"No conversion from "+l+" to "+o}}}return{state:"success",data:t}}x.ajaxSetup({accepts:{script:"text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"},contents:{script:/(?:java|ecma)script/},converters:{"text script":function(e){return x.globalEval(e),e}}}),x.ajaxPrefilter("script",function(e){e.cache===t&&(e.cache=!1),e.crossDomain&&(e.type="GET",e.global=!1)}),x.ajaxTransport("script",function(e){if(e.crossDomain){var n,r=a.head||x("head")[0]||a.documentElement;return{send:function(t,i){n=a.createElement("script"),n.async=!0,e.scriptCharset&&(n.charset=e.scriptCharset),n.src=e.url,n.onload=n.onreadystatechange=function(e,t){(t||!n.readyState||/loaded|complete/.test(n.readyState))&&(n.onload=n.onreadystatechange=null,n.parentNode&&n.parentNode.removeChild(n),n=null,t||i(200,"success"))},r.insertBefore(n,r.firstChild)},abort:function(){n&&n.onload(t,!0)}}}});var Fn=[],Bn=/(=)\?(?=&|$)|\?\?/;x.ajaxSetup({jsonp:"callback",jsonpCallback:function(){var e=Fn.pop()||x.expando+"_"+vn++;return this[e]=!0,e}}),x.ajaxPrefilter("json jsonp",function(n,r,i){var o,a,s,l=n.jsonp!==!1&&(Bn.test(n.url)?"url":"string"==typeof n.data&&!(n.contentType||"").indexOf("application/x-www-form-urlencoded")&&Bn.test(n.data)&&"data");return l||"jsonp"===n.dataTypes[0]?(o=n.jsonpCallback=x.isFunction(n.jsonpCallback)?n.jsonpCallback():n.jsonpCallback,l?n[l]=n[l].replace(Bn,"$1"+o):n.jsonp!==!1&&(n.url+=(bn.test(n.url)?"&":"?")+n.jsonp+"="+o),n.converters["script json"]=function(){return s||x.error(o+" was not called"),s[0]},n.dataTypes[0]="json",a=e[o],e[o]=function(){s=arguments},i.always(function(){e[o]=a,n[o]&&(n.jsonpCallback=r.jsonpCallback,Fn.push(o)),s&&x.isFunction(a)&&a(s[0]),s=a=t}),"script"):t});var Pn,Rn,Wn=0,$n=e.ActiveXObject&&function(){var e;for(e in Pn)Pn[e](t,!0)};function In(){try{return new e.XMLHttpRequest}catch(t){}}function zn(){try{return new e.ActiveXObject("Microsoft.XMLHTTP")}catch(t){}}x.ajaxSettings.xhr=e.ActiveXObject?function(){return!this.isLocal&&In()||zn()}:In,Rn=x.ajaxSettings.xhr(),x.support.cors=!!Rn&&"withCredentials"in Rn,Rn=x.support.ajax=!!Rn,Rn&&x.ajaxTransport(function(n){if(!n.crossDomain||x.support.cors){var r;return{send:function(i,o){var a,s,l=n.xhr();if(n.username?l.open(n.type,n.url,n.async,n.username,n.password):l.open(n.type,n.url,n.async),n.xhrFields)for(s in n.xhrFields)l[s]=n.xhrFields[s];n.mimeType&&l.overrideMimeType&&l.overrideMimeType(n.mimeType),n.crossDomain||i["X-Requested-With"]||(i["X-Requested-With"]="XMLHttpRequest");try{for(s in i)l.setRequestHeader(s,i[s])}catch(u){}l.send(n.hasContent&&n.data||null),r=function(e,i){var s,u,c,p;try{if(r&&(i||4===l.readyState))if(r=t,a&&(l.onreadystatechange=x.noop,$n&&delete Pn[a]),i)4!==l.readyState&&l.abort();else{p={},s=l.status,u=l.getAllResponseHeaders(),"string"==typeof l.responseText&&(p.text=l.responseText);try{c=l.statusText}catch(f){c=""}s||!n.isLocal||n.crossDomain?1223===s&&(s=204):s=p.text?200:404}}catch(d){i||o(-1,d)}p&&o(s,c,p,u)},n.async?4===l.readyState?setTimeout(r):(a=++Wn,$n&&(Pn||(Pn={},x(e).unload($n)),Pn[a]=r),l.onreadystatechange=r):r()},abort:function(){r&&r(t,!0)}}}});var Xn,Un,Vn=/^(?:toggle|show|hide)$/,Yn=RegExp("^(?:([+-])=|)("+w+")([a-z%]*)$","i"),Jn=/queueHooks$/,Gn=[nr],Qn={"*":[function(e,t){var n=this.createTween(e,t),r=n.cur(),i=Yn.exec(t),o=i&&i[3]||(x.cssNumber[e]?"":"px"),a=(x.cssNumber[e]||"px"!==o&&+r)&&Yn.exec(x.css(n.elem,e)),s=1,l=20;if(a&&a[3]!==o){o=o||a[3],i=i||[],a=+r||1;do s=s||".5",a/=s,x.style(n.elem,e,a+o);while(s!==(s=n.cur()/r)&&1!==s&&--l)}return i&&(a=n.start=+a||+r||0,n.unit=o,n.end=i[1]?a+(i[1]+1)*i[2]:+i[2]),n}]};function Kn(){return setTimeout(function(){Xn=t}),Xn=x.now()}function Zn(e,t,n){var r,i=(Qn[t]||[]).concat(Qn["*"]),o=0,a=i.length;for(;a>o;o++)if(r=i[o].call(n,t,e))return r}function er(e,t,n){var r,i,o=0,a=Gn.length,s=x.Deferred().always(function(){delete l.elem}),l=function(){if(i)return!1;var t=Xn||Kn(),n=Math.max(0,u.startTime+u.duration-t),r=n/u.duration||0,o=1-r,a=0,l=u.tweens.length;for(;l>a;a++)u.tweens[a].run(o);return s.notifyWith(e,[u,o,n]),1>o&&l?n:(s.resolveWith(e,[u]),!1)},u=s.promise({elem:e,props:x.extend({},t),opts:x.extend(!0,{specialEasing:{}},n),originalProperties:t,originalOptions:n,startTime:Xn||Kn(),duration:n.duration,tweens:[],createTween:function(t,n){var r=x.Tween(e,u.opts,t,n,u.opts.specialEasing[t]||u.opts.easing);return u.tweens.push(r),r},stop:function(t){var n=0,r=t?u.tweens.length:0;if(i)return this;for(i=!0;r>n;n++)u.tweens[n].run(1);return t?s.resolveWith(e,[u,t]):s.rejectWith(e,[u,t]),this}}),c=u.props;for(tr(c,u.opts.specialEasing);a>o;o++)if(r=Gn[o].call(u,e,c,u.opts))return r;return x.map(c,Zn,u),x.isFunction(u.opts.start)&&u.opts.start.call(e,u),x.fx.timer(x.extend(l,{elem:e,anim:u,queue:u.opts.queue})),u.progress(u.opts.progress).done(u.opts.done,u.opts.complete).fail(u.opts.fail).always(u.opts.always)}function tr(e,t){var n,r,i,o,a;for(n in e)if(r=x.camelCase(n),i=t[r],o=e[n],x.isArray(o)&&(i=o[1],o=e[n]=o[0]),n!==r&&(e[r]=o,delete e[n]),a=x.cssHooks[r],a&&"expand"in a){o=a.expand(o),delete e[r];for(n in o)n in e||(e[n]=o[n],t[n]=i)}else t[r]=i}x.Animation=x.extend(er,{tweener:function(e,t){x.isFunction(e)?(t=e,e=["*"]):e=e.split(" ");var n,r=0,i=e.length;for(;i>r;r++)n=e[r],Qn[n]=Qn[n]||[],Qn[n].unshift(t)},prefilter:function(e,t){t?Gn.unshift(e):Gn.push(e)}});function nr(e,t,n){var r,i,o,a,s,l,u=this,c={},p=e.style,f=e.nodeType&&nn(e),d=x._data(e,"fxshow");n.queue||(s=x._queueHooks(e,"fx"),null==s.unqueued&&(s.unqueued=0,l=s.empty.fire,s.empty.fire=function(){s.unqueued||l()}),s.unqueued++,u.always(function(){u.always(function(){s.unqueued--,x.queue(e,"fx").length||s.empty.fire()})})),1===e.nodeType&&("height"in t||"width"in t)&&(n.overflow=[p.overflow,p.overflowX,p.overflowY],"inline"===x.css(e,"display")&&"none"===x.css(e,"float")&&(x.support.inlineBlockNeedsLayout&&"inline"!==ln(e.nodeName)?p.zoom=1:p.display="inline-block")),n.overflow&&(p.overflow="hidden",x.support.shrinkWrapBlocks||u.always(function(){p.overflow=n.overflow[0],p.overflowX=n.overflow[1],p.overflowY=n.overflow[2]}));for(r in t)if(i=t[r],Vn.exec(i)){if(delete t[r],o=o||"toggle"===i,i===(f?"hide":"show"))continue;c[r]=d&&d[r]||x.style(e,r)}if(!x.isEmptyObject(c)){d?"hidden"in d&&(f=d.hidden):d=x._data(e,"fxshow",{}),o&&(d.hidden=!f),f?x(e).show():u.done(function(){x(e).hide()}),u.done(function(){var t;x._removeData(e,"fxshow");for(t in c)x.style(e,t,c[t])});for(r in c)a=Zn(f?d[r]:0,r,u),r in d||(d[r]=a.start,f&&(a.end=a.start,a.start="width"===r||"height"===r?1:0))}}function rr(e,t,n,r,i){return new rr.prototype.init(e,t,n,r,i)}x.Tween=rr,rr.prototype={constructor:rr,init:function(e,t,n,r,i,o){this.elem=e,this.prop=n,this.easing=i||"swing",this.options=t,this.start=this.now=this.cur(),this.end=r,this.unit=o||(x.cssNumber[n]?"":"px")},cur:function(){var e=rr.propHooks[this.prop];return e&&e.get?e.get(this):rr.propHooks._default.get(this)},run:function(e){var t,n=rr.propHooks[this.prop];return this.pos=t=this.options.duration?x.easing[this.easing](e,this.options.duration*e,0,1,this.options.duration):e,this.now=(this.end-this.start)*t+this.start,this.options.step&&this.options.step.call(this.elem,this.now,this),n&&n.set?n.set(this):rr.propHooks._default.set(this),this}},rr.prototype.init.prototype=rr.prototype,rr.propHooks={_default:{get:function(e){var t;return null==e.elem[e.prop]||e.elem.style&&null!=e.elem.style[e.prop]?(t=x.css(e.elem,e.prop,""),t&&"auto"!==t?t:0):e.elem[e.prop]},set:function(e){x.fx.step[e.prop]?x.fx.step[e.prop](e):e.elem.style&&(null!=e.elem.style[x.cssProps[e.prop]]||x.cssHooks[e.prop])?x.style(e.elem,e.prop,e.now+e.unit):e.elem[e.prop]=e.now}}},rr.propHooks.scrollTop=rr.propHooks.scrollLeft={set:function(e){e.elem.nodeType&&e.elem.parentNode&&(e.elem[e.prop]=e.now)}},x.each(["toggle","show","hide"],function(e,t){var n=x.fn[t];x.fn[t]=function(e,r,i){return null==e||"boolean"==typeof e?n.apply(this,arguments):this.animate(ir(t,!0),e,r,i)}}),x.fn.extend({fadeTo:function(e,t,n,r){return this.filter(nn).css("opacity",0).show().end().animate({opacity:t},e,n,r)},animate:function(e,t,n,r){var i=x.isEmptyObject(e),o=x.speed(t,n,r),a=function(){var t=er(this,x.extend({},e),o);(i||x._data(this,"finish"))&&t.stop(!0)};return a.finish=a,i||o.queue===!1?this.each(a):this.queue(o.queue,a)},stop:function(e,n,r){var i=function(e){var t=e.stop;delete e.stop,t(r)};return"string"!=typeof e&&(r=n,n=e,e=t),n&&e!==!1&&this.queue(e||"fx",[]),this.each(function(){var t=!0,n=null!=e&&e+"queueHooks",o=x.timers,a=x._data(this);if(n)a[n]&&a[n].stop&&i(a[n]);else for(n in a)a[n]&&a[n].stop&&Jn.test(n)&&i(a[n]);for(n=o.length;n--;)o[n].elem!==this||null!=e&&o[n].queue!==e||(o[n].anim.stop(r),t=!1,o.splice(n,1));(t||!r)&&x.dequeue(this,e)})},finish:function(e){return e!==!1&&(e=e||"fx"),this.each(function(){var t,n=x._data(this),r=n[e+"queue"],i=n[e+"queueHooks"],o=x.timers,a=r?r.length:0;for(n.finish=!0,x.queue(this,e,[]),i&&i.stop&&i.stop.call(this,!0),t=o.length;t--;)o[t].elem===this&&o[t].queue===e&&(o[t].anim.stop(!0),o.splice(t,1));for(t=0;a>t;t++)r[t]&&r[t].finish&&r[t].finish.call(this);delete n.finish})}});function ir(e,t){var n,r={height:e},i=0;for(t=t?1:0;4>i;i+=2-t)n=Zt[i],r["margin"+n]=r["padding"+n]=e;return t&&(r.opacity=r.width=e),r}x.each({slideDown:ir("show"),slideUp:ir("hide"),slideToggle:ir("toggle"),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"},fadeToggle:{opacity:"toggle"}},function(e,t){x.fn[e]=function(e,n,r){return this.animate(t,e,n,r)}}),x.speed=function(e,t,n){var r=e&&"object"==typeof e?x.extend({},e):{complete:n||!n&&t||x.isFunction(e)&&e,duration:e,easing:n&&t||t&&!x.isFunction(t)&&t};return r.duration=x.fx.off?0:"number"==typeof r.duration?r.duration:r.duration in x.fx.speeds?x.fx.speeds[r.duration]:x.fx.speeds._default,(null==r.queue||r.queue===!0)&&(r.queue="fx"),r.old=r.complete,r.complete=function(){x.isFunction(r.old)&&r.old.call(this),r.queue&&x.dequeue(this,r.queue)},r},x.easing={linear:function(e){return e},swing:function(e){return.5-Math.cos(e*Math.PI)/2}},x.timers=[],x.fx=rr.prototype.init,x.fx.tick=function(){var e,n=x.timers,r=0;for(Xn=x.now();n.length>r;r++)e=n[r],e()||n[r]!==e||n.splice(r--,1);n.length||x.fx.stop(),Xn=t},x.fx.timer=function(e){e()&&x.timers.push(e)&&x.fx.start()},x.fx.interval=13,x.fx.start=function(){Un||(Un=setInterval(x.fx.tick,x.fx.interval))},x.fx.stop=function(){clearInterval(Un),Un=null},x.fx.speeds={slow:600,fast:200,_default:400},x.fx.step={},x.expr&&x.expr.filters&&(x.expr.filters.animated=function(e){return x.grep(x.timers,function(t){return e===t.elem}).length}),x.fn.offset=function(e){if(arguments.length)return e===t?this:this.each(function(t){x.offset.setOffset(this,e,t)});var n,r,o={top:0,left:0},a=this[0],s=a&&a.ownerDocument;if(s)return n=s.documentElement,x.contains(n,a)?(typeof a.getBoundingClientRect!==i&&(o=a.getBoundingClientRect()),r=or(s),{top:o.top+(r.pageYOffset||n.scrollTop)-(n.clientTop||0),left:o.left+(r.pageXOffset||n.scrollLeft)-(n.clientLeft||0)}):o},x.offset={setOffset:function(e,t,n){var r=x.css(e,"position");"static"===r&&(e.style.position="relative");var i=x(e),o=i.offset(),a=x.css(e,"top"),s=x.css(e,"left"),l=("absolute"===r||"fixed"===r)&&x.inArray("auto",[a,s])>-1,u={},c={},p,f;l?(c=i.position(),p=c.top,f=c.left):(p=parseFloat(a)||0,f=parseFloat(s)||0),x.isFunction(t)&&(t=t.call(e,n,o)),null!=t.top&&(u.top=t.top-o.top+p),null!=t.left&&(u.left=t.left-o.left+f),"using"in t?t.using.call(e,u):i.css(u)}},x.fn.extend({position:function(){if(this[0]){var e,t,n={top:0,left:0},r=this[0];return"fixed"===x.css(r,"position")?t=r.getBoundingClientRect():(e=this.offsetParent(),t=this.offset(),x.nodeName(e[0],"html")||(n=e.offset()),n.top+=x.css(e[0],"borderTopWidth",!0),n.left+=x.css(e[0],"borderLeftWidth",!0)),{top:t.top-n.top-x.css(r,"marginTop",!0),left:t.left-n.left-x.css(r,"marginLeft",!0)}}},offsetParent:function(){return this.map(function(){var e=this.offsetParent||s;while(e&&!x.nodeName(e,"html")&&"static"===x.css(e,"position"))e=e.offsetParent;return e||s})}}),x.each({scrollLeft:"pageXOffset",scrollTop:"pageYOffset"},function(e,n){var r=/Y/.test(n);x.fn[e]=function(i){return x.access(this,function(e,i,o){var a=or(e);return o===t?a?n in a?a[n]:a.document.documentElement[i]:e[i]:(a?a.scrollTo(r?x(a).scrollLeft():o,r?o:x(a).scrollTop()):e[i]=o,t)},e,i,arguments.length,null)}});function or(e){return x.isWindow(e)?e:9===e.nodeType?e.defaultView||e.parentWindow:!1}x.each({Height:"height",Width:"width"},function(e,n){x.each({padding:"inner"+e,content:n,"":"outer"+e},function(r,i){x.fn[i]=function(i,o){var a=arguments.length&&(r||"boolean"!=typeof i),s=r||(i===!0||o===!0?"margin":"border");return x.access(this,function(n,r,i){var o;return x.isWindow(n)?n.document.documentElement["client"+e]:9===n.nodeType?(o=n.documentElement,Math.max(n.body["scroll"+e],o["scroll"+e],n.body["offset"+e],o["offset"+e],o["client"+e])):i===t?x.css(n,r,s):x.style(n,r,i,s)},n,a?i:t,a,null)}})}),x.fn.size=function(){return this.length},x.fn.andSelf=x.fn.addBack,"object"==typeof module&&module&&"object"==typeof module.exports?module.exports=x:(e.jQuery=e.$=x,"function"==typeof define&&define.amd&&define("jquery",[],function(){return x}))})(window);


</script>

  <style type='text/css'>
    body { }
    div#surfacePlotDiv {
    margin-left: 10px;
    margin-top:  10px;
    border-style: solid;
    border-width: 0px;
    border-color: #A0A0A0;
    width: 100%;
    height: 100%;
}
</style>
<script type='text/javascript'>//<![CDATA[ 


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////// Draw Gems Curves ... ////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

$( window ).load(function() {

var data=[{data: [0,0,0,0], name: ""}];
data=%DATA% ;


function dataToMatrix(data) {
  var m={
    dim: [0,0],
    matrice: [],
    xlabel: [],
    ylabel: [],
    valueName: "",
    colName:"Project",
    rowName:"Times"
  };
  for (var i=0;i<data.length;i++) {
     var dico=data[i];
     m.xlabel.push(dico.name);
     m.dim=[i+1,dico.data.length];
     m.matrice.push(dico.data);
  }  
  return(m);
};

function setUp(m) {
    data = {
        nRows: m.dim[0],
        nCols: m.dim[1],
        formattedValues:  m.matrice
    };
    // Define a colour gradient.
    var colour1 = { red: 0,    green: 100,   blue: 255};
    var colour2 = { red: 0,    green: 255, blue: 255     };
    var colour3 = { red: 0,    green: 255, blue: 100     };
    var colour4 = { red: 255,  green: 255, blue: 0     };
    var colour5 = { red: 255,  green: 0,   blue: 0     };

    var colours = [colour1, colour2, colour3, colour4, colour5];
    var chartOrigin = { x: 200, y: 265 };
    // Options for the basic canvas plot.
    basicPlotOptions = {
        fillPolygons: false,
        tooltips:  new Array(),
        renderPoints: true
    }

    // These labels are used when autoCalcZScale is true and false :)
    glOptions = {
        xLabels:  m.xlabel,
        yLabels: m.ylabel,
        autoCalcZScale: true
    };

    // Options common to both types of plot.
    options = {
        xPos: 30,yPos: 90,
        width:  window.innerWidth-100,height:  window.innerHeight-100,
        colourGradient: colours,xTitle: "",  // !..  m.rowName
        yTitle: "",  // !.. m.colName
        zTitle:  m.valueName,backColour: '#ffffff',
        axisTextColour: '#040700',hideFlatMinPolygons: false,
        origin: chartOrigin};
    var surfacePlot = new SurfacePlot(document.getElementById("surfacePlotDiv"));
    surfacePlot.draw(data, options, basicPlotOptions, glOptions);
} 

 function matrix( rows, cols, defaultValue) {
  var arr = [];
  for(var i=0; i < rows; i++){
      arr.push([]);
      arr[i].push( new Array(cols));
      for(var j=0; j < cols; j++) arr[i][j] = defaultValue;
  }
  return(arr);
}

setUp( dataToMatrix(data) ) ;

});
//]]>  
</script>
<body>
<div id="surfacePlotDiv"></div>
<script id="shader-fs" type="x-shader/x-fragment">
    #ifdef GL_ES
    precision highp float;
    #endif
    varying vec4 vColor;
    varying vec3 vLightWeighting;
    void main(void)
    {
    gl_FragColor = vec4(vColor.rgb * vLightWeighting, vColor.a);
    }
</script>
<script id="shader-vs" type="x-shader/x-vertex">
    attribute vec3 aVertexPosition;
    attribute vec3 aVertexNormal;
    attribute vec4 aVertexColor;
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
    uniform mat3 uNMatrix;
    varying vec4 vColor;
    uniform vec3 uAmbientColor;
    uniform vec3 uLightingDirection;
    uniform vec3 uDirectionalColor;
    varying vec3 vLightWeighting;
    void main(void)
    {
    gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
    vec3 transformedNormal = uNMatrix * aVertexNormal;
    float directionalLightWeighting = max(dot(transformedNormal, uLightingDirection), 0.0);
    vLightWeighting = uAmbientColor + uDirectionalColor * directionalLightWeighting;
    vColor = aVertexColor;
    }
</script>
<script id="axes-shader-fs" type="x-shader/x-fragment">
    precision mediump float;
    varying vec4 vColor;
    void main(void)
    {
    gl_FragColor = vColor;
    }
</script>
<script id="axes-shader-vs" type="x-shader/x-vertex">
    attribute vec3 aVertexPosition;
    attribute vec4 aVertexColor;
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
    varying vec4 vColor;
    uniform vec3 uAxesColour;
    void main(void)
    {
    gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
    vColor =  vec4(uAxesColour, 1.0);
    }
</script>
<script id="texture-shader-fs" type="x-shader/x-fragment">
    #ifdef GL_ES
    precision highp float;
    #endif
    varying vec2 vTextureCoord;
    uniform sampler2D uSampler;
    void main(void)
    {
    gl_FragColor = texture2D(uSampler, vTextureCoord);
    }
</script>
<script id="texture-shader-vs" type="x-shader/x-vertex">
    attribute vec3 aVertexPosition;
    attribute vec2 aTextureCoord;
    varying vec2 vTextureCoord;
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
    void main(void)
    {
    gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
    vTextureCoord = aTextureCoord;
    }
</script>
</body></html>
EEND

###########################################################################
###########################################################################
###########################################################################
###########################################################################


=begin
https://rubygems.org/api/v1/downloads/NAME-VERS.json
{"total_downloads":8584,"version_downloads":96}
=end

$result=Queue.new
def analyse(index,name,version) 
  url=RUBYGEMS+'/api/v1/downloads/NAME-VERS.json'.
        gsub('NAME',name.strip).
        gsub('VERS',version.strip)
  #puts "#{index} #{url} : #{name} / #{version} ..."
  json = eval( open(url).read.gsub('":', '"  => ' ) )
  total=json["total_downloads"]
  actual=json["version_downloads"]
  out=memo(name,total)  
  Thread.current[:output] = [name,out]
rescue
  puts 'ERROR for "' + url + '"  ===> '  + $!.to_s
end

NB=40
def memo(name,total)
  fname="mstat/#{name.downcase}.data"
  content= File.exists?(fname) ? eval( File.read(fname) ) : [0]*(NB+1)
  p content if name=="rack"
  last= content[0]==0 ? total : content[0]
  p last if name=="rack"
  content=[total]+(content << (total-last))[-NB..-1]
  p content if name=="rack"
  File.write(fname,content.inspect)
  #puts "#{fname} => #{content}"
  content[1..-1]
end

############################## M A I N ########################
=begin
<a href="/gems/Ruiby" class="profile-rubygem">
    Ruiby
    <em>0.135.0</em>
</a>
=end

puts "start..."
def main(ss)
 
  lth=[]
  no=0
  Dir.mkdir('mstat') unless Dir.exists?('mstat')
  (ss=="1" ? $authors1 : $authors).each do |aut|
    doc = Nokogiri::HTML(open(RUBYGEMS+'/profiles/'+aut))
    doc.css('a.profile-rubygem').each do |a|
      version=a.css('em').inner_html
      name =a.inner_html.split("<")[0].strip
      if name !~ /^acti/ 
        lth << Thread.new(no,name,version) { |j,n,v| analyse(j,n,v)  }
        no+=1
      end
    end
  end
  p $html.encoding

  result=lth.map { |th| th.join()[:output] }
  sdata=result.map { |(name,data)|  { name: name, data: data } }.select {|a| a[:data] }
  sdata=sdata.sort { |a,b| b[:data].last <=> a[:data].last }[0..14]
  p JSON.generate(sdata).encoding
  File.write("#{LOCAL_HTDOCS}/gems#{ss}.html",
      $html.
      encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').
      gsub("%DATA%",JSON.generate(sdata))
  )
end

if ARGV.size>0 
  loop {
    main("") rescue p $!
    sleep(ARGV[0].to_i*60)
  }
else
   main("1")
   system(Dir.exists?("c:/") ? 'start' : 'gnome-open' ,"http://localhost/gems1.html") 
end
