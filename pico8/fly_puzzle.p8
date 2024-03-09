pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- atk
-- lvl
--  up
shapes = "…∧░➡️⧗▤⬆️☉🅾️◆█★⬇️✽●♥웃⌂⬅️▥❎🐱ˇ▒♪😐"
tile_size=10
margin_x = 2
margin_y = 15
initial_speed = 0.2

goblin = {
  x = 1,
  new = function(self)
    local o = setmetatable({}, self)
    self.__index = self
    return o
  end,
  level_up= function(self)
    self.x += 1
  end,
}

man = {
  tile = "웃",
  new = function(self, x, y, dir_x, dir_y)
    local o = setmetatable({}, self)
    self.__index = self
    o.x = x
    o.y = y
    o.vx = dir_x
    o.vy = dir_y
    o.speed = initial_speed
    return o
  end,
  move = function(self)
    self.x += self.vx*self.speed
    self.y += self.vy*self.speed
  end,
  interact = function(self, building)
    if building.interact_with_man != nil then
      return building:interact_with_man(self)
    end
  end,
}

heart = {
  tile = "♥",
  new = function(self, x, y, dir_x, dir_y)
    local o = setmetatable({}, self)
    self.__index = self
    o.x = x
    o.y = y
    o.vx = dir_x
    o.vy = dir_y
    o.speed = initial_speed
    return o
  end,
  move = function(self)
    self.x += self.vx*self.speed
    self.y += self.vy*self.speed
  end,
  interact = function(self, building)
    if building.interact_with_heart then
      return building:interact_with_heart(self)
    end
  end,
}

song = {
  tile = "♪",
  new = function(self, x, y, dir_x, dir_y)
    local o = setmetatable({}, self)
    self.__index = self
    o.x = x
    o.y = y
    o.vx = dir_x
    o.vy = dir_y
    o.speed = initial_speed
    return o
  end,
  move = function(self)
    self.x += self.vx*self.speed
    self.y += self.vy*self.speed
  end,
  interact = function(self, building)
    if building.interact_with_song then
      return building:interact_with_song(self)
    end
  end,
}


house = {
  tile="⌂",
  x=0,
  y=0,
  new = function(self, x, y)
    local o = setmetatable({}, self)
    self.__index = self
    o.x = x
    o.y = y
    return o
  end,
  spawn = function(self)
    local o = man:new(self.x+1, self.y, 1, 0)
    return o
  end,
  interact_with_man = function(self, man)
    return {
      heart:new(self.x, self.y+1, 0, 1),     
      heart:new(self.x, self.y-1, 0, -1),     
--      heart:new(self.x+1, self.y, 1, 0),     
--      heart:new(self.x-1, self.y, -1, 0),     
    }
  end,
  interact_with_heart = function(self, man)
    return {
      song:new(self.x+1, self.y, 1, 0),     
      song:new(self.x-1, self.y, -1, 0), 
    }    
  end,
}

function rotate(o)
  if o.vx > 0 then
    o.vx = 0
    o.vy = 1
  elseif o.vx < 0 then
    o.vy = -1
    o.vx = 0
  elseif o.vy > 0 then
    o.vx = -1
    o.vy = 0
  elseif o.vy < 0 then
    o.vx = 1
    o.vy = 0
  end
  -- fixme: strange
  -- behaviour when object
  -- rotates again because
  -- still at the same rotator
  o.x += o.vx
  o.y += o.vy
end

rotator = {
  tile="➡️",
  x=0,
  y=0,
  new = function(self, x, y)
    local o = setmetatable({}, self)
    self.__index = self
    o.x = x
    o.y = y
    return o
  end,
  spawn = function(self)
    return nil
  end,
  interact_with_man = function(self, man)
    rotate(man)
  end,
  interact_with_heart = function(self, heart)
    rotate(heart)
  end,  
  interact_with_song = function(self, song)
    rotate(song)
  end,
}

function _init()
  tt = 0
  player = {
    x=0,
    y=0,
  }
  objects = {}
  next_level = function() end

  level1()
end

function draw_object(b, x, y, col)
  local abs_x=flr(x)*tile_size+margin_x
  local abs_y=flr(y)*tile_size+margin_y
  rect(
    abs_x,
    abs_y,
    abs_x+8,
    abs_y+8,
    col)
  print(b, abs_x+1,abs_y+2, col)
end

function get_building(x, y)
  for b in all(buildings) do
    if b.x == x and b.y == y then
      return b
    end
  end
  return nil
end

function has_building(x,y)
  local b = get_building(x,y)
  return b != nil
end


function has_goal(x,y)
  for b in all(goals) do
    if b.x == x and b.y == y then
      return true
    end
  end
  return false
end

function remove_building(x,y)
  local b = get_building(x,y)
  del(buildings, b)
  add(left_to_build, b)
end

function switch_building(x,y)
  local b = get_building(x,y)
  del(buildings, b)
  add(left_to_build, b)
end

function add_building(x, y)
  if has_building(x,y) then
    return remove_building(x, y)
  end
  -- cant build on goal
  if has_goal(x,y) then
    return
  end
  if #buildings >= 5 then
    return
  end
  if #left_to_build == 0 then
    return
  end
  
  local f = left_to_build[1]
  del(left_to_build, f)

  local b = f:new(x, y)
  add(buildings, b)
end

