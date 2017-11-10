-- Video Tripwire Project

local GPIO = require("periphery").GPIO

print("Video Tripwire")

-- Configuration
local config

-- Video streams
local mainVideo, triggerVideo = {}, {}

-- Scales
local mainSx, mainSy
local triggerSx, triggerSy

-- State
local currentVideo
local tripped = false

-- GPIO
local tripwirePinId = 21
local tripwireGpio

---

local function getScaleForVideo(video)
	local sx = love.graphics.getWidth() / video:getWidth()
	local sy = love.graphics.getHeight() / video:getHeight()
	
	return sx, sy
end

local function setCurrentVideo(video)
	currentVideo = video
	video.video:rewind()
	video.video:play()
	
	if (video == mainVideo) then print("Switched to main video.") end
	if (video == triggerVideo) then print("Switched to trigger video.") end
end

---

function love.load()
	config = dofile("config.lua")
	
	-- Setup the window
	love.window.setFullscreen(config.fullscreen)
	love.window.setTitle("Video Tripwire")
	love.mouse.setVisible(false)
	
	-- Init GPIO
	print("Initialising GPIO...")
	tripwireGpio = GPIO(tripwirePinId, "in")
	
	-- Load video streams
	print("Loading main video ('" .. config.mainVideo .. "')")
	mainVideo.video = love.graphics.newVideo(config.mainVideo, config.loadAudio)
	
	print("Loading trigger video ('" .. config.triggerVideo .. "')")
	triggerVideo.video = love.graphics.newVideo(config.triggerVideo, config.loadAudio)
	
	-- Calculate scales
	mainVideo.sx, mainVideo.sy = getScaleForVideo(mainVideo.video)
	triggerVideo.sx, triggerVideo.sy = getScaleForVideo(triggerVideo.video)
	
	
	setCurrentVideo(mainVideo)
end

function love.draw()
	-- Draw video
	love.graphics.draw(currentVideo.video, 0, 0, 0, currentVideo.sx, currentVideo.sy)
	
	if not currentVideo.video:isPlaying() then
		if tripped and (currentVideo == mainVideo) then
			-- Tripwire tripped and we're playing the main video, switch to the trigger video
			setCurrentVideo(triggerVideo)
			tripped = false -- Reset trip
		elseif currentVideo == triggerVideo then
			-- We're playing the trigger video - don't repeat and switch back to the main video
			setCurrentVideo(mainVideo)
		else
			-- Just playing the normal video and nothing has tripped. Loop main video
			currentVideo.video:rewind()
			currentVideo.video:play()
		end
	end
end

function love.update(dt)
	if ((currentVideo == mainVideo) and tripwireGpio:read()) then
		-- Tripped!
		tripped = true
	end
end

