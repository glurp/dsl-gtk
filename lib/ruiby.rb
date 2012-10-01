###############################################################################################
#            ruiby.rb :   A DSL for Ruby/Gui
#                         Gtk based. Should will support SWT , Qt, WinForms ?...
###############################################################################################
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# d
require 'tmpdir'
require 'pathname'
require 'gtk2'

if Gtk.check_version(2, 0, 0) =~ /old/i
	 md=Gtk::MessageDialog.new(nil,Gtk::Dialog::DESTROY_WITH_PARENT,Gtk::MessageDialog::QUESTION, 
            Gtk::MessageDialog::BUTTONS_YES_NO, "Gtk version invalide!, need 2.0.0 or later")
	 md.run
	 md.destroy
	 exit!
end
#require 'gtksourceview2'

module Ruiby
  DIR = Pathname.new(__FILE__).realpath.dirname.to_s
  VERSION = IO.read(File.join(DIR, '../VERSION')).chomp
  GUI='gtk'
  
  # update gui while necessary
  def self.update() 
		Gtk.main_iteration while Gtk.events_pending?  
  end
  ########### Local storage : save/retreive hash to a /tmp/script-name.storage
  def self.stock_put(name,value)
	db="#{Dir.tmpdir}/#{$0}.storage"
	data={}
    (File.open(db,"r") { |f| data=Marshal.load(f) } if File.exists?(db)) rescue nil
	data[name]=value
    File.open(db,"w") { |f| Marshal.dump(data,f) }
  end
  def self.stock_get(name)
	db="#{Dir.tmpdir}/#{$0}.storage"
	data={}
    (File.open(db,"r") { |f| data=Marshal.load(f) } if File.exists?(db) )rescue nil
	data[name] || ""
  end
  
  # start ruiby, one shot (reloading of source can be done)
  def self.start(&bloc)
	return if defined?($__MARKER_IS_RUIBY_INITIALIZED)
	$__MARKER_IS_RUIBY_INITIALIZED = true
	$stdout.sync=true 
	$stderr.sync=true 
	Thread.abort_on_exception = true  
	BasicSocket.do_not_reverse_lookup = true if defined?(BasicSocket)
	trap("INT") { exit!(0) }
	Gtk.init
	yield
	Gtk.main
  end
  # start ruiby, one shot (reloading of source can be done)
  # Gtk Exception are trapped, so process should not exited by ruiby fault!
  def self.start_secure(&bloc)
	return if defined?($__MARKER_IS_RUIBY_INITIALIZED)
	$__MARKER_IS_RUIBY_INITIALIZED = true
	$stdout.sync=true 
	$stderr.sync=true 
	Thread.abort_on_exception = true  
	BasicSocket.do_not_reverse_lookup = true if defined?(BasicSocket)
	trap("INT") { exit!(0) }
	Gtk.init
	yield
	secure_main()	
  end
  
  # Direct acces to Ruiby DSL
  # config can contain :title, :width, :height
  # Warning ! bloc use used for create a inner method, don't define sub methods :
  # def action() puts "CouCou..." end
  # Ruib.app {
  #    stack do button("test") { action() } end
  # }
  def self.app(config={},&blk)
		$blk=blk
		klass = Class.new Ruiby_gtk do
			def initialize(title,w,h)
				super
				threader(10)
			end
		end
		klass.send(:define_method,:component,&blk)
		start_secure { klass.new(config[:title] || "",config[:width] ||600,config[:height] ||600) }
  end
end


require_relative 'ruiby_gtk/ruiby_default_dialog.rb'
require_relative 'ruiby_gtk/ruiby_dsl.rb'
require_relative 'ruiby_gtk/ruiby_threader.rb'
require_relative 'ruiby_gtk/windows.rb'
require_relative 'ruiby_gtk/editor.rb'
require_relative 'ruiby_gtk/systray.rb'

Dir.glob("#{Ruiby::DIR}/plugins/*.rb").each do |filename| 
  autoload(File.basename(filename).split(".")[0].capitalize.to_sym, filename) 
end

module Kernel
	# do a gem require, anf if fail, try to load the gem from internet.
	# asking  permission is done for each gem. the output of 'gem install'
	# id show in ruiby log window
	def ruiby_require(*gems)
		w=Ruiby_dialog.new
		gems.flatten.each do|gem| 
			begin
				require gem
			rescue LoadError => e
				rep=w.ask("<em>Loading #{gems.join(', ')}</em>\n\n'#{gem}' package is missing. Can I load it from internet ?")
				exit! unless rep
				require 'open3'
				w.log("gem install  #{gem} --no-ri --no-rdoc")
				Gtk.main_iteration while Gtk.events_pending?
				Open3.popen3("gem install  #{gem}") { |si,so,se| 
					q=Queue.new
					Thread.new { loop {q.push(so.gets) } rescue nil; q.push(nil)}
					Thread.new { loop {q.push(se.gets) } rescue nil; q.push(nil)}
					str=""
					while str
						timeout(1) { str=q.pop } rescue nil
						(w.log(str);str="") if str && str.size>0
						Ruiby.update
					end
				}
				w.log "done!"
				Ruiby.update
				Gem.clear_paths() 
				require(gem) 
				w.log("loading '#{gem}' ok!")
			end		
		end
		w.destroy()
	end
end