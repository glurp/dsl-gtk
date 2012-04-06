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
	# show a modal dialogue, asking question, active bloc closure with text response
	def prompt(txt,value="") 
		 dialog = Dialog.new("Message",
			self,
			Dialog::DESTROY_WITH_PARENT,
			[ Stock::OK, Dialog::RESPONSE_NONE ])

		label=label(txt)
		entry=entry(value.to_s)
		dialog.vbox.add(label)
		dialog.vbox.add(entry)

		dialog.signal_connect('response') do |w,e|
			rep=true
			rep=yield(entry.text) if block_given?
			dialog.destroy if rep
		end
		dialog.show_all	
	end


	# show a modal dialogue, asking yes/no question, ruturn boolean response
	def ask(*txt) 
		text=txt.join(" ")
        md = MessageDialog.new(self,
            Dialog::DESTROY_WITH_PARENT,  Gtk::MessageDialog::QUESTION, 
            MessageDialog::BUTTONS_YES_NO, text)
		rep=md.run
		md.destroy
		return( rep==-8 )
	end
	def trace(*txt) message(MessageDialog::WARNING,*txt) end

	def message(style,*txt)
		text=txt.join(" ")
        md = MessageDialog.new(self,
            Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::QUESTION, 
            ::Gtk::MessageDialog::BUTTONS_CLOSE, text)
        md.run
        md.destroy
	end
	# dialog asking a color
	def ask_color
		cdia = ColorSelectionDialog.new("Select color")
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
	def edit(filename)
		Editor.new(self,filename)
	end
	
	########## File dialog <<== Green Shoes!

	def ask_file_to_read(dir,filter)
		dialog_chooser("Open File (#{filter}) ...", Gtk::FileChooser::ACTION_OPEN, Gtk::Stock::OPEN)
	end
	def ask_file_to_write(dir,filter)
	 dialog_chooser("Save File (#{filter}) ...", Gtk::FileChooser::ACTION_SAVE, Gtk::Stock::SAVE)
	end
	def ask_dir()
		dialog_chooser("Save Folder...", Gtk::FileChooser::ACTION_CREATE_FOLDER, Gtk::Stock::SAVE)
	end
	def dialog_chooser(title, action, button)
	    dialog = Gtk::FileChooserDialog.new(
	      title,
	      self,
	      action,
	      nil,
	      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
	      [button, Gtk::Dialog::RESPONSE_ACCEPT]
	    )
	    ret = ( dialog.run == Gtk::Dialog::RESPONSE_ACCEPT ? dialog.filename : nil rescue false)
	    dialog.destroy
	    ret
	end
end

# Direct Static call to common dialog
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