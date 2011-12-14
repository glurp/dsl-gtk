call giti
ruby  -e "a=File.read('VERSION').split('.') ; a[-1]=(a.last.to_i+1).to_s; puts r=a.join('.'); File.open('VERSION','w') {|f| f.write(r)}"
git commit -a -m "%1 %2 %3 %4 %5 %6 %7 %8 %9"
git push