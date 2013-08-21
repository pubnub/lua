--
-- PubNub Dev Console 
--
require "pubnub"
require "crypto"
require "PubnubUtil"


-- INITIALIZE PUBNUB STATE
--
local pubnub_obj = pubnub.new({
    publish_key   = "demo",
    subscribe_key = "demo",
    secret_key    = "demo",
    ssl           = false,
    origin        = "pubsub.pubnub.com"
})

local function notifyUser(x)
	print(x)
end

local x = 0



local function get_input(msg,valtype,default)
	local x
	while type(x) ~= valtype do
		print(msg .. " (" .. valtype .. ") :")
		x = io.read()
		 
		if x == nil and default ~= nil then return default end

		if valtype == "number" then
			x = tonumber(x) or nil
		end

		if valtype == "boolean" then
			x =  x == "true" or x == "True" or x == "yes" or x == "Yes" or x == "y" or x == "Y" or nil
		end
	end

	return x
end


local function subscribe_handler()
	local channel = get_input("Enter Channel Name", "string")

	pubnub_obj:subscribe({
		channel  = channel,
		callback = function(r)  print(r) end,	
		error  	 = function(e)  print(e) end
	})
end

local function publish_handler()
	local channel = get_input("Enter Channel Name", "string")
	local message = get_input("Enter message", "string")
	pubnub_obj:publish({
		channel  = channel,
		message  = message,
		callback = function(r)  print(r) end,	
		error  	 = function(e)  print(e) end
	})
end

local function history_handler()
	local channel = get_input("Enter Channel Name", "string")
	local count = get_input("Enter Count", "number")
	local reverse = get_input("Reverse?", "boolean")
	pubnub_obj:history({
		channel = channel, 
		count = count,
		reverse = reverse,
		callback = function(r)  print(r) end,	
		error  	 = function(e)  print(e) end
	})
end

local function time_handler()
	pubnub_obj:time(function(t) print(t) end)
end

local function here_now_handler()
	local channel = get_input("Enter Channel Name", "string")
	pubnub_obj:here_now({
		channel = channel, 
		callback = function(r)  print(r) end,	
		error  	 = function(e)  print(e) end
	})
end

local function unsubscribe_handler()
	pubnub_obj:unsubscribe({
		channel = channel	
	})
end

local function init_handler()
	local pubkey = get_input("Enter Publish Key", "string", "demo")
	local subkey = get_input("Enter Subscribe Key", "string", "demo")
	local seckey = get_input("Enter Secret Key", "string")
	local ssl 	 = get_input("SSL ?","boolean",false)
	local origin = get_input("Enter origin", "string", "pubsub.pubnub.com")

	pubnub_obj = pubnub.new({
	    publish_key   = pubkey,
	    subscribe_key = subkey,
	    secret_key    = seckey,
	    ssl           = ssl,
	    origin        = origin
	})
end


local cmd_table = {
	{cmd = "Subscribe", handler = subscribe_handler},
	{cmd = "Publish", handler = publish_handler},
	{cmd = "History", handler = history_handler},
	{cmd = "Here Now", handler = here_now_handler},
	{cmd = "Time", handler = time_handler},
	{cmd = "Init", hanlder = init_handler}

}

local function last_cmd()
	local x = 1
	for k,v in next,cmd_table do
    	x = x + 1
	end
	return x 
end

local function print_menu()
	local x = 1
	for k,v in next,cmd_table do
    	print("Enter " .. k .. " for " .. v.cmd)
    	x = x + 1
	end
	print("Enter " .. x .. " to exit")
	print("Enter " .. x + 1 .. " or more to specify interval in seconds\nafter which command input should be asked")
end


local function get_command()	
	print_menu()
	x = get_input("Please enter a command", "number")
	if (cmd_table[x]) then cmd_table[x].handler() end
	local delay = 5
	if x > last_cmd() then delay = x end
	if (x ~= last_cmd()) then timer.performWithDelay( delay * 1000, get_command) end
end

timer.performWithDelay( 1 * 1000, get_command)
