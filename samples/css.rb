# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

# Edit and try css declarration
#

require 'Ruiby'

$css=<<EEND
@define-color bg_color #cece00;
@define-color fg_color #ff0000;
@define-color base_color #fcfcfc;
@define-color text_color #000;
@define-color selected_bg_color #398ee7;
@define-color selected_fg_color #fff;
@define-color tooltip_bg_color #000;
@define-color tooltip_fg_color #e1e1e1;

* {
    engine: none;
  border-width: 9px;
  background: @bg_color ;
  border-radius: 39px;
  border-color: #fcfcfc;
  border-style: solid;
  color: @fg_color;
}
EEND

Ruiby.app width: 400, height: 300, title: "Css test" do
 def make_c()
   clear_append_to(@c) do
  label("a label")
        button("a bouton")
        check_button("a checkbox",true)
        flowi { label "ientry : "; ientry(22,min:0, max:100, by:2) }
  flowi {
    @l1=list("List 1...",w=100,h=300,options={})
    @l2=grid(%w{n1 n2 n3 n4},w=100,h=300,options={})
    @l1.set_data(('aaa'..'bbb').to_a)
    @l2.set_data(('aaa'..'bbb').map { |v| [v]*4 })
  }
  sloti(calendar())
   end
 end

 stack do
   flow do
      stack do
        @ed=source_editor(:lang=> "css").editor
        @ed.buffer.text=Ruiby.stock_get("css",$css)
        buttoni(" Load ") {
          css= @ed.buffer.text 
          Ruiby.stock_put("css",css)
          def_style( @ed.buffer.text )
          #make_c()
        }
      end
      @c=stack do end
      make_c()
   end
 end
end	