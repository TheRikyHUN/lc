-- No touch, kthxbai
local tiles = { }
local timer
local enabled = false

local ROW_COUNT = 12

function toggleCustomTiles ( )
	-- Toggle!
	enabled = not enabled
	
	-- Check whether we enabled it
	if enabled then
		-- Load all tiles
		handleTileLoading ( )
		
		-- Set a timer to check whether new tiles should be loaded (less resource hungry than doing it on render)
		timer = setTimer ( handleTileLoading, 500, 0 )
	else
		-- If our timer is still running, kill it with fire
		if isTimer ( timer ) then killTimer ( timer ) end
		
		-- Unload all tiles, so the memory footprint has disappeared magically
		for name, data in pairs ( tiles ) do
			unloadTile ( name )
		end
	end
end
addEventHandler("onClientResourceStart",resourceRoot,toggleCustomTiles)
--bindKey("F5","down",toggleCustomTiles)
addCommandHandler ( "cusradar", toggleCustomTiles )

function handleTileLoading ( )
	-- Get all visible radar textures
	local visibleTileNames = table.merge ( engineGetVisibleTextureNames ( "radar??" ), engineGetVisibleTextureNames ( "radar???" ) )
	
	-- Unload tiles we don't see
	for name, data in pairs ( tiles ) do
		if not table.find ( visibleTileNames, name ) then
			unloadTile ( name )
		end
	end
	
	-- Load tiles we do see
	for index, name in ipairs ( visibleTileNames ) do
		loadTile ( name )
	end
end

function table.merge ( ... )
	local ret = { }
	
	for index, tbl in ipairs ( {...} ) do
		for index, val in ipairs ( tbl ) do
			table.insert ( ret, val )
		end
	end
	
	return ret
end

function table.find ( tbl, val )
	for index, value in ipairs ( tbl ) do
		if value == val then
			return index
		end
	end
	
	return false
end

-------------------------------------------
--
-- Tile loading and unloading functions
--
-------------------------------------------

function loadTile ( name )
	-- Make sure we have a string
	if type ( name ) ~= "string" then
		return false
	end
	
	-- Check whether we already loaded this tile
	if tiles[name] then
		return true
	end
	
	-- Extract the ID
	local id = tonumber ( name:match ( "%d+" ) )
	
	-- If not a valid ID, abort
	if not id then
		return false
	end
	
	-- Fetch the filename
	local file = string.format ( "sattelite/radar%d.png", id )
	
	-- Check if it exists
	if not fileExists(file) then
		file = "sattelite/black.png"
	end
	
	-- Now, load that damn file! (Also create a transparent overlay texture)
	local texture = dxCreateTexture ( file, "dxt5", true )
	
	-- If it failed to load, abort
	if not texture --[[or not overlay]] then
		outputChatBox ( string.format ( "Failed to load texture for %q (%q)", tostring ( name ), tostring ( file ) ) )
		return false
	end
	
	-- Now we just need the shader
	local shader = dxCreateShader ( "texreplace.fx" )
	
	-- Abort if failed (don't forget to destroy the texture though!!!)
	if not shader then
		outputChatBox ( "Failed to load shader" )
		destroyElement ( texture )
		return false
	end
	
	-- Now hand the texture to the shader
	dxSetShaderValue ( shader, "gTexture", texture )
	
	-- Now apply this stuff on the tile
	engineApplyShaderToWorldTexture ( shader, name )
	
	-- Store the stuff
	tiles[name] = { shader = shader, texture = texture }
	
	-- Return success
	return true
end

function unloadTile ( name )
	-- Get the tile data
	local tile = tiles[name]
	
	-- If no data is present, we failed
	if not tile then
		return false
	end
	
	-- Destroy the shader and texture elements, if they exist
	if isElement ( tile.shader )  then destroyElement ( tile.shader )  end
	if isElement ( tile.texture ) then destroyElement ( tile.texture ) end
	
	-- Now remove all reference to it
	tiles[name] = nil
	
	-- We succeeded
	return true
end