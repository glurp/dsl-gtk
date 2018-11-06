#!/usr/bin/ruby
# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative '../lib/Ruiby' 
#require 'Ruiby'

Ruiby.app(title: "Text my Animation", width: 900, height: 300) do
	l,size=nil,40
	stack  { l=label("Hello Ruiby...",font: "Arial bold #{1}",bg: "#05A") }
	after(500) do
		anim(20) do
			 size=size>100 ? 10 : size+0.2
			 options={
					font: 	"Arial bold #{size}", 
					fg: 	"#%02X%02X%02X" % [50+(200-size%200),50+size%200,50+size%200]
				}
			 apply_options(l, options)
		end
	end
end