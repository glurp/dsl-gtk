# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
  
  # Create a drawing area, for pixel/vectoriel draw
  # for interactive actions see test.rb fo little example.
  #
  # @cv=canvas(width,height,opt) do
  #    on_canvas_draw { |w,ctx|  myDraw(w,ctx) }
  #    on_canvas_button_press {|w,e|  [e.x,e.y]  } # must return a object which will given to next move/release callback
  #    on_canvas_button_motion {|w,e,o| n=[e.x,e.y] ; ... ; n }
  #    on_canvas_button_release {|w,e,o| ... }
  #    on_canvas_keypress       {|w,key| ... }
  # end
  #
  # for drawing in canvas, this commands are offered.
  # basic gtk comands can be uses to ( move_to(), line_to()... )
  # def myDraw(w,ctx)
  #     w.init_ctx
  #     w.draw_line([x1,y1,....],color,width)
  #     w.draw_point(x1,y1,color,width)
  #     w.draw_polygon([x,y,...],colorFill,colorStroke,widthStroke)
  #     w.draw_circle(cx,cy,rayon,colorFill,colorStroke,widthStroke)
  #     w.draw_rectangle(x0,y0,w,h,r,widthStroke,colorFill,colorStroke)
  #     w.draw_image(x,y,filename)
  #     w.draw_text(x,y,text,scale,color)
  #     lxy=w.translate(lxy,dx=0,dy=0) # move a list of points
  #     lxy=w.rotate(lxy,x0,y0,angle)  # rotate a list of points
  #     w.scale(10,20,2) { w.draw_image(3,0,filename) } # draw in a transladed/scaled coord system
  #                          >> image with be draw at 16,20, and his size doubled
  # end

  def canvas(width,height,option={})
    autoslot()
    cv=DrawingArea.new()
    cv.width_request=width
    cv.height_request=height
    cv.add_events(Gdk::EventMask::BUTTON_PRESS_MASK  | Gdk::EventMask::BUTTON_MOTION_MASK | Gdk::EventMask::KEY_PRESS_MASK)
    cv.can_focus = true
    @currentCanvas=cv
    @lcur << HandlerContainer.new
    yield
    @lcur.pop
    @currentCanvas=nil

    attribs(cv,option) 
    def cv.set_memo(memo) @memo=memo end
    def cv.get_memo() @memo end
    cv.set_memo(nil)    
    
    def cv.redraw() 
      self.queue_draw_area(0,0,self.allocation.width,self.allocation.height)
    end
    def cv.app_window()  @app_window end
    def cv.set_window(r) @app_window=r end
    cv.set_window(self)
    def cv.init_ctx(color_fg="#000000",color_bg="#FFFFFF",width=1)
        w,cr=*@currentCanvasCtx 
        cr.set_line_join(Cairo::LINE_JOIN_ROUND)
        cr.set_line_cap(Cairo::LINE_CAP_ROUND)
        cr.set_line_width(width)
        cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color_bg))
        cr.paint
        #cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color_fg))
        @currentWidth=width
        @currentColorFg=color_fg
        @currentColorBg=color_bg
    end
    
    def cv.draw_line(lxy,color=nil,width=nil) 
        raise("odd number of coord for lxy") if !lxy || lxy.size==0 || lxy.size%2==1
        if lxy.size==2 
          return draw_point(lxy.first,lxy.last,color,width)
        end
        _draw_poly(lxy,color|| @currentColorFg,nil,width)
    end
    def cv.draw_polygon(lxy,colorStroke=nil,colorFill=nil,widthStroke=nil)
        raise("odd number of coord for lxy") if !lxy || lxy.size==0 || lxy.size%2==1
        if lxy.size==2 
          return draw_point(lxy.first,lxy.last,colorStroke,widthStroke)
        end
       colorStroke=@currentColorFg if colorFill.nil? && colorStroke.nil?
        _draw_poly(lxy,colorStroke,colorFill,widthStroke)
    end
    def cv._draw_poly(lxy,color_fg,color_bg,width)
        raise("odd number of coord for lxy") if !lxy || lxy.size==0 || lxy.size%2==1
        w,cr=@currentCanvasCtx
        cr.set_line_width(width) if width
        x0,y0,*poly=*lxy
        if color_bg
          cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color_bg))
          cr.move_to(x0,y0)
          poly.each_slice(2) {|x,y| cr.line_to(x,y) } 
          cr.fill
        end
        if color_fg
          cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color_fg))
          cr.move_to(x0,y0)
          poly.each_slice(2) {|x,y| cr.line_to(x,y) } 
          cr.stroke  
        end
    end
    def cv.draw_point(x,y,color=nil,width=nil)
      width||=@currentWidth
      draw_line([x,y-width/4, x,y+width/4],color,width)
    end
    def cv.draw_text(x,y,text,scale=1,color=nil)
      w,cr=@currentCanvasCtx
      cr.set_line_width(1)
      cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
      scale(x,y,scale) {  cr.move_to(0,0); cr.show_text(text) }
    end
    def cv.draw_rectangle(x0,y0,w,h,r=0,colorStroke=nil,colorFill=nil,widthStroke=nil)
      x1, y1 = x0+w, y0+h
      colorStroke=@currentColorFg if colorFill.nil? && colorStroke.nil?
      _draw_poly([x0,y0, x1,y0, x1,y1, x0,y1, x0,y0],colorStroke,colorFill,widthStroke)
    end
    def cv.draw_circle(x0,y0,r,color_bg=nil,color_fg=nil,width=nil)
        w,cr=@currentCanvasCtx
        cr.set_line_width(width || @currentWidth )
        if color_bg
          color=Ruiby_dsl.html_color(color_bg)
          cr.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, 1)
          cr.arc(x0,y0, r, width || @currentWidth , 3.0*Math::PI)
          cr.fill
        end
        if color_fg
          color=Ruiby_dsl.html_color(color_fg)
          cr.set_source_rgba(color.red/65000.0, color.green/65000.0, color.blue/65000.0, 1)
          cr.arc(x0,y0, r, 0 , 3.0*Math::PI)
          cr.stroke
        end
    end
    def cv.draw_image(x,y,filename,sx=1,sy=sx)
      w,cr=@currentCanvasCtx
      pxb=w.app_window.get_pixbuf(filename)
      scale(x,y,sx,sy) { cr.set_source_pixbuf(pxb,0,0) ; cr.paint}
      [pxb.width,pxb.height]
    end
    # draw in scale factor
    # scale(20,100,2,4) { w.draw_line(10,10,20,20) ; ... } 
    # the line will be scaling by x/y factor 2 and 4 relative to center
    # point x=10 y=100
    def cv.scale(cx,cy,ax,ay=nil,&blk)
     ay=ax unless ay
     w,cr=@currentCanvasCtx
     cr.translate(cx,cy)
     cr.scale(ax,ay)
     blk.call rescue Message.error $!
     cr.scale(1.0/ax,1.0/ay)
     cr.translate(-cx,-cy)
    end
    def cv.rotation(cx,cy,a,&blk) 
     w,cr=@currentCanvasCtx
     cr.translate(cx,cy)
     cr.rotate(a)
     blk.call rescue Message.error $!
     cr.rotate(-a)
     cr.translate(-cx,-cy)
    end
    def cv.translate(lxy,dx=0,dy=0) 
      lxy.each_slice(2).inject([]) {|l,(x,y)| l <<x+dx; l <<y+dy}
    end
    def cv.rotate(lxy,x0,y0,angle)
      sa,ca=Math.sin(angle),Math.cos(angle)
      lxy.each_slice(2).inject([]) {|l,(x,y)| l << ((x-x0)*ca-(y-y0)*sa)+x0 ; l << ((x-x0)*sa+(y-y0)*ca)+y0}
    end
    cv
  end
  
  # update a canvas
  def force_update(canvas) canvas.queue_draw unless  canvas.destroyed?  end
  
  # define action on button_press
  # action must return an object whici will be transmit to motion/release handler
  def on_canvas_button_press(&blk)
    _accept?(:handler)
    @currentCanvas.signal_connect('button_press_event')   { |w,e| 
      ret=w.set_memo(blk.call(w,e))  rescue error($!)
      force_update(w) 
      ret
    }  
  end
  def on_canvas_resize(&blk)
    _accept?(:handler)
    @currentCanvas.signal_connect('configure_event')   { |w,e| 
      ret=blk.call(w,e.width,e.height)  rescue error($!)
      force_update(w) 
      ret
    }  
  end
  # define action on mouse button press on current canvas definition
  def on_canvas_button_release(&blk)
    _accept?(:handler)
    @currentCanvas.signal_connect('button_release_event') { |w,e| 
      ret=blk.call(w,e,w.get_memo) rescue error($!)
      w.set_memo(nil)
      force_update(w) 
      ret
    }  
  end
  # define action on mouse button motion on current canvas definition
  def on_canvas_button_motion(&blk )
    _accept?(:handler)
    @currentCanvas.signal_connect('motion_notify_event')  { |w,e| 
      next unless w.get_memo()
      w.set_memo(blk.call(w,e,w.get_memo)) rescue error($!)
      force_update(w)
    }
  end
  # define action on  keyboard press on current **window** definition
  def on_canvas_key_press(&blk)
    _accept?(:handler)
    p "signal key press"    
    @currentCanvas.signal_connect('key_press_event')  { |w,e| 
      p "signal key press  ok #{e}"    
      blk.call(w,e,Gdk::Keyval.to_name(e.keyval)) rescue error($!)
      force_update(w) 
    }
  end
  
  # define the drawing on current canvas definition
  def on_canvas_draw(&blk)
    _accept?(:handler)
    @currentCanvas.signal_connect(  'draw' ) do |w,cr| 
      cr.save do
        cr.set_line_join(Cairo::LINE_JOIN_ROUND)
        cr.set_line_cap(Cairo::LINE_CAP_ROUND)
        cr.set_line_width(2)
        cr.set_source_rgba(1,1,1,1)
        cr.paint
        begin
           w.instance_eval { @currentCanvasCtx=[w,cr] }
           blk.call(w,cr) 
           w.instance_eval { @currentCanvasCtx=nil }
        rescue Exception => e
         after(1) { error(e) }
        end  
      end
    end
  end  

  # DEPRECATED; Create a drawing area, for pixel draw
  # option can define closure :mouse_down :mouse_up :mouse_move
  # for interactive actions
  def canvasOld(width,height,option={})
    puts "*** DEPRECATED: use canvas do end in place of canvasOld ***"
    autoslot()
    w=DrawingArea.new()
    w.width_request=width
    w.height_request=height
    w.events |=  ( ::Gdk::EventMask::BUTTON_PRESS_MASK | ::Gdk::EventMask::POINTER_MOTION_MASK | ::Gdk::EventMask::BUTTON_RELEASE_MASK)

    w.signal_connect(  'draw' ) { |w1,cr| 
      cr.save {
        cr.set_line_join(Cairo::LINE_JOIN_ROUND)
        cr.set_line_cap(Cairo::LINE_CAP_ROUND)
        cr.set_line_width(2)
        cr.set_source_rgba(1,1,1,1)
        cr.paint
        if option[:expose]
          begin
            option[:expose].call(w1,cr) 
          rescue Exception => e
           bloc=option[:expose]
           option.delete(:expose)
           after(1) { error(e) }
           after(3000) {  puts "reset expose bloc" ;option[:expose] = nil }
          end  
        end
      }
    }
    @do=nil
    w.signal_connect('button_press_event')   { |wi,e| @do = option[:mouse_down].call(wi,e)  rescue error($!)              ; force_update(wi) }  if option[:mouse_down]
    w.signal_connect('button_release_event') { |wi,e| (option[:mouse_up].call(wi,e,@do)  rescue error($!)) if @do ; @do=nil ; force_update(wi) if @do }  if option[:mouse_up]
    w.signal_connect('motion_notify_event')  { |wi,e| (@do = option[:mouse_move].call(wi,e,@do) rescue error($!)) if @do     ; force_update(wi) if @do }  if option[:mouse_move]
    w.signal_connect('key_press_event')  { |wi,e| (option[:key_press].call(wi,e) rescue error($!)) ; force_update(wi) }  if option[:key_press]
    attribs(w,option) 
    def w.redraw() 
      self.queue_draw_area(0,0,self.width_request,self.height_request)
    end
    w
  end
  
  #  define a plot zone, with several curves :
  #  pl=plot(400,200,{
  #      "curve1" => {
  #         data:[[0,1],[110,1],[20,1],[30,1],[10,1],[22,1],[55,1],[77,1]],
  #         color: '#FF0000', xminmax:[0,100], yminmax:[0,100], style: :linear,},...})
  #  }
  #
  # this methods are added :
  # * pl.set_data(name,data) : replace current values par a new list of point [ [y,x],....] for curve named 'name'
  # * pl.get_data(name) 
  # * pl.add_curve(name,{data:...}) : add a curve
  # * pl.delete_curve(name) : delete a curve  
  # * pl.add_data(name,pt)  : add a point at the end of the curve
  # * pl.scroll_data(name,value)  : add a point at last and scroll if necessary (act as oscilloscope)
  # see samples/plot.rb
  def plot(width,height,curves,config={})
     plot=canvas(width,height) do
       on_canvas_draw { |w,ctx| w.expose(ctx) }
       on_canvas_button_press { |w,event| }
     end
     def plot.add_curve(name,config) 
        c=config.dup
        c[:data] ||= [[0,0],[100,100]]
        c[:maxlendata] ||= 100
        c[:color] ||= "#003030"
        c[:xminmax] ||= [c[:data].first[1],c[:data].last[1]]
        c[:yminmax] ||= [0,100]
        c[:style] ||= :linear
        c[:xa] = 1.0*width_request/(c[:xminmax][1]-c[:xminmax][0])
        c[:xb] = 0.0    -c[:xminmax][0]*c[:xa]
        c[:ya] = 1.0*height_request/(c[:yminmax][0]-c[:yminmax][1])
        c[:yb] = 1.0*height_request+c[:yminmax][0]*c[:xa]
        @curves||={}
        @curves[name]=c
     end
     def plot.delete_curve(name) 
        @curves.delete(name)
        redraw
     end
     def plot.expose(ctx) 
        @curves.values.each do |c|
              next if c[:data].size<2
              l=c[:data].map { |(y,x)|  [x*c[:xa]+c[:xb] , y*c[:ya]+c[:yb] ]  }
              coul=c[:rgba]
              ctx.set_source_rgba(coul.red,coul.green,coul.blue)
              ctx.move_to(*l[0])
              l[1..-1].each { |pt| ctx.line_to(*pt) }
              ctx.stroke
        end
     end
     
     def plot.set_data(name,data) 
       @curves[name][:data]=data
       maxlen(name,@curves[name][:maxlendata])
       redraw
     end
     def plot.get_data(name) 
       @curves[name][:data]
     end
     def plot.add_data(name,pt) 
       @curves[name][:data] << pt
       maxlen(name,@curves[name][:maxlendata])
       redraw
     end
     def plot.scroll_data(name,value) 
        l=@curves[name][:data]
        pas=width_request/l.size
        l.each { |pt| pt[1]-=pas } 
        l << [ value , @curves[name][:xminmax].last ]
        maxlen(name,@curves[name][:maxlendata])
        redraw
     end
     def plot.maxlen(name,len)
       @curves[name][:data]=@curves[name][:data][-len..-1] if @curves[name][:data].size>len
     end
     curves.each { |name,descr| descr[:rgba]=color_conversion(descr[:color]||'#303030') ; plot.add_curve(name,descr) }
     plot
  end
end

