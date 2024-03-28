pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- game loop

chosen = 1

function _init()
  cartdata("adz_cards_1")
  max_level = dget(0)
  show_start_screen()
end

function default_deck()
  local cards  = {}
  for suit=0,3 do
    for rank=2,14 do
      add(cards, new_card(suit, rank))
    end
  end
  return cards
end

function restart_game()
  _drw = draw_game
  _upd = update_game
  hand = {}
  deck = {}
  upgrades = {}
  to_discard = {}
  to_play = {}
  level = 1
  score = 0
  max_plays = 4
  max_discards = 4
  score_needed = 300
  play_left = max_plays
  discards_left = max_discards
  my_deck = default_deck()

  -- fill deck
  for c in all(my_deck) do
    add(deck, c)
  end
  draw_hand()
end

function next_level()
  level += 1
  score = 0
  score_needed = flr(1.5*score_needed)  play_left = max_plays
  discards_left = max_discards
  -- todo: dry with restart!!!
  deck = {}
  hand = {}
  for c in all(my_deck) do
    c.play = false
    c.discard = false
    add(deck, c)
  end
  draw_hand()
  _drw = draw_game
  _upd = update_game
end

function draw_hand()
  for i=1, 8-#hand do
    local card = rnd(deck)
    add(hand, card)
    del(deck, card)
  end
  sort_cards(hand)
end

function _update()
  _upd()
end

function _draw()
  _drw()
end

function random_card()
  return {
    rank=flr(rnd(13)+1),
    suit=flr(rnd(3)+1),
    discard=false,
    play=false,
  }
end

function toggle_to_play(idx)
  local cnt = 0
  for c in all(hand) do
    c.discard = false
    if c.play then
      cnt += 1
    end
  end
  if not hand[idx].play and
     cnt < 5 then
    hand[idx].play = true
  else
    hand[idx].play = false
  end
end

function toggle_to_discard(idx)
  local cnt = 0
  for c in all(hand) do
    c.play = false
    if c.discard then
      cnt += 1
    end
  end
  
  if hand[idx].discard then
    hand[idx].discard = false
    return nil    
  end
  if cnt >= 5 then
    return nil
  end
  
  hand[idx].discard = true
end


function update_game()
  if btnp(⬅️) then
    chosen -= 1
  end
  if btnp(➡️) then
    chosen += 1
  end
  if chosen > #hand then
    chosen = 1
  elseif chosen <= 0 then
    chosen = #hand
  end
  
  if #hand == 0 then
    restart_game()
  end

  -- discard
  if btnp(⬇️) then
    for_discard = true
    toggle_to_discard(chosen)
  end
  -- play
  if btnp(⬆️) then
    for_discard = false
    toggle_to_play(chosen)
  end


  
  to_play = {}
  for c in all(hand) do
    if c.play then
      add(to_play, c)
    end
  end

  to_discard = {}
  for c in all(hand) do
    if c.discard then
      add(to_discard, c)
    end
  end

  
  preview = play_preview(to_play)
  if btnp(❎) then
    if for_discard and
       #to_discard >= 1 and
       #to_discard <= 5 and
       discards_left > 0 then
      discard()
    elseif #to_play > 0 and #to_play <= 5 then
      turn()
    end
  end
  if btn(🅾️) then
    show_info_screen()
--    sort_by_suit = not sort_by_suit
--    hand = sort_cards(hand, sort_by_suit)
  end
end

function draw_card(c, x, y, col, border_color)
  palt(0, false)

  if border_color == nil then
    border_color = 1
  end
  pal(1, border_color)


  palt(11, true)
  -- change border color
  --pal(5, rnd{8,21})
  spr(5,x,y, 4, 6)
  
  palt(11, true)
  -- big suit??
  -- spr(192+2*c.suit, x+8,y+16, 2,2) 
  -- small suit
  spr(200+2*c.suit, x+5, y+34, 2,2) 
  -- inverted
  spr(200+2*c.suit, x+12, y-4, 2,2, true, true) 


  -- rank
  local rank_sprite = 224
  if c.rank <=14 then
    rank_sprite = 224+c.rank-1
  end
  
  spr(rank_sprite, x+4,y+4)
  spr(rank_sprite, x+20,y+35, 1,1,true, true)
  
  -- face center
  if c.rank >= 11 and 
     c.rank <= 13 then
    spr(135+2*(c.rank-11), x+8,y+16,2,2)
  end
  palt()
  pal()
end

function draw_game()
  cls(0)
  for i=1,#hand do
    local c = hand[i]
    
    x = (i-1)*16
    y = 62
    local col = nil
    if chosen == i then
      y += 2*sin(t())
    end
    if c.play then
      y -= 10
    elseif c.discard then
      y += 10
      col = 14
    end

    local border = nil
    if i==chosen then
      border=9
    end

    draw_card(c, x,y, col, border)
  end
 
  
  if #to_discard != 0 then
    print("discard "..
      #to_discard..
      " cards", 16, 40, 14)
  end
  if #to_play != 0 then
    print("play \fa"..preview.name, 16, 40, 5)
    print("+"..
      preview.chips.."*"..
      preview.multiplier, 
      36, 46, 15)
  end

  print("\f5score \ff"..score.."/"..score_needed, 48, 16, 12)

  if play_left != 1 or (t()*2)%2 >= 1 then
    print("HANDS   :"..play_left, 3, 116, 10)
  end
  if discards_left != 1 or (t()*2)%2 >= 1 then
    print("DISCARDS:"..discards_left, 3, 122, 14)
  end
  print("LEVEL "..level, 96,122, 5)
