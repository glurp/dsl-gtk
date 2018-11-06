# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#####################################################################
#  ex.rb : simple text (ruby) editorend test view
#####################################################################
# encoding: utf-8
#require 'Ruiby'
require_relative '../lib/Ruiby.rb'


class RubyApp < Ruiby_gtk
  def initialize(*files)
      super("Testing Ruiby editor",700,600)
      load(files.first) if files.size>0
      @content_cv=""
  end
  def component()
    stack do
      a=slot(Image.new( :stock => Gtk::Stock::OPEN, :size => :button))
      sloti(htoolbar do
        toolbar_button("open","ouvrir fichier") {
          load(ask_file_to_read(".","*.rb"))
        }
        toolbar_button("Save","sauvegarder le fichier") {
          content=@edit.buffer.text
          File.open(@file,"wb") { |f| f.write(content) } if @file && content && content.size>2
        }
        toolbar_button("save_as","sauvegarder le fichier") {
          file=ask_file_to_write(".","*.rb")
          if file
            @file=file
            set_title(@file)
            content=@edit.buffer.text
            File.open(@file,"w") { |f| f.write(content) } if @file && content && content.size>2
          end
        }
      end)
      flow_paned(1200,0.5) do 
        stack do
          @edit=source_editor(:width=>200,:height=>50,
            :lang=> "ruby", :font=> "Courier new 12",:on_change=> proc { change }
          ).editor
          @edit.buffer.text=Ruiby.stock_get("text1","")
          flowi {
            @bt=button("Test in console...") { Ruiby.stock_put("text1",@edit.buffer.text); execute_console() }
            @bt=button("Test in canvas...") { Ruiby.stock_put("text1",@edit.buffer.text);execute_canvas() }
            @bt=button("Test in stack...") { Ruiby.stock_put("text1",@edit.buffer.text);execute_stack() }
          }
        end
        @nb=notebook do   
          page("console") do
            content=Ruiby.stock_get("text1","")
            @ta=text_area(300,600,:font=> "Courier new 12")
            @ta.text=content
          end
          page("canvas") do
            @cv=canvas(300,600)  { 
              on_canvas_draw { |w,cr| redraw(w,cr) } 
            } 
          end
          page("Stack") do
            @box=stack {}
          end
        end
      end
      @nbh=notebook do 
        page("Error") { 
          @error_log=text_area(600,100,{:font=>"Courier new 10"}) 
        }
        page("Ex. canvas") { 
          t=text_area(1,1,:font=> "Courier new 10")
          t.text=<<-EEND
          
          Real code:
          ==========
          cv.draw_pie(
           200,300,70,
           [[1,"#F00","P1e"],[2,"#00F","P2"],[3,"#0F0","P3"],
           [1,"#F00","P1"],[2,"#00F","P2"],[3,"#0F0","P3"],
           [1,"#F00","P1"],[2,"#00F","P2"],[3,"#0F0","P3"]
          ],true)
          cv.draw_pie(80,500,50,[1,5,3,4])
          cv.draw_image(400,3,"d:/usr/icons/regis.jpg")
          cv.scale(300,300,0.3) {
           cv.draw_image(300,300,"d:/usr/icons/regis.jpg")
           w=150
           cv.draw_rectangle(300,300,w,w,0,"#000",nil,4)
          }
          cv.draw_line([1,10,100,10,100,10,100,110],"#0A0",1)
          cv.draw_polygon([1,110,100,110,100,110,100,210,1,110],"#0FF","#DDD",1)
          cv.draw_text(200,70,"Hello !",6,"#000")
          EEND
          c=File.read("#{Ruiby::DIR}/ruiby_gtk/dsl/canvas.rb").split(/\r?\n/).grep(/^\s+def\s+cv\./).reject {|a|a=~/end/}.join("\n")
          t.text+=c 
        }
        page("Ex. stack") { 
          t=text_area(1,1,:font=> "Courier new 10")
          t.text=<<-EEND
            flowi{ button("button") {alert("Hi!")}
          EEND
        }
        page("Ruiby APi") { 
          doc=::Ruiby.make_doc_api().uniq
          flow {
            stacki { 
              label "Search :"
              e=entry("",20)
              button("Go") { alert( doc.grep(/#{e.text}/).join("\n")) }
            }
            t=text_area(1,1,:font=> "Courier new 10")
            l,r= *(doc.each_with_index.partition {|a,i| i<(doc.size/2)})
            t.text=l.zip(r).map {|l,r| "%-55s | %-40s" % [l.first,r.first]}.join("\n")
          }
        }
        #
    end
    end
    # end nb
    after(20)   { rposition(-3,3) }
  end
  
  def execute_stack()
    @nb.page=2
    @content_cv=""
    @content= @edit.buffer.text
    @ta.text=""
    @error_log.text=""
    @nbh.page=0
    clear_append_to(@box) {
      frame { stack {
      eval(@content,binding() ,"<script>",1) 
      @error_log.text="ok." 
      } }
    }
    File.open(@filedef,"w") {|f| f.write(@content)} if @content.size>30  && @filedef
    true
  rescue Exception => e
    t="#{e} \n  #{e.backtrace.join("\n  ")}\n"
    @error_log.append(t)
  end
  
  def execute_canvas()
    @nb.page=1
    update
    @content_cv= @edit.buffer.text
    @ta.text=""
    @error_log.text=""
    File.open(@filedef,"w") {|f| f.write(@content_cv)} if @content_cv.size>30  && @filedef
    @nbh.page=0
    @cv.redraw
    true
  rescue Exception => e
    t="#{e} \n  #{e.backtrace.join("\n  ")}\n"
    @error_log.append(t)
  end
  def redraw(w,ctx)
    cv=w
    eval(@content_cv,binding(),"<script>",1) if @content_cv && @content_cv.size>3
    @error_log.text="ok." 
  rescue Exception => e
    @content_cv=""
    t="#{e} \n  #{e.backtrace.join("\n  ")}\n"
    @error_log.append(t)  
  end
  
  def execute_console()
    @nb.page=0
    @content_cv=""
    @content= @edit.buffer.text
    @ta.text=""
    @error_log.text=""
    @nbh.page=0
    exec_to_widget(@ta,@content) {
      eval(@content,binding() ,"<script>",1) 
    }
    File.open(@filedef,"w") {|f| f.write(@content)} if @content.size>30  && @filedef
    true
  rescue Exception => e
    t="#{e} \n  #{e.backtrace.join("\n  ")}\n"
    @error_log.append(t)
  end
  def exec_to_widget(wt,code)
    stdout_save=$stdout
    $stdout=IOWidget.new(wt)
    begin
      yield
    ensure
      $stdout=stdout_save
    end
  end
  def trace(e)
    @error_log.text=e.to_s + " : \n   "+ e.backtrace[0..3].join("\n   ")
  end
  def change(*t)
  end    
  
  def load(file)
    return unless file
    return unless File.exists?(file)
    @file=file
    @filedef=file
    set_title(@file)
    @mtime=File.mtime(@file)
    @edit.buffer.text=File.read(@file)
  end
end

class IOWidget 
  def initialize(widget)
    @w=widget
  end
  def write(txt) @w.append(txt) end
  def print(txt) @w.append(txt) end
  def puts(txt) @w.append(txt);@w.append("\n") end
  def read() Message.prompt("reading") end
  def flush()  end
  def fsynf(a)  end
end

Ruiby.start_secure { RubyApp.new(*ARGV) }


