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
  # for drawing in canvas, this commands are usable.
  # basic gtk commands can still be uses ( move_to(), line_to()... )
  # def myDraw(w,ctx)
  #     w.init_ctx(color_fg="#000000",color_bg="#FFFFFF",width=1)
  #     w.draw_point(x1,y1,color,width)
  #     w.draw_polygon([x,y,...],colorFill,colorStroke,widthStroke)
  #     w.draw_circle(cx,cy,rayon,colorFill,colorStroke,widthStroke)
  #     w.draw_rectangle(x0,y0,w,h, r,widthStroke,colorFill,w)
  #     cv.draw_rounded_rectangle(x0,y0,w,h,ar,colorStroke,colorFill,widthStroke)
  #     w.draw_pie(x,y,r,l_ratio_color_label)
  #     w.draw_arc(x,y,r,start,eend,width,color_stroke,color_fill=nil) # camenber
  #     w.draw_arc2(x,y,r,start,eend,width,color_stroke,color_fill=nil) # circle fraction
  #     w.draw_varbarr(x0,y0,x1,y1,vmin,vmax,l_date_value,width) {|value| color}
  #     w.draw_image(x,y,filename,sx,sy)
  #     cv.ctx_font(name,size)        # choose font name and size for next draw_text...
  #     w.draw_text(x,y,text,scale,color,bgcolor=nil)
  #     w.draw_text_left(x,y,text,scale,color,bgcolor=nil)
  #     w.draw_text_center(x,y,text,scale,color,bgcolor=nil)
  #     lxy=w.translate(lxy,dx=0,dy=0) # move a list of points
  #     lxy=w.rotate(lxy,x0,y0,angle)  # rotate a list of points
  #     cv.rotation(cx,cy,a) { draw... }
  #     w.scale(10,20,2) { w.draw_image(3,0,filename) } 
  #                   >> draw in a transladed/scaled coord system
  #                   >> image will be draw at 16/20 (10+3*2)/(20+0*2)
  #                      , and size doubled
  # 
  # end
  # gradient can be use for recangle and polygone, see samples/gradients.rb
  # in place od String bg-color, say Array : #w{type direction color1 color2 ...}
  # type = linear/radial direction : tb Top->Bottom, bu Bottom->Up , lr: Left->Right, ..., trb -> TopLeft -> BottomRight 

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
    def cv._set_gradient(cv,cr,acolor,lxy)
      type,sens,*data=acolor
      return unless type && sens && data && data.size>=2
      cr.set_source_rgba(*Ruiby_dsl.cv_color_html("#FFF"))
      if type =~ /^g/
        x0,y0,x1,y1=*bbox(lxy)
        case sens
          when "tb" then x0,y0,x1,y1 = x1/2,y0,  x1/2,y1
          when "bu" then x1,y1,x0,y0 = x1/2,y0,  x1/2,y1
          when "lr" then x0,y0,x1,y1 = 0,y1/2,   x1,y1/2
          when "rl" then x0,y0,x1,y1 = x1,y1/2,  x0,y1/2
          when "trb" then x0,y0,x1,y1 = x0,y0,   x1,y1
          when "tlb" then x0,y0,x1,y1 = x1,y0,   x0,y1
          else
            error("unknown gradient : #{sens}")
        end
        #p [sens,x0,y0,x1,y1]
        pattern = Cairo::LinearPattern.new(x0,y0,x1,y1)
        last_color="#000"
        data.each_with_index {|color,i|
            pos= 1.0*i/(data.length-1)
            #p [pos,Ruiby_dsl.cv_color_html(color)]
            color=last_color if color=="-"
            last_color=color
            pattern.add_color_stop(pos, *(Ruiby_dsl.cv_color_html(color)[0..2]))
         }
         cr.set_source(pattern)
      else
      end
    end
    def cv.bbox(lxy)
      xmin,ymin=lxy[0..1]
      xmax,ymax=lxy[0..1]
      lxy.each_slice(2) {|x,y| 
        xmin=x if x<xmin ;ymin=y if y<ymin 
        xmax=x if x>xmax ;ymax=y if y>ymax 
      }
      [xmin,ymin,xmax,ymax]
    end
    def cv._draw_poly(lxy,color_fg,color_bg,width)
        raise("odd number of coord for lxy") if !lxy || lxy.size==0 || lxy.size%2==1
        w,cr=@currentCanvasCtx
        cr.set_line_width(width) if width
        x0,y0,*poly=*lxy
        if color_bg
          cr.move_to(x0,y0)
          poly.each_slice(2) {|x,y| cr.line_to(x,y) } 
          if Array === color_bg
            _set_gradient(w,cr,color_bg,lxy)
          else
             cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color_bg))
          end
          cr.fill
        end
        if color_fg
          #p lxy
          cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color_fg))
          cr.move_to(x0.round,y0.round)
          poly.each_slice(2) {|x,y| cr.line_to(x.round,y.round) } 
          cr.stroke()  
        end
    end
    def cv.draw_point(x,y,color=nil,width=nil)
      width||=@currentWidth
      draw_line([x,y-width/2.0, x,y+width/2.0],color,width)
    end
    def cv.draw_varbarr(x0,y0,x1,y1,dmin,dmax,lvalues0,width,&b)
      ax=1.0*(x1-x0)/(dmax-dmin) ;bx= x0-ax*dmin 
      ay=1.0*(y1-y0)/(dmax-dmin) ;by= y0-ay*dmin 
      xconv=proc {|d| (x1==x0) ? x1 :  (ax*d+bx) }
      yconv=proc {|d| (y1==y0) ? y1 :  (ay*d+by) }
      w,cr=@currentCanvasCtx
      lvalues=lvalues0.sort_by {|a| a.first}
      l=[lvalues.first]+lvalues.each_cons(2).map {|(d,v),(d1,v1)|
        (v1 && v!=v1) ? [d1,v1] : nil 
      }.compact+[lvalues.last]
      #p l
      cr.set_line_join(Cairo::LINE_JOIN_MITER)
      cr.set_line_cap(Cairo::LINE_CAP_BUTT)
      l.each_cons(2).map {|(d,v),(d1,v1)| 
        next unless v1
        color=  block_given? ? yield(v) : v.to_s
        lxy=[xconv.call(d),yconv.call(d),xconv.call(d1),yconv.call(d1)]
        #p "   #{d},#{d1} ==> #{lxy.inspect}" if l.size>1
        w.draw_line(lxy,color, width) if color
      }
    end 
    def cv.ctx_font(name,size)
      w,cr=@currentCanvasCtx
      fd=Pango::FontDescription.new(name)
      cr.select_font_face(fd.family, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
      cr.set_font_size(size)
    end
    def cv.draw_text(x,y,text,scale=1,color=nil,bgcolor=nil)
      w,cr=@currentCanvasCtx
      cr.set_line_width(1)
      cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
      scale(x,y,scale) {  
        if bgcolor
          a=cr.text_extents(text)
          w.draw_rectangle(0,1,a.width,-a.height,1,bgcolor,bgcolor,0)
          cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
        end
        cr.move_to(0,0)
        cr.show_text(text) 
        cr.fill
      }
    end
    
    def cv.draw_text_left(x,y,text,scale=1,color=nil,bgcolor=nil)
      w,cr=@currentCanvasCtx
      cr.set_line_width(1)
      cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
      scale(x,y,scale) {  
        a=cr.text_extents(text)
        if bgcolor
          w.draw_rectangle(-a.width,-a.height,a.width,a.height+2,1,bgcolor,bgcolor,1)
          cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
        end
        cr.move_to(-a.width,0)
        cr.show_text(text) 
        cr.fill
      }
    end
    def cv.draw_text_center(x,y,text,scale=1,color=nil,bgcolor=nil)
      w,cr=@currentCanvasCtx
      cr.set_line_width(1)
      cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
      scale(x,y,scale) {  
        a=cr.text_extents(text)
        if bgcolor
          w.draw_rectangle(-a.width/2,-1,a.width,-a.height-3,1,bgcolor,bgcolor,1)
          cr.set_source_rgba(*Ruiby_dsl.cv_color_html(color || @currentColorFg ))
        end
        cr.move_to(-a.width/2.0,0)
        cr.show_text(text) 
        cr.fill
      }
    end
    def cv.draw_rectangle(x0,y0,w,h,r=0,colorStroke=nil,colorFill=nil,widthStroke=nil)
      return draw_rounded_rectangle(x0,y0,w,h,r,colorStroke,colorFill,widthStroke) if r.kind_of?(Array) || r>1
      x1, y1 = x0+w, y0+h
      colorStroke=@currentColorFg if colorFill.nil? && colorStroke.nil?
      _draw_poly([x0,y0, x1,y0, x1,y1, x0,y1, x0,y0],colorStroke,colorFill,widthStroke)
    end
    def cv.draw_rounded_rectangle(x0,y0,w,h,ar,colorStroke,colorFill,widthStroke)
      cv,cr=@currentCanvasCtx
      pi=Math::PI
      ar=[ar,ar,ar,ar] if ar.kind_of?(Numeric)
      if Array === colorFill
        _set_gradient(w,cr,colorFill,[x0,y0,x0+w,y0+h])
      else
        cr.set_source_rgba(*Ruiby_dsl.cv_color_html(colorFill ? colorFill : colorStroke))
      end
      cr.set_line_width( widthStroke )
      r=ar[0]
      cr.move_to(x0,y0+r)
      cr.arc(x0+r,y0+r, r, -pi,-pi/2)
      r=ar[1]
      cr.line_to(x0+w-r,y0)
      cr.arc(x0+w-r,y0+r, r, -pi/2, 0)
      r=ar[2]
      cr.line_to(x0+w,y0+h-r)
      cr.arc(x0+w-r,y0+h-r, r, 0, pi/2)
      r=ar[3]
      cr.line_to(x0+r,y0+h)
      cr.arc(x0+r,y0+h-r, r, pi/2,pi)
      r=ar[0]
      cr.line_to(x0,y0+r)
      colorFill ? cr.fill : cr.stroke
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
    def cv.draw_pie(x0,y0,r,l_ratio_color_txt,with_legend=false)
      lcolor=%w{#F00 #A00 #AA0 #AF0 #AAF #AAA #FAF #AFA #33F #044}
      cv,ctx=@currentCanvasCtx
      start=3.0*Math::PI/2.0
      total=l_ratio_color_txt.inject(0.0) { |sum,(a)| sum+a }
      h0=y0-r
      p0=x0+r*1.2
      l_ratio_color_txt.each_with_index { |(sweep0,coul,text),i|
        coul=lcolor[i%lcolor.size] unless coul
        sweep=sweep0/total
        eend=start+Math::PI*2.0*sweep
        mid=(eend+3*start)*0.25
        if !with_legend && sweep>0.11 && r>=20 && text && text.size>0
          dx=(mid>(Math::PI/2+Math::PI/4) && mid < Math::PI*3/2) ? text.size*7 : 0
          cv.draw_line([x0,y0,x0+1.4*r*Math.cos(mid),y0+1.4*r*Math.sin(mid)],"#000",1)
          cv.draw_text(x0+1.4*r*Math.cos(mid)-dx,y0+1.4*r*Math.sin(mid),text,1,coul)
        end
        if with_legend && text && text.size>0 && h0<y0+r
          draw_rectangle(p0,h0,20,8,0,"#000",coul,1)
          draw_text(p0+30,h0+10,text,1,"#000")
          draw_text(p0+70,h0+10,": #{sweep0}",1,"#000")
          h0+=10
        end
        ctx.move_to(x0,y0)
        ctx.line_to(x0+r*Math.cos(start),y0+r*Math.sin(start)) 	
        ctx.arc( x0,y0, r, start, eend );
        ctx.close_path
        ctx.set_line_width( 1.0 )
        ctx.set_source_rgba(*Ruiby_dsl.cv_color_html(coul))
        ctx.fill
        #ctx.set_source_rgba(*Ruiby_dsl.cv_color_html("#000"))
        #ctx.stroke
        start=eend
      }
    end
    def cv.draw_arc2(x,y,r,start,eend,width,color_stroke,color_fill=nil)
      w,ctx=@currentCanvasCtx
      ctx.set_line_width( width )
      ctx.set_source_rgba(*Ruiby_dsl.cv_color_html(color_fill ? color_fill : color_stroke))
      ctx.arc( x,y, r, Math::PI*2.0*start, Math::PI*2.0*eend );
      color_fill ? ctx.fill : ctx.stroke
    end
    def cv.draw_arc(x,y,r,start,eend,width,color_stroke,color_fill=nil)
      w,ctx=@currentCanvasCtx
      ctx.set_line_width( width )
      ctx.set_source_rgba(*Ruiby_dsl.cv_color_html(color_fill ? color_fill : color_stroke))
      ctx.move_to(x,y)
      ctx.arc( x,y, r, Math::PI*2.0*start, Math::PI*2.0*eend );
      ctx.close_path
      color_fill ? ctx.fill : ctx.stroke
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
     cr.rotate(Math::PI*2.0*a)
     blk.call rescue Message.error $!
     cr.rotate(-Math::PI*2.0*a)
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
    @currentCanvas.signal_connect('button-press-event')   { |w,e| 
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
        cr.set_line_join(Cairo::LINE_JOIN_ROUND)
        cr.set_line_cap(Cairo::LINE_CAP_ROUND)
        cr.set_line_width(2)
        cr.set_source_rgba(1,1,1,1)
        cr.paint
        begin
           w.instance_eval { @currentCanvasCtx=[w,cr] }
           blk.call(w,cr) 
           w.set_memo(false)
           #w.instance_eval { @currentCanvasCtx=nil }
        rescue Exception => e
         ( after(1) { error(e) } ) if w.get_memo()!=true
         w.draw_text(5,20,"Canvas ERROR...",1,"#EEE","#000")
         w.draw_text(5,30,e.to_s,1,"#EEE","#000")
         w.set_memo(true)
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
end

