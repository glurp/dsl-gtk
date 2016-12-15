# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
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
       on_canvas_draw { |w,ctx| w.expose(w,ctx) }
       on_canvas_button_press { |w,event| w.track(event)}
     end
     def plot.config(c) @config=c end
     plot.config(config.merge({w: width,h:height}))
     def plot.add_curve(name,config) 
        c=config.dup
        c[:type] = :curve
        c[:data] ||= [[0,0],[100,100]]
        c[:maxlendata] ||= c[:data].size
        c[:color] ||= "#003030"
        c[:rgba] = ::Gdk::Color.parse(c[:color])
        c[:xminmax] ||= [c[:data].first[1],c[:data].last[1]]
        c[:yminmax] ||= [0,100]
        c[:style] ||= :linear
        c[:xa] = 1.0*width_request/(c[:xminmax][1]-c[:xminmax][0])
        c[:xb] = 0.0    -c[:xminmax][0]*c[:xa]
        c[:ya] = 1.0*height_request/(c[:yminmax][0]-c[:yminmax][1])
        c[:yb] = 0.0-c[:yminmax][1]*c[:ya]
        @curves[name]=c
     end
     def plot.add_bar(name,values)
        c={type: :bar,data:values, xmin: values.first.first , xmax: values.last.first}
        @curves[name]=c
     end
     def plot.delete_curve(name) 
        @curves.delete(name)
        redraw
     end
     def plot.expose(w,ctx) 
        return unless @curves
        w.draw_rectangle(0,0,@config[:w],@config[:h],0,@config[:bg],@config[:bg],0) if @config[:bg]
        if @config[:grid] 
          dx=dy=(@config[:grid]||"40").to_i
          color=@config[:grid_color] || "#AAA"
          0.step(width_request,dx) {|x| 
            w.draw_line([x,0,x,height_request],color,1) 
          }
          0.step(height_request,dy) {|y|
            w.draw_line([0,y,width_request,y],color,1)           
          }
        end
        yb0=3
        @curves.values.each do |c|
              next if c[:data].size<2
              case c[:type] 
              when :curve
                  l=c[:data].each_with_object([]) { |(y,x),a|  
                    a << x*c[:xa]+c[:xb] ; a <<  y*c[:ya]+c[:yb] 
                  }
                  w.draw_line(l,c[:color],2)
              when :bar
                 w.draw_varbarr(0,@config[:h]-yb0,@config[:w],@config[:h]-yb0,c[:xmin],c[:xmax],c[:data],5)
                 yb0+=5
              end
        end
        if @tx && @track_text
           w.draw_text_center(width_request/2,20,"Date: #{@track_title}",1.3,"#FFF","#000")
           w.draw_line([@tx,0,@tx,height_request],"#FFF",1)
           dx=(@tx<(width_request-70)) ? 10 : -10
           @track_text.each do |name,text,h,ht|
              w.draw_line([@tx,h,@tx+dx,ht],@curves[name][:color],1)
              if dx>0 
                w.draw_text(@tx+dx,ht,text,1,@curves[name][:color],"#000")
              else
                w.draw_text_left(@tx+dx,ht,text,1,@curves[name][:color],"#000")
              end
           end
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
       @curves[name][:data]=if @curves[name][:data].size>=len
        @curves[name][:data][-len..-1] 
       else
        @curves[name][:data]
       end
     end
     def plot.track(event)
      return unless @config[:tracker]
      x=nil
      lt=@curves.each_with_object([]) {|(name,d),a|
        next unless d[:type]==:curve
        x=(event.x-d[:xb])/d[:xa]
        y=psearch(d[:data],x)
        h=y*d[:ya]+d[:yb]
        a << [name,@config[:tracker][1].call(name,y) || "",h,(h>30) ? (h-10) : (h+10)]
      }
     50.times {
        t=false
        lt.each_with_index {|a,ia| h=a[3]
          ld=lt.each_with_index.select {|(n,t,h0,hh),ii| ii!=ia && (h-hh).abs<8}
          if ld.size>0
            ref=lt.each_with_object(0) {|(n,t,h0,hh),sum| sum+=(h-hh)}/ld.size
            moin=a[3]<20
            delta=(h-ref<0.1)? rand(h-2..h+2) : ((h-ref) > 0) ?  2 : -2 
            a[3]= [0,a[3]+delta,height_request].sort[1]
            t=true
            break 
          end
        }
        break unless t
      }
      @tx,@track_text,@track_title=event.x,lt,@config[:tracker][0].call(x)
     end
     def plot.psearch(lxy,x)
       imin,imax=0,(lxy.size-1)
       while imin<imax
          i= (imin+imax)/2
          vi=lxy[i][1]
          if vi<x
            imin=i+1
          elsif vi>x
            imax=i-1
          else
            return(lxy[i][0])
          end
       end
       return lxy[i][0]
     end

     def plot.init() @curves,@tx,@track_text={},nil,nil  end
     plot.init
     curves.each { |name,descr|  ; plot.add_curve(name,descr) }
     plot
  end
end