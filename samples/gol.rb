# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require 'Ruiby'
Ruiby.app width: 900, height: 800, title: "Game of Life" do
  def freemap() m=[];MAXC.times { m<<[] ; MAXL.times {  m.last << false} } ; m end
  MAXC=MAXL=70
  PASX=default_width/MAXC
  PASY=(default_width-80)/MAXL
  @mat=freemap()
  @run=false
  
  stack do
    @formula = "new_ =  old ?  (relatives == 2 || relatives == 3) : ( relatives == 3 )"
    flowi {
      labeli "Life Formula : "
      @edit=entry(@formula) 
      buttoni("enter")  { instance_eval "def formula(old,relatives) ; #{@edit.text} ; end" }
    }
    @cv=canvas(self.default_width,self.default_height-80,
          :mouse_down => proc do |w,e|   
              no= [e.x/PASX,e.y/PASY] ;  @mat[no.first][no.last]=! @mat[no.first][no.last]; no    
          end,
          :expose => proc do |w,ctx|  
        ctx.set_source_rgba(0,0.5,0.5)
        MAXC.times { |col| MAXL.times { |li|
          (ctx.rectangle(col*PASX,li*PASY,PASX,PASY); ctx.fill())  if @mat[col][li]
        }}
    end)
    
    flowi do
      button " clear " do @mat=freemap() ; @cv.redraw end
      button " random " do 
        rand(MAXC*MAXL/10).times {  @mat[rand(MAXC)][rand(MAXL)]=true }
        @cv.redraw
      end
      button " start  " do @run=true ;end
      button " stop   " do  @run=false ; end
    end    
  end  
  
  anim 20 do  game() if @run; @cv.redraw end
  
  def game()
    mat2=freemap()
    MAXC.times do |col| MAXL.times do |li|
          relatives = 0
          [-1, 0, 1].each { |col_off| [-1, 0, 1].each { |li_off|
              next if col_off == 0 && li_off == 0
              next if col+col_off < 0 || li+li_off < 0
              next if col+col_off >= MAXC || li+li_off >= MAXL
              relatives += 1 if @mat[col + col_off][li + li_off]
          } }          
          mat2[col][li]= formula(@mat[col][li],relatives)          
    end  end
    @mat=mat2 if @run    # seem that GTK:Timer use threading...?
  end
  def formula(old,relatives)
     new_ =  old ?  (relatives == 2 || relatives == 3) : ( relatives == 3 )
  end
end