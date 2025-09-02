pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- todo:
-- - randomize levels (choose random)
-- - opponent hand (mirror)
-- - infinite mode
-- - fake basket
-- - moving all things (even ui)
-- - no time or random time
-- - moving basket
-- - hidden fish (some kind of pointer)
-- - bad fish!
-- - elapsed for all levels (for example one minutes but score is different by levels)
-- - sequence of fish grabbing

infinite_mode = true

level5 = {
 fishes = 4,
 timeout=15,
 update=function()		 
		  local dx=0
		  local dy=0
		  p.ax = 0
		  p.ay = 0
		 -- change direction on btn
		 if btn(⬆️) then
		  dy = -p.speed
		 elseif btn(⬇️) then
		  dy = p.speed
		 else
		  dy = 0
		 end
		 
		 if btn(⬅️) then
		  dx = -p.speed
		 elseif btn(➡️) then
		  dx = p.speed
		 else
		  dx = 0
		 end
		
		  p.x += dx
		  p.y += dy

		 
		 for f in all(fish) do
		  f.no_grab = true
    if collision(f) and (
       abs(dx) >= 0.1 or
       abs(dy) >= 0.1 ) then
     f.ax += mid(-1,dx,1)
     f.ay += mid(-1,dy,1)
    else
     f.ax *= 0.95
     f.ay *= 0.95
    end
    f.x += f.ax
    f.y += f.ay
    if f.x < 0 then
     f.ax = 2
     f.ay += rnd(0.6)-0.3
    elseif f.x > 100 then
     f.ax = -2
     f.ay += rnd(0.6)-0.3
    end
    
    if f.y < 0 then
     f.ay = 2
     f.ax += rnd(0.6)-0.3
    elseif f.y > 100 then
     f.ay = -2
     f.ax += rnd(0.6)-0.3
    end
    
    
    if coll(f, basket) then
     in_basket(f)
    end
   end
 end,
 next=nil,
}


level4 = {
 fishes = 5,
 timeout=15,
 update=function()
		 
		  local dx=0
		  local dy=0
		  p.ax = 0
		  p.ay = 0
		 -- change direction on btn
		 if btn(⬆️) then
		  dy = -p.speed
		 elseif btn(⬇️) then
		  dy = p.speed
		 else
		  dy = 0
		 end
		 
		 if btn(⬅️) then
		  dx = -p.speed
		 elseif btn(➡️) then
		  dx = p.speed
		 else
		  dx = 0
		 end
		
		 local f
		 if p.grabbed != nil then
		  p.x += dx
		  p.y += dy
		 elseif #fish > 0 then
		  f = fish[1]
		  f.x += dx
		  f.y += dy 
		 end
 end,
 on_basket=function()
  p.x = 100
 end,
 next=level5,
}

level3 = {
 fishes = 6,
 timeout=20,
 update=function()
 
 -- change direction on btn
		 if btn(⬆️) then
		  p.ay = p.speed
		 elseif btn(⬇️) then
		  p.ay = -p.speed
		 else
		  p.ay = 0
		 end
		 
		 if btn(⬅️) then
		  p.ax = p.speed
		 elseif btn(➡️) then
		  p.ax = -p.speed
		 else
		  p.ax = 0
		 end
 
 end,
 next=level4,
}

level2 = {
 fishes = 4,
 timeout=20,
 update=function()
 
 if abs(p.ay) <= 0.01 then
  p.ay = p.speed
 end
 -- change direction on btn
 if btnp(⬆️) or btnp(⬇️) then
  p.ay = -p.ay
 end
 
 
 if btn(❎) or btn(⬅️) then
  p.ax = -p.speed
 else
  p.ax = p.speed
 end
 
 if p.y >= 100 or p.y <= 0 then
    p.ay = -p.ay
 end
 
 end,
 next=level3,
}


