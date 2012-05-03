require_relative '../lib/ruiby'
Ruiby.app do
	stack do
		ARGV.each { |fn| 
			label File.exist?(fn) ? 
				"#"+fn : 
				"Oups !! unknown file '#{fn}'" 
		}
	end
end
