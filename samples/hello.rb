require_relative '../lib/ruiby'
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL


class RubyApp1 < Ruiby_gtk
	def component() slot( label("Hello, world!") )  end
end

class RubyApp2 < Ruiby_gtk
	def component()  
		ed =slot( source_editor(width: 300, height: 100) )
		ed.editor.buffer.text="\ninclude Hello 'world' !"  
	end
end

class RubyApp3 < Ruiby_gtk
	def component() slot( button("Hello, ") { log(ask "world !") } )  end
end

class RubyApp4 < Ruiby_gtk
	def component() slot( button("Hello, ") { 
		w=RubyApp1.new("hx",200,200) 
		w.rposition(1,1) 
	  })  
	end
end

class RubyApp0 < Ruiby_gtk
	def component() 
		lc=File.read(__FILE__).split(/cl[a]ss/)
		lcode=lc[1..-2].map { |code| "cla"+"ss "+ code }
		democode= "cla"+"ss "+ lc.last
		stack do
			slot( label("\n\n\n\tPlease, Choose one of this hello-world version... \n\n",:font=> "Verdana 12") )
			lcode.each_with_index { |code,i| slot(button(code) { system("ruby",$0,(i+1).to_s) }) }
			slot(button("What's that ?") {
				Editor.new(self,democode)
			})
		end
		rposition(300,300)
	end
end



Gtk.init
window = eval("RubyApp"+(ARGV[0]||'0')).new("Hw",200,100)
Gtk.main
