--
-- INIT CHAT:
-- This initializes the pubnub networking layer.
--
require "pubnub"
require "PubnubUtil"

chat = pubnub.new({
    publish_key   = "demo",
    subscribe_key = "demo",
    secret_key    = nil,
    ssl           = nil,
    origin        = "pubsub.pubnub.com"
})

-- 
-- CHAT CHANNEL DEFINED HERE
-- 
CHAT_CHANNEL = 'PubNub-Chat-Channel'

local textout = PubnubUtil.textout
-- 
-- STARTING WELCOME MESSAGE FOR THIS EXAMPLE
-- 
PubnubUtil.set_starty(display.contentHeight * 0.05)
textout("Type your message in the box. Messages on the channel '"..CHAT_CHANNEL.."' will appear below")
textout(" ")

-- 
-- HIDE STATUS BAR
-- 
display.setStatusBar( display.HiddenStatusBar )


-- 
-- CREATE CHATBOX TEXT INPUT FIELD
-- 
chatbox = native.newTextField( 10, 10, display.contentWidth - 20, 40)
chatbox:addEventListener('userInput', function(event)
    -- Only send when the user is ready.
    if not (event.phase == "ended" or event.phase == "submitted") then
        return
    end

    -- Don't send Empyt Message
    if chatbox.text == '' then return end

    send_a_message(tostring(chatbox.text))
    chatbox.text = ''
    native.setKeyboardFocus(nil)
end )

chatbox.anchorX = 0
chatbox.anchorY = 0


--
-- A FUNCTION THAT WILL OPEN NETWORK A CONNECTION TO PUBNUB
--
function connect()
    chat:subscribe({
        channel  = CHAT_CHANNEL,
        connect  = function()
            textout('Connected!')
			native.setKeyboardFocus(chatbox)
        end,
        callback = function(message)
		    if message.msgtext then
				textout(message.msgtext)
			else
				textout(message)
			end
			native.setKeyboardFocus(chatbox)
        end,
        error = function(message)
            textout(message or "Connection Error")
        end
    })
end

--
-- A FUNCTION THAT WILL CLOSE NETWORK A CONNECTION TO PUBNUB
--
function disconnect()
    chat:unsubscribe({
        channel = CHAT_CHANNEL
    })
    textout('Disconnected!')
end

--
-- A FUNCTION THAT WILL SEND A MESSAGE
--
function send_a_message(text)
    chat:publish({
        channel  = CHAT_CHANNEL,
        message  = { msgtext = text },
        callback = function(info)
        end
    })
end

--
-- OPEN NETWORK CONNECTION VIA PUBNUB
--
connect()
