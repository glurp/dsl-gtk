@echo off
IF DEFINED %1=="" (
	call giti
	ruby  -e "a=File.read('VERSION').split('.') ; a[-1]=(a.last.to_i+1).to_s; puts r=a.join('.'); File.open('VERSION','w') {|f| f.write(r)}"
	echo "%1 %2 %3 %4 %5 %6 %7 %8 %9" >> CHANGELOG.txt
	git commit -a -m "*  %1 %2 %3 %4 %5 %6 %7 %8 %9"
	git push
	echo
	echo call gitc.bat without args for make/post rubygem
	goto :eof
)
:gem
rem ==== no args, pgenerate gem and push it to rubygems.org

ruby  -e "a=File.read('VERSION').split('.').pop ; a[-1]=(a.last.to_i+1).to_s; puts r=(a+%{0}).join('.'); File.open('VERSION','w') {|f| f.write(r)}"
ruby -e "Dir.glob('Ruiby*.gem').each {|f| File.delete(f) }"
call gem build Ruiby.gemspec
call :test_gem
call gem push Ruiby*.gem
goto :eof

:test_gem
echo
echo test_gem...
cd ..
call gem install Ruiby/Ruiby*.gem
ruby -e "print File.read('Ruiby/samples/test.rb').gsub(/require_relative.*uiby.*/,'require \"ruiby\"')" > RuibyGemTest/test.rb 
ruby  RuibyGemTest/test.rb
cd Ruiby 
goto :eof