# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require_relative  '../lib/Ruiby'

Ruiby.app width: 400, height: 300, title: "Game of Life" do
  def freemap() l=[]; MAXC.times { l << [[false]*MAXL] } ; l end
  MAXC=MAXL=100
  PASX=default_width/MAXC
  PASY=(default_width)/MAXL
  @oldmat=freemap()
  @mat=freemap()
  @run=false
  
  stack do
    @formula = " old ?  (nb_neighboring == 2 || nb_neighboring == 3) : ( nb_neighboring == 3 )"
    flowi {
      labeli "Life Formula : "
      @edit=entry(@formula) 
      buttoni("enter")  { instance_eval "def formula(old,nb_neighboring) ; #{@edit.text} ; end" }
    }
    @cv=canvasOld(self.default_width,self.default_height,
          :mouse_down => proc do |w,e|   
            no= [e.x/PASX,e.y/PASY] ;  @mat[no.first][no.last]=! @mat[no.first][no.last]; no    
          end,
          :expose => proc do |w,ctx|  
            ctx.set_source_rgba(0,0.5,0.5)
            MAXC.times { |col| MAXL.times { |li| (ctx.rectangle(col*PASX,li*PASY,PASX,PASY); ctx.fill())  if @mat[col][li] }}
          end
    )
    
    flowi do
      button " clear " do @mat=freemap() ; @cv.redraw end
      tooltip("Hello <b>en gras</b> !")
      button " random " do 
        rand(MAXC*MAXL/10).times {  @mat[rand(MAXC)][rand(MAXL)]=true }
        @cv.redraw
      end
      button " start  " do @run=true ;end
      tooltip("Hello <b>en gras</b> !")
      button " stop   " do  @run=false ; end
    end    
  end
  
  anim 50 do  game() if @run ; @cv.redraw  end
  def game()
    mat2=@oldmat
    MAXC.times do |col| MAXL.times do |li|
          nb_neighboring= 0
          [-1, 0, 1].each { |col_off| [-1, 0, 1].each { |li_off|
              next if col_off == 0 && li_off == 0
              next if col+col_off < 0 || li+li_off < 0
              next if col+col_off >= MAXC || li+li_off >= MAXL
              nb_neighboring += 1 if @mat[col + col_off][li + li_off]
          } }          
          mat2[col][li]= formula(@mat[col][li],nb_neighboring)          
    end  end
    @oldmat,@mat=@mat,mat2 if @run    # seem that GTK:Timer use threading...?
  end
  def formula(old,nb_neighboring)
     old ?  (nb_neighboring == 2 || nb_neighboring == 3) : ( nb_neighboring == 3 )
  end
end