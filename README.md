# Ruiby [![Build Status](https://secure.travis-ci.org/raubarede/Ruiby.png?branch=master)](http://travis-ci.org/raubarede/Ruiby) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/raubarede/Ruiby) [![Dependency Status](http://www.versioneye.com/package/Ruiby/badge.png)](http://www.versioneye.com/package/Ruiby)
[![Gem Version](https://badge.fury.io/rb/Ruiby.png)](http://badge.fury.io/rb/Ruiby)

A DSL for building simple GUI ruby application.
Based on gtk.

Resources
==========
blog: http://raubarede.tumblr.com/post/19640720031/currents-work

Code: http://github.com/raubarede/Ruiby

Doc: [Ref.](https://rawgithub.com/raubarede/Ruiby/master/doc.html)   


Gem : https://rubygems.org/gems/Ruiby


Status
======

NEW : 0.133.0 !!  20-12-2013
- bourrage() for force space(s) (with widget)
- samples : dyn.rb and tilesviewer.rb

TODO for 1.0 :
- Easy Form : almost done !!! : see samples/dyn.rb
- ask_file_for_read... do be refonding (default dir, file filter...)

TODO  :
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

NOTA
GTK3 give some instability : 
*  window resize scratch on MSWindows, sometime...
*  many deprecated messages on stdout


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

Usage with gtk2 : 

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


License
=======
LGPL, CC BY-SA

Exemples
========
see samples in "./samples" directory
See at end of Doc reference : [Ex.](https://rawgithub.com/raubarede/Ruiby/master/doc.html#code) 


