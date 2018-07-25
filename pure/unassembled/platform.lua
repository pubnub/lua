

local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")


function pubnub.new( init )

	local self          = pubnub.base(init)


	function self:set_timeout ( delay, func, ... )
		--socket.sleep(delay) -- FIXME needs to be on background thread
		--func ( unpack ( arg ) )
	end

	function self:json_encode(msg)
		return json.encode(msg)
	end

	function self:json_decode(msg)
		return json.decode(msg)
	end

	function self:_request ( args )
		local t = {}	    
		local r, c = http.request {
			url = args.url,
			sink = ltn12.sink.table(t),	    
			headers = {
				V = "VERSION",
				['User-Agent'] = "PLATFORM"
			},
			redirect = true
		}

		if r==nil or c ~= 200 then return args.fail() end
		message = self:json_decode(table.concat(t))

		if message then
			return args.callback ( message )
		else
			return args.callback ( nil )
		end
		return function() end
	end

	-- RETURN NEW PUBNUB OBJECT
	return self
end