function _draw()
  cls(0)

  x=0
  y=64
  for i=0,16 do
    x += 8
    if x >= 128-8 then
      y += 8
      x = 0
    end
  end
  

  -- borders
  rect(0, 12, 127,127, 15)  
  
  -- player
  print("🐱",
    player.x*tile_size+margin_x+1, 
    player.y*tile_size+margin_y+2,
    15)
  -- buildings
  for b in all(buildings) do
    draw_object(b.tile, b.x, b.y, 3)
  end
  for o in all(objects) do
    draw_object(o.tile, o.x, o.y, 15)
  end
  for g in all(goals) do
    local c = 5
    fillp(▒)
    if g.done then
      c = 10
    end
    draw_object(g.tile, g.x, g.y, c)
    fillp()
  end
  -- panel
  rectfill(0,0, 128, 8, 15)
  rectfill(1,1, 126, 7, 14)
  -- left buildings
  print(level_name, 2, 2, 15)
  for i=1,#left_to_build do
    print(left_to_build[i].tile, 20+i*10, 2, 15)
  end
--  draw_object(shapes[to_build_index], 0, 0, 3)
end

function collision(a,b)
  return flr(a.x) == flr(b.x) and
         flr(a.y) == flr(b.y)
end

function is_win()
  -- why is it needed?
  -- race in load levels?
  if #goals == 0 then
    return false
  end
  for g in all(goals) do
    if not g.done then
      return false
    end
  end
  return true
end

function _update()
  tt+=1
  
  if btnp(⬅️) then
    player.x -= 1
  end
  if btnp(➡️) then
    player.x += 1
  end
  if btnp(⬆️) then
    player.y -= 1
  end
  if btnp(⬇️) then
    player.y += 1
  end
  player.x = mid(0, player.x, 11)
  player.y = mid(0, player.y, 10)  

  if btnp(❎) then
    add_building(player.x, player.y)
  end

  for o in all(objects) do
    o:move()
    if o.x > 15 or
       o.x < 0  or
       o.y > 15 or
       o.y < 0  then
      del(objects,o)
    end
  end

  -- sometime clear goals
  if #objects == 0 then
    -- check win 
    -- and go to next level
    if is_win() then
      next_level()
      sfx(1)
    end

    objects = {}
    for b in all(buildings) do
      local o = b:spawn()
      add(objects,o)
    end
    -- clear goals
    for g in all(goals) do
      g.done = false
    end
  end


  -- with buildings
  for o in all(objects) do
    for b in all(buildings) do
      if collision(o, b) then
        local created = o:interact(b)
        for r in all(created) do
          add(objects, r)
        end
        
        -- fixme: needed?
        if created != nil then
          del(objects, o)
          break
        end
      end
    end
  end
  
  
  -- with goals
  for o in all(objects) do
    for g in all(goals) do
      if o.tile == g.tile and
         collision(o,g) then
        del(objects, o)
        g.done = true
        sfx(0)
      end
    end
  end
end
-->8
-- levels

function level1()
  level_name = "level1"

  left_to_build = {
    house,
  }
  
  buildings = {
    house:new(5,5),
  }
  
  goals = {
    man:new(10, 5),
    man:new(10, 8)
  }
  next_level = level2
end

function level2()
  level_name = "level2"

  left_to_build = {
  }
  
  buildings = {
    house:new(0,0),
    rotator:new(2,10),
    rotator:new(10,0),
    rotator:new(10,10),
  }
  
  goals = {
    man:new(3, 3),
  }
  next_level = level3
end


function level3()
  level_name = "level3"

  left_to_build = {
    rotator,
  }
  
  buildings = {
    house:new(0,5),
    house:new(8,5),
  }
  
  goals = {
    heart:new(8, 1),
    heart:new(0, 8),
  }
  next_level = level4
end

function level4()
  level_name = "level4"

  left_to_build = {
    house,
    rotator,
    rotator,
    house,
  }
  
  buildings = {
  }
  
  goals = {
    heart:new(0, 0),
  }
  next_level = level1
end
__gfx__
00000000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888888000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700888888888000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000888888888000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc8000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccc8000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc8000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc8888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
fefeeefffefefefffefeeeffeeeeeeeefffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
fefeeefeeefefefeeefeeeefeeeeeeefffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
fefeeeffeefefeffeefeeeefeeeeeefffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
fefeeefeeefffefeeefeeeefeeeeeeefefefeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
fefffefffeefeefffefffefffeeeeeefefffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f00f00000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f00fffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f00f0fff0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f00f0fff0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f0000000000000000000000000000000000000000000000000003333333330000000000000000000000000000000fffffffff00505050500000000000000000f
f0000000000000000000000000000000000000000000000000003000000030000000000000000000000000000000f0000000f05000000050000000000000000f
f0000000000000000000000000000000000000000000000000003003330030000000000000000000000000000000f00fff00f00005550000000000000000000f
f0000000000000000000000000000000000000000000000000003033333030000000000000000000000000000000f00fff00f05005550050000000000000000f
f0000000000000000000000000000000000000000000000000003333333330000000000000000000000000000000f0fffff0f00055555000000000000000000f
f0000000000000000000000000000000000000000000000000003030303030000000000000000000000000000000f00fff00f05005550050000000000000000f
f0000000000000000000000000000000000000000000000000003030333030000000000000000000000000000000f00f0f00f00005050000000000000000000f
f0000000000000000000000000000000000000000000000000003000000030000000000000000000000000000000f0000000f05000000050000000000000000f
f0000000000000000000000000000000000000000000000000003333333330000000000000000000000000000000fffffffff00505050500000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050500000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005550000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005005550050000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005005550050000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505050500000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

__sfx__
0002000007150091500b1500c1501015011150171501a15021150211500a100091000810000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00080000155501455016550195501e5501b5501e55020500225002550027550275502c5502e550315503655038550005000050000500275502e550335503a5503a55000500005000050000500005000050000500
