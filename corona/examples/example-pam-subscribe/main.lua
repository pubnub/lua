--
-- INIT CHAT:
-- This initializes the pubnub networking layer.
--
require "pubnub"
require "PubnubUtil"
local widget = require( "widget" )

local events_display = display.newText( "Events Display", 0, 0, "AmericanTypewriter-Bold", 18 )
events_display.x, events_display.y = display.contentCenterX, 200

local messages_display = display.newText( "Messages Display", 0, 0, "AmericanTypewriter-Bold", 18 )
messages_display.x, messages_display.y = display.contentCenterX, 250





local channelField, authKeyField
local fields = display.newGroup()

-- Note: currently this feature works in device builds or Xcode simulator builds only (also works on Corona Mac Simulator)
local isAndroid = "Android" == system.getInfo("platformName")
local inputFontSize = 18
local inputFontHeight = 30
tHeight = 30

channelField = native.newTextField( 50, 50, 200, tHeight )
channelField.font = native.newFont( native.systemFontBold, inputFontSize )
channelField.placeholder = "channel"

authKeyField = native.newTextField( 50, 100, 200, tHeight )
authKeyField.font = native.newFont( native.systemFontBold, inputFontSize )
authKeyField.placeholder = "auth_key"

pubnub = pubnub.new({
    publish_key   = "pub-c-c077418d-f83c-4860-b213-2f6c77bde29a",
    subscribe_key = "sub-c-e8839098-f568-11e2-a11a-02ee2ddab7fe",
    secret_key    = nil,
    ssl           = nil,
    origin        = "pubsub.pubnub.com"
})

-- 
-- HIDE STATUS BAR
-- 
display.setStatusBar( display.HiddenStatusBar )

--
-- A FUNCTION THAT WILL OPEN NETWORK A CONNECTION TO PUBNUB
--
function connect()
    pubnub:set_auth_key(authKeyField.text)
    pubnub:subscribe({
        channel  = channelField.text ,
        connect  = function(channel)
            events_display.text = 'Connected to ' .. ( channel or channelField.text )
        end,
        disconnect  = function(channel)
            events_display.text = 'Disconnected from ' .. ( channel or channelField.text )
        end,
        reconnect  = function(channel)
            events_display.text = 'Reconnected to ' .. ( channel or channelField.text )
        end,
        callback = function(message)
            messages_display.text = message
        end,
        error = function(message)
            events_display.text = "Connection Error on " .. ( channel or channelField.text )
        end
    })
end


local button1 = widget.newButton
{
    defaultFile = "buttonRed.png",
    overFile = "buttonRedOver.png",
    label = "Subscribe",
    emboss = true,
    onRelease = connect,
}


button1.x = 160; button1.y = 320

