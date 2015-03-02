# LGPL and Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
require_relative '../lib/Ruiby.rb'

class Object ; def puts(*t) $app.instance_eval { log("  >",*t) } end ; end


Ruiby.app width: 800, height: 400, title: "Demo script layout" do
  stack do
    labeli(<<-EEND,font: "Arial bold 12")
      This is demo of script layout. With this command, you can quickly create
      a HMI for a typical script.
    EEND
    script("Parameters",3,"package_name" => "Ruiby" , "version" => "3.0") do
        button("install",bg: "#FFAABB") { exe("gem install #{@ctx.package_name.value}") }
        button("remove",bg: "#AABBFF")  { exe("gem remove #{@ctx.package_name.value}")  }
        button("cleanup",bg: "#AA88AA") { exe("gem cleanup #{@ctx.package_name.value}") }
        button("push")                  { log("gem puts #{@ctx.package_name.value}.gem") }
        button("yank")                  { log("gem yank #{@ctx.package_name.value} -v #{@ctx.version.value} ")   }
        button("ls") { exe("ls -lt") }
    end
  end
  def exe(cmd)
    log cmd
    Thread.new {
      t=`#{cmd}` rescue $!.to_s
      gui_invoke { log(t); log("done.") }
    }
  end
end
