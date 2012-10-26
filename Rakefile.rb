#################################################################
#  Rakefile : git commit/add *.rb, git push, test & gem push
#################################################################
#
# Usage:
#	> rake commit  # commit in local directory and push to repository
#   > rake gem	   # commit and make gem (and test it) and push to gemcutter !
#
#################################################################
#  Requirments :
#		auto-commit only .rb files
#		one application for test : samples/test.rb
#		tested only on windows !
#		version : X.Y.Z X: 
#           X   : to be hand-modified 
#           Y.Z : increment Y/0 to Z for each gem generation
#           Z   : increment on each (one or more) file commit(s)
#
#  to be better:
#     it create a ._ file (empty)  for each ruby file. 
#     is be done in a cached directory : marker
#
#     Perhaps should use git status output
#################################################################

# gem name is name of current directory

NAME= Dir.pwd.gsub(File.dirname(Dir.pwd)+'/',"")

Rake.application.options.trace = false

def push_changelog(line)
  b=File.read('CHANGELOG.txt').split(/\r?\n/) 
  b.unshift(line)
  File.open('CHANGELOG.txt','w') {|f| f.write(b[0..500].join("\n")) }
end
def changelog_push_currrent_versions()
  version=File.read('VERSION').strip
  b=File.read('CHANGELOG.txt').split(/\r?\n/) 
  b.unshift(version)  
  File.open('CHANGELOG.txt','w') {|f| f.write(b.join("\n")) }
  yield rescue p $!.to_s
  b.shift  
  File.open('CHANGELOG.txt','w') {|f| f.write(b.join("\n")) }
end

def change_version()
  a=File.read('VERSION').strip.split('.')[0..2]
  yield(a)
  version=a.join('.') 
  File.open('VERSION','w') {|f| f.write(version) }
  version
end


######################## Comment each file modified ######################


desc "commit file changed and created"
task :commit_status do
  `git status -s`.split(/\r?\n/).each do |line|
	words=line.split(/\s+/)
	case line
		when /^ M /
			filename=words[2]
			print("Comment for change in #{filename} : ")
			comment=$stdin.gets
			if comment && comment.chomp.size>0
				  comment.chomp!
				  (puts "Abort!";exit!) 	if comment=~/^a(b(o(r(t)?)?)?)?$/
				  sh "git commit #{filename} -m \"#{comment.strip}\"" rescue 1
				  push_changelog("    #{File.basename(filename)} : #{comment}")
				  $changed=true
			end
		when /^\?\?/
			filename=words[1]
			print("Comment for new file in #{filename} : ")
			comment=$stdin.gets.chomp
		    (puts "Abort!";exit!) 	if comment=~/^a(b(o(r(t)?)?)?)?$/
			if comment =~ /^y|o/i
				sh "git add #{src.source}"
				sh "git commit #{filename} -m \"creation\"" rescue 1
				$changed=true
			end
	end
  end
end


desc "job before commit"
task :pre_commit do
	puts RUBY_PLATFORM
	sh "cls" if RUBY_PLATFORM =~ /(win32)|(mingw)/i 
	puts <<EEND2


--------------------------------------------------------------------
                 Commmit and push #{NAME}
--------------------------------------------------------------------
EEND2
	
	#sh "giti"
	$changed=false
end

desc "job after local commit done: push to git repo"
task :post_commit do
  if $changed
	  $version=change_version { |a| a[-1]=(a.last.to_i+1) }  
      sh "git commit VERSION -m update"
	  changelog_push_currrent_versions {
		  sh "git commit CHANGELOG.txt -m update"
		  sh "git push"
		  puts "\n\nNew version is #{$version}\n"
	  } 
  else
	puts "no change!"
  end
end

desc "commit local and then distant repo"
task :commit => [:pre_commit,"commit_status",:post_commit]


desc "make a gem and push it to gemcutter"
task :gem => :commit do
	puts <<EEND


--------------------------------------------------------------------
       make gem, test it localy, and push gem #{NAME} to gemcutter
--------------------------------------------------------------------
EEND
	$version=change_version { |a| 
			a[-2]=(a[-2].to_i+1) 
			a[-1]=0 
	}   
	puts "New version ==>> #{$version}"
	l=FileList['*.gem']
	l.each { |fn| rm fn }
	gem_name="#{NAME}-#{$version}.gem"
	push_changelog  "#{$version} : #{Time.now}"
	sh "gem build #{NAME}.gemspec"
	Rake::Task["test"].execute		if File.exists?("samples/test.rb")
	sh "gem push #{gem_name}"
	l.each { |fn|
      ov=fn.split('-')[1].gsub('.gem',"")
	  sh "gem yank -v #{ov} #{NAME}"
	}
end

desc "test the current version of the framework by installing the gem and run a test programme"
task :test do
 cd ".."
 mkdir "#{NAME}Test" unless File.exists?("#{NAME}Test")
 nname="#{NAME}Test/test.rb"
 content=File.read("#{NAME}/samples/test.rb").gsub(/^\s*require_relative/,"require").gsub('../lib/','')
 File.open(nname,"w") { |f| f.write(content) }
 sh "gem install #{FileList["#{NAME}/#{NAME}*.gem"][-1]}"
 ruby  nname
 cd NAME
 puts "\n\nOk for diffusion ?"
 rep=$stdin.gets
 raise("aborted!") unless rep && rep =~ /^y|o|d/
end


task :travis do
 puts "Starting travis test..."
 cmd="bundle exec rspec spec/test_all.rb"
 system("export DISPLAY=:99.0 && #{cmd}")
 #system(cmd)
 raise "rspec failed!" unless $?.exitstatus == 0
end


