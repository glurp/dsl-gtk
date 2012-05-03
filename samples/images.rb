require_relative '../lib/ruiby'

Ruiby.app do
	stack do
		ARGV.each { |fn| 
			if File.exist?(fn) 
				label("#"+fn) 
			else
				label("unknown file '#{fn}'") 
			end
		}
	end
end