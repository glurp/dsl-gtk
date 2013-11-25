# encoding: utf-8
# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
# LGPL

require  'Ruiby'
require  'pp'

Ruiby.app width: 1000, height: 700, title: "Game of Analogic Life" do
  def freemap()  l=[]; MAXC.times { l << [0]*MAXL } ; l end
  MAXC=MAXL=120
  PASX=default_width/MAXC
  PASY=(default_width)/MAXL
  @oldmat=freemap()
  @mat=freemap()
  @run=false
  
  stack do
    def formula(opoids,poids)
         #--#
     opoids>30 ?  (opoids<82 ? (poids*1.0003) : poids*0.99 ) : ((opoids<10 && opoids>1) ? (100-poids/2) : (poids*0.93))
         #--#
    end
    @formula = File.read(__FILE__).split("#-"+"-#")[1].strip
    flowi {
      labeli "Life Formula : "
      @edit=entry(@formula) 
      buttoni("enter")  { instance_eval "  def formula(opoids,poids)  #{@edit.text} ; end" }
    }
    @cv=canvas(self.default_width,self.default_height,
          :mouse_down => proc do |w,e|   
            no= [e.x/PASX,e.y/PASY] ;  
            c=(@mat[no.first][no.last]>50 ? 0 : 100)            
            [-2,-1, 0, 1,+2].each { |col_off| [-2,-1, 0, 1,2].each { |li_off| @mat[no.first+col_off][no.last+li_off]=  c}}
            no    
          end,
          :expose => proc do |w,ctx|  
            MAXC.times { |col| MAXL.times { |li| 
               coul=1.0-(@mat[col][li] / 100.0)
               r,g,b=coul,coul,coul
               r=coul*2 if coul<0.4
               g*=2 if coul>0.8
               b*=2 if coul>0.4
               ctx.set_source_rgba(r,g,b)
               ctx.rectangle(col*PASX,li*PASY,PASX,PASY)
               ctx.fill()  
           }}
           #p @mat[MAXC/2][MAXL/2]
          end
    )
    
    flowi do
      button " clear " do @mat=freemap() ; @cv.redraw end
      button " random " do 
        rand(MAXC*MAXL/10).times {  @mat[rand(MAXC)][rand(MAXL)]=rand(10..90) }
        @cv.redraw
      end
      button " start  " do @run=true ;end
      button " stop   " do  @run=false ; end
      button " 3D   " do do_timeline(@mat) end
    end    
  end
  
  anim 200 do  game() if @run ; @cv.redraw  ; (make_curve() ; @ccc.redraw) if @ccc  end
  
  def game()
    mat2=@oldmat
    MAXC.times do |col| MAXL.times do |li|
          poids= 0; n=0
          [-1, 0, 1].each { |col_off| [-1, 0, 1].each { |li_off|
              next if col_off == 0 && li_off == 0
              next if col+col_off < 0 || li+li_off < 0
              next if col+col_off >= MAXC || li+li_off >= MAXL
              poids +=  @mat[col + col_off][li + li_off]
              n+=1
          } }          
          c=formula(@mat[col][li],poids/n)
          mat2[col][li] = ((c<0) ? 0 : (c>100 ? 100 : c))
    end  end
    @oldmat,@mat=@mat,mat2 if @run    # seem that GTK:Timer use threading...?
  end
  # end component()
  
  def do_timeline(mat)
    return unless mat
    dialog_async("3D view",response: proc  { |w,e| @ccc=false ; false }) do
      make_curve()
      @ccc=canvas(1000,800,{ 
          :expose     => proc do |w,cr|  
            color=::Gdk::Color.parse("#774433")
            color1=::Gdk::Color.parse("#334477")
            cr.set_line_width(2)
            @ll.reverse.each_with_index do |line,i|
              cr.set_source_rgba((color.red-i*200)/65000.0, (color.green+i*200)/65000.0, color.blue/65000.0, 1)
              pt0,*poly=*line
              cr.move_to(*pt0)
              poly.each {|px| cr.line_to(*px) } 
              cr.fill 
              cr.set_source_rgba((color1.red)/65000.0, (color1.green+i)/65000.0, (color1.blue-i*200)/65000.0, 1)
              pt0,*poly=*line
              cr.move_to(*pt0)
              poly.each {|px| cr.line_to(*px) } 
              cr.stroke 
            end
          end
      })
    end
  end
  def make_curve()
       mat=@mat
       @ll=[]
       0.step(MAXL-1,5).each_with_index do |l,ic| 
        lline=[]
        0.step(MAXC-1,1).each do |c|
           value=mat[c][l]
           lline << [(c+ic*3)*5,400+(400-value*4-ic*10)] 
        end
        @ll << [lline[0].tap {|pt| pt[1]=800}]+lline+[lline[-1].tap {|pt| pt[1]=800}]
      end
  end
end

