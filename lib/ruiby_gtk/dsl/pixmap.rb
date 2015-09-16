# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
  ########################### raster images access #############################
  
  def get_image(name)
    Image.new(get_pixmap(name));
  end
  
  def get_pixmap(name)
    if name=~ /^famfamfam/
      name=Dir.glob("#{Ruiby::MEDIA}/#{name.split(/\s+/).join("*")}.png").to_a.first
    end
    if name.index('.') 
      if File.exists?(name)
         @cach_pix||={}
         @cach_pix[name]=Gdk::Pixbuf.new(name) unless @cach_pix[name]
         return @cach_pix[name]
      elsif name.index("[")
        return get_pixbuf(name)
      end
      error("Unknown file #{name} for image raster")
      return(nil)
    end
    begin
      return get_stockicon_pixbuf(name)
    rescue Exception => e
      error("Unknown pixmap for icon '#{name}' :\n",e)
      return nil
    end
  end
  
  # get pixmap from Gtk stoc
  def get_stockicon_pixbuf(name)
    begin
      icn="#{name.downcase.gsub('_','-')}"
      return Gtk::IconTheme.default().load_icon(icn,16,0)
    rescue Exception => ee
       puts ee.inspect
      return Gtk::IconTheme.default().load_icon("process-stop",48,0)
    end
  end
  
  # obsolete  
  def get_icon(name) get_pixmap(name) end
  

  # get a Image widget from a file or from a Gtk::Stock or famfamfam embeded in Ruiby.
  # image can be a filename or a predefined icon in GTK::Stock or a famfamfam icon name (without .png)
  # for file image, whe can specify a sub image (sqared) :
  #     filename.png[NoCol , NoRow]xSize
  #     filename.png[3,2]x32 : extract a icon of 32x32 pixel size from third column/second line
  #     see samples/draw.rb
  def get_image_from(name,size=:button)
    if name.index('.') 
      return Image.new(file: name) if File.exists?(name)
      return _sub_image(name) if name.index("[")
      alert("unknown icone #{name}")
    end
    iname=get_icon(name)
    if iname && Gdk::Pixbuf  === iname
      return Image.new(:pixbuf => iname) 
    elsif iname
      Image.new(:stock => iname,:size=> size)
    else
      nil
    end
  end
  def _sub_image(name)
    Image.new(pixbuf: get_pixbuf(name))
  end
  def get_pixbuf(name)
    @cach_pix={} unless defined?(@cach_pix)
    if @cach_pix.size>100
      puts "purge cached pixbuf (>100)"
      @cach_pix={}
    end
    filename,px,py,bidon,dim=name.split(/\[|,|(\]x)/)
    if filename && px && py && bidon && dim && File.exist?(filename)
      dim=dim.to_i
      @cach_pix[filename]=Gdk::Pixbuf.new(filename) unless @cach_pix[filename]
      x0= dim*px.to_i
      y0= dim*py.to_i
      #p [x0,y0,"/",@cach_pix[filename].width,@cach_pix[filename].height]
      Gdk::Pixbuf.new(@cach_pix[filename],x0,y0,dim,dim)
    elsif File.exists?(name)
      unless @cach_pix[name]
        px=Gdk::Pixbuf.new(name) rescue error($!)
        @cach_pix[name]=px if px
      end
      @cach_pix[name]
    elsif ! name.index(".")
      get_stockicon_pixbuf(name)
    else
      raise("file #{name} not exist");
    end
  end
end