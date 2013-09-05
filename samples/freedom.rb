#!/usr/bin/ruby
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

##############################################################################################
#  GPL in 'star-wars scroll' panel ...
##############################################################################################

require_relative '../lib/Ruiby'

TXT=<<EEND
Freeware ( of "free" and "software") is software that is available for use at no monetary cost or for an optional fee, but usually (although not necessarily)  with one or more restricted usage rights. Freeware is in contrast to commercial
 software, which is typically sold for profit, but might be distributed for a business or commercial  purpose in the aim to expand the marketshare of  a "premium" product. According to the  Free Software Foundation,"freeware" is a loosely defined category and it has no clear accepted  definition, 
although FSF says it must be distinguished from free software (libre) 

Copyright 2007 Free Software Foundation, Inc. http://fsf.org Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.

Preamble

The GNU General Public License is a free, copyleft license for software and other kinds of works. The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to any other work released this way by its authors.  You can apply it to your programs, too.

When we speak of free software, we are referring to freedom, not price.  Our General Public Licenses are designed to make sure that you have the freedom to distribute copies of free software (and charge for them if you wish), that you receive source code or can get it if you want it, that you can change the software or use pieces of it in new free programs, and that you know you can do these things.

To protect your rights, we need to prevent others from denying you these rights or asking you to surrender the rights.  Therefore, you have certain responsibilities if you distribute copies of the software, or if you modify it: responsibilities to respect the freedom of others.

For example, if you distribute copies of such a program, whether gratis or for a fee, you must pass on to the recipients the same freedoms that you received.  You must make sure that they, too, receive or can get the source code.  And you must show them these terms so they know their rights.

Developers that use the GNU GPL protect your rights with two steps: (1) assert copyright on the software, and (2) offer you this License giving you legal permission to copy, distribute and/or modify it.

For the developers' and authors' protection, the GPL clearly explains that there is no warranty for this free software.  For both users' and authors' sake, the GPL requires that modified versions be marked as changed, so that their problems will not be attributed erroneously to authors of previous versions.

Some devices are designed to deny users access to install or run modified versions of the software inside them, although the manufacturer can do so.  This is fundamentally incompatible with the aim of protecting users' freedom to change the software.  The systematic pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we have designed this version of the GPL to prohibit the practice for those products.  If such problems arise substantially in other domains, we stand ready to extend this provision to those domains in future versions of the GPL, as needed to protect the freedom of users.

Finally, every program is threatened constantly by software patents. States should not allow patents to restrict development and use of software on general-purpose computers, but in those that do, we wish to avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that patents cannot be used to render the program non-free. The precise terms and conditions for copying, distribution and modification follow.

EEND


class String 
  def decoupe(ss)   
    s=self
    l=[]
    while s.size > ss 
      l << s[0..ss]
      s=s[(ss+1)..-1]
      while s.size>0 && s[0]!=" "
        l.last << s[0]
        s=s[1..-1]
      end
    end 
    l 
  end 
end

Ruiby.app width: 1200,height: 800, title: "GPL "*50 do
  def get_text_size(ctx,fs,text)
    ctx.set_font_size(fs)
    e=ctx.text_extents(text)
    [e.width,e.height]
  end
  def text(ctx,fs,x,y,text)
    ctx.set_font_size(fs)
    ctx.set_line_width(1)
    #ctx.set_source_rgba(0, 0 ,0, 1)
    ctx.move_to(x,y)
    ctx.show_text(text)
  end
  
  @lt=TXT.split(/\s*\r?\n\s*/).join(" ").decoupe(20)
  @t,@decl=[], 0.0
  flow do
    space 20
    stack do
      space 4
      @cv=canvas(self.default_width,self.default_height,:expose     => proc do |w,ctx|  
        y=10
        12.times { |noline| 
            avance=(1.0*(12-noline))/12.0
            ctx.set_source_rgba(0.4,1-avance,avance,1-avance/4)
            decl=@decl.floor
            frac=@decl-decl
            t=@lt[(noline+decl) % @lt.size]
            fs=4+((noline+1-frac)*10).floor
            
            tw=get_text_size(ctx,fs,t)[0]
            x=[0,(default_width()-tw)/2].max
            text(ctx,fs,x,y,t) 
            y+=fs
          }
      end)
     space 4
    end
    space 20
  end
  anim 50 do  @decl = (@decl>@lt.size) ? 0 : (@decl+0.08) ; @cv.redraw end
  anim 200 do set_title(title[-1,1]+title[0..-2]) end
end
