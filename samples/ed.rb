# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require 'Ruiby'
$file=ARGV[0]
(puts "file not exist"; exit(1)) unless File.exist?($file)
Ruiby.app width: 700, height:300,title: $file do
    stack do
      @edit=source_editor(:lang=> "ruby", :font=> "Courier new 12").editor
      @edit.buffer.text=File.read($file)
      flowi do  flow do
        regular
        button("Save") { save;  }
        button("Save & Exit") { save; puts @edit.buffer.text; exit! }
      end
        buttoni("abort") {  exit!(1) }
      end
    end
    def save()  File.write($file,@edit.buffer.text) end
end
