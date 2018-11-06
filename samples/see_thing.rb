# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require 'Ruiby'

$command="ruby"
if ARGV.first == "-e" && ARGV.size>2
 ARGV.shift
 $command=ARGV.shift
end
$files=ARGV.select {|fn| File.exists?(fn) }
p $files
p $files.first
p File.extname($files.first)
$lang=  case File.extname($files.first)
  when ".rb" then "ruby"
  when ".py" then "python"
  when ".pl" then "perl"
  when ".js" then "javascript"
  when ".json" then "javascript"
  else
      $files.first.extname[1..-1]
end
(puts "no files!"; exit(1)) if $files.size==0

Ruiby.app width: 700, height:700,title: "See Things (#{$files.size})" do
    @fn=nil
    flow do
      flowi { li=list("File",170,700) {|_,lfn| dofn(lfn.first) }; li.set_data($files) }
      stack {
        @edit=source_editor(:lang=> $lang, :font=> "Courier new 12").editor.buffer
        flowi {
          button("save") { 
             File.write(@fn,@edit.text) if @fn && File.exists?(@fn)
          }
          button("run") { run_text }
        }
        
      }
      @edit.text=File.read($files.first)
    end
    def save()  File.write(@fn,@edit.buffer.text) if @fn && File.exists?(@fn) end
    def dofn(fn)
        if fn!=@fn
          @edit.text=File.read(fn)
          @fn=fn
          set_title("See Thing: #{fn}")
        end
    end
    def run_text
          return unless File.exists?(@fn) && @edit.text.size>0
          File.write("__a.rb",@edit.text)
          Thread.new { sleep(0.1) ; system($command,"__a.rb") }
    end
end
