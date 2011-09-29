--[[
getset.lua
A library for adding getters and setters to Lua tables.
Copyright (c) 2011 Josh Tynjala
Licensed under the MIT license.
]]--

local function throwReadOnlyError(table, key)
	error("Cannot assign to read-only property '" .. key .. "' of " .. tostring(table) .. ".");
end

local function throwNotExtensibleError(table, key)
	error("Cannot add property '" .. key .. "' because " .. tostring(table) .. " is not extensible.")
end

local function throwSealedError(table, key)
	error("Cannot redefine property '" .. key .. "' because " .. tostring(table) .. " is sealed.")
end

local getsetmt = {}
function getsetmt.__index(table, key)
	local gs = table.__getset
	
	-- try to find a descriptor first
	local descriptor = gs.descriptors[key]
	if descriptor and descriptor.get then
		return descriptor.get()
	end
	
	-- if an old metatable exists, use that
	if gs.mt then
		return gs.mt.__index(table, key)
	end
	
	return nil
end
function getsetmt.__newindex(table, key, value)
	local gs = table.__getset
	
	-- check for a property first
	local descriptor = gs.descriptors[key]
	if descriptor then
		if not descriptor.set then
			throwReadOnlyError(table, key)
		end
		descriptor.set(value)
		return
	end
	
	-- use the metatable next
	if gs.mt and gs.mt.__newindex then
		gs.mt.__newindex(table, key, value)
		return
	end
	
	-- finally, fall back to rawset()
	if gs.isExtensible then
		rawset(table, key, value)
	else
		throwNotExtensibleError(table, key)
	end
end

-- initializes the table with __getset field
local function initgetset(table)
	if table.__getset then
		return
	end
	
	local oldmt = getmetatable(table)
	table.__getset = 
	{
		mt = oldmt,
		descriptors = {},
		isExtensible = true
	}
	setmetatable(table, getsetmt)
	return table
end

local getset = {}

--- Defines a new property or modifies an existing property on a table. A getter
-- and a setter may be defined in the descriptor, but both are optional.
-- @param table			The table on which to define or modify the property
-- @param key			The name of the property to be defined or modified
-- @param descriptor	The descriptor containing the getter and setter functions for the property being defined or modified
-- @return 				The table and the old raw value of the field
function getset.defineProperty (table, key, descriptor)
	initgetset(table)
	
	local gs = table.__getset
	
	local oldDescriptor = gs.descriptors[key]
	local oldRawValue = rawget(table, key)
	
	if gs.isSealed and (oldDescriptor or oldRawValue) then
		throwSealedError(table, key)
	elseif not gs.isExtensible and not oldDescriptor and not oldRawValue then
		throwNotExtensibleError(table, key)
	end
	
	gs.descriptors[key] = descriptor
	
	-- we need to set the raw value to nil so that the metatable works
	rawset(table, key, nil)
	
	-- but we'll return the old raw value, just in case it is needed
	return table, oldRawValue
end

--- Prevents new properties from being added to a table. Existing properties may
-- be modified and configured.
-- @param table		The table that should be made non-extensible
-- @return			The table
function getset.preventExtensions(table)
	initgetset(table)
	local gs = table.__getset
	gs.isExtensible = false
	return table
end

--- Determines if a table is extensible. If a table isn't initialized with
-- getset, this function returns true, since regular tables are always
-- extensible.
-- @param table		The table to be checked
-- @return			true if extensible, false if non-extensible
function getset.isExtensible(table)
	local gs = table.__getset
	if not gs then
		return true
	end
	return gs.isExtensible
end

--- Prevents new properties from being added to a table, and existing properties 
-- may be modified, but not configured.
-- @param table		The table that should be sealed
-- @return			The table
function getset.seal(table)
	initgetset(table)
	local gs = table.__getset
	gs.isExtensible = false
	gs.isSealed = true
	return table
end

--= Determines if a table is sealed. If a table isn't initialized with getset,
-- this function returns false, since regular tables are never sealed.
-- @param table		The table to be checked
-- @return			true if sealed, false if not sealed
function getset.isSealed(table)
	local gs = table.__getset
	if not gs then
		return false
	end
	return gs.isSealed
end
		
return getset