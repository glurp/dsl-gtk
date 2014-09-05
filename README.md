# Ruiby 
[![Dependency Status](http://www.versioneye.com/package/Ruiby/badge.png)]
[![Travis](https://travis-ci.org/glurp/dsl-gtk.svg?branch=master)]
[![Gem Version](https://badge.fury.io/rb/Ruiby.png)](http://badge.fury.io/rb/Ruiby)

A DSL for building simple GUI ruby application.
Based on gtk.

Gui programming should be as simpler as in Tcl/Tk environment.

Resources
==========


Code: http://github.com/glurp/Ruiby

Doc: [Ref.](https://rawgithub.com/glurp/Ruiby/master/doc.html)   

Gem : https://rubygems.org/gems/Ruiby


Status
======

NEW : 1.8.0  !!   09-03-2014

- terminal on Ctrl-Shift-h on any widget of application

TODO  :

- refactor samples demos with last improve
- resolve 100% gtk3 deprecated warning
- corrections in ruiby_require(?)
- complete treeview and tree_grid,
- complete rspec => 99% ?





Installation
============
1) system

Install Ruby 1.9 or 2.0.x


2) install Ruiby
(Ruiby install ruby-gtk3 which install gtk3 libs)

```
> gem update --system    # gem 2.0.3
> gem install Ruiby

> ruiby_demo             # check good installation with gtk3 (default)
> ruiby_sketchi          # write and test ruiby code
```



Usage
======
DSL is usable via inherit, include, Ruiby.app bloc, or one-liner command.

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
				button("Hello Word #{@vb.children.size}") {
					add_a_ruiby_button() 
				}
			end
		end
	end
end
Ruiby.start { Win.new("application title",350,10) }
```

Autonomous DSL, for  little application :

```ruby 
require  'Ruiby'
Ruiby.app do
	stack do
		. . . 
	end
end
```
And, for very little application ('~' are replaced by guillemet):

```ruby 

> ruiby   button(~Continue ? ~) "{  exit!(0) }"
> ruiby   fields([%w{a b},%w{b c},%w{c d}]) { "|a,b,c|" p [a,b,c] if a; exit!(a ?0:1) }
> ruiby -width 100  -height 300 -title "Please, select a file" \
             l=list(~Files :~);l.set_data Dir.glob(~*~) ;  \
             buttoni(~Selected~) { puts l.selection ; exit!(0) } ;\
			 buttoni(~Annul~) { exit!(1) }

```

Require
=======
Simple usage with gtk3 :

```ruby 
require 'Ruiby'
```

Usage with gtk2 (obsollete) : 

```ruby 
require 'gtk2'
require 'Ruiby'
```

Usage with Event Machine: preload event-machine before Ruiby :

```ruby 
require 'em-proxy'
require 'Ruiby'
```

Warning : EM.run is done when starting mainloop, after creation of window(s).
So, if you need initialization of event-machine callback, do it in component(), in a after(0):

```ruby 
Ruiby.app do
  ....
  after(0) { EventMachine::start_server().. { ... } }
end
```

See samples/spygui.rb, for exemple of gui with EM.


Threading
=========
Ruiby do not confidence qith gtk multi threading, so all Ruiby commands must be done in
main thread context. A Ruiby delegate is provided in Kenel module for supporte multi-threading

A Queue is polled by main-window thread :
* main window poll Queue , messagers are proc to be instance_eval() in the main window context
* everywere, a thread can invoke ```invoke_gui {ruiby code}```. this send to the main queue the proc,
 which will be evaluated asynchroniously 

instance_eval is avoided in ruiby. He is used only for thread invoker : gui_invoke().

```ruby
require_relative '../lib/Ruiby'
class App < Ruiby_gtk
    def initialize
        super("Testing Ruiby for Threading",150,0)
		threader(10)
		Thread.new { A.new.run }
    end
	def component()        
	  stack do
		sloti(label("Hello, this is Thread test !"))
		stack { @lab=stacki { } }
	  end
	end # endcomponent
	
end
class A
	def run
 		loop do
		 	sleep(1) # thread...
			there=self 
			gui_invoke { append_to(@lab) { sloti( 
					label( there.aaa )  # ! instance_eval on main window
			)  } }
		end
	end 
	def aaa() Time.now.to_s  end
end

Ruiby.start { App.new }

```

Observed Object/Variable
========================

Dynamic variable
----------------
Often, a widget (an entry, a label, a slider...) show the value of a ruby variable.
each time a code mofify this variable, it must modify the widget, and vice-versa...
This is very tyring :)

With data binding, this notifications are done by the framework

So ```DynVar``` can be  used for representing a value variable which is dynamics, ie. 
which must notify widgets which show the variable state.

So we can do :
```ruby
  foo=DynVar.new(0)
  entry(foo)
  islider(foo)
  ....
  foo.value=43  ## entry and slider will be updated
  ....
```

That works ! the entry and the slider will be updated.

A move on slider will update foo.value and the entry.
Idem for a key in the entry : slider and foo.value will be updated.

if you want to be notified for your own traitment, you can observ a DynVar :
```ruby
  foo.observ { |v| @socket.puts(v.to_s) rescue nil }
```

Here, a modification of foo variable will be send on the network...

Warning !! the block will always be executed in the main thread context (mainloop gtk context).
So DynVar is a ressource internal to Ruiby framework.

Widget which accept DynVar are : entry, ientry, islider, label, check_button, 

```must be exend to button, togglebutton, combo, radio_button ... list, grid,...```


Dynamic Object
--------------

Often, this kind of Dyn variables are members of a 'record', which should be organised by an
Ruby Object (a Struct...)

So ```DynObject``` create a class, which is organised by a hash  :
* packet of variable name 
* put initial value for each
* each variable will be a DynVar

```ruby 
  FooClass=make_DynClass("v1" => 1 , "v2" => 2, "s1" => 'Hello...')
  foo=FooClass.new( "s1" => Time.now.to_s ) # default value of s1 variable is replaced 
  ...
  label(" foo: ") ; entry(foo.s1)
  islider(foo.v1)
  islider(foo.v2)
  ....
  button("4x33") { Thread.new { foo.s1.value="s4e33" ; foo.v2.value=33 ; foo.v1.value=4} }
  ....
```

Dynamic Stock Object
--------------------
DynObject can be persisted to filesystem : use ```make_StockDynObject```, and
instantiate with an object persistant ID

```ruby 
  foo1=make_StockDynClass("v1"=> 1 , "v2" => 2, "s1" => 'Hello...')
  foo1=FooClass.new( "foo1" , "s1" => Time.now.to_s )
  foo2=FooClass.new( "foo2" , "s1" => (Time.now+10).to_s )
  ....
  button("Exit") { ruiby_exit} # on exit, foo1 and foo2 will been saved to {tmpdir}/<$0>.storage  
  ....
```

```make_StockDynObject``` do both : Class creation **and** class instanciation.


License
=======
LGPL, CC BY-SA

Exemples
========
see samples in "./samples" directory
See at end of Doc reference : [Ex.](https://rawgithub.com/glurp/Ruiby/master/doc.html#code) 

A little one
------------

ScreenShot:

![](http://raw.github.com/raubarede/Ruiby/master/samples/media/snapshot_simplissime.png)

```ruby
require 'Ruiby'

Ruiby.app width: 300,height: 200,title:"UpCase" do
  chrome(false)
  # create a class from a hash, instanciate on object which will save/restor at each stop/start of the script
  # structure of class and initale values are in the hash
  ctx=make_StockDynObject("simpl1",{"value" => "0" , "len" => 10, "res"=> ""})
  stack do
    flowi {
      sloti(toggle_button("D",false) {|v| chrome(v)})
      frame("Convertissor",margins: 20) do
       flowi {
         labeli "Value: " ,width: 200
         entry(ctx.value)
         button("reset") { ctx.value.value="" }}
       separator
       flowi { labeli "len: " ,width: 200 ; entry(ctx.len) }
       flowi { labeli " " ,width: 200 ; islider(ctx.len) }
       flowi { labeli "Resultat: " ,width: 200 ; entry(ctx.res) }
      end
    }
    flowi { regular # tool bar of buttons, each must have same size (regular on flow => same width)
      button("Validation") { validation(ctx) }
      button("Exit") { ruiby_exit }
    }
  end
  def validation(ctx) # a method appended to current class (private)
    Thread.new do
      sleep 1 # long time traitment...
      ctx.res.value= ctx.value.value.upcase 
      ctx.len.value= ctx.res.value.size
    end
  end
end
```
