local _ = require "lib.lume"
local autobatch = require "lib.autobatch"
local flux = require "lib.flux"
local log = require "lib.log"
local lovebird = require "lib.lovebird"

debug = require "pancake.debug"
vec2 = require "pancake.vec2"

Object = require "lib.classic"

local max_cells = 40
local cell_size = 10
local current_cell = nil
local cell_stack = {}
local cell_tbl = {}
local chosen_cell

Cell = Object:extend()

function Cell:new(pos, coords)
  self.pos = pos
  self.coords = coords
  self.visited = false
  self.walls = {left = true, right = true, top = true, bottom = true}
end

function Cell:draw()
  love.graphics.setColor(255,255,255)
  for i,v in pairs(self.walls) do
    local c = self.coords
    if i == "left" and v == true then
      love.graphics.line(c.x * cell_size, c.y * cell_size, c.x * cell_size, (c.y + 1)*cell_size)
    elseif i == "right" and v == true then
      love.graphics.line((c.x+1) * cell_size, c.y * cell_size, (c.x+1) * cell_size, (c.y + 1)*cell_size)
    elseif i == "top" and v == true then
      love.graphics.line(c.x * cell_size, c.y * cell_size, (c.x+1) * cell_size, c.y*cell_size)
    elseif i == "bottom" and v == true then
      love.graphics.line(c.x * cell_size, (c.y+1) * cell_size, (c.x+1) * cell_size, (c.y + 1)*cell_size)
    end
  end
end

function Cell:drawCurrent()
  love.graphics.setColor(200,0,50)
  love.graphics.rectangle("fill", self.pos.x, self.pos.y, cell_size, cell_size)
end

function Cell:drawChosen()
  love.graphics.setColor(0,200,50)
  love.graphics.rectangle("fill", self.pos.x, self.pos.y, cell_size, cell_size)
end

function love.load()
  math.randomseed( os.time() )
  -- This might be confusing, because in the end, the current cell will be an Object
  -- But I don't care
  local start_cell = vec2(math.random(1,max_cells), math.random(1, max_cells))
  for i=0,max_cells do
    for j=0,max_cells do
      if not cell_tbl[i] then cell_tbl[i] = {} end
      cell_tbl[i][j] = Cell(vec2(i*cell_size, j*cell_size), vec2(i,j))
    end
  end

  current_cell = cell_tbl[start_cell.x][start_cell.y]
end

function love.update(dt)
  lovebird.update()
  debug.update()

  if not love.window.hasFocus() then return end
  -- Start updating here
  local c = current_cell.coords

  -- x-1,y0; x+1,y0; x0;y-1; x0; y+1
  local numNeighbors = 0
  for i,v in pairs({{-1,0}, {1,0}, {0,-1}, {0,1}}) do
    if cell_tbl[c.x+v[1]] and cell_tbl[c.x+v[1]][c.y+v[2]] and not cell_tbl[c.x+v[1]][c.y+v[2]].visited then
      numNeighbors = numNeighbors + 1
    end
  end
  if numNeighbors > 0 then
    table.insert(cell_stack, current_cell)local shuffle_tbl = {"x+1", "x-1", "y+1", "y-1"}
    for i,v in pairs(_.shuffle(shuffle_tbl)) do
      if v == "x+1" then
        if c.x+1 <= max_cells and not cell_tbl[c.x+1][c.y].visited then
          chosen_cell = cell_tbl[c.x+1][c.y]
          chosen_cell.walls["left"] = false
          current_cell.walls["right"] = false
          break
        end
      elseif v == "x-1" then
        if c.x-1 >= 0 and not cell_tbl[c.x-1][c.y].visited then
          chosen_cell = cell_tbl[c.x-1][c.y]
          chosen_cell.walls["right"] = false
          current_cell.walls["left"] = false
          break
        end
      elseif v == "y+1" then
        if c.y+1 <= max_cells and not cell_tbl[c.x][c.y+1].visited then
          chosen_cell = cell_tbl[c.x][c.y+1]
          chosen_cell.walls["top"] = false
          current_cell.walls["bottom"] = false
          break
        end
      elseif v == "y-1" then
        if c.y-1 >= 0 and not cell_tbl[c.x][c.y-1].visited then
          chosen_cell = cell_tbl[c.x][c.y-1]
          chosen_cell.walls["bottom"] = false
          current_cell.walls["top"] = false
          break
        end
      end
    end

    if chosen_cell then
      chosen_cell.visited = true
      current_cell = chosen_cell
    end
  else
    local stack_cnt = _.count(cell_stack)
    if stack_cnt > 0 then
      current_cell = cell_stack[stack_cnt]
      table.remove(cell_stack, stack_cnt)
    end
  end

  -- love.timer.sleep(2)
end

function love.draw()
  for i,v in pairs(cell_tbl) do
    for j,k in pairs(v) do
      k:draw()
    end
  end

  current_cell:drawCurrent()
  -- Draw this one last
  --debug.draw()
end
