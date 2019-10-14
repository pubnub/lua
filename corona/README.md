## PubNub 3.3 Real-time Cloud Push API - Corona
## www.pubnub.com - PubNub Real-time Push Service in the Cloud. 

###GET YOUR PUBNUB KEYS HERE:
###http://www.pubnub.com/account#api-keys

PubNub is a Massively Scalable Real-time Service for Web and Mobile Games.
This is a cloud-based service for broadcasting Real-time messages
to thousands of web and mobile clients simultaneously.

#### Be sure to copy "pubnub.lua" and "Json.lua" into your Project Directory,
and check out the sample code in the 3.3 directory for complete code examples!

```lua
require "pubnub"

multiplayer = pubnub.new({
    publish_key   = "demo",             -- YOUR PUBLISH KEY
    subscribe_key = "demo",             -- YOUR SUBSCRIBE KEY
    secret_key    = nil,                -- YOUR SECRET KEY
    ssl           = nil,                -- ENABLE SSL?
    origin        = "pubsub.pubnub.com" -- PUBNUB CLOUD ORIGIN
})
```

### Publish
```lua
multiplayer:publish({
    channel  = "lua-corona-demo-channel",
    message  = { "1234", 2, 3, 4 },
    callback = function(info)

        -- WAS MESSAGE DELIVERED?
        if info[1] then
            print("MESSAGE DELIVERED SUCCESSFULLY!")
        else
            print("MESSAGE FAILED BECAUSE -> " .. info[2])
        end

    end
})
```

### Signal
```lua
pubnub_obj:signal({
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
multiplayer:subscribe({
    channel  = "lua-corona-demo-channel",
    callback = function(message)
        -- MESSAGE RECEIVED!!!
        print(Json.Encode(message))
    end,
    errorback = function()
        print("Network Connection Lost")
    end
})
```

### Unsubscribe
```lua
multiplayer:unsubscribe({
    channel = "lua-corona-demo-channel"
})
```

### Detailed History
```lua
function detailedHistory(channel, count, reverse)
    pubnub_obj:history({
        channel = channel,
        count = count,
        reverse = reverse,
        callback = function(response)
            if response then
                for k, v in pairs(response[1])
                    do
                    print( type (v) )
                    if (type (v) == 'string')
                    then print(v)
                    elseif (type (v) == 'table')
                    then
                        for i,line in ipairs(v) do
                            print(line)
                        end
                    end
                end
            end

        end
    })
end

local my_channel = 'hello_world'
detailedHistory( my_channel, 5, false )
```

### Time
```lua
multiplayer:time(function(time)
    -- PRINT TIME
    print("PUBNUB SERVER TIME: " .. time)
end)
```

### UUID
```lua
uuid = multiplayer.uuid
print("PUBNUB UUID: ", uuid)
```

### here_now
```lua
function here_now(channel)
    pubnub_obj:here_now({
        channel = channel,
        limit = limit,
        callback = function(response)
            if response then
                for k, v in pairs(response) 
                    do 
                    if (type (v) == 'string')
                    then textout(v)
                    elseif (type (v) == 'table') 
                    then
                        for i,line in ipairs(v) do
                            textout(line)
                        end
                    end
                end
            end
        end
    })
end

local my_channel = 'hello-corona-demo-channel'
here_now( my_channel )
```

### Presence/where-now
```lua
function presence( channel)
    pubnub_obj:where_how({
        channel = channel,
        callback = function(message)
            for i,v in pairs(message.payload.channels) do textout(i .. " " .. v) end
        end,
        error = function()
            textout("Oh no!!! Dropped 3G Conection!")
        end
    })
end

local my_channel = 'hello_world'
presence(my_channel)

```
