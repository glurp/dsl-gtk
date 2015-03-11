# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_dsl
  ########################### raster images access #############################

  def get_icon(name)
    return name if name.index('.') && File.exists?(name)
    if name=~ /^famfamfam/
      fn=Dir.glob("#{Ruiby::MEDIA}/#{name.split(/\s+/).join("*")}.png").to_a.first
      if File.exists(fn)
         @cach_pix[fn]=Gdk::Pixbuf.new(fn) unless @cach_pix[fn]
         return @cach_pix[fn]
      end
    end
    n="Gtk::Stock::#{name.to_s.upcase}"
    if defined?(n)
       a=eval(n)
       $stderr.puts ">>>========== stock icon #{a.inspect} / #{n}"
       a
    else 
       $stderr.puts "not icon : #{name}"
       nil
    end
  end
  # Image#initialize(:label => nil, :mnemonic => nil, :stock => nil, :size => nil)'
  def get_stockicon_pixbuf(name)
    Image.new( :stock => eval("Gtk::Stock::"+name.upcase), :size => :button).pixbuf
  end

  # get a Image widget from a file or from a Gtk::Stock
  # image can be a filename or a predefined icon in GTK::Stock
  # for file image, whe can specify a sub image (sqared) :
  #     filename.png[NoCol , NoRow]xSize
  #     filename.png[3,2]x32 : extract a icon of 32x32 pixel size from third column/second line
  #    see samples/draw.rb
  def get_image_from(name,size=:button)
    if name.index('.') 
      return Image.new(name) if File.exists?(name)
      return _sub_image(name) if name.index("[")
      alert("unknown icone #{name}")
    end
    iname=get_icon(name)
    if iname
      Image.new(:stock => iname,:size=> size)
    else
      nil
    end
  end
  def _sub_image(name)
    Image.new(get_pixbuf(name))
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