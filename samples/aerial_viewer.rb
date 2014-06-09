# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
####################################################################################
#   aerial_viewer.rb :  Mapbox  photo viewer,caching tiles in temporary directory
#
#   WARNNG!! : I don't know if layer geoeye.map is public in Mapbox  ...
#
####################################################################################
# Usage : 
#    > ruby aerial_viewer.rb [zoomLevel [lon lat]]
####################################################################################
require_relative '../lib/Ruiby'
require 'open-uri'
#$URLTILES='http://otile4.mqcdn.com/tiles/1.0.0/osm/ZOOM/LON/LAT.jpg'
 $URLTILES='http://b.tiles.mapbox.com/v3/geoeye.map-cjxgqnhb/ZOOM/LON/LAT.png'
 
$SHOW_TILES_BORDER=false

######################################### Tiles cache ###############################

class CacheTiles
  DIR="#{Dir.tmpdir}/atiles"
  TMPZ="#{DIR}/ZOOM"
  TMPZL="#{TMPZ}/LON"
  TMP="#{TMPZL}/LAT.jpg"
  URL=$URLTILES
  
  def initialize(app)
     Dir.mkdir(DIR) unless Dir.exists?(DIR)
     p DIR
     @app=app
     @current={}
  end
  def get_tile(z,lon,lat)
     filename=TMP.gsub("LAT",lat.to_s).gsub("LON",lon.to_s).gsub("ZOOM",z.to_s)
     if File.exists?(filename)  
       return(filename)
     else
        if ! @current[filename]
          @current[filename]=true
          Thread.new { load_tile(z,lon,lat,filename) }
        end
       return(nil)
     end
  end
  def load_tile(z,lon,lat,filename)
    tmpz= TMPZ.gsub("LAT",lat.to_s).gsub("LON",lon.to_s).gsub("ZOOM",z.to_s)
    Dir.mkdir(tmpz) unless Dir.exists?(tmpz)
    tmpl= TMPZL.gsub("LAT",lat.to_s).gsub("LON",lon.to_s).gsub("ZOOM",z.to_s)
    Dir.mkdir(tmpl) unless Dir.exists?(tmpl)
    
    url= URL.gsub("LAT",lat.to_s).gsub("LON",lon.to_s).gsub("ZOOM",z.to_s)
    puts "#{filename} delayed to #{url}"
    open(url,"rb") do |resp|
      File.open(filename+".tmp","wb") { |f| f.write(resp.read) }
      puts "notif app for raster #{filename}"
      current=@current
      File.rename(filename+".tmp",filename)
      gui_invoke {  current.delete(filename) ; refresh }
    end rescue (puts "unknown #{filename}")
  end  
end
###################################### Tools carto ###########################################
module Tools  
  CROSSGAP=8
  def draw_tile(ctx,f,x,y,pdx,pdy)
    ctx.set_source_pixbuf(get_pixbuf(f),(x-pdx)*256,(y-pdy)*256)
    ctx.paint
    draw_border(ctx,x,y,pdx,pdy) if $SHOW_TILES_BORDER
  end
  def draw_border(ctx,x,y,pdx,pdy)
    ctx.set_line_width(1)
    ctx.set_source_rgba(0,0,0,0.4)    
    ctx.move_to((x-pdx+1)*256,(y-pdy)*256).line_to((x-pdx)*256,(y-pdy)*256).line_to((x-pdx)*256,(y-pdy+1)*256)
    ctx.stroke
  end
  def draw_cross(ctx,w,h)
    ctx.set_line_width(2)
    ctx.set_source_rgba(0,0,0,0.7)    
    x0,y0=w/2.0,h/2.0
    ctx.move_to(x0,y0)
    ctx.line_to(x0-CROSSGAP,y0);ctx.line_to(x0+CROSSGAP,y0)
    ctx.line_to(x0,y0);ctx.line_to(x0,y0-CROSSGAP);ctx.line_to(x0,y0+CROSSGAP)
    ctx.stroke
  end
end

