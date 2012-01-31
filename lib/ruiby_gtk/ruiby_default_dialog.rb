module Ruiby_default_dialog
	include ::Gtk
	###################################### Alerts

	def alert(*txt) message(MessageDialog::INFO,*txt) end
	def error(*txt) message(MessageDialog::ERROR,*txt) end
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