var pieMenu = function(config){
  var jg = null;
  var id = '';
  var containerId = 'pieMenu' + uniqid();
  this.innerId = '';
  var currentX = 0;
  var currentY = 0;  
  var items = [];  
  this.items = items;
  var currentSelectedIndex = -1;
  var menuItemId = '';
  var that = this;
  
  this.show = function(x, y)  {
    this.showed = true;
    $('<div id=' + containerId + '></div>').appendTo('body');
    jg = new jsGraphics(containerId);
    id = 'menu' + x + y;
    this.innerId = 'innerCircle' + x + y;
    currentX = x;
    currentY = y;
    drawOuterCircle(x, y);
    drawItems(x, y, that);
    drawInnerCircle(x, y, this.innerId);
    jg.paint();
    $('#' + id).bind('click', this, this.menuClick);    
    //$('#' + id).bind('mouseover', this, this.menuHover);
    //$('#' + id).bind('mousemove', this, this.menuHover);
    //FROM HERE!!
    $(document).bind('mousemove', this, this.menuHover);
    //$('#' + id).bind('mouseout', this, this.removeHighlight);
    $('#' + this.innerId).parent().addClass('zIndex900');
    $('#' + this.innerId).bind('click', this, this.remove);
    $('#' + this.innerId).bind('mouseover', this, this.innerCircleHover);
    $('#' + this.innerId).bind('mouseleave', this, this.innerCircleBlur);
  };
  
  this.innerCircleHover = function(e){
    var that = e && e.data ? e.data : this;
    $('#' + that.innerId).attr("src","image/pie-innerCircleHover.png");
    $('div[id*=menuItem]').remove();
    that.isInnerCircleHovered = true;
  };
  
  this.innerCircleBlur = function(e){
    var that = e && e.data ? e.data : this;
    $('#' + that.innerId).attr("src","image/pie-innerCircle.png");
    that.isInnerCircleHovered = false;
  };
  
  this.remove = function(e){
    var that = e && e.data ? e.data : this;
    if(that.innerId){
      $('#' + that.innerId).remove();
      $('#' + id).remove();
      $('#' + containerId).remove();
      $(document).unbind('mousemove', that.menuHover);
      if(menuItemId)
        $('#' + menuItemId).remove();
      
      that.showed = false;
      //if we delete menu, we should delete submenu as well
      if(!!that.submenu){
        that.submenu.remove();
      }
      //if we delete submenu, we should show inner circle in menu and all arrows
      if(that.parentMenu && that.parentMenu.innerId && e){        
        $(document).bind('mousemove', that.parentMenu, that.parentMenu.menuHover);
        $('#' + that.parentMenu.innerId).parent().addClass('zIndex900');
        for(var i = 0; i < that.parentMenu.items.length; i++){
            var item = that.parentMenu.items[i];
            item.showArrow();
        }  
      }
      //remove all arrows in current menu
      for(var i = 0; i < that.items.length; i++){
          var item = that.items[i];
          $('#' + item.arrowId).remove();
      }      
    }
    if(e){
      return false;
    }      
  };  
  
  this.getSelectedItemIndex = function(x, y){
    var selectedItemIndex = -1;    
    for(var i = 0; i < items.length ; i++){
      var item = items[i];
      if(item.virtuallyContains(x,y)){        
        selectedItemIndex = i;        
      }
    }
    return selectedItemIndex;
  };
  
  this.menuClick = function(e){
    var selectedItemIndex = e.data.getSelectedItemIndex(e.pageX, e.pageY);        
  };  
  
  this.contains = function(x, y){
    var R = parseInt(config.outerRadius);
    var c = (x - currentX) * (x - currentX) + (y - currentY) * (y - currentY) < R * R;
    return c || (this.submenu && this.submenu.contains(x, y));
  };
  
  this.menuHover = function(e){
    
    var that = e && e.data ? e.data : this;
    var selectedItemIndex = e.data.getSelectedItemIndex(e.pageX, e.pageY);    
    //console.log('menuHover x:' + e.pageX + ' y:' + e.pageY + ' i:' + selectedItemIndex);
    if(that.isInnerCircleHovered){
      selectedItemIndex = -1;
    }
    var noSubmenuShowed = !e.data.submenu || (e.data.submenu && !e.data.submenu.showed);
    if(currentSelectedIndex != selectedItemIndex && noSubmenuShowed){
      currentSelectedIndex = selectedItemIndex;
      $('div[id*=menuItem]').remove();
      $(document).unbind('click');
      if(selectedItemIndex > -1){        
        menuItemId = e.data.id + 'menuItem' + selectedItemIndex;
        $('<div id=' + menuItemId + '></div>').appendTo('body');        
        var jg = new jsGraphics(menuItemId);
        items[selectedItemIndex].drawFilled(jg, config.lineColor, config.selectedColor, config.textColor);
        if(items[selectedItemIndex].trigger){
          //$('#' + menuItemId + '>div').bind('click', items[selectedItemIndex].trigger);
          $(document).bind('click', items[selectedItemIndex].trigger);
        }
      }
    }
  };
  
  this.removeHighlight = function(e){
    $('div[id*=' + e.data.id + 'menuItem]').remove();
  };
  
  function drawOuterCircle(x, y){
    var X = x - config.outerRadius;
    var Y = y - config.outerRadius;    
    jg.drawImage("image/pie-circle.png", X, Y, config.outerRadius * 2, config.outerRadius * 2, 'id=' + id);    
  }
  
  function drawItems(x, y, that){    
    var itemsCount = config.items.length;
    if(!config.items[itemsCount - 1]){
      itemsCount -= 1;
    }
    var itemAngle = 360 / itemsCount;
    var R = config.outerRadius;
    var centerX = x - R;
    var centerY = y - R;        
    //lines
    var lines = [];
    var angles = [];
    var extLines = [];
    for(var i = 0; i < itemsCount; i++){
      var angle = itemAngle * (i);
      var ac = R * Math.sin(toRadians(angle));
      var bc = R * Math.cos(toRadians(angle));      
      var X = x + bc;
      var Y = y + ac;
      lines.push({ x: X, y: Y});
      
      var eR = R + 500;
      var eAC = eR * Math.sin(toRadians(angle));
      var eBC = eR * Math.cos(toRadians(angle));      
      var eX = x + eBC;
      var eY = y + eAC;
      extLines.push({ x: eX, y: eY});      
      
      angles.push(angle);
    }
    //populate items collection with objects and draw them
    for(var i = 0; i < itemsCount; i++){
      start = i;
      end = i + 1;
      if(end == itemsCount)
        end = 0;
      var sa = itemsCount - start - 1;
      var ea = itemsCount - end + 1;
      if(ea == itemsCount + 1){
        ea = 1;        
      }
      if(ea == itemsCount){
        ea = 0;
      }
      var startAngle = angles[sa];
      var endAngle = angles[ea];      
      j = itemsCount - i - 1;
      if(config.items[j]){
        var trigger = config.items[j].trigger ? config.items[j].trigger : (config.items[j].items ? showSubMenuTrigger({
          outerRadius: config.outerRadius,
          innerRadius: config.innerRadius,
          color: config.color,
          lineColor: config.lineColor,
          selectedColor: config.selectedColor,
          textColor: config.textColor,
          items: config.items[j].items
        }, that) : function(){});
        var visibility = config.items[j].items ? 'visible' : 'hidden';
        
        var startTextAngle = angles[start];
        var endTextAngle = angles[end];
        var item = new menuItem(x, y, lines[start], lines[end], extLines[end], extLines[start], R, startAngle, endAngle, itemAngle, config.items[j].title, trigger, startTextAngle, endTextAngle);
        item.arrowVisibility = visibility;
        if(itemsCount > 1){
          item.draw(jg, config.lineColor, config.textColor);
        }
        else{
          item.drawJustText(jg, config.textColor);
        }
        if(itemsCount == 2){
          item.index = i;
        }
        if(itemsCount == 1){
          item.isSingle = true;
        }
        items.push(item);
        that.items.push(item);
      }
    }
  }
  
  function showSubMenuTrigger(config, that){
    return function(e){ showSubMenu(e, config, that); }
  }
  
  
  function showSubMenu(e, subConfig, that){    
    $(document).unbind('mousemove', that.menuHover);
    that.submenu = new pieMenu(subConfig);
    that.submenu.show(e.pageX, e.pageY);    
    $('#' + that.innerId).parent().removeClass('zIndex900');
    that.submenu.parentMenu = that;
    for(var i = 0; i < that.items.length; i++){
      var item = that.items[i];
      if(that.submenu.contains(item.arrowX, item.arrowY)){
        item.hideArrow();
      }
    }
  }
  
  function drawInnerCircle(x, y, imageId){
    var X = x - config.innerRadius;
    var Y = y - config.innerRadius;    
    jg.drawImage("image/pie-innerCircle.png", X, Y, config.innerRadius * 2, config.innerRadius * 2, 'id=' + imageId);    
  }
  
  function uniqid()
    {
    var newDate = new Date;
    return newDate.getTime();
    }

}

