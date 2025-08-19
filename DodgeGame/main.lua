-- AI Shape Chaos - Juiced Edition 🔥
-- Neon chaos arcade shooter for LÖVE2D

love.window.setMode(800, 600)
love.window.setTitle("AI Shape Chaos")

-- Player
player = {x=400, y=300, r=10, speed=300}

-- Shots
shots = {}
shotSpeed = 500

-- Shapes
shapes = {}
spawnTimer = 0
spawnRate = 1

-- Score & GameOver
score = 0
gameOver = false

-- Screen shake
shake = {time=0, intensity=0}

-- Stars background
stars = {}
for i=1,100 do
    stars[i] = {x=math.random(0,800), y=math.random(0,600), speed=math.random(20,80)}
end

-- Helpers
math.randomseed(os.time())

function ShakeScreen(power, duration)
    shake.intensity = power
    shake.time = duration
end

-- Collision check
function CheckCollisionCircle(x1,y1,r1, x2,y2,r2)
    local dx = x1-x2
    local dy = y1-y2
    return dx*dx + dy*dy < (r1+r2)^2
end

-- Restart game
function RestartGame()
    player.x, player.y = 400, 300
    shots = {}
    shapes = {}
    score = 0
    gameOver = false
    spawnTimer = 0
end

-- Update
function love.update(dt)
    -- Background stars
    for _,s in ipairs(stars) do
        s.y = s.y + s.speed*dt
        if s.y > 600 then
            s.y = 0
            s.x = math.random(0,800)
        end
    end

    -- Screen shake decay
    if shake.time > 0 then
        shake.time = shake.time - dt
        if shake.time < 0 then shake.time = 0 end
    end

    if gameOver then
        if love.keyboard.isDown("return") then
            RestartGame()
        end
        return
    end

    -- Player move
    if love.keyboard.isDown("left") then player.x = player.x - player.speed*dt end
    if love.keyboard.isDown("right") then player.x = player.x + player.speed*dt end
    if love.keyboard.isDown("up") then player.y = player.y - player.speed*dt end
    if love.keyboard.isDown("down") then player.y = player.y + player.speed*dt end

    -- Clamp player inside screen
    if player.x < player.r then player.x = player.r end
    if player.x > 800 - player.r then player.x = 800 - player.r end
    if player.y < player.r then player.y = player.r end
    if player.y > 600 - player.r then player.y = 600 - player.r end

    -- Spawn shapes (faster as score increases)
    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        local type = math.random(1,3)
        local shape = {
            type = type, -- 1=triangle,2=circle,3=square
            x = math.random(0,800),
            y = math.random(0,600),
            r = 15,
            vx = 0,
            vy = 0
        }
        table.insert(shapes, shape)
        spawnRate = math.max(0.3, 1 - score/200) -- difficulty scaling
        spawnTimer = spawnRate
    end

    -- Move shapes
    for i=#shapes,1,-1 do
        local s = shapes[i]
        local dx = player.x - s.x
        local dy = player.y - s.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist>0 then
            dx, dy = dx/dist, dy/dist
        end

        -- Behavior by type
        if s.type==1 then -- triangle chases aggressively
            s.vx = dx*200
            s.vy = dy*200
        elseif s.type==2 then -- circle orbits player
            local angle = math.atan2(dy, dx) + math.pi/2
            s.vx = math.cos(angle)*150
            s.vy = math.sin(angle)*150
        elseif s.type==3 then -- square slowly chases
            s.vx = dx*100
            s.vy = dy*100
        end

        s.x = s.x + s.vx*dt
        s.y = s.y + s.vy*dt

        -- Check collision with player
        if CheckCollisionCircle(player.x,player.y,player.r, s.x,s.y,s.r) then
            gameOver = true
            ShakeScreen(15, 0.5)
        end
    end

    -- Update shots
    for i=#shots,1,-1 do
        local sh = shots[i]
        sh.x = sh.x + sh.vx*dt
        sh.y = sh.y + sh.vy*dt

        -- Remove if out of screen
        if sh.x<0 or sh.x>800 or sh.y<0 or sh.y>600 then
            table.remove(shots,i)
        else
            -- Check collision with shapes
            for j=#shapes,1,-1 do
                local s = shapes[j]
                if CheckCollisionCircle(sh.x,sh.y,5, s.x,s.y,s.r) then
                    score = score + 10
                    ShakeScreen(5, 0.2)
                    -- square splits
                    if s.type==3 and s.r>8 then
                        local new1 = {type=3, x=s.x+5, y=s.y, r=s.r/2}
                        local new2 = {type=3, x=s.x-5, y=s.y, r=s.r/2}
                        table.insert(shapes,new1)
                        table.insert(shapes,new2)
                    end
                    table.remove(shapes,j)
                    table.remove(shots,i)
                    break
                end
            end
        end
    end
end

-- Shoot
function love.keypressed(key)
    if gameOver then return end
    local vx, vy = 0,0
    if key=="w" then vy=-shotSpeed end
    if key=="s" then vy=shotSpeed end
    if key=="a" then vx=-shotSpeed end
    if key=="d" then vx=shotSpeed end
    if vx~=0 or vy~=0 then
        table.insert(shots,{x=player.x, y=player.y, vx=vx, vy=vy})
    end
end

-- Glow helper (draw multiple outlines for neon effect)
function GlowCircle(mode, x, y, r, color)
    for i=3,1,-1 do
        love.graphics.setColor(color[1], color[2], color[3], 0.1*i)
        love.graphics.circle(mode, x, y, r+i*3)
    end
    love.graphics.setColor(color)
    love.graphics.circle(mode, x, y, r)
end

-- Draw
function love.draw()
    -- Screen shake offset
    local dx, dy = 0, 0
    if shake.time > 0 then
        dx = love.math.random(-shake.intensity, shake.intensity)
        dy = love.math.random(-shake.intensity, shake.intensity)
    end
    love.graphics.push()
    love.graphics.translate(dx, dy)

    -- Background stars
    love.graphics.setColor(1,1,1,0.3)
    for _,s in ipairs(stars) do
        love.graphics.points(s.x, s.y)
    end

    -- Player (cyan glow)
    GlowCircle("fill", player.x, player.y, player.r, {0,1,1})

    -- Shapes
    for _,s in ipairs(shapes) do
        if s.type==1 then
            love.graphics.setColor(1,0,0)
            love.graphics.polygon("fill", s.x,s.y-10, s.x-10,s.y+10, s.x+10,s.y+10)
        elseif s.type==2 then
            GlowCircle("fill", s.x, s.y, s.r, {0,0,1})
        elseif s.type==3 then
            love.graphics.setColor(0,1,0)
            love.graphics.rectangle("fill", s.x-s.r, s.y-s.r, s.r*2, s.r*2)
        end
    end

    -- Shots (yellow glow)
    for _,sh in ipairs(shots) do
        GlowCircle("fill", sh.x, sh.y, 5, {1,1,0})
    end

    love.graphics.pop()

    -- Score
    love.graphics.setColor(1,1,1)
    love.graphics.print("Score: "..math.floor(score), 10, 10)

    -- Game over
    if gameOver then
        love.graphics.setColor(1,0,0)
        love.graphics.printf("💀 GAME OVER 💀\nPress Enter to Restart", 0, 250, 800, "center")
    end
end

