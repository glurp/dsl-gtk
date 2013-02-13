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
require 'thread'
require 'pathname'
require 'gtk2' if ! defined?(Gtk)

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
  
  # Update gui while event is pending
  # to be use if current algorithme is long and user want see gui update
  # log long list of message to screen...
  #
  def self.update() 
		Gtk.main_iteration while Gtk.events_pending?  
  end
  ###########################################################
  #                S t o r a g e 
  ###########################################################
  
  # persistent stock a value associated to a name
  # dictionary is serialised (Marshalling) to a default file
  # file is /tmp/$0.storage
  def self.stock_put(name,value)
	db="#{Dir.tmpdir}/#{File.basename($0)}.storage"
	data={}
    (File.open(db,"r") { |f| data=Marshal.load(f) } if File.exists?(db)) rescue nil
	data[name]=value
    File.open(db,"w") { |f| Marshal.dump(data,f) }
  end
  # read a value associated to a name from persistant storage
  def self.stock_get(name)
	db="#{Dir.tmpdir}/#{File.basename($0)}.storage"
	data={}
    (File.open(db,"r") { |f| data=Marshal.load(f) } if File.exists?(db) )rescue nil
	data[name] || ""
  end
  # clear persistant strorage
  def self.stock_reset()
	db="#{Dir.tmpdir}/#{File.basename($0)}.storage"
	File.delete(db) if File.exists?(db)
  end
  ###########################################################
  #                start Ruiby application
  ###########################################################
  
  # start ruiby.
  # Usage: Ruiby.start { Win.new() }
  # One shot :reloading of source can be done, block wjile not be evaluated
  #
  # Thread.abort_on_exception, BasicSocket.do_not_reverse_lookup, 
  # trap('INT') are settings
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
  
  # Start ruiby with a main loop which trap all error :
  # A Exception in a callback will not kill the process.
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
  # Warning ! bolc is invoked vy instance_eval on window
  # def action() puts "Hello..." end
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
		klass.send(:chrome,config[:chrome]) if config.has_key?(:chrome)
		start_secure { 
			w=klass.new(config[:title] || "",config[:width] ||600,config[:height] ||600) 
		    w.send(:chrome,config[:chrome]) if config[:chrome]
		}
  end
  def self.set_last_log_window(win)
	@last_log=win
  end
  def self.destroy_log()
	return unless @last_log  && ! @last_log.destroyed?
	@last_log.destroy() rescue nil
	@last_log=nil
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
	# do a gem require, anfd if fail, try to load the gem from internet.
	# asking  permission is done for each gem. the output of 'gem install'
	# id show in ruiby log window
	def ruiby_require(*gems)
		w=Ruiby_dialog.new
		gems.flatten.each do|gem| 
			begin
				require gem
			rescue LoadError => e
				rep=w.ask("Loading #{gems.join(', ')}\n\n'#{gem}' package is missing. Can I load it from internet ?")
				exit! unless rep
				Ruiby.update
				require 'open3'
				w.log("gem install  #{gem} --no-ri --no-rdoc")
				Ruiby.update
				Open3.popen3("gem install  #{gem} --no-ri --no-rdoc") { |si,so,se| 
					q=Queue.new
					Thread.new { loop {q.push(so.gets) } rescue p $!; q.push(nil)}
					Thread.new { loop {q.push(se.gets) } rescue p $!; q.push(nil)}
					str=""
					while str
						timeout(1) { str=q.pop } rescue p $!
						(w.log(str);str="") if str && str.size>0
						w.log Time.now
						Ruiby.update						
					end
				}
				w.log "done!"
				Ruiby.update
				Gem.clear_paths() 
				require(gem) 
				w.log("loading '#{gem}' ok!")
				Ruiby.update
			end		
		end
		w.destroy()
		Ruiby.update
	end
end