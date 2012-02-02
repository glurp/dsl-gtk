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

require 'tmpdir'
require 'pathname'
require 'gtk2'



module Ruiby
  DIR = Pathname.new(__FILE__).realpath.dirname.to_s
  VERSION = IO.read(File.join(DIR, '../VERSION')).chomp
  GUI='gtk'
  
  def self.start()
	Gtk.init
	yield
	Gtk.main
  end
end


require_relative 'ruiby_gtk/ruiby_default_dialog.rb'
require_relative 'ruiby_gtk/ruiby_dsl.rb'
require_relative 'ruiby_gtk/ruiby_threader.rb'
require_relative 'ruiby_gtk/windows.rb'
require_relative 'ruiby_gtk/editor.rb'
require_relative 'ruiby_gtk/systray.rb'

Dir.glob("#{Ruiby::DIR}/plugins/*.rb").each do |filename| 
  autoload(File.basename(:filename).split(".")[0].downcase.to_s, filename) 
end
