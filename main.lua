local class = require 'middleclass'

local CELL_SIZE  = 8
local MAX_WIDTH  = math.floor(love.graphics.getWidth() / CELL_SIZE) - 1
local MAX_HEIGHT = math.floor(love.graphics.getHeight() / CELL_SIZE) - 1

local function inc(x)
    return x + 1
end

-- 2D point class
local Point = class('point')
function Point:initialize(x, y)
    self.x = x
    self.y = y
end

-- Rectangle class
local Rect = class('Rect')
function Rect:initialize(x, y, w, h)
    self.x, self.y = x, y
    self.w, self.h = w, h
end

function Rect:in_bounds(point)
    return point.x >= self.x and point.x <= self.x + self.w
       and point.y >= self.y and point.y <= self.y + self.h
end

-- Cell class
local Cell = class('Cell')
function Cell:initialize(position)
    self.position = position
    self.bounds   = Rect((position.x - 1) * CELL_SIZE,
                         (position.y - 1) * CELL_SIZE,
                         CELL_SIZE, CELL_SIZE)
    self.isAlive  = false
end

function Cell:onclick(x, y, button)
    local p = Point(x, y)
    if self.bounds:in_bounds(p) then
        -- left-click will regenerate a dead cell
        if button == 1 then
            self.isAlive = true
        -- right-click will kill an alive cell
        elseif button == 2 then
            self.isAlive = false
        end
    end
end

function Cell:draw()
    if self.isAlive then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill', self.bounds.x, self.bounds.y,
                                        self.bounds.w, self.bounds.h)
        love.graphics.setColor(1, 1, 1)
    end
end

-- Grid class
local Grid = class('Grid')
function Grid:initialize()
    -- initialize the grid to be a 2D array of cells
    self.cells = {}
    self.next_state = {}
    for j = 1, MAX_HEIGHT do
        local t1 = {}
        local t2 = {}
        for i = 1, MAX_WIDTH do
            t1[#t1 + 1] = Cell(Point(i, j))
            t2[#t2 + 1] = Cell(Point(i, j))
        end
        table.insert(self.cells, t1)
        table.insert(self.next_state, t2)
    end
end

function Grid:update(dt)
    for j = 1, MAX_HEIGHT do
        for i = 1, MAX_WIDTH do
            local cell = self.cells[j][i]
            local alive = cell.isAlive
            local count = self:getLivingNeighborCount(i, j)
            local result = false

            if alive and count < 2 then
                result = false
            end
            if alive and (count == 2 or count == 3) then
                result = true
            end
            if alive and count > 3 then
                result = false
            end
            if not alive and count == 3 then
                result = true
            end

            self.next_state[j][i].isAlive = result
        end
    end

    self:state_step()
end

function Grid:state_step()
    for j = 1, MAX_HEIGHT do
        for i = 1, MAX_WIDTH do
            self.cells[j][i].isAlive = self.next_state[j][i].isAlive
        end
    end
end

function Grid:getLivingNeighborCount(x, y)
    local count = 0

    -- right
    if x + 1 <= MAX_WIDTH then
        if self.cells[y][x + 1].isAlive then
            count = inc(count)
        end
    end
    -- bottom right
    if x + 1 <= MAX_WIDTH and y + 1 <= MAX_HEIGHT then
        if self.cells[y + 1][x + 1].isAlive then
            count = inc(count)
        end
    end
    -- bottom
    if y + 1 <= MAX_HEIGHT then
        if self.cells[y + 1][x].isAlive then
            count = inc(count)
        end
    end
    -- bottom left
    if x - 1 >= 1 and y + 1 <= MAX_HEIGHT then
        if self.cells[y + 1][x - 1].isAlive then
            count = inc(count)
        end
    end
    -- left
    if x - 1 >= 1 then
        if self.cells[y][x - 1].isAlive then
            count = inc(count)
        end
    end
    -- upper left
    if x - 1 >= 1 and y - 1 >= 1 then
        if self.cells[y - 1][x - 1].isAlive then
            count = inc(count)
        end
    end
    -- up
    if y - 1 >= 1 then
        if self.cells[y - 1][x].isAlive then
            count = inc(count)
        end
    end
    -- upper right
    if x + 1 <= MAX_WIDTH and y - 1 >= 1 then
        if self.cells[y - 1][x + 1].isAlive then
            count = inc(count)
        end
    end

    return count
end

function Grid:handle_click(x, y, button)
    for j = 1, MAX_HEIGHT do
        for i = 1, MAX_WIDTH do
            local cell = self.cells[j][i]
            cell:onclick(x, y, button)
        end
    end
end

function Grid:draw()
    for j = 1, MAX_HEIGHT do
        for i = 1, MAX_WIDTH do
            local cell = self.cells[j][i]
            cell:draw()
        end
    end
end

function Grid:clear()
    for j = 1, MAX_HEIGHT do
        for i = 1, MAX_WIDTH do
            local cell = self.cells[j][i]
            cell.isAlive = false
        end
    end
end

function love.load()
    love.graphics.setBackgroundColor(1, 1, 1)

    pause = false
    conway = Grid()
end

function love.update(dt)
    if not pause then
        love.timer.sleep(0.05)
        conway:update(dt)
    end

    local mx, my = love.mouse.getX(), love.mouse.getY()
    if love.mouse.isDown(1) then
        conway:handle_click(mx, my, 1)
    elseif love.mouse.isDown(2) then
        conway:handle_click(mx, my, 2)
    end
end

function love.draw()
    conway:draw()

    love.graphics.setColor(0, 0, 0, .2)
    for y = 1, MAX_HEIGHT do
        love.graphics.line(0, y * CELL_SIZE, love.graphics.getWidth(), y * CELL_SIZE)
    end
    for x = 1, MAX_WIDTH do
        love.graphics.line(x * CELL_SIZE, 0, x * CELL_SIZE, love.graphics.getHeight())
    end

    if pause then
        love.graphics.rectangle('fill', 0, 0,
            love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function love.keypressed(key)
    if key == 'space' then
        pause = not pause
    end
    if key == 'r' then
        conway:clear()
    end
    if key == 'escape' then
        love.event.quit()
    end
end