--
-- PubNub Dev Console 
--
require "pubnub"
require "crypto"
require "PubnubUtil"


local textout = PubnubUtil.textout
local widget = require "widget"
local fontSize = display.contentWidth/25

-- INITIALIZE PUBNUB STATE
--
local pubnub_obj = pubnub.new({
    publish_key   = "demo",
    subscribe_key = "demo",
    secret_key    = "demo",
    ssl           = false,
    origin        = "pubsub.pubnub.com"
})


local function print_to_console(x)
	if type(x) == "table" then
		textout(table.tostring(x))
	else
		textout(x)
	end
end

local function current_sub_channel_list()
	local list_str = " "
	for k,v in next, pubnub_obj:get_current_channels() do
		list_str = list_str .. v .. "  "
	end
	return " ( Currently Subscribed to " .. list_str .. ")"
end

local function subscribe_handler(with_presence)
	local chn = channel_name.text
	local input = {
		channel  = chn,
		restore  = restore,
		callback = function(x)  print_to_console(x) end,
		connect  = function(x) print_to_console('CONNECTED to ' .. chn) end,
		disconnect = function(x) print_to_console('DISCONNECTED from ' .. chn) end,
		reconnect = function(x) print_to_console('RECONNECTED to ' .. chn) end,
		error  	 = function(e)  print_to_console(e) end
	}
	if with_presence then input['presence'] = function(x) print_to_console(x) end end
	pubnub_obj:subscribe(input)
	textout(current_sub_channel_list())
end

local function subscribe_wout_presence_handler() subscribe_handler(false) end
local function subscribe_with_presence_handler() subscribe_handler(true) end

local function publish_handler()
	textout("publishing "..param.text.." on "..channel_name.text)
	pubnub_obj:publish({
		channel  = channel_name.text,
		message  = param.text,
		callback = function(r)  print_to_console(r) end,	
		error  	 = function(e)  print_to_console(e) end
	})
end