#################################### Carto wiewer #############################################
module Carto
  def radians(degrees) (Math::PI * degrees) / 180.0 end
  def degrees(radians) (radians * 180.0) / Math::PI end
  def tile_nums_2_lonlat(xtile, ytile, zoom)
    factor = 2.0 ** (zoom)
    lon = ((xtile * 360) / factor) - 180.0
    lat = Math.atan(Math.sinh(Math::PI * (1 - 2 * ytile / factor)))
    return  [lon,degrees(lat),zoom]
  end
  def lonlat_2_tilenums(lon,lat, zoom)
    factor1 = 2**(zoom)
    rlat = radians(lat)

    xtile = factor1 * (lon+180.0)/ 360.0

    sec= (1 / Math.cos(rlat))
    tan=Math.tan(rlat)
    ytile = factor1 * (1 - (Math.log(tan + sec) / Math::PI) )/2.0
    
    ([xtile.to_i, ytile.to_i,zoom,xtile-xtile.to_i, ytile-ytile.to_i] rescue [1,1,zoom,0,0])
  end

  def expose(w,ctx)
    @z=[1,@z,18].sort[1]
    #puts "lon=#{@lon0} lat=#{@lat0} z=#{@z}"
    xtile,ytile,bidon,pdx,pdy=lonlat_2_tilenums(@lon0,@lat0, @z)
    w,h=*$app.size
    nbx,nby=w/256,h/256
    x0,y0=w/2.0,h/2.0
    ((xtile-nbx/2)..(xtile+nbx/2+2)).each_with_index  do |xt,x| ((ytile-nby/2)..(ytile+nby/2+2)).each_with_index do |yt,y|
        f=@ct.get_tile(@z,xt,yt)   
        draw_tile(ctx,f,x,y,pdx,pdy)  if f
    end end
    draw_cross(ctx,w,h)
    @wlonlat.text= "%3.5f / %3.5f" % [@lon0,@lat0]
    @wzoom.text= @z.to_s
  end
  
  def move_carto(dx,dy)
    xtile,ytile,bidon,pdx,pdy=lonlat_2_tilenums(@lon0,@lat0, @z)
    lon0,lat0=tile_nums_2_lonlat(xtile,ytile,@z)
    lon1,lat1=tile_nums_2_lonlat(xtile-dx/256.0,ytile-dy/256.0,@z)
    @lonRef+=lon1-lon0
    @latRef+=lat1-lat0
    refresh
  end
end

######################################## Ruiby App ############################################
w= (ARGV.shift || "800").to_i
h= (ARGV.shift || "800").to_i
Ruiby.app(:width=> w, :height=>h, :title=> "Aerial Map from Mapbox") do
  extend Tools
  extend Carto
  $app=self
  @ct=CacheTiles.new(self)
  @z=(ARGV[0]||Ruiby.stock_get("Z","5")).to_i
  @lon0=(ARGV[1]||Ruiby.stock_get("LON","2.0")).to_f
  @lat0=(ARGV[2]||Ruiby.stock_get("LAT","48.0")).to_f
  @lonRef=@lon0
  @latRef=@lat0
  @zRef=@z
  stack {
    @cv=canvas(self.default_width,self.default_height) {
      on_canvas_draw { |w,ctx|  expose(w,ctx) }
      on_canvas_button_press {|w,e|  [e.x,e.y]  }
      on_canvas_button_motion {|w,e,o| n=[e.x,e.y] ;$app.move_carto(n[0]-o[0],n[1]-o[1]) if o ;n }
      on_canvas_button_release {|w,e,o| n=[e.x,e.y] ;$app.move_carto(n[0]-o[0],n[1]-o[1]) }
    }
    flowi { 
      regular
      table(0,0) { 
          row { cell( label "Lon/Lat : " ) ; cell( @wlonlat=entry("",6) ) }
         row  { cell( label "Zoom: "     ) ; cell( @wzoom=ientry(@z,min: 1,max: 18) { |v| @z=v.to_i })}
      }
      button("Goto...") { 
        prompt("Longitude ?",@lon0.to_s) { |lon|  
          prompt("Latitude  ?",@lat0.to_s) { |lat| 
            if ask("#{lon.to_f} ; #{lat.to_f}\n Validation ?")
              @lonRef,@latRef=lon.to_f,lat.to_f
              puts "========> #{@lonRef} #{@latRef}"
            end
            true
          } 
          true
        }
      }
      flowi {
        button("X") { begin load __FILE__ ; rescue Exception => e ; error(e) ; end} 
        button("Exit") { ruiby_exit } 
      }
    }
  }
  anim(20) {
    #@lon0+=0.001
    if @lon0!=@lonRef || @lat0!=@latRef || @zRef!=@z
      @lon0+= sqrs((@lonRef-@lon0))
      @lat0+= sqrs((@latRef-@lat0))
      if ((@lon0-@lonRef).abs+(@lat0-@latRef).abs) < 0.05/(2.0 ** @z)
        Ruiby.stock_put("Z",@z)
        Ruiby.stock_put("LON",@lon0)
        Ruiby.stock_put("LAT",@lat0)
        @lon0,@lat0=@lonRef,@latRef 
      end
      @zRef=@z
      refresh 
    end
  }
  def sqrs(b) 
    ret=b>0 ? b*b+b : -b*b+b 
    ret=[0,b/10,ret].sort[1]
  end
  def refresh() @cv.redraw end
end
