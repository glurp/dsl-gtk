# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

=begin
dsl 
  image() ==> get_pixmap(file) + pix.scale ==> Img.new(pixbuf)
  button("#") => htoolbar { toolbar_button() }
  label("#")  => get_image_from(name)
  
get_image => (Image)
    Image.new( get_pixmap )

get_icon(n) ==> (Pixbuff)
    get_pixmap(n) 

get_pixmap ==> (Pixbuff)
    ?< fn= famfamfam+fn >
    Pixbuff.new(fn) | 
    get_pixbuf("[]name") |
    get_stockicon_pixbuf(name)
    
get_stockicon_pixbuf() ==>  (Pixbuff)
   Gtk::IconTheme.default().load_icon |
   Gtk::IconTheme.default().load_icon(GTK2ICONNAME[icn]) |
   Gtk::IconTheme.default().load_icon("process-stop")
   
get_image_from(name) ( Image )
  Image.new(file: name) |
  _sub_image(name) |
  Image.new(:pixbuf => get_icon(iname))
  Image.new(:stock => get_icon(iname))

_sub_image(name) ==>  ( Image )
    Image.new(pixbuf: get_pixbuf(name))  

get_pixbuf(name)  => ( Pixbuf )
  Cache || Gdk::Pixbuf.new(filename) ||
  get_stockicon_pixbuf(name)
   
=end
module Ruiby_dsl
  ########################### raster images access #############################
  
  def get_image(name)
    Image.new(get_pixmap(name));
  end
  
  def get_pixmap(name)
    if name=~ /^famfamfam/
      name=Dir.glob("#{Ruiby::MEDIA}/#{name.split(/\s+/).join("*")}*").first
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
  
  def get_stockicon_pixbuf(name)
    begin
      icn="#{name.downcase.gsub('_','-')}"
      return Gtk::IconTheme.default().load_icon(icn,16,0)
    rescue Exception => ee
       if GTK2ICONNAME[icn]
        ( return Gtk::IconTheme.default().load_icon(GTK2ICONNAME[icn],16,0) ) rescue error($!)
       end
       puts ee.inspect
      return Gtk::IconTheme.default().load_icon("process-stop",48,0)
    end
  end
  GTK2ICONNAME= {
"about" => "help-about", "add" => "list-add", "bold" => "format-text-bold", "cancel" => "process-stop", "clear" => "edit-clear", 
"close" => "window-close", "copy" => "edit-copy", "cut" => "edit-cut", "delete" => "edit-delete", "execute" => "system-run", 
"find-and-replace" => "edit-find-replace", "find" => "edit-find", "fullscreen" => "view-fullscreen", "go-back-ltr" => "go-previous",
 "go-back-rtl" => "go-next", "go-down" => "go-down", "go-forward-ltr" => "go-next", "go-forward-rtl" => "go-previous", "go-up" => "go-up",
 "goto-bottom" => "go-bottom", "goto-first-ltr" => "go-first", "goto-first-rtl" => "go-last", "goto-last-ltr" => "go-last",
 "goto-last-rtl" => "go-first", "goto-top" => "go-top", "help" => "help-contents", "home" => "go-home", "indent-ltr" => "format-indent-more",
 "indent-rtl" => "format-indent-less", "italic" => "format-text-italic", "jump-to-ltr" => "go-jump", "jump-to-rtl" => "go-jump",
 "justify-center" => "format-justify-center", "justify-fill" => "format-justify-fill", "justify-left" => "format-justify-left",
 "justify-right" => "format-justify-right", "leave-fullscreen" => "view-restore", "media-forward-ltr" => "media-seek-forward",
 "media-forward-rtl" => "media-seek-backward", "media-next-ltr" => "media-skip-forward", "media-next-rtl" => "media-skip-backward",
 "media-pause" => "media-playback-pause", "media-play-ltr" => "media-playback-start", "media-previous-ltr" => "media-skip-backward",
 "media-previous-rtl" => "media-skip-forward", "media-record" => "media-record", "media-rewind-ltr" => "media-seek-backward",
 "media-rewind-rtl" => "media-seek-forward", "media-stop" => "media-playback-stop", "new" => "document-new", "open" => "document-open",
 "paste" => "edit-paste", "print-preview" => "document-print-preview", "print" => "document-print", "properties" => "document-properties",
 "quit" => "application-exit", "redo-ltr" => "edit-redo", "refresh" => "view-refresh", "remove" => "list-remove",
 "revert-to-saved-ltr" => "document-revert", "revert-to-saved-rtl" => "document-revert", "save-as" => "document-save-as",
 "save" => "document-save", "select-all" => "edit-select-all", "sort-ascending" => "view-sort-ascending",
 "sort-descending" => "view-sort-descending", "spell-check" => "tools-check-spelling", "stop" => "process-stop",
 "strikethrough" => "format-text-strikethrough", "underline" => "format-text-underline", "undo-ltr" => "edit-undo",
 "unindent-ltr" => "format-indent-less", "unindent-rtl" => "format-indent-more", "zoom-100" => "zoom-original",
 "zoom-fit" => "zoom-fit-best" }
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