var menuItem = function(centerX, centerY, p1, p2, extP1, extP2, R, startAngle, endAngle, itemAngle, title, trigger, startTextAngle, endTextAngle){
  var arrowId = "arrow" + startAngle + endAngle;
  var that = this;
  this.arrowId = arrowId;
  this.trigger = trigger;  
  
  this.draw = function(jg, color, textColor){    
    jg.setColor(color);
    if(!this.isSingle){
      jg.drawLine(centerX, centerY, p1.x, p1.y);
      jg.drawLine(centerX, centerY, p2.x, p2.y);
    }
    this.drawText(jg, centerX, centerY, R, startTextAngle, endTextAngle, itemAngle, title, textColor);
    this.drawArrow();
  };
  //called in case when itemsCount = 1
  this.drawJustText = function(jg, textColor){
    this.drawText(jg, centerX, centerY, R, startTextAngle, endTextAngle, itemAngle, title, textColor);
    this.drawArrow();
  };
  
  this.drawText = function(jg, centerX, centerY, R, startAngle, endAngle, itemAngle, title, textColor){
    var textR = R / 1.5;
    var textAngle = startAngle + itemAngle / 2;
    var ac = textR * Math.sin(toRadians(textAngle));
    var bc = textR * Math.cos(toRadians(textAngle));
    var textX = centerX - textR / 5  + bc;
    var textY = centerY - textR / 5 + ac;
    jg.setColor(textColor);
    if(textAngle < 45){
      textY += 12;
    }
    if(textAngle >= 45 && textAngle < 90){
      textY +=15;
    }
    if(textAngle >= 90 && textAngle <= 180){
      textY +=15;
      textX -=10;
    }
    if(textAngle > 180 && textAngle < 270){
      textX -= 8;
      textY -= 4;
    }
    if(textAngle >= 270 && textAngle < 360){
      textX += 4;
      textY += 2;
    }
    jg.drawString(title, textX, textY);
    //console.log(title + ' ' + textX + ' ' + textY + ' a:' + textAngle);
  }
  
  this.drawFilled = function(jg, color, bgColor, textColor){
    jg.setColor(bgColor);
    jg.fillArc(centerX - R, centerY - R, 2 * R, 2 * R, startAngle, endAngle);
    this.draw(jg, color, textColor);
    jg.paint();
  };
  
  this.drawArrow = function(){
    
    var img = $('#'+ arrowId);    
    if(img.size() == 0){
      $('body').append('<img src="image/pie-arrow.png" id="'+ arrowId +'" style="visibility:hidden;"/>');
    }    
    if(this.arrowVisibility == 'visible'){      
      var arrowR = R / 1.1;
      var arrowAngle = 360 - startAngle + itemAngle / 2 - itemAngle;
      var ac = arrowR * Math.sin(toRadians(arrowAngle));
      var bc = arrowR * Math.cos(toRadians(arrowAngle));
      var arrowX = centerX - 10 + bc;
      var arrowY = centerY - 10  + ac;      
      if(arrowAngle > 270)
        arrowAngle = arrowAngle - 360;      
      $('#'+ arrowId).rotate(arrowAngle + 90, true);
      $('#'+ arrowId).attr("style", "visibility:" + this.arrowVisibility + ";z-index:900;position:absolute;top:" + arrowY + ";left:" + arrowX);
      that.arrowX = arrowX;
      that.arrowY = arrowY;
    }
  };
  
  this.hideArrow = function(){
    $('#'+ arrowId).hide();
  };
  
  this.showArrow = function(){
    $('#'+ arrowId).show();
  };
  
  this.contains = function(x, y){      
    p = {x: x, y: y};
    c = {x: centerX, y: centerY};
    //p1
    //p2
    var cR = R + 10;
    if(this.isSingle){
      return !(Math.abs(c.x - x) > cR || Math.abs(c.y - y) > cR);
    }
    if(c.y == p1.y && p1.y == p2.y){        
      var upper = this.index == 0 && y > c.y && Math.abs(y - c.y) < cR;
      var down = this.index == 1 && y < c.y && Math.abs(y - c.y) < cR;
      return upper || down;
    }
    var s = square(c, p1, p2);
    var a = square(c, p1, p);
    var b = square(c, p, p2);
    var d = square(p, p1, p2);      
    return Math.abs((a + b + d) - s) < 0.05;
  };  
  
  this.virtuallyContains = function(x, y){
    p = {x: x, y: y};
    c = {x: centerX, y: centerY};
    //extP1
    //extP2
    var eR = R + 500;
    if(this.isSingle){
      return !(Math.abs(c.x - x) > eR || Math.abs(c.y - y) > eR);
    }    
    if(Math.abs(c.y - extP1.y) < 0.0005 && Math.abs(extP1.y - extP2.y) < 0.0005){
      //debugger;
      var upper = this.index == 0 && y > c.y && Math.abs(y - c.y) < eR;
      var down = this.index == 1 && y < c.y && Math.abs(y - c.y) < eR;
      return upper || down;
    }
    var s = square(c, extP1, extP2);
    var a = square(c, extP1, p);
    var b = square(c, p, extP2);
    var d = square(p, extP1, extP2);
    //console.log(Math.abs((a + b + d) - s));
    return Math.abs((a + b + d) - s) < 0.05;
  };
  
  function left(x, y, p1){
    var a = { 
      x: centerX - x,
      y: centerY - y
    };
    var b = {
      x: centerX - p1.x,
      y: centerY - p1.y
    }
    return a.x * b.y - b.x * a.y;
  }
  
  function square(a, b, c){
    return Math.abs(a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
  }
  
}

  function toRadians(degree){
    var yo=(2*Math.PI)/360;
    return yo * degree;
  }