-- Version: 3.4.0
-- www.pubnub.com - PubNub realtime push service in the cloud.
-- https://github.com/pubnub/pubnub-api/tree/master/lua lua-Corona Push API

-- PubNub Real Time Push APIs and Notifications Framework
-- Copyright (c) 2010 Stephen Blum
-- http://www.pubnub.com/

-- -----------------------------------
-- PubNub 3.4.0 Real-time Push Cloud API
-- -----------------------------------

require "Json"
require "crypto"
require "BinDecHex"


function string:split(sSeparator, nMax, bRegexp)
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)

    local aRecord = {}

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField=1 nStart=1
        local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = self:sub(nStart)
    end

    return aRecord
end


pubnub      = {}

function pubnub.base(init)
    local self          = init
    local CHANNELS      = {}
    local SUB_CALLBACK  = nil
    local SUB_RESTORE   = false
    local SUB_RECEIVER  = nil
    local PRESENCE_SUFFIX = '-pnpres'
    local SUB_WINDOWING = 1
    local SUB_TIMEOUT   = 310
    local TIMETOKEN     = 0
    local KEEPALIVE     = 15
    local SECOND        = 1
    local methods       = {}
    local stop_keepalive = true 

    if not self.origin then
        self.origin = "pubsub.pubnub.com"
    end

    local origin = self.origin

    function change_origin()
        origin = string.gsub(self.origin, "pubsub", "ps-" .. math.random(1000))
    end

    local function each(table,func)
        for k,v in next, table do
            func(v)
        end
    end

    local function _encode(str)
        str = string.gsub( str, "([^%w])", function(c)
            return string.format( "%%%02X", string.byte(c) )
        end )
        return str
    end

    local function _map( func, array )
        local new_array = {}
        for i,v in ipairs(array) do
            new_array[i] = func(v)
        end
        return new_array
    end

     local Hex2Dec, BMOr, BMAnd, Dec2Hex
     if(BinDecHex)then
        Hex2Dec, BMOr, BMAnd, Dec2Hex = BinDecHex.Hex2Dec, BinDecHex.BMOr, BinDecHex.BMAnd, BinDecHex.Dec2Hex
     end

     local function UUID()
        local chars = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
        local uuid = {[9]="-",[14]="-",[15]="4",[19]="-",[24]="-"}
        local r, index
        for i = 1,36 do
                if(uuid[i]==nil)then
                        -- r = 0 | Math.random()*16;
                        r = math.random (36)
                        if(i == 20 and BinDecHex)then 
                                -- (r & 0x3) | 0x8
                                index = tonumber(Hex2Dec(BMOr(BMAnd(Dec2Hex(r), Dec2Hex(3)), Dec2Hex(8))))
                                if(index < 1 or index > 36)then 
                                        print("WARNING Index-19:",index)
                                        return UUID() -- should never happen - just try again if it does ;-)
                                end
                        else
                                index = r
                        end
                        uuid[i] = chars[index]
                end
        end
        return table.concat(uuid)
     end

    local function build_url(url_components, url_params)

        table.insert ( url_components, 1, origin )
        local url = table.concat(url_components,'/')
        
        if self.ssl then
            url = "https://" .. url
        else
            url = "http://" .. url
        end

        local params = {}
        if not url_params then return url end

        for k,v in next,url_params do
            if v then
                table.insert(params, k .. "=" .. v)
            end
        end
        local query = table.concat(params, '&')

        if (query and string.len(query) > 0) then 
            url = url .. "?" .. query
        end

        return url
    end

    function self:set_auth_key(key)
        self.auth_key = key
    end

    function self:get_auth_key(key)
        return self.auth_key
    end

    function self:publish(args)
        local callback = args.callback or function() end
        local error_cb    = args.error or function() end

        if not (args.channel and args.message) then
            return callback({ nil, "Missing Channel and/or Message" })
        end

        local channel   = args.channel
        local message   = Json.Encode(args.message)
        local signature = "0"

        -- SIGN PUBLISHED MESSAGE?
        if self.secret_key then
            signature = crypto.hmac( crypto.sha256,self.secret_key, table.concat( {
                self.publish_key,
                self.subscribe_key,
                self.secret_key,
                channel,
                message
            }, "/" ) )
        end

        -- PUBLISH MESSAGE
        self:_request({
            callback = function(response)
                if not response then
                    return error_cb({ nil, "Connection Lost" })
                end
                callback(response)
            end,
            fail = function(response) error_cb(response) end ,
            url  = build_url({
                "publish",
                self.publish_key,
                self.subscribe_key,
                signature,
                _encode(channel),
                "0",
                _encode(message)
            }, { auth = self.auth_key })
        })
    end

    local function generate_channel_list(channels)
        local list = {}
        each(channels, function(channel)
            if channel.subscribed then
                table.insert(list, channel.name)
            end
        end)
        return list
    end

    local function each_channel(callback) 
        local count = 0
        if not callback then return end
        each( generate_channel_list(CHANNELS), function(channel) 
            local chan = CHANNELS[channel]

            if not chan then return end

            count = count + 1
            callback(chan)
            end
        )

        return count
    end

    function self:get_current_channels()
        return generate_channel_list(CHANNELS)
    end

    function self:subscribe(args)
        local channel       = args.channel
        local callback      = callback              or args.callback
        local error_cb         = args['error']         or function() end
        local connect       = args['connect']       or function() end
        local reconnect     = args['reconnect']     or function() end
        local disconnect    = args['disconnect']    or function() end
        local noheresync    = args['noheresync']    or false
        local presence      = args['presence']      or false
        local backfill      = args['backfill']      or false
        local timetoken     = args['timetoken']     or 0
        local timeout       = args['timeout']       or SUB_TIMEOUT
        local windowing     = args['windowing']     or SUB_WINDOWING
        local restore       = args['restore']       or false

        if not channel then return print("Missing Channel") end
        if not callback then return print("Missing Callback") end
        if not self.subscribe_key then return print("Missing Subscribe Key") end

        SUB_RESTORE = restore
        TIMETOKEN   = timetoken

        each(string.split(channel, ','), function(ch)

            local settings = CHANNELS[ch] or {}
            SUB_CALLBACK = callback
            SUB_CHANNEL = ch
            CHANNELS[SUB_CHANNEL] = {
                name            = ch ,
                connected       = settings.connected or false ,
                disconnected    = settings.disconnected or false ,
                subscribed      = true ,
                callback        = SUB_CALLBACK,
                connect         = connect,
                disconnect      = disconnect,
                reconnect       = reconnect
            }
            if not presence then return end

            self:subscribe({
                channel = ch .. PRESENCE_SUFFIX,
                callback = presence
            })

            if settings.subscribed then return end

        end)
                    -- Test Network Connection

        local function _test_connection(success) 
            if success then
                -- Begin Next Socket Connection
                self:set_timeout( SECOND, function() methods:CONNECT() end );
            
            else 
                change_origin()

                -- Re-test Connection
                self:set_timeout( SECOND, function() 
                    self:time(_test_connection);
                end);
            end

            -- Disconnect & Reconnect
            each_channel(function(channel)
                -- Reconnect
                if success and channel.disconnected then
                    channel.disconnected = 0;
                    return channel.reconnect(channel.name)
                end

                -- Disconnect
                if not success and not channel.disconnected then
                    channel.disconnected = 1
                    channel.disconnect(channel.name)
                end 
            end)
        end

        local function _invoke_callback(msg, channel)
            CHANNELS[channel]['callback'](msg, channel)
        end

        local function _reset_offline(err) 
            if SUB_RECEIVER then SUB_RECEIVER(err) end
            SUB_RECEIVER = nil;
        end


        local function _poll_online()
            if stop_keepalive then return end
            self:time(function(success) 
                if not success then  _test_connection() end
                self:set_timeout( KEEPALIVE, function() _poll_online() end)
            end)
        end

        local function start_poll_online()
            if stop_keepalive then
                stop_keepalive = false
                _poll_online()
            end
        end



        -- SUBSCRIPTION RECURSION 
        local function _connect()

            local channels = table.concat(generate_channel_list(CHANNELS), ",")

            if not channels then
                stop_keepalive = true
                return 
            end

            _reset_offline()
            start_poll_online()

            -- CONNECT TO PUBNUB SUBSCRIBE SERVERS
            SUB_RECEIVER = self:_request({
                timeout = timeout,
                url = build_url({
                    "subscribe",
                    self.subscribe_key,
                    _encode(channels),
                    "0",
                    tostring(TIMETOKEN)
                    }, 
                    { uuid = self.uuid, 
                    auth = self.auth_key }),
                fail = function()
                    SUB_RECEIVER = nil
                    self:time(_test_connection)
                end,
                callback = function(messages)
                    SUB_RECEIVER = nil

                    -- Check for errors
                    if not messages then 
                        error_cb()
                        return self:set_timeout(windowing, _connect)
                    end

                    -- Restore previous Connection point if needed
                    TIMETOKEN = messages[2]

                    -- connect

                    each_channel(function(channel) 
                        if channel.connected then return end;
                        channel.connected = 1;
                        channel.connect(channel.name);
                    end);

                    -- invoke memory catchup and invoke upto 
                    -- 100 previous messages from the Queue

                    if backfill then
                        TIMETOKEN = 10000
                        backfill = 0
                    end


                    -- invoke callback on channels
                    if not messages[3] then
                            for k,v in next, messages[1] do
                                _invoke_callback(v, SUB_CHANNEL)
                            end
                    else
                        for k,v in next, string.split(messages[3], ',') do 
                            _invoke_callback(messages[1][k], string.split(v,"-pnpres")[1])
                        end
                    end

                    -- do recursive connect
                    self:set_timeout(windowing, _connect)
                end
            })

        end
        function methods:CONNECT()
            _reset_offline()
            _connect()
        end
        methods:CONNECT()
        
    end

    function self:unsubscribe(args)
        local channel = args.channel
        if not CHANNELS[channel] then return nil end
        -- DISCONNECT
        CHANNELS[channel].connected = nil
        CHANNELS[channel].subscribed = nil

        self:unsubscribe({channel = channel .. PRESENCE_SUFFIX})

    end

    function self:here_now(args)
        if not (args.callback and args.channel) then
            return print("Missing Here Now Callback and/or Channel")
        end

        local channel  = args.channel
        local callback = args.callback
        local error_cb = args.error or function() end

        self:_request({
            callback = callback,
            fail = error_cb,
            url  = build_url({
                'v2',
                'presence',
                'sub-key', self.subscribe_key,
                'channel', _encode(channel)
            }, { auth = self.auth_key })
        })

    end    

    function self:history(args)
        if not (args.callback and args.channel) then
            return print("Missing History Callback and/or Channel")
        end

        query = {}

        if (args.start or args.stop or args.reverse) then

            if args.start then
                query["start"] = args.start
            end

            if args.stop then
                query["stop"] = args.stop
            end

            if args.reverse then
                if (args.reverse == true or args.reverse == "true") then
                    query["reverse"] = "true"
                    else
                    query["reverse"] = "false"
                end
            end
        end

        local channel  = args.channel
        local callback = args.callback
        local error_cb = args.error or function() end
        local count = args.count

        if not count then
            count = 10
            else count = args.count
        end

        query["count"] = count

        query.auth = self.auth_key

        self:_request({
            callback = callback,
            fail     = error_cb,
            url  = build_url({
                'v2',
                'history',
                'sub-key',
                self.subscribe_key,
                'channel',
                _encode(channel)
            }, query );
        })
    end

    function self:time(callback)
        if not callback then
            return print("Missing Time Callback")
        end

        self:_request({
            url  = build_url({ "time", "0" }),
            callback = function(response)
                if response then
                    return callback(response[1])
                end
                    callback(nil)
            end,
            fail = function(response)
                callback(nil)
            end
        })
    end



    self.uuid = UUID()
    
    -- RETURN NEW PUBNUB OBJECT
    return self

end

function pubnub.new(init)
    local self          = pubnub.base(init)

    function self:set_timeout(delay, func)
        timer.performWithDelay( delay * 1000, func)
    end

    function self:_request(args)
        local request_id = nil
        local params = {}

        local http_status_lookup = {}
        http_status_lookup[200] = true


        local function abort()
            if request_id then network.cancel(request_id) end
        end

        params["V"] = "3.4.0"
        params["User-Agent"] = "Corona"
        params.timeout = args.timeout

        request_id = network.request( args.url, "GET", function(event)
            if (event.isError) then
                return args.fail(nil)
            end

            status, message = pcall( Json.Decode, event.response )

            if status and http_status_lookup[event.status] then
                return args.callback(message)
            else 
                return args.fail(message)
            end
        end, params)

        return abort
    end

    -- RETURN NEW PUBNUB OBJECT
    return self

end
