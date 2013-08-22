#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require 'Ruiby'

Ruiby.app(title: "Text Animation", width: 900, height: 300) do
	l=nil
	size=3
	stack do
		l=label("Hello Ruiby...",font: "Arial bold #{size}",bg: "#05A")
	end
		after(500) do
			anim(20) do
				 size=size>130 ? 30 : size+0.2
				 options={
						font: 	"Arial bold #{size}", 
						fg: 		"#%02X%02X%02X" % [50+(200-size%200),50+size%200,50+size%200]
					}
				 apply_options(l, options)
			end
		end
end