--  print("DECK "..#deck.."/"..#my_deck, 0,122)
end


-->8
-- turn

function turn()
  tt = 0
  anim_speed = 45
  turn_cards = {}
  cur_score = 0

  _upd = update_turn
  _drw = draw_turn


  play_left -= 1
  for c in all(hand) do
    if c.play then
      add(turn_cards, c)
      del(hand, c)
    end
  end
  chips,mult,cur_hand = calc_score(turn_cards, upgrades)
  old_score = score
  hand_score = chips*mult
  score += hand_score
  anim_score = score
end

function discard()
  tt = 0
  turn_cards = {}
  cur_score = 0

  discards_left -= 1
  for c in all(hand) do
    if c.discard then
      del(hand, c)
    end	
  end
  draw_hand()
end


function draw_turn()
  cls(0)
  
  local width = 32
  if #turn_cards == 5 then
    width = 24
  end
  
  local x = 64-#turn_cards*(width/2)
  local y = 64
  for c in all(turn_cards) do
    print("+"..c.chips, x, y-6, 12)
    draw_card(c, x, y)
    x+=width
  end

  if cur_hand then
    print(
      cur_hand.name.." "..
        cur_hand.chips.."*"..cur_hand.mult,
      32, y-16,5)
    print("\f5score \ff"
      ..flr(anim_score)
      .."/"..
      score_needed, 48, 16, 12)
    print("\f5hand score \ff"
      ..hand_score
      , 48, 24, 12)
  end
  
  print("press ❎ to skip", 32, 120, 5)

  if score >= score_needed then
    print("congrats! next level!", 32, 32, rnd(15))
  end
end

function lerp(a,b,step)
  return a + (b-a)*step
end

function update_turn()
  tt += 1
  anim_score = 
    flr(lerp(old_score, score, tt/anim_speed))
  
  anim_score = min(score, anim_score)
  if tt % 4 == 0 and anim_score < hand_score then
    sfx(1)
  end
  if tt >= anim_speed or btnp(❎) then
    sfx(1, -2)     
    if score >= score_needed then
      sfx(0)
      init_shop()
    elseif play_left == 0 then
      game_over()
    else
      draw_hand()
      _upd = update_game
      _drw = draw_game
    end
  end
end

function game_over()
  if not max_level  
     or max_level < level then
    max_level = level
    dset(0, level)
  end
  show_game_over()
end
-->8
-- poker hands

function new_card(suit, rank)
  -- ace
  local chips = rank
  if rank == 14 then
    chips = 11
  elseif rank >= 11 then
    chips = 10
  end

  return {
    rank=rank,
    suit=suit,
    chips=chips,
    discard=false,
    play=false,
  }
end

function poker_hand_name(cards)
  if #cards == 0 then
    return ""
  end

  for kind in all(poker_hands) do
    local scored = kind.get(cards)
    if scored != nil then
      return kind.name
    end
  end
end

function concat_cards(cs1, cs2)
  local result = {}
  for c in all(cs1) do
    add(result, c)
  end
  for c in all(cs2) do
    add(result, c)
  end
  return result
end

function remove_cards(cards, to_remove)
  local result = {}
  for c in all(cards) do
    add(result, c)
  end
  for c in all(to_remove) do
    del(result, c)
  end
  return result
end

function play_preview(cards)
  if #cards == 0 then
    return nil
  end
  local name = poker_hand_name(cards)
  local chips, mult, kind, lvl = calc_score(cards, upgrades)
  
  local lvl_color = "\f5"
  if lvl > 1 then
    lvl_color = "\ff"
  end
  return {
    name=name
      ..lvl_color.." lvl"..lvl,
    chips=kind.chips,
    score=kind.multiplier,
    multiplier=mult,
  }
end

function sort_cards(cards, by_suit)
  local cmp_rank = function(a,b)
    return a.rank > b.rank
  end
  local cmp_suit = function(a,b)
    return a.suit > b.suit
  end
  
  local cmp = cmp_rank
  if by_suit then
    cmp = cmp_suit
  end

  for i=1, #cards-1 do
    for j=i+1, #cards do
      if cmp(cards[i],cards[j]) then
        cards[i],cards[j] = 
          cards[j], cards[i]
      end
    end
  end
  return cards
end

function get_n_of_kind(n)
  return function(cards)  
    for card in all(cards) do
      local cnt = 0
      local matched = {}
      for other in all(cards) do
        if card.rank == other.rank then
          cnt+=1
          add(matched, other)
        end 
      end
      if cnt == n then
        return matched
      end
    end
  end
end

local high_card = {
  name="high card",
  chips=5,
  mult=1,
  get=function(cards)
	  if #cards == 0 then
	    return nil
	  end
	  local high_card = cards[1]
	  for card in all(cards) do
	    if card.rank > high_card.rank then
	      high_card = card
	    end
	  end
	  return {high_card}
  end,
}

local pair = {
	name = "pair",
	chips = 10,
	mult  = 2,
	get = function (hand)
	  for card in all(hand) do
	    for other in all(hand) do
	      if card != other then
	        if card.rank == other.rank then
	          return {card, other}
	        end 
	      end
	    end
	  end
	  return nil
	end,
}

local two_pairs = {
  name="two pairs",
  chips=20,
  mult=2,
  get=function(cards)  
    local first_pair = pair.get(cards)
	  if not first_pair then
	    return nil
	  end
	  
	  -- remove first pair cards
    local left = remove_cards(cards, first_pair)
	  -- and check again for pairs
	  local second_pair = pair.get(left)
	  if not second_pair then
	    return nil
	  end
	  return concat_cards(
	    first_pair,
	    second_pair)
  end
}

local three = {
  name="three of kind",
  chips=30,
  mult=3,
  get=get_n_of_kind(3),
}

local flush = {
  name="flush",
  chips=35,
  mult=4,
  get=function(cards)  
    for card in all(cards) do
      local cnt = 0
      local matched = {}
      for other in all(cards) do
        if card.suit == other.suit then
          cnt+=1
          add(matched, other)
        end 
      end
      if cnt == 5 then
        return matched
      end
    end
  end,
}


straight = {
  name="straight",
  chips=30,
  mult=4,
  get=function(cards)
    for card in all(cards) do 
      local need_ranks = {
        card.rank+0,
        card.rank+1,
        card.rank+2,
        card.rank+3,
        card.rank+4,
      }
      local matched = {}
      for c in all(cards) do
        if del(need_ranks, c.rank) != nil then
          add(matched, c)
        end
      end
      if #need_ranks == 0 then
        return matched
      end
    end
  end,
}

straight_flush = {
  name="straight flush",
  chips=100,
  mult=8,
  get=function(cards)
     return 
       straight.get(
         flush.get(
           cards))    
  end,
}

full_house = {
  name="full house",
  chips=40,
  mult=4,
  get=function(cards)  
    local first = three.get(cards)
	  if not first then
	    return nil
	  end
	  
	  -- remove first three cards
    local left = remove_cards(cards, first)
	  -- and check again for pairs
	  local second_pair = pair.get(left)
	  if not second_pair then
	    return nil
	  end
	  return concat_cards(
	    first,
	    second_pair)
  end
}

four = {
  name="four of kind",
  chips=60,
  mult=7,
  get=get_n_of_kind(4),
}

five = {
  name="five of kind",
  chips=120,
  mult=12,
  get=get_n_of_kind(5),
}

poker_hands={
  straight_flush,
  four,
  straight,
  full_house,
  flush,
  three,
  two_pairs,
  pair,
  high_card,
}

function apply_upgrades(kind, upgrades)
  local chips = kind.chips
  local mult  = kind.mult
  -- apply upgrades
  local lvl = 1
  for u in all(upgrades) do
    if u.upgrades == kind then
      chips += u.chips
      mult += u.mult
      lvl += 1
    end
  end
  return {
    name=kind.name,
    chips=chips,
    mult=mult,
    get=kind.get,
    lvl=lvl,
  }
end

function match_hand(cards)
  for k in all(poker_hands) do
    scored_cards = k.get(cards)
    if scored_cards != nil then
      return k, scored_cards
    end
  end
end

function calc_score(cards, upgrades)
  local kind,scored_cards = match_hand(cards)
  kind = apply_upgrades(kind, upgrades)
  local chips = kind.chips
  local mult = kind.mult

  -- apply scored cards
  for s in all(scored_cards) do
    chips += s.chips
  end
  return chips,mult,kind,kind.lvl
end

-->8
-- jokers


function joker_runner() 
  return {
    chips=20,
    before_mult=
     function(self, player, hand)
        return nil
      end,
    after_play_hand=
      function(self, player, hand)
        if hand.is_straight() then
          self.chips +=  10
        end
      end,
  }
end
-->8
-- shop


-- todo: choice
-- - planet
-- - destroy card
-- - joker

pluto = {
  name="pluto",
  planet=true,
  upgrades=high_card,
  mult=1,
  chips=10,
}

mercury = {
  name="mercury",
  planet=true,
  upgrades=pair,
  mult=1,
  chips=15,
}

uranus = {
  name="urAnus",
  planet=true,
  upgrades=two_pairs,
  mult=1,
  chips=20,
}


jupiter = {
  name="jupiter",
  planet=true,
  upgrades=flush,
  mult=2,
  chips=15,
}

venus = {
  name="venus",
  planet=true,
  upgrades=three,
  mult=2,
  chips=20,
}

earth = {
  name="earth",
  planet=true,
  upgrades=full_house,
  mult=2,
  chips=25,
}

saturn = {
  name="saturn",
  planet=true,
  upgrades=straight,
  mult=2,
  chips=30,
}

mars = {
  name="mars",
  planet=true,
  upgrades=four,
  mult=3,
  chips=30,
}

neptune = {
  name="neptune",
  planet=true,
  upgrades=straight_flush,
  mult=3,
  chips=40,
}

all_upgrades={
  pluto,
  mercury,
  uranus,
  jupiter,
  venus,
  earth,
  saturn,
  mars,
  meptune,
}

function init_shop()
  shop = {
    upgrades= {
      rnd(all_upgrades),
      rnd(all_upgrades),
      rnd(all_upgrades),
    },
    confirm=false,
    selected=1,
  }
  _upd = update_shop
  _drw = draw_shop
end

function update_shop()
  if btnp(⬅️) then
    shop.selected -= 1
    shop.confirm = false
  end
  if btnp(➡️) then
    shop.selected += 1
    shop.confirm = false
  end
  shop.selected = mid(
    1, 
    shop.selected, 
    #shop.upgrades)
    
  if btnp(❎) then
    if shop.confirm then
      add(
        upgrades,
        shop.upgrades[shop.selected])
      next_level()
    else
      shop.confirm = true
    end
  end
  
  if btn(🅾️) then
    show_info_screen()
--    sort_by_suit = not sort_by_suit
--    hand = sort_cards(hand, sort_by_suit)
  end
end

function draw_shop()
  cls()
  print("\^w shop\^-w", 25,0,15)
  print("\^w shop\^-w", 24,1,14)  
  local x = 64 - 16*#shop.upgrades
  for i=1,#shop.upgrades do
    local u = shop.upgrades[i]
    local y = 64
    if shop.selected == i then
      y = y+2*sin(t())
      if shop.confirm then
        print(
          "press ❎ to buy",
          x-12, y-10)
      end
    end
    if u.planet then
      draw_shop_planet(u, x, y, shop.selected == i)
    end
    x+= 32
  end
end

function upgrade_level(planet, upgrades)
  local lvl = 1
  for u in all(upgrades) do
    if planet.upgrades == u.upgrades then
      lvl+=1
    end
  end
  return lvl
end

function draw_shop_planet(p, x, y, selected)
  local lvl = upgrade_level(p, upgrades)
  if selected then
    local chips = 
      p.upgrades.chips + 
      p.chips*lvl
    local mult = 
      p.upgrades.mult + 
      p.mult*lvl
    print(p.name, 32, 16, 15)
    print("upgrades "..p.upgrades.name,6)
    print("to lvl"..lvl+1, 6)
    print("+ "..chips, 12)
    print("* "..mult, 8)
  end
 
  clip(x,y,4*8, 6*8)
  palt(11,true)
  spr(5, x, y, 4, 6)
  print(p.name, x+3,y+4,15)
  --print("lvl"..lvl, x+3,y+20,6)
  print("+ "..p.chips, 12)
  print("* "..p.mult, 8)
  palt()
  clip()
end
-->8
-- info screen
-- when press 🅾️

function show_info_screen()
  info_screen = {
    tt = 0,
    _drw = _drw,
    _upd = _upd,
  }
  _drw = draw_info_screen
  _upd = update_info_screen
end

function draw_info_screen()
  local h = min(128, info_screen.tt*10)
  clip(0,0,128,h)
  rectfill(0,0, 128, h, 10)
  rectfill(1,1, 126, h-2, 5)
  local y = 2
  for h in all(poker_hands) do
    h = apply_upgrades(h, upgrades)
    print(h.name, 2, y, 15)
    print(" lvl"..h.lvl, 64, y, 15)
    print("+"..h.chips,96, y, 12)
    print("*"..h.mult,112, y, 8)
    y+=6
  end


  -- remaining cards in deck
  -- rank header
  print("deck cards",22, y+3, 10)
  y+= 10

  local x = 10
  for r=2,14 do
    local c = new_card(s,r)
    palt(0, false)
    palt(11, true)
    spr(224+c.rank-1, x, y)
    x+=8
  end

  -- suit header
  local x = 1
  for s=0,3 do
    palt(0, false)
    palt(11, true)
    spr(200+s*2, x, 8+y+s*10, 2, 2)
  end
  
  for s=0,3 do
    local x = 10
    for r=2,14 do
      local c = new_card(s,r)
      local cnt = 0
      for d in all(deck) do
        if d.rank == c.rank and
           d.suit == c.suit then
          cnt+=1
        end
      end
      print(cnt, x+2, y+10, 0)
      x+= 8
    end
    y += 10
  end
  clip()
end

function update_info_screen()
  info_screen.tt += 1
  if not btn(🅾️) then
    _upd = info_screen._upd
    _drw = info_screen._drw
    camera(0,0)
  end
end
-->8
-- start screen

function show_start_screen()
  start_screen = {
    cards={
      new_card(0,14),
      new_card(0,13),
      new_card(0,12),
      new_card(0,11),
      new_card(0,10),
    },
   kind=straight_flush,
  }
  _drw = draw_start_screen
  _upd = update_start_screen
end

function update_start_screen()
  if btnp(❎) then
    restart_game()
  end
  if (t())%10 == 0 then
    local cards

    for times=0,60 do
      cards = {}
      for n=1, 3+flr(rnd(3)) do
        add(cards, new_card(
          flr(rnd(4)), 
          2+flr(rnd(12))))
      end
      local kind = match_hand(cards)
      if kind.name != "high card" and
         kind.name != "pair" then
        break
      end
    end
    start_screen.kind = match_hand(cards)
    start_screen.cards = cards
  end
end

function draw_start_screen()
  cls()

  local i = 0
  local tt = t()/8
  for c in all(start_screen.cards) do
    local x = 48+64*sin(i/10+tt) 
    local y = 8+10*cos(i/10+tt)

    draw_card(c, x ,y)
    i+= 1
  end

  local x = 64+32*sin(tt)
  local y = 8
--  if start_screen.kind.name != "high card" then
--    print(start_screen.kind.name, x,y,15)
--    print(start_screen.kind.name, x+1,y+1,12)
--  end


  print("\^ibalatro demake!", 32, 32, (t()*4)%16)
  if start_screen.kind.name != "high card" then
    print("\^i"..start_screen.kind.name, 32, 40, (t()*2)%16)
  end
  if max_level and t()%2>=1 then
    print("max level "..max_level, 80, 0, 5)  
  end
  print("")
  print("controls:", 0, 80,10)
  print(" \fa⬅️➡️\f5 choose card", 5)
  print(" \fa⬆️\f5 toggle card to play", 5)
  print(" \fa⬇️\f5 toggle card to discard")
  print(" \fa❎\f5 play or discard", 5)
  print(" \fa🅾️\f5 upgrades and deck stat", 5)
  print("press ❎ to play", 30, 120, 5+t()*10%2)
  print("v2", 116,122, 5)
end
-->8
-- game over

function show_game_over()
  _drw = draw_game_over
  _upd = update_game_over
end

function update_game_over()
  if btnp(❎) then
    show_start_screen()
  end
end

function draw_game_over()
  cls()
  print("\^igame over!", 32, 32, (t()*32)%16)
  print("level: "..level, 32, 40, 10)
  print("press ❎ to continue", 30, 120, 14+t()%2)
end
__gfx__
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb5555555555555555555555555555bbbb1111111111111111111111111111bb00111111111111111111111111111100000000000000000000000000
00700700b557777777777777777777777777755bb117777777777777777777777777711b01177777777777777777777777777110000000000000000000000000
00077000b57777566577ddddddddddd5ddd7775bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00077000b5775566665575555555555d000d775bb177777777777777777777777777771b017eeeee7eee7eeeeee7eee7eeeee710000000000000000000000000
00700700b577666666667777777777d00000d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b575666666665777777777d00000d75bb177777777777777777777777777771b0177e7e7e77777777777777e7e7e7710000000000000000000000000
00000000b576666666666777777777d00000d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b5766666666667777777777d000d575bb177777777777777777777777777771b017777e777777777777777777e777710000000000000000000000000
00000000b57666666666677777777777ddd5d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b557666666667777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b577666666667777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b575776666777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d557777777777777777777775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d575577777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710000000000000000000000000
00000000b57d577577777777777777775775d75bb177777777777777777777777777771b01777777777777777777777777777710000000000000000000000000
00000000b57d577777777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b57d577757777777777777777775d75bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b57d577775777777777777555577d75bb177777777777777777777777777771b01777777777777777777777777777710057777777777777777777777
00000000b57d577777577777777755666655775bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b57d577777755777777766666666775bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b57d577777777555557566666666575bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b57d5ddd77777777777666666666675bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b575d000d7777777777666666666675bb177777777777777777777777777771b017777e777777777777777777e777710057777777777777777777777
00000000b57d00000d777777777666666666675bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b57d00000d777777775766666666755bb177777777777777777777777777771b0177e7e7e77777777777777e7e7e7710057777777777777777777777
00000000b57d00000d777777777766666666775bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b577d000d5555555555577666677575bb177777777777777777777777777771b017eeeee7eee7eeeeee7eee7eeeee710057777777777777777777777
00000000b5777ddd5ddddddddddd55777755775bb177777777777777777777777777771b0177e7777777777777777777777e7710057777777777777777777777
00000000b557777777777777777777555577755bb117777777777777777777777777711b01177777777777777777777777777110055777777777777777777777
00000000bb5555555555555555555555555555bbbb1111111111111111111111111111bb00111111111111111111111111111100005555555555555555555555
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bbb8888888888888888888888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb880000000000000000000000000088bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb800888888888800008888888888008bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808000000087780087780000000808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808008800087780087780008800808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808087780877778877778087780808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808087780877778877778087780808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808008800877780087778008800808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808000008777780087777800000808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808008887777780087777788800808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808887777777780087777777788808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808777777777780087777777777808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808777888877780087778888777808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808778777787780087787777877808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bb808787788778778877877887787808bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000008087878778787800878787787878080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000
00000000008087878778787800878787787878080000000000000000bbb000000000bbbbbbbbb0b0b0bbbbbbbbbb00b0b00bbbbbbb0000000000000000000000
00000000008087877887788000088778877878080000000000000000bb06066066060bbbbbbb0707070bbbbbbbbb0707070bbbbbbb0000000000000000000000
00000000008087787777878000087877778778080000000000000000bb06606060660bbbbbbb0676760bbbbbbbbb0676760bbbbbbb0000000000000000000000
00000000008087778888780877808788887778080000000000000000bbb066666660bbbbbbbb0666660bbbbbbbbb0666660bbbbbbb0000000000000000000000
00000000008087777778808788780887777778080000000000000000bbbb0000000bbbbbbbbb0000000bbbbbbbbb0000000bbbbbbb0000000000000000000000
00000000008008877880087800878008877880080000000000000000bbb077770660bbbbbbb077770660bbbbbbb077770660bbbbbb0000000000000000000000
00000000008000088008878000087880088000080000000000000000bb07707770660bbbbb07707770660bbbbb07707770660bbbbb0000000000000000000000
00000000008000088008878000087880088000080000000000000000b077777770660bbbb077707770660bbbb077777770660bbbbb0000000000000000000000
00000000008008877880087800878008877880080000000000000000bb00777770660bbbbb00777770660bbbbb00077770660bbbbb0000000000000000000000
00000000008087777778808788780887777778080000000000000000bbb0077770660bbbbbbb000770660bbbbb00007770660bbbbb0000000000000000000000
00000000008087778888780877808788887778080000000000000000bbb07777706660bbbbbbb077706660bbbbb07777706660bbbb0000000000000000000000
00000000008087787777878088087877778778080000000000000000bbbb0007706660bbbbbbbb07706660bbbbbb0000006660bbbb0000000000000000000000
00000000008087877887788088088778877878080000000000000000bbbbbb00000660bbbbbbbb00000660bbbbbb0707070660bbbb0000000000000000000000
00000000008087878778787800878787787878080000000000000000bbbbbb0000000bbbbbbbb00000000bbbbbbbb00000000bbbbb0000000000000000000000
00000000008087878778787800878787787878080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000
00000000008087877887787788778778877878080000000000000000b00000bbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000
000000000080877877778778008778777787780800000000000000000777750bb07750bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
000000000080877788887778008777888877780800000000000000000555750b0755750bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008087777777777800877777777778080000000000000000b000750b0750750bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008088877777777800877777777888080000000000000000b000750b0750750bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
000000000080800888777778008777778880080800000000000000000700750b0757500bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008080000087777800877778000008080000000000000000057750bb0575750bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008080088008777800877780088008080000000000000000b0550bbbb05050bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008080877808777788777780877808080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008080877808777788777780877808080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008080088000877800877800088008080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008080000000877800877800000008080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008008888888888000088888888880080000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000008800000000000000000000000000880000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000000888888888888888888888888888800000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
bbbbbbb55bbbbbbbbbbbbbbeebbbbbbbbbbbbbb55bbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbb8bbbbbbbbbbbbbbb00bbbbbbbbbbb888bb888bbbbbbb
bbbbbb5005bbbbbbbbbbbbe87ebbbbbbbbbbbb5005bbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbb888bbbbbbbbbbbbb0000bbbbbbbbb8888888888bbbbbb
bbbbb500005bbbbbbbbbb488e7ebbbbbbbbbb500005bbbbbbbbbbbbbbbbbbbbbbb000000bbbbbbbbbb88888bbbbbbbbbbbb0000bbbbbbbbb8888888888bbbbbb
bbbb50000005bbbbbbbbe888ee7ebbbbbbbbb000000bbbbbbbb888bbbb888bbbb00000000bbbbbbbb8888888bbbbbbbbb00b00b00bbbbbbb8888888888bbbbbb
bbb5000000005bbbbbb48888eee7ebbbbbbbb000000bbbbbbb888888888888bb0000000000bbbbbb888888888bbbbbbb0000000000bbbbbb8888888888bbbbbb
bb500000000005bbbb488888eeee7ebbbbb5570000755bbbb88888888888888b0000000000bbbbbbb8888888bbbbbbbb0000000000bbbbbbb88888888bbbbbbb
b50000000000005bb4888888eeeee7ebbb500570075005bbb88888888888888b0000000000bbbbbbbb88888bbbbbbbbbb00b00b00bbbbbbbbb888888bbbbbbbb
b00000000000000bb4448888eeeee88bb50000000000005bbe888888888888ebb00b00b00bbbbbbbbbb888bbbbbbbbbbbbbb00bbbbbbbbbbbbb8888bbbbbbbbb
b00000000000000bbb444444888888bbb00000000000000bbbe8888888888ebbbbb0000bbbbbbbbbbbbb8bbbbbbbbbbbbbb0000bbbbbbbbbbbbb88bbbbbbbbbb
bb000000000000bbbbb4444488888bbbbb0000b00b0000bbbbbe88888888ebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb000b00b000bbbbbbb44448888bbbbbbb00bb00bb00bbbbbbbe888888ebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb00bbbbbbbbbbbb444888bbbbbbbbbbbb00bbbbbbbbbbbbe8888ebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbb5005bbbbbbbbbbbb4488bbbbbbbbbbbb5005bbbbbbbbbbbbe88ebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbb0000bbbbbbbbbbbbb48bbbbbbbbbbbbb0000bbbbbbbbbbbbbeebbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb00bbbbb000bbb000000bb0000000b000000bbbb0000bbb000000bb000000bb000000bb0bb00bbb00000bbbb000bbbb00000bbbb00bbbb0000000000000000
bb0750bbb07750bb0777500b0750750b0777750bb077750bb077770bb077770bb077770b0700770b0777750bb07750bbb07070bbb0770bbb0000000000000000
b07750bb0755750b0555750b0750750b075550bb075550bbb000770bb070070bb070070b070700700555750b0755750bb07070bb075570bb0000000000000000
b05750bb0500750b0077750b0750750b0777500b077750bbbb00700bb077770bb077770b07070070b000750b0750750bb07700bb070070bb0000000000000000
bb0750bbb077550bb055750b0577750b0555750b0755750bbb0700bbb070070bb000070b07070070b000750b0750750bb07770bb077770bb0000000000000000
bb0750bb0755000b0000750b0055750b0000750b0750750bbb070bbbb070070bbb00070b070700700700750b0757500bb070700b075570bb0000000000000000
bb0750bb0777750b0777500bb000750b0777500b057750bbbb070bbbb077770bbb07770b0700770b057750bb0575750bb070070b070070bb0000000000000000
bb0550bb0555550b055550bbbbb0000b000000bbb0550bbbbb000bbbb000000bbb00000bb0bb00bbb0550bbbb05050bbb000000b050050bb0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000005500000000000555500000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000555055505050000050005550505055505000000055500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000555050505050000050005000505050005000000000500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000505055500500000050005500505055005000000055500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050000050005000555050005000000050000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000505050505050000055505550050055505550000055500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001177777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001777700777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001777077077777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001770755707777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001177777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001777777777777777777700
00001111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000001777000007777777770070
00011777777777777777777777777771100000000000000000000000000000000000000000000001111111111111111111111111111777070707777777700000
00017777777777777777777000077777100000001111111111111111111111111111000000000011777777777777777777777777771177070707777777700000
00017770770077777777700700700777100000011777777777777777777777777771100000000017777777777777777777000077777177077007777777700000
00017707007707777777000000000077100000017777777777777777777000077777100000000017770000007777777700700700777177077707777777770000
00017707070070777777000000000077100000017777000007777777700700700777100000000017770077007777777000000000077177070700777777777000
00017707070070777777000000000077100000017777077707777777000000000077100000000017770700707777777000000000077177070070777777777700
00017707070070777777700000000777100000017777007007777777000000000077100000000017770700707777777000000000077177000000777777777770
00017707070070777777770000007777100000017777707077777777000000000077100000000017770700707777777700000000777177777777777777777777
00017707007707777777777000077777100000017770007077777777700000000777100000000017770700700777777770000007777177777777777777777777
00017770770077777777777700777777100000017770707077777777770000007777100000000017770077770777777777000077777177777777777777777777
00017777777777777777777777777777100000017770777077777777777000077777100000000017770000000777777777700777777177777777777777777777
00017777777777777777777777777777100000017770000077777777777700777777100000000017777777777777777777777777777177777777777777777777
00017777777777777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177777777777777777777
00017777777777777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177777777777777777777
00017777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777177777777777777777777
00017777777777777777777777777777100700077777777777777777777777777777100700070017777777777777777777777777777177777777777777777777
00017777777777777777777777777777170707077777777777777777777777777777177700070717777777777777777777777777777177777777777777777777
00017777777777777777777777777777107700077777777777777777777777777777107707070017777777777777777777777777777177777777777777777777
00017777777777777777777777777777170707077777777777777777777777777777177707070717777777777777777777777777777177777777777777777777
00017777777777777777777777777777100707077777777777777777777777777777100707070717777777777777777777777777777177777777777777777777
00017777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777177777777777777777777
00017777777777777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177777777777777777777
0001777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7777777777777777777177777777777777777777
0001777777777777777777777777777bb00b000b777b777b777bb77b7b7b777bbbbb100b0bbb0b1bb77b7b7b7777777777777777777177777777777777777777
0001777777777777777777777777777b1bbbb0bb7b7b7b7bb7bb7bbb7b7bb7bbbbbb1bbb0bbb0b1b7bbb7b7b7777777777777777777177777777777777777777
0001777777777777777777777777777b100bb0bb77bb777bb7bb7bbb777bb7bbbbbb10bb0bbb0b1b777b777b7777777777777777777177777777777777777777
0001777777777777777777777777777bbb0bb0bb7b7b7b7bb7bb7b7b7b7bb7bbbbbb1bbb0bbb0b1bbb7b7b7b7777777777777777777177777777777777777777
0001777777777777777777777777777b10bbb0bb7b7b7b7b777b777b7b7bb7bbbbbb1bbb000bb01b77bb7b7b7777777777777777777177777777777777777777
0001777777777777777777777777777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7777777777777777777177777777777777777777
00017777777777777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177777700777777777777
00017777777777777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177777000077777777700
00017777777777777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177770000007777777707
00017777777007777777777777777777100000017777777777777777777777777777100000000017777777777777777777777777777177700000000777777700
00017777770000777777777700770777100000017777777777777777777777777777100000000017777777007777777777777777777177000000000077777770
00017777700000077777777077007077100000017777777007777777777777777777100000000017777770000777777770000000777177000000000077777770
00017777000000007777770700707077100000017777770000777777777700000777100000000017777700000077777770777700777177000000000077777770
00017770000000000777770700707077100000017777700000077777777707770777100000000017777000000007777770070070777177700700700777777770
00017770000000000777770700707077100000017777000000007777777707070777100000000017770000000000777777070070777177777000077777777770
00017770000000000777770700707077100000017770000000000777777707000777100000000017770000000000777777070070777177777777777777777777
00017777007007007777777077007077100000017770000000000777777707077777100000000017770000000000777777070070777177777777777777777777
00017777770000777777777700770777100000017770000000000777777007007777100000000017777007007007777777007700777177777777777777777777
00017777777777777777777777777777100000017777007007007777777077707777100000000017777770000777777777000000777111111111111111111111
00017777777777777777777777777777100000017777770000777777777000007777100000000017777777777777777777777777777100000000000000000000
00011777777777777777777777777771100000017777777777777777777777777777100000000017777777777777777777777777777100000000000000000000
00001111111111111111111111111111000000017777777777777777777777777777100000000011777777777777777777777777771100000000000000000000
00000000000000000000000000000000000000011777777777777777777777777771100000000001111111111111111111111111111000000000000000000000
00000000000000000000000000000000000000001111111111111111111111111111000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa00aa0aa00aaa0aaa00aa0a0000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000a0a0a0a00a00a0a0a0a0a000a0000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000a0a0a0a00a00aa00a0a0a000aaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000a0a0a0a00a00a0a0a0a0a00000a00a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aa0aa00a0a00a00a0a0aa00aaa0aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaa000aaaaa00000005505050055005500550555000000550555055505500000000000000000000000000000000000000000000000000000000000000
0000aaa00aa0aa00aaa0000050005050505050505000500000005000505050505050000000000000000000000000000000000000000000000000000000000000
0000aa000aa0aa000aa0000050005550505050505550550000005000555055005050000000000000000000000000000000000000000000000000000000000000
0000aaa00aa0aa00aaa0000050005050505050500050500000005000505050505050000000000000000000000000000000000000000000000000000000000000
00000aaaaa000aaaaa00000005505050550055005500555000000550505050505550000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaa0000005550055005500550500055500000055055505550550000005550055000005550500055505050000000000000000000000000000000000000
0000aaa0aaa000000500505050005000500050000000500050505050505000000500505000005050500050505050000000000000000000000000000000000000
0000aa000aa000000500505050005000500055000000500055505500505000000500505000005550500055505550000000000000000000000000000000000000
0000aa000aa000000500505050505050500050000000500050505050505000000500505000005000500050500050000000000000000000000000000000000000
00000aaaaa0000000500550055505550555055500000055050505050555000000500550000005000555050505550000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaa0000005550055005500550500055500000055055505550550000005550055000005500555005500550555055505500000000000000000000000000
0000aa000aa000000500505050005000500050000000500050505050505000000500505000005050050050005000505050505050000000000000000000000000
0000aa000aa000000500505050005000500055000000500055505500505000000500505000005050050055505000555055005050000000000000000000000000
0000aaa0aaa000000500505050505050500050000000500050505050505000000500505000005050050000505000505050505050000000000000000000000000
00000aaaaa0000000500550055505550555055500000055050505050555000000500550000005550555055000550505050505550000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaa0000005550500055505050000005505550000055005550055005505550555055000000000000000000000000000000000000000000000000000000
0000aa0a0aa000005050500050505050000050505050000050500500500050005050505050500000000000000000000000000000000000000000000000000000
0000aaa0aaa000005550500055505550000050505500000050500500555050005550550050500000000000000000000000000000000000000000000000000000
0000aa0a0aa000005000500050500050000050505050000050500500005050005050505050500000000000000000000000000000000000000000000000000000
00000aaaaa0000005000555050505550000055005050000055505550550005505050505055500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaaaa0000005050555005505550555055005550055000005550550055000000550055500550505000000550555055505550000000000000000000000000
0000aa000aa000005050505050005050505050505000500000005050505050500000505050005000505000005000050050500500000000000000000000000000
0000aa0a0aa000005050555050005500555050505500555000005550505050500000505055005000550000005550050055500500000000000000000000000000
0000aa000aa000005050500050505050505050505000005000005050505050500000505050005000505000000050050050500500000000000000000000000000
00000aaaaa0000000550500055505050505055505550550000005050505055500000555055500550505000005500050050500500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000066606660666006600660000006666600000066600660000066606000666060600000000000000000000000000000000000
00000000000000000000000000000060606060600060006000000066060660000006006060000060606000606060600000000000000000000000000000000000
00000000000000000000000000000066606600660066606660000066606660000006006060000066606000666066600000000000000000000000505055500000
00000000000000000000000000000060006060600000600060000066060660000006006060000060006000606000600000000000000000000000505000500000
00000000000000000000000000000060006060666066006600000006666600000006006600000060006660606066600000000000000000000000505055500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555050000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050055500000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffff
__sfx__
000c000018150181501b1501f1502215024150291502b1502e1003010035100371003a1003c1003c1003f10000100001000010000100001000010000100001000010000100001000010000100001000010000100
00040000365101f5102451027510275102451024550245502b550295002b5002b5002b5002b5002b5003050000500005002b50030500305003050030500355000050000500005000050000500005000050000500
