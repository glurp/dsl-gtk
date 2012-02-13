RUIBY
=====

A simple helper for building simple GUI ruby application rapidly.

'simple' mean :

* 'without great look&feel precision' 
* for little gui application, like autoit, xdialog...

Inspirations from Shoes.

Hard codes (gtk) copyed from green_shoes (thank you ashbb :) .

Based on gtk at first, should evolve for support swt (jruby) Forms (IronRuby) Qt...

Design
======
DSL is usable via inherit or include

By inherit:

```ruby
class Application < Ruiby_gtk
    def initialize(t,w,h)
        super(t,w,h)
    end	
	def component()        
	  stack do
		...
	  end
	end
	.....your code....
end
Ruiby.start { Win.new("application title",350,10) }

```

By include, calling ruiby_component() :

```ruby
class Win < Gtk::Window
	include Ruiby
    def initialize(t,w,h)
        super()
		add(@vb=VBox.new(false, 2)) 
		....
    end	
	def add_a_ruiby_button() 
		ruiby_component do
			append_to(@vb) do 
				slot(button("Hello Word #{@vb.children.size}") {
					add_a_ruiby_button() 
				})
			end
		end
	end
end

Ruiby.start { Win.new("application title",350,10) }
```

Threading is supported via a Queue :
* main window poll Queue , messagers are proc to be instance_eval() in the main window context
* everywere, a thread can invoke invoke_gui {ruiby code}. this send to the main queue the proc,
 which will be evaluated asynchroniously 

 
Status
======
In developpement :

* basic widget works (stack/flow/button/label/entry....)
* container done : vbox, hbox, frame, notebook, pane, table 
* some more complex widget:  scollbox, drawing, code_editor, 
* threading support ok ( threader(polling) / gui_invoke { } )
* **waiting** : data grid, list, treeview,

Screen copy at : http://regisaubarede.posterous.com/

Code: http://github.com/raubarede/Ruiby

License
=======
LGPL, CC BY-SA

Exemple 
=======
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


