# Please direct all Support Questions and Concerns to Support@PubNub.com

## PubNub 3.5 Real-time Cloud Push API - for Corona and Moai
## www.pubnub.com - PubNub Real-time Push Service in the Cloud. 

###GET YOUR PUBNUB KEYS HERE:
###http://www.pubnub.com/account#api-keys

PubNub is a Massively Scalable Real-time Service for Web and Mobile Games.
This is a cloud-based service for broadcasting Real-time messages
to thousands of web and mobile clients simultaneously.

#### Be sure to check out the sample code in the platform examples directories for complete code examples!

```lua
require "pubnub"
require "crypto"
require "PubnubUtil"

local pubnub_obj = pubnub.new({
    publish_key = "demo",
    subscribe_key = "demo",
    secret_key = "demo",
    ssl = false,
    origin = "pubsub.pubnub.com"
})

```

### Publish
```lua
pubnub_obj:publish({
        channel = channel,
        message = text,
        callback = function(r) --textout(r)
        end,
        error = function(r) textout(r)
        end
    })
})
```

### Subscribe
```lua
    pubnub_obj:subscribe({
        channel = channel,
        connect = function()
            textout('Connected to channel ')
            textout(channel)
        end,
        callback = function(message)
            --print(message.data.message)
            textout(message)
        end,
        error = function()
            textout("Oh no!!! Dropped 3G Conection!")
        end,
    })
```

### Unsubscribe
```lua
    multiplayer:unsubscribe({
        channel = channel,
    })
    textout( 'Disconnected from ' .. channel )
```

### Detailed History
```lua
function detailedHistory(channel, count, reverse)
    pubnub_obj:history({
        channel = channel,
        count = count,
        reverse = reverse,
        callback = function(response)
            textout(response)
        end,
        error = function (response)
            textout(response)
        end
    })
end

local my_channel = 'hello_world'
detailedHistory( my_channel, 5, false )
```

### Time
```lua
pubnub_obj:time(function(time)
    -- PRINT TIME
    print("PUBNUB SERVER TIME: " .. time)
end)
```

### UUID
```lua
uuid = pubnub_obj.uuid
print("PUBNUB UUID: ", uuid)
```

### here_now
```lua
function here_now(channel)
    pubnub_obj:here_now({
        channel = channel,
        limit = limit,
        callback = function(response)
            textout(response)
        end,
        error = function (response)
            textout(response)
        end
    })
end

local my_channel = 'hello-corona-demo-channel'
here_now( my_channel )
```

### Presence
```lua
function presence( channel, donecb )
    pubnub_obj:presence({
        channel = channel,
        connect = function()
            textout('Connected to channel ')
            textout(channel)
        end,
        callback = function(message)
            for i,v in pairs(message) do textout(i .. " " .. v) end
            timer.performWithDelay( 500, donecb )
        end,
        errorback = function()
            textout("Oh no!!! Dropped 3G Conection!")
        end
    })
end

local my_channel = 'hello_world'
presence(my_channel, function() end)

```

# Please direct all Support Questions and Concerns to Support@PubNub.com
