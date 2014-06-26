require_relative '../lib/Ruiby' 
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

Ruiby.app width: 200,height: 100 do
  stack do
    label "  Testing log scrolling",font: "Arial bold 16  "
	space
    buttoni("go 1  ...") {  log('Hello') }
    buttoni("go 10  ...") { 10.times {|i| log('*'*i%100) } }
    buttoni("go 1000...") { 1000.times {|i| log((0..i%30).map {|i| i.to_s}.join('') ) } }
	space
    buttoni("methods") { show_methods "ee",/a/ }
	space
    label "  Testing window icon setting",font: "Arial bold 16  "
	space
    buttoni("set icon 1") { set_icon "media/angel.png" }
    buttoni("set icon 2") { set_icon "media/face_crying.png" }
    buttoni("anim") { anim(500) { set_icon "media/"+ %w{angel.png face_crying.png}[(Time.now.to_f*10).round%2] } }
  end
  log( "" )
end
