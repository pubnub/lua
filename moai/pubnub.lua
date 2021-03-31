-- Version: 3.6.0
-- www.pubnub.com - PubNub realtime push service in the cloud.
-- https://github.com/pubnub/lua lua-Corona Push API

-- PubNub Real Time Push APIs and Notifications Framework
-- Copyright (c) 2013 Stephen Blum
-- http://www.pubnub.com/

-- -----------------------------------
-- PubNub 3.6.0 Real-time Push Cloud API
-- -----------------------------------

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

    if not init then init = {} end

    init.pnsdk          = 'PubNub-Lua-Moai/3.6.0'

    local self          = init
    local CHANNELS      = {}
    local SUB_CALLBACK  = nil
    local SUB_RESTORE   = false
    local SUB_RECEIVER  = nil
    local PRESENCE_SUFFIX = '-pnpres'
    local SUB_WINDOWING = 1
    local SUB_TIMEOUT   = 310
    local MINIMAL_HEARTBEAT_INTERVAL = 270
    local MESSAGE_TYPE_PUBLISHED = 0
    local MESSAGE_TYPE_SIGNAL = 1
    local MESSAGE_TYPE_ACTION = 3
    local TIMETOKEN     = 0
    local REGION        = 0
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

    function _encode(str)
      if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w %-%_%.%~])",
            function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "%%20")
      end
      return str
    end

    function _encode_url_param(str)
      if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w %-%_%.%~])",
            function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
      end
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
        if url_params then
            for k,v in next,url_params do
                if v then
                    table.insert(params, k .. "=" .. _encode_url_param(v))
                end
            end
        end

        table.insert(params, "PNSDK" .. "=" .. _encode_url_param(self.pnsdk))
        table.insert(params, "uuid" .. "=" .. _encode_url_param(self.uuid))
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

    function self:leave(channel)
        if not (channel) then
            return print("Missing Channel")
        end

        self:_request({
            callback = function() end,
            fail = function() end,
            url  = build_url({
                'v2',
                'presence',
                'sub_key', self.subscribe_key,
                'channel', _encode(channel), 'leave'
            }, { uuid = self.uuid, auth = self.auth_key })
        })
    end

    function self:message_type_published()
        return MESSAGE_TYPE_PUBLISHED
    end

    function self:message_type_signal()
        return MESSAGE_TYPE_SIGNAL
    end

    function self:message_type_action()
        return MESSAGE_TYPE_ACTION
    end

    function self:publish(args)
        local callback = args.callback or function() end
        local error_cb    = args.error or function() end

        if not (args.channel and args.message) then
            return callback({ nil, "Missing Channel and/or Message" })
        end

        local channel   = args.channel
        local message   = self:json_encode(args.message)
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
            }, { auth = self.auth_key, meta = args.meta })
        })
    end

    function self:signal(args)
        local callback = args.callback or function() end
        local error_cb    = args.error or function() end

        if not (args.channel and args.message) then
            return callback({ nil, "Missing Channel and/or Message" })
        end

        local channel   = args.channel
        local message   = self:json_encode(args.message)
        local signature = "0"

        -- SIGNAL MESSAGE
        self:_request({
            callback = function(response)
                if not response then
                    return error_cb({ nil, "Connection Lost" })
                end
                callback(response)
            end,
            fail = function(response) error_cb(response) end ,
            url  = build_url({
                "signal",
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

    function self:get_timetoken()
        return TIMETOKEN
    end

    function self:subscribe(args)
        local channel       = args.channel
        local callback      = callback              or args.callback
        local error_cb      = args['error']         or function() end
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
                self:set_timeout( 10*SECOND, function()
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
            CHANNELS[channel]['callback'](msg, string.split(channel,"-pnpres")[1])
        end

        local function _reset_offline(err)
            if SUB_RECEIVER then SUB_RECEIVER(err) end
            SUB_RECEIVER = nil;
        end


        local function _poll_online()
            if stop_keepalive then return end
            self:time(function(success)
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

            if not channels or string.len(channels) == 0 then
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
                            _invoke_callback(messages[1][k], v)
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
        self:leave(channel)
        methods:CONNECT()
    end

    function self:message_v2_type(message_v2)
        return message_v2['e']
    end

    function self:is_message_v2_published(message_v2)
        return self:message_v2_type(message_v2) == MESSAGE_TYPE_PUBLISHED
    end

    function self:is_message_v2_signal(message_v2)
        return self:message_v2_type(message_v2) == MESSAGE_TYPE_SIGNAL
    end

    function self:is_message_v2_action(message_v2)
        return self:message_v2_type(message_v2) == MESSAGE_TYPE_ACTION
    end

    function self:subscribe_v2(args)
        local channel       = args.channel
        local callback      = callback_v2           or args.callback
        local error_cb      = args['error']         or function() end
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
        local filter_expr   = args.filter_expr
        local heart_beat    = args['heart_beat']    or MINIMAL_HEARTBEAT_INTERVAL

        if not channel then return print("Missing Channel") end
        if not callback then return print("Missing Callback") end
        if not self.subscribe_key then return print("Missing Subscribe Key") end

        SUB_RESTORE = restore
        TIMETOKEN   = timetoken

        each(string.split(channel, ','), function(ch)

            local settings = CHANNELS[ch] or {}
            SUB_CHANNEL = ch
            CHANNELS[SUB_CHANNEL] = {
                name            = ch ,
                connected       = settings.connected or false ,
                disconnected    = settings.disconnected or false ,
                subscribed      = true ,
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
                self:set_timeout( SECOND, function() methods:CONNECT_V2() end );

            else
                change_origin()

                -- Re-test Connection
                self:set_timeout( 10*SECOND, function()
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

        local function _reset_offline(err)
            if SUB_RECEIVER then SUB_RECEIVER(err) end
            SUB_RECEIVER = nil;
        end


        local function _poll_online()
            if stop_keepalive then return end
            self:time(function(success)
                self:set_timeout( KEEPALIVE, function() _poll_online() end)
            end)
        end

        local function start_poll_online()
            if stop_keepalive then
                stop_keepalive = false
                _poll_online()
            end
        end



        -- SUBSCRIPTION_V2 RECURSION
        local function _connect()

            local channels = table.concat(generate_channel_list(CHANNELS), ",")

            if not channels or string.len(channels) == 0 then
                stop_keepalive = true
                return
            end

            _reset_offline()
            start_poll_online()

            -- CONNECT TO PUBNUB SUBSCRIBE_V2 SERVERS
            SUB_RECEIVER = self:_request({
                timeout = timeout,
                url = build_url({
                    "v2",
                    "subscribe",
                    self.subscribe_key,
                    _encode(channels),
                    "0"
                    },
                    { tt = tostring(TIMETOKEN),
                      tr = tostring(REGION),
                      auth = self.auth_key,
                      ['filter-expr'] = filter_expr,
                      heartbeat = tostring(heart_beat)}),
                fail = function()
                    SUB_RECEIVER = nil
                    self:time(_test_connection)
                end,
                callback = function(response)
                    SUB_RECEIVER = nil

                    -- Check for errors
                    if not response then
                        error_cb()
                        return self:set_timeout(windowing, _connect)
                    end

                    -- Restore previous Connection point
                    TIMETOKEN = response['t']['t']
                    REGION = response['t']['r']

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

                    -- invoke callback
                    callback(response);

                    -- do recursive connect
                    self:set_timeout(windowing, _connect)
                end
            })

        end
        function methods:CONNECT_V2()
            _reset_offline()
            _connect()
        end
        methods:CONNECT_V2()

    end

    function self:where_now(args)
        if not (args.callback) then
            return print("Missing Where Now Callback")
        end

        local uuid  = args.uuid or self.uuid
        local callback = args.callback
        local error_cb = args.error or function() end

        self:_request({
            callback = callback,
            fail = error_cb,
            url  = build_url({
                'v2',
                'presence',
                'sub_key', self.subscribe_key,
                'uuid', _encode(uuid)
            }, { auth = self.auth_key })
        })

    end

    function self:here_now(args)
        if not (args.callback) then
            return print("Missing Here Now Callback")
        end

        local channel  = args.channel
        local callback = args.callback
        local error_cb = args.error or function() end

        query = {
                'v2',
                'presence',
                'sub-key', self.subscribe_key
            }

        if args.channel then
            table.insert(query, 'channel')
            table.insert(query, _encode(channel))
        end

        self:_request({
            callback = callback,
            fail = error_cb,
            url  = build_url(query, { auth = self.auth_key })
        })

    end

    function self:_get_objs_query(args)
        local query = {}
        if args.start then query["start"] = args.start end
        if args.endt then  query["end"] = args.endt end
        if args.limit then query["limit"] = args.limit end
        if args.count then query["count"] = args.count end
        if args.include then query["include"] = args.include end
        query["uuid"] = args.uuid or self.uuid
        query["auth"]= self.auth_key
        return query
    end

    function self:_get_objects(which, args)
        if not args.callback then
            return print("Missing callback")
        end
        if (args.start and args.endt) then
            return print("Cannot have both start and endt params for getting "..which)
        end

        self:_request({
            callback = args.callback,
            fail     = args.error or function() end,
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                which
            }, self:_get_objs_query(args))
        })
    end

    function self:_upd_obj_query(args)
        local query = {}
        if args.include then query["include"] = args.include end
        query["uuid"] = args.uuid or self.uuid
        query["auth"]= self.auth_key
        return query
    end

    function self:_get_object(which, args)
        if not args.callback then
            return print("Missing callback")
        end
        local sing = which:sub(1, which:len()-1)
        local obj_id = args[sing.."_id"] or args[sing].id
        if not obj_id then
            return print("Must provide "..sing.."_id or "..sing..".id to get object from "..which)
        end
        if args[sing.."_id"] and args[sing].id then
            return print("Cannot provide both "..sing.."_id and "..sing..".id to get object from "..which)
        end

        self:_request({
            callback = args.callback,
            fail     = args.error or function() end,
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                which,
                obj_id
            }, self:_upd_obj_query(args) )
        })
    end

    function self:_create_object(which, args)
        if not args.callback then
            return print("Missing callback")
        end
        local obj = args[which:sub(1, which:len()-1)]
        if not obj then
            return print("Must provide an object to create in "..which)
        end

        self:_request({
            callback = args.callback,
            fail     = args.error or function() end,
            method   = "POST",
            body     = obj,
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                which
            }, self:_upd_obj_query(args) )
        })
    end

    function self:_update_object(which, args)
        if not args.callback then
            return print("Missing callback")
        end
        local obj = args[which:sub(1, which:len()-1)]
        if not obj then
            return print("Must provide an object to update "..which)
        end
        if not obj.id then
            return print("Object must have an id to be updated")
        end

        self:_request({
            callback = args.callback,
            fail     = args.error or function() end,
            method   = "PATCH",
            body     = obj,
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                which,
                obj.id
            }, self:_upd_obj_query(args) )
        })
    end

    function self:_delete_object(which, args)
        if not args.callback then
            return print("Missing callback")
        end
        local singl = which:sub(1, which:len()-1)
        local obj_id = args[singl.."_id"] or args[singl].id
        if not obj_id then
            return print("Must provide "..singl.."_id or "..singl..".id to delete object from "..which)
        end
        if args[singl.."_id"] and args[singl].id then
            return print("Cannot provide both "..singl.."_id and "..singl..".id to delete object from "..which)
        end

        self:_request({
            callback = args.callback,
            fail     = args.error or function() end,
            method   = "DELETE",
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                which,
                obj_id
            }, self:_upd_obj_query(args) )
        })
    end

    function self:get_users(args)
        return self:_get_objects("users", args)
    end

    function self:get_user(args)
        return self:_get_object("users", args)
    end

    function self:create_user(args)
        return self:_create_object("users", args)
    end

    function self:update_user(args)
        return self:_update_object("users", args)
    end

    function self:delete_user(args)
        return self:_delete_object("users", args)
    end

    function self:get_spaces(args)
        return self:_get_objects("spaces", args)
    end

    function self:get_space(args)
        return self:_get_object("space", args)
    end

    function self:create_space(args)
        return self:_create_object("spaces", args)
    end

    function self:update_space(args)
        return self:_update_object("spaces", args)
    end

    function self:delete_space(args)
        return self:_delete_object("spaces", args)
    end

    function self:_update_obj_memberships(key, master, args)
        if not args.callback then
            return print("Missing callback")
        end
        if not args.update_obj then
            return print("Need update_obj to "..key)
        end
        if not args[master.."_id"] then
            return print("Need "..master.."_id to "..key)
        end

        local obj = { [key] = args.update_obj }
        local error_cb = args.error or function() end
        local others = master == "space" and "users" or "spaces"

        self:_request({
            callback = args.callback,
            fail     = error_cb,
            method   = "PATCH",
            body     = obj,
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                master.."s",
                args[master.."_id"],
                others
            }, self:_upd_obj_query(args) )
        })
    end

    function self:_get_obj_memberships(master, args)
        if not args.callback then
            return print("Missing callback")
        end
        if (args.start and args.endt) then
            return print("Cannot have both start and endt params for getting "..which)
        end
        if not args[master.."_id"] then
            return print("Need "..master.."_id to get")
        end

        local error_cb = args.error or function() end
        local others = master == "space" and "users" or "spaces"

        self:_request({
            callback = args.callback,
            fail     = error_cb,
            url  = build_url({
                'v1',
                'objects',
                self.subscribe_key,
                master.."s",
                args[master.."_id"],
                others
            }, self:_get_objs_query(args))
        })
    end

    function self:get_memberships(args)
        return self:_get_obj_memberships("user", args)
    end

    function self:update_memberships(args)
        return self:_update_obj_memberships("update", "user",  args)
    end

    function self:join_spaces(args)
        return self:_update_obj_memberships("add", "user",  args)
    end

    function self:leave_spaces(args)
        return self:_update_obj_memberships("leave", "user",  args)
    end

    function self:get_members(args)
        return self:_get_obj_memberships("space", args)
    end

    function self:update_members(args)
        return self:_update_obj_memberships("update", "space", args)
    end

    function self:add_members(args)
        return self:_update_obj_memberships("add", "space", args)
    end

    function self:remove_members(args)
        return self:_update_obj_memberships("remove", "space", args)
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

    function self:message_counts(args)
        local channels = args.channels
        local ctt = args.channelTimeTokens
        if not (args.callback and channels and ctt) then
            return print("Missing Message Counts Callback and/or Channels and/or Channel Time Tokens")
        end
        if #channels == 0 then
            return print("Channels cannot be empty")
        end
        if #ctt ~= 1 and #ctt ~= #channels then
            return print("Channels and channel time tokens must have same number of elements")
	end

        query = {}
        query.auth = self.auth_key
        if #ctt == 1 then
            query.timetoken = ctt[1]
        else
            query.channelsTimetoken = table.concat(ctt, ",")
        end
        local callback = args.callback
        local error_cb = args.error or function() end

        self:_request({
            callback = callback,
            fail     = error_cb,
            url  = build_url({
                'v3',
                'history',
                'sub-key',
                self.subscribe_key,
                'message-counts',
                _encode(table.concat(channels, ","))
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



    if not self.uuid then
        self.uuid = UUID()
    end

    -- RETURN NEW PUBNUB OBJECT
    return self

end


function pubnub.new( init )

    local self          = pubnub.base(init)


    function self:set_timeout ( delay, func, ... )
		local t = MOAITimer.new()
		t:setSpan ( delay )
		t:setListener ( MOAITimer.EVENT_TIMER_END_SPAN, function ()
			t:stop ()
			t = nil
			func ( unpack ( arg ) )
		end )
		t:start ()
	end

	function self:json_encode(msg)
		return MOAIJsonParser.encode(msg)
	end

	function self:json_decode(msg)
		return MOAIJsonParser.decode(msg)
	end

    function self:_request ( args )

    	local task = MOAIHttpTask.new ()

    	function done(err)
    		task:setCallback(function() end)
    		task:setTimeout(1)
    	end

		local verb = MOAIHttpTask.HTTP_GET
		if args.method == "DELETE" then
			verb = MOAIHttpTask.HTTP_DELETE
		elseif args.method == "PATCH" then
			verb = MOAIHttpTask.HTTP_PATCH
		elseif args.method == "POST" then
			verb = MOAIHttpTask.HTTP_POST
		elseif args.method == "PUT" then
			verb = MOAIHttpTask.HTTP_PUT
		end
		task:setVerb(verb)
		if args.body then
			task:setBody(args.body)
		end

		task:setUrl(args.url)
		task:setHeader 			( "V", "3.6.0" )
		if args.timeout then
			task:setTimeout     	(args.timeout)
		end
		task:setHeader 			( "User-Agent", "Moai" )
		task:setFollowRedirects 	(true)
		task:setFailOnError		(false)

		task:setCallback	( function ( response )

			if task:getResponseCode() ~= 200 then
				return args.fail()
			end

			message = self:json_decode(response:getString())

			if message then
            	return args.callback ( message )
            else
                return args.callback ( nil )
            end

		end )

		task:performAsync()
		return done
    end

    -- RETURN NEW PUBNUB OBJECT
    return self
end
