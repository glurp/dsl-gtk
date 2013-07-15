#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL
require 'Ruiby'
TXT=<<EEND
Freeware ( of "free" and "software") is software that is available for use at 
no monetary cost or for an optional fee, but usually (although not necessarily) 
with one or more restricted usage rights. Freeware is in contrast to commercial 
software, which is typically sold for profit, but might be distributed for 
a business or commercial  purpose in the aim to expand the marketshare of 
a "premium" product. According to the  Free Software Foundation,"freeware" 
is a loosely defined category and it has no clear accepted  definition, 
although FSF says it must be distinguished from free software 
(libre).
EEND

Ruiby.app width: 800,height: 400, title: "Wikipedia freedom freeware Wikipedia freedom freeware Wikipedia                 " do
  flow do
    space 4
    stack do
      space 2
      TXT.split(/\r?\n/).each_with_index {|t,size|  label(t,font: "Arial #{4+2*size}",height: 10) }
      space 2
    end
    space 4
  end
  anim 200 do set_title(title[-1,1]+title[0..-2]) end
end