level1 = {
 fishes = 2,
 timeout=30,
 update=function()
   if p.y > 100 or p.y < 0 then
    p.ay = -p.ay
   end
		 
		 if btn(⬆️) then
		  p.ay = -p.speed
		 elseif btn(⬇️) then
		  p.ay = p.speed
		 else
		  p.ay = 0
		 end
		 
		 if btn(⬅️) then
		  p.ax = -p.speed
		 elseif btn(➡️) then
		  p.ax = p.speed
		 else
		  p.ax = 0
		 end
		 
 
 end,
 next=level2,
}

levels = {
 level2,
 level3,
 level4,
 level5,
}

function _init()
 cartdata("adz_fish_0")
 restart()
end

function  restart()
 winned = false
 high_score = dget(0) or 0
 
 
 score = 0
 nlevel = 1
 __draw = game_draw
 __update = game_update
 
 p = {
  x = 80,
  y = 40,
  ax = 0,
  ay = 0,
  speed = 1.5,
  grabbed = nil,
  grab=0,
 }

 fish = {}
 
 level = level1

 timeout = level.timeout*60

 
 basket = {
  x  = 30,
  y = rnd(60)+30,
 }
 spawn_fish()
end

function spawn_fish()
 for i=1,level.fishes do
  add_fish()
 end
end

function next_level()
-- if level.next == nil then
--  win()
--  return
-- end
 nlevel += 1
 level = rnd(levels)
 spawn_fish()
 
 basket = {
  x  = 30,
  y = rnd(60)+30,
 }
 score += flr(timeout/60)*nlevel
 timeout=(level.timeout-level_cap())*60
end

function level_cap()
 return nlevel/2
end

function add_fish()
 add(fish, {
  x=rnd(60)+10,
  y=rnd(80)+20,
  ax=0,
  ay=0,
  no_grab=false,
 })
end


function _update60()
 __update()
end

function game_update()
 timeout -=1
 p.x += p.ax
 p.y += p.ay
 level.update()

 if p.x >= 100 then
  p.x = 100
 end
 if p.x <= 0 then
  p.x = 0
 end

 if p.y >= 100 then
  p.y = 100
 end
 if p.y <= 0 then
  p.y = 0
 end
 
 for f in all(fish) do
  if collision(f) and 
     p.grabbed == nil and
     f.no_grab == false then
   grab(f)
   break
  end
 end
 
 if p.grabbed != nil 
   and collision(basket) then
  in_basket(p.grabbed)
 end

 if p.grabbed != nil then
  p.grabbed.x = p.x
  p.grabbed.y = p.y+8
 end

 if #fish == 0 then
  next_level()
 end
 
 if flr(timeout) <= 0 then
  gameover()
 end
end

function in_basket(f)
  score += 100 
  del(fish, f)
  p.grabbed = nil 
  if level.on_basket then
   level.on_basket()
  end
end

function collision(f)
 return sqrt((p.x - f.x)^2 + 
   (p.y - f.y)^2) <= 10
end

function coll(a, b)
 return dist(a,b) <= 10
end

function dist(a,b)
return sqrt((a.x - b.x)^2 + 
   (a.y - b.y)^2)
end

function grab(f)
 p.grabbed = f
end

function game_draw()
 cls()
 foreach(fish, draw_fish)
 draw_basket()
 draw_hand()
 draw_ui()
 -- draw_debug()
end

function draw_debug()
 circ(p.x, p.y, 1, 15)
 for f in all(fish) do
  circ(f.x, f.y, 1, 15)
  print(dist(f,p), f.x, f.y)
 end
end


function _draw()
 __draw()
end


function draw_ui()
 local xx = 30
 local yy = 0
 rrect(xx, yy, 80, 20, 3, 9)
 print("score:"..score, xx+4, yy+2)
 if timeout/60 <= 10 then
  print("⧗:"..flr(timeout/60).."-"..flr(level_cap()), 60, 22, rnd(16))
 else
  print("⧗:"..flr(timeout/60).."-"..flr(level_cap()), 60, 22, 3)
 end
 print("level:"..nlevel, xx+4, yy+10, 2)
end

