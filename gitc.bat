rem @echo off
IF DEFINED %1=="" (
	call giti
	ruby  -e "a=File.read('VERSION').split('.') ; a[-1]=(a.last.to_i+1).to_s; puts r=a.join('.'); File.open('VERSION','w') {|f| f.write(r)}"
	git commit -a -m "%1 %2 %3 %4 %5 %6 %7 %8 %9"
	git push
)
:gem
call gem build Ruiby.gemspec
call :test_gem
call gem push Ruiby.gemspec
goto :eof

:test_gem
echo "test_gem..."
cd ..
gem install Ruiby/Ruiby*.gem
ruby -e "print File.read('Ruiby/samples/test.rb').gsub(/require_relative.*/,'require 'ruiby')" > RuibyGemTest/test.rb 
ruby  RuibyGemTest/test.rb
cd Ruiby 
goto :eof