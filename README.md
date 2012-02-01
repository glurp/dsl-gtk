RUIBY
=====

A simple helper for building simple GUI ruby application rapidly.

'simple' mean 'without great look&feel precision' 

Inspirations from Shoes.

Hard codes (gtk) copyed from green_shoes (thank you ashbb :) .

Based on gtk at first, should evolve for support swt (jruby) Forms (IronRuby) Qt...

Design
======
I try do make a sample DSL avoiding instance_eval, dynamique methods and so on.
DSL is usable via inherit or include

By inherit:
```
class Application < Ruiby_gtk
    def initialize()
        super("application title",350,0)
    end	
	def component()        
	  stack do
		...
	  end
	end
	.....your code....
end
```

by include:
```
class Win < Gtk::Window
	include Ruiby
    def initialize()
        super("application title",350,0)
		....
    end	
	def onclick(ev) 
		ruiby_component { stack { button "Hello" { }}  }
	end
end
```


Status
======
In developpement :

* basic widget works (stack/flow/button/label/entry....)
* container done : vbox, hbox, frame, notebook, pane, table 
* some more complex widget:  scollbox, drawing, code_editor, 
* threading support ok ( gui_invoke { } )
* waiting : data grid, list, treeview, systray

Hard copy dispo at :
http://regisaubarede.posterous.com/

Code:
http://github.com/raubarede/Ruiby

License
=======
LGPL, CC BY-SA

Exemple 
======
see samples in "./samples" directory


```ruby
def component()        
  stack do
    slot(label( <<-EEND
     This window is done with 55 LOC...
    EEND
    ))
    separator
    flow {
      @left=stack {
        frame("") { table(2,10,{set_column_spacings: 3}) do
          row { cell label  "mode de fontionnement" ; cell(button("set") { alert("?") }) }
          row { cell label  "vitesse"               ; cell entry("aa")  }
          row { cell label  "size"                  ; cell ientry(11,{:min=>0,:max=>100,:by=>1})  }
          row { cell label  "feeling"               ; cell islider(10,{:min=>0,:max=>100,:by=>1})  }
        end }
      }
      separator
      notebook do
        page("Page of Notebook") {
          table(2,2) {
            row { cell(button("eeee"));cell(button("dddd")) }
            row { cell(button("eeee"));cell(button("dddd")) }
          }
        }
        page("eee","#home") {
          sloti(button("Eeee"))
          sloti(button("#harddisk") { alert("image button!")})
          sloti(label('#cdrom'))
        }
      end
      frame("") do
        stack {
          sloti(label("Test scrolled zone"))
          separator
          vbox_scrolled(-1,100) { 
            100.times { |i| 
              flow { sloti(button("eeee#{i}"));sloti(button("eeee")) }
            }
          }
          vbox_scrolled(100,100) { 
            100.times { |i| 
              flow { sloti(button("eeee#{i}"));sloti(button("eeee"));sloti(button("aaa"*100)) }
            }
          }
        }
      end      
    }
    sloti( button("Exit") { exit! })
  end
end # endcomponent
```


