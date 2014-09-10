-- 
-- Abstract: Button Events sample app, showing different button properties and handlers.
-- (Also demonstrates the use of external libraries.)
-- 
-- Version: 1.1
-- 
-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2010 Corona Labs Inc. All Rights Reserved.

-- This example shows you how to create buttons in various ways by using the widget library.
-- The project folder contains additional button graphics in various colors.
--
-- Supports Graphics 2.0

-- Require the widget library
require "pubnub"
local json = require "json"

local widget = require("widget")

local background = display.newImage("carbonfiber.jpg", true) -- flag overrides large image downscaling
background.x = display.contentWidth / 2
background.y = display.contentHeight / 2

local roundedRect = display.newRoundedRect(10, 50, 300, 40, 8)
roundedRect.anchorX, roundedRect.anchorY = 0.0, 0.0 -- simulate TopLeft alignment
roundedRect:setFillColor(0 / 255, 0 / 255, 0 / 255, 170 / 255)

local t = display.newText("Waiting for subscribed message receipt...", 0, 0, native.systemFont, 10)
t.x, t.y = display.contentCenterX, 70

local outputWindow = display.newText("Waiting for Presence / History Events", 0, 0, 300, 100, native.systemFont, 12)
outputWindow.x, outputWindow.y = display.contentCenterX, 450
-------------------------------------------------------------------------------
-- Create 5 buttons, using different optional attributes
-------------------------------------------------------------------------------

multiplayer = pubnub.new({
    publish_key = "demo",
    subscribe_key = "demo",
    secret_key = nil,
    ssl = nil,
    origin = "pubsub.pubnub.com"
})

channel = "z"

multiplayer:subscribe({
    channel = channel,
    callback = function(message)
        if message.msgtext ~= nil then
            t.text = "Received the published message: " .. message.msgtext
        else
            t.text = "Make sure message has a 'msgtext' key, eg {'msgtext':'myMessage'}"
        end
    end,
    errorback = function()
        print("Oh no!!! Dropped 3G Conection!")
    end,
    presence = function(message)
        outputWindow.text = ""
        local presenceOutput = ""
        for i, v in pairs(message) do
            presenceOutput = (i .. ": " .. v .. "\n")
            outputWindow.text = outputWindow.text .. presenceOutput
            print(presenceOutput)
        end
    end
})

-- These are the functions triggered by the buttons

local getHistory = function(event)
    t.text = "Fetching history..."

    multiplayer:history({
        count = 5,
        channel = channel,
        callback = function(message)
            outputWindow.text = ""
            local presenceOutput = ""
                presenceOutput = (json.encode(message) .. "\n")
                outputWindow.text = outputWindow.text .. presenceOutput
                print(presenceOutput)
        end,
        errorback = function()
            print("Oh no!!! Dropped 3G Conection!")
        end
    })
end

local publishMessage = function(event)
    t.text = "Publishing message..."

    multiplayer:publish({
        channel = channel,
        message = { msgtext = "sent from corona!" }
    })
end

local buttonHandler = function(event)
    t.text = "id = " .. event.target.id .. ", phase = " .. event.phase
end


-- This button has individual press and release functions
-- (The label font defaults to native.systemFontBold if no font is specified)

local publishButton = widget.newButton{
    defaultFile = "buttonRed.png",
    overFile = "buttonRedOver.png",
    label = "PUBLISH",
    emboss = true,
    onPress = publishMessage
}

local historyButton = widget.newButton{
    id = "historyButton",
    defaultFile = "buttonYellow.png",
    overFile = "buttonYellowOver.png",
    label = "HISTORY",
    labelColor =
    {
        default = { 51, 51, 51, 255 },
    },
    font = native.systemFont,
    fontSize = 22,
    emboss = true,
    onEvent = getHistory,
}

local button3 = widget.newButton{
    id = "button3",
    defaultFile = "buttonGray.png",
    overFile = "buttonBlue.png",
    label = "Button 3 Label",
    font = native.systemFont,
    fontSize = 28,
    emboss = true,
    onEvent = buttonHandler,
}

publishButton.x = 160; publishButton.y = 160
historyButton.x = 160; historyButton.y = 240
button3.x = 160; button3.y = 320

