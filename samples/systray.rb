# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
#####################################################################################
#          systray.rb : configure a systray icon for run scripts
#   Usage : 
#     >systray open.png ddd.rb 
#     >systray open.png --menuitem1  rubyw ddd.rb ==menuitem2 ls.exe  --sep --quit
#     >systray <icon-name> --<menu-text> command.... ... [--sep] [--quit]
#####################################################################################
require_relative '../lib/Ruiby' 

Thread.abort_on_exception=true
icon=ARGV.shift
Ruiby.app do
  def end_command(item)
      lw=@lw.dup
      @lw=[]
      return if !item || item.size==0 || lw.size<1
      puts " menu: #{item} ==> #{lw.join(' ')}"
      if @style == :shell
        syst_add_button(item) { |state| system(*(["start",'"shell"',"/wait","cmd","/K"] + lw))}
      else
        syst_add_button(item) { |state| 
          system(*lw)
       }
      end
      @style=nil
  end
  
  systray(1000,0, icon: icon) do
    syst_icon icon
    @lw=[]
    @style=nil
    item="Execute"
    while word=ARGV.shift
        case word
          when "--sep" 
             end_command(item)
             syst_add_sepratator
          when '--quit' 
             end_command(item)
             syst_quit_button true
          when /^--([\d\w]*)$/  
             a=$1
             end_command(item)
             item=a
             @style=nil
          when /^==([\d\w]*)$/  
             a=$1
             end_command(item)
             item=a
             @style=:shell
          else
             @lw << word
        end
    end
    end_command(item)
  end # end component()
  after 1 do self.hide end
end
