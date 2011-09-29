# getset.lua

A library for defining getters and setters on Lua tables by [Josh Tynjala](http://twitter.com/joshtynjala).

## Usage

	local getset = require("getset")
	
	function createSimple2DPoint()
		local _x = 0
		local _y = 0
		local point = {}
		getset.defineProperty( point, "x",
		{
			get = function()
				return _x
			end,
			set = function( value )
				_x = value
			end
		})
		getset.defineProperty( point, "y",
		{
			get = function()
				return _y
			end,
			set = function( value )
				_y = value
			end
		})
		
		getset.defineProperty(point, "length",
		{
			get = function(self)
				return math.sqrt(_x * _x + _y * _y)
			end
			-- no setter required
		})
		
		-- prevents new fields from being added later, and existing fields cannot
		-- be configured (we can't redefine the getters and setters later).
		-- see also: getset.preventExtensions()
		return getset.seal(point)
	end
	
	local myPoint = createSimple2DPoint()
	myPoint.x = 4
	myPoint.y = 4
	
	-- returns 5.6568542494924:
	local myPointLength = myPoint.length
	
	-- runtime error because the table is not extensible:
	myPoint.z = 7 
	
	-- runtime error because length has no setter:
	myPoint.length = 9 
	
	-- runtime error because table is sealed:
	getset.defineProperty( myPoint, "x",
	{
		get = function()
			return 1
		end
	})
	
## API

The getset library offers the following functions. For more detailed descriptions, see the documentation above each function in getset.lua.

### getset.defineProperty( table, key, descriptor )

Defines a getter and setter on a table for a specific key. Both are optional.

### getset.preventExtensions( table )

Prevents new properties from being added to a table. Existing properties may be modified and configured.

### getset.isExtensible( table )

Determines if a table is may be extended.

### getset.preventExtensions( table )

Prevents new properties from being added to a table, and existing properties may be modified, but not configured.

### getset.isSealed( table )

Determines if a table is sealed.