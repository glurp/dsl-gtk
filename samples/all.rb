# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

Dir.glob("*.rb").each { |s| 
 next if s ==__FILE__
	puts "="*50
	puts "                     #{s} "
	puts "^"*50
  system("ruby",s)
	puts "V"*50
	puts
	puts
	puts
}