function draw_basket()
 spr(37, basket.x, basket.y, 2, 2)
end

function draw_hand()
 local s = 5

 if p.grabbed then
  s = 7
 end

 spr(s, p.x,p.y, 2,2)
 for x=p.x+16,p.x+120, 16 do
  spr(33, x, p.y, 2,2)
 end
end

function draw_fish(f)
 spr(3, f.x, f.y, 2, 2)
end

-->8
-- gameover

function win()
 winned = true
 gameover()
end

function gameover()
 prev_high_score = high_score
 if score and score > high_score then
  high_score = score
  dset(0, score)
 end
 clicked = 0
 __draw = gameover_draw
 __update = gameover_update
end

function gameover_update()
 if btnp() > 0 then
  clicked += 1
 end
 if clicked >= 3 then
  restart()
  clicked = 0
 end
end

function gameover_draw()
 cls()
 
 if winned then
  print("winner!!!!", rnd(15))
 else
  print("gameover")
 end
 color(5)
 print("score:"..score)
 print("high score:"..high_score)
 print("previous high score:"..prev_high_score)
 print("")
 
 if score > prev_high_score then
  print("new high score", rnd(15))
 end
 
 print("  press  key ⬇️ 5 times ")
 for i=1,clicked do
   print("❎")
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000000ff0ff000000000000000000000000000ddddd00000000000ddddd0000000000000dd000000000000000000000000000000000000000000000000
000770000000ff00ff0000000000000000000000000ddd66dd000000000ddd66dd00000000000deed00000000000000000000000000000000000000000000000
0007700000fff0000f000000000000000000000000dd66666d00000000dd66666d00000000000deed00dddd00000000000000000000000000000000000000000
0070070000f000000fffffff008888888800000800d666666ddddddd00d666666ddddddd000000dd00deeedd0000000000000000000000000000000000000000
0000000000f000eee0000000088000000880008800dddd666666666600dd6666666666660dd0000000deeed00000000000000000000000000000000000000000
0000000000fff0eee000000088000000008888c800d666666666666600d6666666666666deed000000deed000000000000000000000000000000000000000000
0000000000ff00eee000000080080000000888c800d666666666666600d6666666666666deed000000deed000000000000000000000000000000000000000000
0000000000f0000000ffffff88000000008808c800dddd6666dddddd00dd666666dddddd0dd0000000deeed00000000000000000000000000000000000000000
0000000000f000000f000000088000000880008800d666666d00000000d666666d000000000000dd00deeedd0000000000000000000000000000000000000000
0000000000fff0000f000000008888888800000800d666666d00000000d666666d00000000000deed00dddd00000000000000000000000000000000000000000
00000000000fff0fff0000000000000000000000000ddd6ddd000000000ddd6ddd00000000000deed00000000000000000000000000000000000000000000000
0000000000000fff0000000000000000000000000000dddd000000000000dddd00000000000000dd000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000ddddd000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000ffffff0000000000022222220000000ddd66dd00000000000000000000000000000000000000000000000000000000000000
0000000000d0000ddd00000000fff0000f000000009988222228899000dd66666d00000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddd00f000000fffffff009098888888909000d666666ddddddd00000000000000000000000000000000000000000000000000000000
00000000666666666666666600f000eee0000000009009999999009000dddd666666666600000000000000000000000000000000000000000000000000000000
00000000666666666666666600fff0eee0000000009000000000009000d666666666666600000000000000000000000000000000000000000000000000000000
00000000666666666666666600ff00eee00000000090a9999999a09000d666666666666600000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddd00f0000000ffffff0090a0000000a09000dddd6666dddddd00000000000000000000000000000000000000000000000000000000
000000000000d000000d000000f000000f0000000090a9999999a09000d666666d00000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000ffffffff0000000090a0000000a09000d666666d00000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000090a9999999a090000ddd6ddd00000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000900000000000900000dddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000009000000000900000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000999999999000000000000000000000000000000000000000000000000000000000000000000000000000
