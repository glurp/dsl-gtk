# create a diaog which cntain end little editor
class Editor < Ruiby_gtk 
    def initialize(w,filename,width=350)
		@filename=filename
        super("Edit #{filename[0..40]}",width,0)
		transient_for=w
    end	
	def component()
	  stack do
		@edit=slot(source_editor()).editor
		@edit.buffer.text=File.exists?(@filename) ? File.read(@filename) : @filename
		sloti( button("Exit") { destroy() })
	  end
	end # endcomponent

end
