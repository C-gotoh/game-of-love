require('dump')
math.randomseed(os.time())

local Field
local Image

local function isAlive(x, y)
    local _, _, _, a = Field:getPixel(x, y)
    return a == 1
end
local function setDead(x, y)
    local color = math.random()
    local color2 = math.random()
    Field:setPixel(x, y, 0, color, color2, 0.9)
end
local function setAlive(x, y) Field:setPixel(x, y, 1, 1, 1, 1) end

local function updateColor(x, y)
    local r, g, b, a = Field:getPixel(x, y)
    Field:setPixel(x, y, r, math.max(0, g - 0.002), math.max(0, b - 0.01), 1)
end

local function getNumNeighbors(x, y)

    local w, h = Field:getDimensions()
    if x < 1 or x > w - 2 or y < 1 or y > h - 2 then return 0 end
    local count = 0
    for i = x - 1, x + 1 do
        for j = y - 1, y + 1 do
            if (i ~= x or j ~= y) and isAlive(i, j) then
                count = count + 1
            end
        end
    end
    return count
end

local function tickField()
    local dead_bois = {}
    local alive_bois = {}
    local w, h = Field:getDimensions()
    for i = 0, w - 1 do
        for j = 0, h - 1 do
            local num = getNumNeighbors(i, j)
            if isAlive(i, j) then
                if num ~= 2 and num ~= 3 then
                    table.insert(dead_bois, {i = i, j = j})
                else
                    updateColor(i, j)
                end
            else
                local r, g, b, a = Field:getPixel(i, j)
                Field:setPixel(i, j, r, g, b, math.max(0.2, a * 0.99))
                if num == 3 then
                    table.insert(alive_bois, {i = i, j = j})
                end
            end
        end
    end
    for _, boi in pairs(dead_bois) do setDead(boi.i, boi.j) end
    for _, boi in pairs(alive_bois) do setAlive(boi.i, boi.j) end
end

local function buildField()
    local w, h = love.graphics.getDimensions()
    Field = love.image.newImageData(w / Scale, h / Scale)
    print('created with ', w / 2, h / 2)
    for i = 0, (w / Scale) - 1 do
        for j = 0, (h / Scale) - 1 do
            local alive = math.random() > 0.7
            if alive then setAlive(i, j) end
        end
    end
    Image = love.graphics.newImage(Field)
    return Field
end

function love.load()
    Shader = love.graphics.newShader("glow.glsl")
    love.graphics.setDefaultFilter('linear', 'nearest', 0)
    -- init field
    RefreshRate = 0.1
    Paused = false
    Fps = 0
    Cooldown = 0
    Debug = true
    Shading = false
    Scale = 2
    Field = buildField()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "r" then
        print('reset')
        Field = buildField()
    end
    if key == "t" then tickField() end
    if key == "space" then Paused = not Paused end
    if key == "d" then Debug = not Debug end
    if key == "s" then Shading = not Shading end
    if key == "2" then Scale = 2 end
    if key == "4" then Scale = 4 end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        print('set pixel', x, y)
        print('field coordinate', x / Scale, y / Scale)
        setAlive(math.floor(x / Scale), math.floor(y / Scale))
    end
    if button == 2 then Paused = not Paused end
end

local function round(n) return math.floor(n * 1000) / 1000 end

function love.update(dt)
    Fps = round(1 / dt)
    Cooldown = Cooldown + dt
    if (Cooldown > RefreshRate) then
        if not Paused then tickField() end
        Cooldown = 0
    end
    Image:replacePixels(Field)
end

function love.draw()

    if Debug then love.graphics.print(Fps, 10, 10) end
    if Shading then love.graphics.setShader(Shader) end
    love.graphics.setColor(1, 1, 1);
    love.graphics.draw(Image, 0, 0, 0, Scale, Scale)
    love.graphics.setShader()
end

