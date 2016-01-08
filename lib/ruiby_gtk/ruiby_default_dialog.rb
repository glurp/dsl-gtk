# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

module Ruiby_default_dialog
	include ::Gtk
	###################################### Alerts

	# modal popup with text (as html one!)
	def alert(*txt) message(MessageDialog::INFO,*txt) end
	# modal popup with text and/or ruby Exception.
	def error(*txt) 
		lt=txt.map { |o| 
			if Exception===o 
				o.to_s + " : \n  "+o.backtrace.join("\n  ")
			else
				o.to_s
			end
		}
		message(MessageDialog::ERROR,*lt) 
	end
	# show a modal dialogu, asking question, active bloc closure with text response
	def prompt(txt,value="") 
		 dialog = Dialog.new(
      title: "Message",
			parent: self,
			flags: [Dialog::DESTROY_WITH_PARENT],
			buttons: [ [Stock::OK,1], [:annulation,2] ]
    )

		label=Label.new(txt)
		entry=Entry.new().tap {|e| e.set_text(value) }
		dialog.vbox.add(label)
		dialog.vbox.add(entry)
		dialog.set_window_position(Window::POS_CENTER)

		dialog.signal_connect('response') do |w,e|
			rep=true
			rep=yield(entry.text) if block_given?
			dialog.destroy if rep
		end
		dialog.show_all	
	end


	# show a modal dialog, asking yes/no question, return boolean response
	def ask(*txt) 
		text=txt.join(" ")
        md = MessageDialog.new(
            self,
            Dialog::DESTROY_WITH_PARENT,  Gtk::MessageDialog::QUESTION, 
            MessageDialog::BUTTONS_YES_NO, text)
		md.set_window_position(Window::POS_CENTER)
		rep=md.run
		md.destroy
		return( rep==-8 )
	end
	
	# a warning alert
	def trace(*txt) message(MessageDialog::WARNING,*txt) end

	def message(style,*txt)
		text=txt.join(" ")
        md = MessageDialog.new(self,
            Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::QUESTION, 
            ::Gtk::MessageDialog::BUTTONS_CLOSE, text)
		md.set_window_position(Window::POS_CENTER)
        md.run
        md.destroy
	end
	# dialog asking a color
	def ask_color
		cdia =  ColorSelectionDialog.new("Select color")
		cdia.set_window_position(Window::POS_CENTER)
		response=cdia.run
		color=nil
        if response == Gtk::Dialog::RESPONSE_OK
            colorsel = cdia.colorsel
            color = colorsel.current_color
        end 		
		cdia.destroy
		color
	end

	########## File Edit
	
	# dialog showing code editor
	def edit(filename,&blk)
		Editor.new(self,filename,350,&blk) 
	end
	
	########## File dialog

	def ask_file_to_read(dir,filter)
		dialog_chooser("Choose File (#{filter}) ...", Ruiby.gtk_version(3) ? :open : Gtk::FileChooser::ACTION_OPEN, Gtk::Stock::OPEN)
	end
	def ask_file_to_write(dir,filter)
	 dialog_chooser("Save File (#{filter}) ...", Ruiby.gtk_version(3) ? :save : Gtk::FileChooser::ACTION_SAVE, Gtk::Stock::SAVE)
	end
	def ask_dir_to_read(initial_dir=nil)
		dialog_chooser(
				"Select existing Folder ...",
				Gtk::FileChooser::ACTION_SELECT_FOLDER,
				Gtk::Stock::OPEN) {|d| 
			d.filename=initial_dir if initial_dir && File.exists?(initial_dir)
		}
	end
	def ask_dir_to_write(initial_dir=nil)
		dialog_chooser(
			"Select Folder or create one ...", 
			Gtk::FileChooser::ACTION_SELECT_FOLDER ,
			Gtk::Stock::OPEN) {|d|
			d.filename=initial_dir if initial_dir 
		}
	end
	def dialog_chooser(title, action, button)
      if Ruiby.gtk_version(3)
        dialog = Gtk::FileChooserDialog.new(
            :title => title, 
            :parent => self, 
            :action => action, 
            :buttons => [ ##  ??
              [Gtk::Stock::CANCEL, Ruiby.gtk_version(3) ? :cancel : Gtk::Dialog::RESPONSE_CANCEL],
              [button, Gtk::Dialog::RESPONSE_ACCEPT]
            ])
      else
        dialog = Gtk::FileChooserDialog.new(
          title,
          self,
          action,
          nil,
          [Gtk::Stock::CANCEL, Ruiby.gtk_version(3) ? :cancel : Gtk::Dialog::RESPONSE_CANCEL],
          [button, Gtk::Dialog::RESPONSE_ACCEPT]
        )
      end
      dialog.set_window_position(Window::POS_CENTER)
	yield(dialog) if block_given?
	ret = ( dialog.run == Gtk::Dialog::RESPONSE_ACCEPT ? dialog.filename : nil )rescue false
	dialog.destroy
	    ret ? ret.gsub('\\','/') : ""
      end
end

#  To be use for direct  call (blocking) of common dialog :
#  Message.alert("ddde",'eee')
class Message
	class Embbeded  < ::Gtk::Window
		include ::Ruiby_default_dialog
	end
	def self.alert(*txt) Embbeded.new.alert(*txt) end
	def self.error(*txt) Embbeded.new.error(*txt) end
	def self.ask(*txt)   Embbeded.new.ask(*txt)   end
	def self.prompt(txt,value="")  Embbeded.new.alert(*txt) end
end