local function history_handler_ex(reversed)
	local count = tonumber(param.text) or 10
	--textout("Getting history in "..count.." records"..(reversed and ", reversed" or ""))
	pubnub_obj:history({
		channel = channel_name.text, 
		count = count,
		reverse = reversed,
		callback = function(r)
			textout("Message history ("..#r[1].." messages):")
			--for i = 1, #r[1] do
			--	textout("    "..r[1][1])
			--end
			textout("    "..table.tostring(r[1]))
		end,
		error  	 = function(e)  print_to_console(e) end
	})
end

local function history_handler() history_handler_ex(false) end
local function history_reversed_handler() history_handler_ex(true) end

local function time_handler()
	pubnub_obj:time(function(t) textout(string.format("%.f", t)) end)
end

local function here_now_handler()
	pubnub_obj:here_now({
		channel = channel_name.text, 
		callback = function(r)  print_to_console(r) end,	
		error  	 = function(e)  print_to_console(e) end	
	})
end

local function init_handler()
	local seckey = get_input("Enter Secret Key", "string")

	pubnub_obj = pubnub.new({
	    publish_key   = "demo",
	    subscribe_key = "demo",
	    secret_key    = seckey,
	    ssl           = ssl,
	    origin        = "pubsub.pubnub.com"
	})
end

local function ssl_handler(newstate)
	pubnub_obj = pubnub.new({
	    publish_key   = pubnub_obj.publish_key,
	    subscribe_key = pubnub_obj.subscribe_key,
	    secret_key    = pubnub_obj.secret_key,
	    ssl           = newstate,
	    origin        = pubnub_obj.origin
	})
end

local function ssl_on_handler() 
	ssl_handler(true) 
	textout("SSL is now: On")
end
local function ssl_off_handler() 
	ssl_handler(false) 
	textout("SSL is now: Off")
end

local function secret_key_handler()
	pubnub_obj = pubnub.new({
	    publish_key   = pubnub_obj.publish_key,
	    subscribe_key = pubnub_obj.subscribe_key,
	    secret_key    = param.text,
	    ssl           = pubnub_obj.ssl,
	    origin        = pubnub_obj.origin
	})
	local seckey = pubnub_obj.secret_key
	textout(" ( Current secret key : " .. ( seckey or "") .. ")")
end

local function auth_key_set_handler()
	pubnub_obj:set_auth_key(param.text)
	local authkey = pubnub_obj:get_auth_key()
	textout(" ( Current auth key : " .. ( authkey or "") .. ")")
end

local function unsubscribe_handler()
	textout("unsubscribe from: "..channel_name.text)
	pubnub_obj:unsubscribe{channel = channel_name.text }
	textout(current_sub_channel_list())
end


local function textWidth(the_text)
	local tempTxt = display.newText(the_text, 0, 0, nil, fontSize)
	local rslt = tempTxt.width
	tempTxt:removeSelf()
	return rslt
end

local function textHeight(the_text)
	local tempTxt = display.newText(the_text, 0, 0, nil, fontSize)
	local rslt = tempTxt.height
	tempTxt:removeSelf()
	return rslt
end

local spacing = textHeight("Ty") * 0.25
local button_y_pos = spacing

-- 
-- CREATE developer channel and param TEXT INPUT FIELDs
-- 
local channel_text = display.newText("Channel", spacing, button_y_pos, nil, fontSize)
channel_text.anchorX = 0
channel_text.anchorY = 0
button_y_pos = button_y_pos + channel_text.height + spacing
channel_name = native.newTextField(spacing, button_y_pos, display.contentWidth - 2*spacing, 6*spacing)
channel_name.text = "hello_world"
channel_name.anchorX = 0
channel_name.anchorY = 0
button_y_pos = button_y_pos + channel_name.height + spacing
 
local param_text = display.newText("Parameter", spacing, button_y_pos, nil, fontSize)
param_text.anchorX = 0
param_text.anchorY = 0
button_y_pos = button_y_pos + param_text.height + spacing
param = native.newTextField(spacing, button_y_pos, display.contentWidth - 2*spacing, 6*spacing)
param.placeholder = "(publish message, history count, auth/secret key)"
param.anchorX = 0
param.anchorY = 0
button_y_pos = button_y_pos + param.height + spacing

--
-- Buttons
--

button_y_pos = button_y_pos + spacing
local button_x_pos = 10

local function add_button(label, f)
	local btn = widget.newButton{
		id = "zec",
		label = label,
		left = button_x_pos,
		top = button_y_pos,
		shape = "roundedRect",
		width = textWidth(label) + 2*spacing,
		emboss = true,
		cornerRadius = 8,
		strokeWidth = 4,
		fontSize = fontSize,
		labelColor = {default={0,0,1,0.8}, over={0,0,0, 0.5}},
		onEvent = function (e)
			if e.phase == "ended" then
				f()
			end
		end
		}
	--btn.anchorY = 1
	button_x_pos = button_x_pos + btn.width + spacing
	if button_x_pos + btn.width > display.contentWidth then 
		button_x_pos = spacing
		button_y_pos = button_y_pos + btn.height + 2*spacing
	end
end

add_button("Subscribe", subscribe_wout_presence_handler)
add_button("Unubscribe", unsubscribe_handler)
add_button("Subscribe w/presence", subscribe_with_presence_handler)
add_button("Publish", publish_handler)
add_button("History", history_handler)
add_button("History, reversed", history_reversed_handler)
add_button("Time", time_handler)
add_button("Here Now", here_now_handler)
add_button("Set Auth Key", auth_key_set_handler)
add_button("Set Secret Key", secret_key_handler)
add_button("SSL On", ssl_on_handler)
add_button("SSL Off", ssl_off_handler)

--
-- Position the "terminal" below buttons
--

if button_x_pos > spacing then button_y_pos = button_y_pos + spacing * 8 end
PubnubUtil.set_starty(button_y_pos + spacing)
