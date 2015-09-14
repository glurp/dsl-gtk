require "gtk3"

include Gtk

window = Window.new

cv=DrawingArea.new()
cv.width_request=400
cv.height_request=100
cv.events |= ( Gdk::Event::Mask::LEAVE_NOTIFY_MASK |
    Gdk::Event::Mask::BUTTON_PRESS_MASK |
    Gdk::Event::Mask::POINTER_MOTION_MASK |
    Gdk::Event::Mask::POINTER_MOTION_HINT_MASK)
    
cv.signal_connect("button_press_event")   { |w,e| 
          puts "button: #{ '%16X' % e.button} #{e.class}"
          puts "======================="
          e.methods.select {|m| m.to_s=~/=$/ }.each {|m| 
              name=m.to_s[0..-2]
              puts "e.#{name} => #{e.send(name)}" rescue nil 
         }
}

window.add(cv).show_all
Gtk.main
