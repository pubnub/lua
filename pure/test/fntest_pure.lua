require "pubnub"
local json = require("dkjson")

local params = {...}

local function getenv_ex(env, dflt)
    local s = os.getenv(env)
    return s or (dflt)
end

local pubkey = getenv_ex("PUBNUB_PUBKEY", (#params > 0) and params[1] or "demo")
local subkey = getenv_ex("PUBNUB_KEYSUB", (#params > 1) and params[2] or "demo")
local origin = getenv_ex("PUBNUB_ORIGIN", (#params > 2) and params[3] or "ps.pndsn.com")


function get_file_name() return debug.getinfo(2, 'S').source end
function get_line_num() return debug.getinfo(2, 'l').currentline end

local publish_test_callback = function ( t_ctx, info )
    if not info[1] then
        print( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
        print ( "publish failed: " .. info[2] )
        t_ctx.test_passing = false
        t_ctx.failed_tests = t_ctx.failed_tests + 1
    end
end

local signal_test_callback = function ( t_ctx, info )
    if not info[1] then
        print( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
        print ( "signal failed: " .. info[2] )
        t_ctx.test_passing = false
        t_ctx.failed_tests = t_ctx.failed_tests + 1
    end
end

local function shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

local subscribe_test_callback = function ( t_ctx, message, ch )
    local message_table = shallowCopy(t_ctx.expected_messages)
    for k,v in pairs(message_table) do
        if (v == (json.encode(message) or message)) then
            if t_ctx.expected_channels then
                if (t_ctx.expected_channels[k] ~= ch) then
                    print( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
                    print( t_ctx.FILE .. ":" .. t_ctx.LINE .. ": " ..
                          "channel \"" .. ch .. "\" doesn't match on received message: " ..
                          (json.encode(message) or message) ..
                          " - expected channel = \"" .. t_ctx.expected_channels[k] .. "\"" )
                    if t_ctx.test_passing then
                        t_ctx.failed_tests = t_ctx.failed_tests + 1
                        t_ctx.test_passing = false
                    end
                end
                table.remove(t_ctx.expected_channels, k)
            end
            table.remove(t_ctx.expected_messages, k)
            break
        end
    end
end

local subscribe_v2_test_callback = function ( t_ctx, response )
    --[[ messages removed from the table --]]
    local r = 0;
    local message_table = shallowCopy(t_ctx.expected_messages)
    local m_type_table = shallowCopy(t_ctx.expected_message_types)
    for k,v in pairs(message_table) do
        for j,vr in next, response['m'] do
            local message = vr['d'];
            if (v == (json.encode(message) or message)) then
               local m_type = vr['e']
               if (not m_type and (m_type_table[k] == 0) or (m_type == m_type_table[k])) then
                  if t_ctx.expected_channels then
                      local ch = vr['c']
                      if (t_ctx.expected_channels[k] ~= ch) then
                          print( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
                          print( t_ctx.FILE .. ":" .. t_ctx.LINE .. ": " ..
                                 "channel \"" .. ch .. "\" doesn't match on received message: " ..
                                 (json.encode(message) or message) ..
                                 " - expected channel = \"" .. t_ctx.expected_channels[k] .. "\"" )
                          t_ctx.failed_tests = t_ctx.failed_tests + 1
                          t_ctx.test_passing = false
                          break
                      end
                  end
                  table.remove(t_ctx.expected_messages, k - r)
                  r = r + 1
                  break
               else
                  print( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
                  print( t_ctx.FILE .. ":" .. t_ctx.LINE .. ": " ..
                         "message type \"" .. (m_type or "published") ..
                         "\" doesn't match on received message: " ..
                         (json.encode(message) or message) ..
                         " - expected message type = \"" .. m_type_table[k] .. "\"" )
                  t_ctx.failed_tests = t_ctx.failed_tests + 1
                  t_ctx.test_passing = false
                  break
               end
            end
        end
        if not t_ctx.test_passing then
            break
        end 
    end
end

local presence = function(message, ch)
    print ( "presence - " .. ch .. " : " .. ( json.encode(message) or message ) )
end

local function received_all_expected_messages( t_ctx, subs_file_name, subs_line_num )
    if (t_ctx.test_passing and (#t_ctx.expected_messages ~= 0)) then
        print ( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
        print(subs_file_name .. ":" .. subs_line_num .. ": " ..
              "remaining expected messages are not received: " ..
              table.concat( t_ctx.expected_messages, "," ) )
        t_ctx.failed_tests = t_ctx.failed_tests + 1
        t_ctx.test_passing = false
    end
    return t_ctx.test_passing
end

local function received_any_expected_message( t_ctx,
                                              control_message_table,
                                              subs_file_name,
                                              subs_line_num )
    if (t_ctx.test_passing and (#t_ctx.expected_messages ~= #control_message_table)) then
        print ( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
        print(subs_file_name .. ":" .. subs_line_num .. ": " ..
              "Some of the messages expected not to be received are received. " ..
              "Remaining messages from 'control_message_table': " ..
              table.concat( t_ctx.expected_messages, "," ) )
        t_ctx.failed_tests = t_ctx.failed_tests + 1
        t_ctx.test_passing = false
    end
    return not t_ctx.test_passing
end

local function subscribe_and_check( t_ctx,
                                    pn,
                                    chan,
                                    time_s,
                                    message_list,
                                    channel_list,
                                    subs_file_name,
                                    subs_line_num  )
    local t0 = os.time()
    t_ctx.expected_messages = message_list
    t_ctx.expected_channels = channel_list
    t_ctx.FILE = subs_file_name
    t_ctx.LINE = subs_line_num
    while (t_ctx.test_passing and
           (#t_ctx.expected_messages ~= 0) and
           (os.difftime(os.time(), t0) < time_s)) do
        pn:subscribe ( {
            channel  = chan,
            timetoken = pn:get_timetoken(),
            callback = function( message, ch )
                subscribe_test_callback( t_ctx, message, ch )
            end,
            error = function ( err )
                test_failed( t_ctx, subs_file_name, subs_line_num, err )
            end
        } )
    end
    if not received_all_expected_messages( t_ctx, subs_file_name, subs_line_num ) then return false end
    
    return true
end

local function subscribe_v2_and_check( t_ctx,
                                       reverse_test,
                                       pn,
                                       chan,
                                       time_s,
                                       filter_exp,
                                       message_list,
                                       message_type_list,
                                       channel_list,
                                       subs_file_name,
                                       subs_line_num  )
    local t0 = os.time()
    local message_table = shallowCopy(message_list)
    t_ctx.expected_messages = message_list
    t_ctx.expected_message_types = message_type_list
    t_ctx.expected_channels = channel_list
    t_ctx.FILE = subs_file_name
    t_ctx.LINE = subs_line_num
    while (t_ctx.test_passing and
           (#t_ctx.expected_messages ~= 0) and
           (os.difftime(os.time(), t0) < time_s)) do
        pn:subscribe_v2 ( {
            channel  = chan,
            timetoken = pn:get_timetoken(),
            filter_expr = filter_exp,
            callback = function( response )
                subscribe_v2_test_callback( t_ctx, response )
            end,
            error = function ( err )
                test_failed( t_ctx, subs_file_name, subs_line_num, err )
            end
        } )
    end
    if reverse_test then
       if received_any_expected_message( t_ctx,
                                         message_table,
                                         subs_file_name,
                                         subs_line_num ) then
           return false
       end
    else
       if not received_all_expected_messages( t_ctx, subs_file_name, subs_line_num ) then
           return false
       end
    end
    
    return true
end

local function test_failed( t_ctx, subs_file_name, subs_line_num, response )
    print ( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : failed" ) 
    print ( subs_file_name .. ":" .. subs_line_num .. ": transaction failed: " .. (response) )
    t_ctx.test_passing = false
    t_ctx.failed_tests = t_ctx.failed_tests + 1
end

local function test_indetrminate( t_ctx, subs_file_name, subs_line_num, response )
    print ( t_ctx.test_index .. ".test - " .. t_ctx.test_name .. " : indeterminate" ) 
    print ( subs_file_name .. ":" .. subs_line_num .. ": transaction failed: " .. (response) )
    t_ctx.test_passing = false
    t_ctx.indeterminate_tests = t_ctx.indeterminate_tests + 1
end

local function publish_error( t_ctx, subs_file_name, subs_line_num, response )
    if string.find(response, "\"Account quota exceeded") then
        test_indetrminate( t_ctx, subs_file_name, subs_line_num, response )
    else
        test_failed( t_ctx, subs_file_name, subs_line_num, response )
    end
end

local function start_test( t_ctx )
    t_ctx.test_passing = true
    t_ctx.test_index = t_ctx.test_index + 1
end

local function fntest_connect_and_send_over_single_channel( t_ctx )
    t_ctx.test_name = "connect_and_send_over_single_channel_lua"
    local chan = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn = pubnub.new ( t_ctx.init )
    pn:subscribe ( {
        channel  = chan,
        callback = function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan,
                  message  = "test Lua 1",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan,
                  message  = "test Lua 1-2",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    subscribe_and_check(t_ctx,
                        pn,
                        chan,
                        5,
                        { "\"test Lua 1\"" , "\"test Lua 1-2\"" },
                        nil,
                        get_file_name(),
                        get_line_num())
end

local function fntest_connect_and_send_over_several_channels( t_ctx )
    t_ctx.test_name = "connect_and_send_over_several_channels_lua"
    local chan_1 = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    local chan_2 = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn = pubnub.new ( t_ctx.init )
    pn:subscribe ( {
        channel  = chan_1 .. "," .. chan_2,
        callback =  function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan_1,
                  message  = "test Lua M1",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan_2,
                  message  = "test Lua M1-2",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    subscribe_and_check(t_ctx,
                        pn,
                        chan_1 .. "," .. chan_2,
                        5,
                        { "\"test Lua M1\"" , "\"test Lua M1-2\"" },
                        { [1] = chan_1, [2] = chan_2 },
                        get_file_name(),
                        get_line_num())
end

local function fntest_connect_and_receiver_over_single_channel( t_ctx )
    t_ctx.test_name = "connect_and_receiver_over_single_channel_lua"
    local chan = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn_1 = pubnub.new ( t_ctx.init )
    --[[ For different pubnub objects 'init' tables must be different( locations in memory) --]] 
    local init_2 = { publish_key   = pubkey,
                     subscribe_key = subkey,
                     secret_key    = nil,
                     auth_key      = "abcd",
                     ssl           = true,
                     origin        = origin
                   }
    local pn_2 = pubnub.new ( init_2 )
    
    pn_1:subscribe ( {
        channel  = chan,
        callback = function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn_2:publish ( {channel  = chan,
                    message  = "test - 3 - lua",
                    callback = function( info )
                        publish_test_callback( t_ctx, info )
                    end,
                    error = function ( response )
                        publish_error( t_ctx, get_file_name(), get_line_num(), response )
                    end
                 } )
    if not t_ctx.test_passing then return end
    subscribe_and_check(t_ctx,
                        pn_1,
                        chan,
                        5,
                        { "\"test - 3 - lua\"" },
                        nil,
                        get_file_name(),
                        get_line_num())
end

local function fntest_connect_and_receiver_v2_over_single_channel_no_filter( t_ctx )
    t_ctx.test_name = "connect_and_receiver_v2_over_single_channel_no_filter_lua"
    local chan = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn_1 = pubnub.new ( t_ctx.init )
    --[[ For different pubnub objects 'init' tables must be different( locations in memory) --]] 
    local init_2 = { publish_key   = pubkey,
                     subscribe_key = subkey,
                     secret_key    = nil,
                     auth_key      = "abcd",
                     ssl           = true,
                     origin        = origin
                   }
    local pn_2 = pubnub.new ( init_2 )
    
    pn_1:subscribe ( {
        channel  = chan,
        callback = function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn_2:publish ( {channel  = chan,
                    message  = "test - 4 - lua",
                    callback = function( info )
                        publish_test_callback( t_ctx, info )
                    end,
                    error = function ( response )
                        publish_error( t_ctx, get_file_name(), get_line_num(), response )
                    end
                 } )
    if not t_ctx.test_passing then return end
    pn_2:signal ( {channel  = chan,
                   message  = "test_signal - 4 - lua",
                   callback = function( info )
                       signal_test_callback( t_ctx, info )
                   end,
                   error = function ( response )
                       publish_error( t_ctx, get_file_name(), get_line_num(), response )
                   end
                } )
    if not t_ctx.test_passing then return end
    subscribe_v2_and_check( t_ctx,
                            false,
                            pn_1,
                            chan,
                            5,
                            nil,
                            { "\"test - 4 - lua\"" , "\"test_signal - 4 - lua\"" },
                            { [1] = pn_1:message_type_published() , [2] = pn_1:message_type_signal() },
                            { [1] = chan, [2] = chan },
                            get_file_name(),
                            get_line_num() )
end

local function fntest_connect_v2_and_send_over_several_channels_no_filter( t_ctx )
    t_ctx.test_name = "connect_v2_and_send_over_several_channels_no_filter_lua"
    local chan_1 = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    local chan_2 = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn = pubnub.new ( t_ctx.init )
    pn:subscribe ( {
        channel  = chan_1 .. "," .. chan_2,
        callback = function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn:signal ( {channel  = chan_1,
                 message  = "test Lua M5 signal",
                 callback = function( info )
                     signal_test_callback( t_ctx, info )
                 end,
                 error = function ( response )
                     publish_error( t_ctx, get_file_name(), get_line_num(), response )
                 end
                } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan_2,
                  message  = "test Lua M5 publish",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    subscribe_v2_and_check( t_ctx,
                            false,
                            pn,
                            chan_1 .. "," .. chan_2,
                            5,
                            nil,
                            { "\"test Lua M5 signal\"" , "\"test Lua M5 publish\"" },
                            { [1] = pn:message_type_signal() , [2] = pn:message_type_published() },
                            { [1] = chan_1, [2] = chan_2 },
                            get_file_name(),
                            get_line_num() )
end

local function fntest_connect_v2_and_receive_with_matching_filter_expression( t_ctx )
    t_ctx.test_name = "connect_v2_and_receive_with_matching_filter_expression_lua"
    local chan = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn = pubnub.new ( t_ctx.init )
    pn:subscribe ( {
        channel  = chan,
        callback = function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan,
                  message  = "test Lua 6",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan,
                  message  = "test_metadata Lua 6-2",
                  meta = "{\"pub\":\"nub\"}",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    subscribe_v2_and_check( t_ctx,
                            false,
                            pn,
                            chan,
                            5,
                            "pub=='nub'",
                            { "\"test_metadata Lua 6-2\"" },
                            { [1] = pn:message_type_published() },
                            { [1] = chan },
                            get_file_name(),
                            get_line_num() )
end

local function fntest_connect_v2_and_receive_with_non_matching_filter_expression( t_ctx )
    t_ctx.test_name = "connect_v2_and_receive_with_non_matching_filter_expression_lua"
    local chan = t_ctx.test_name .. "_" .. math.random(t_ctx.number)
    start_test( t_ctx )
    local pn = pubnub.new ( t_ctx.init )
    pn:subscribe ( {
        channel  = chan,
        callback = function( message, ch )
            subscribe_test_callback( t_ctx, message, ch )
        end,
        error = function ( err )
            test_failed( t_ctx, get_file_name(), get_line_num(), err )
        end,
        presence = presence
    } )
    if not t_ctx.test_passing then return end
    pn:publish ( {channel  = chan,
                  message  = "test_metadata Lua 7-1",
                  meta = "{\"pub\":\"nub\"}",
                  callback = function( info )
                      publish_test_callback( t_ctx, info )
                  end,
                  error = function ( response )
                      publish_error( t_ctx, get_file_name(), get_line_num(), response )
                  end
                 } )
    if not t_ctx.test_passing then return end
    pn:signal ( {channel  = chan,
                 message  = "test_signal Lua 7-2",
                 callback = function( info )
                     signal_test_callback( t_ctx, info )
                 end,
                 error = function ( response )
                     publish_error( t_ctx, get_file_name(), get_line_num(), response )
                 end
                } )
    if not t_ctx.test_passing then return end
    subscribe_v2_and_check( t_ctx,
                            true,
                            pn,
                            chan,
                            5,
                            "pub==7",
                            { "\"test_metadata Lua 7-1\"", "test_signal Lua 7-2" },
                            { [1] = pn:message_type_published(), [2] = pn:message_type_signal() },
                            { [1] = chan, [2] = chan },
                            get_file_name(),
                            get_line_num() )
end

local function run_tests()
   local t_ctx = { number = 10^9,
                   test_index = 0,
                   test_name = nil,
                   test_passing = nil,
                   expected_messages = nil,
                   expected_message_types = nil,
                   expected_channels = nil,
                   indeterminate_tests = 0,
                   failed_tests = 0,
                   FILE = nil,
                   LINE = nil,
                   init = { publish_key   = pubkey,
                            subscribe_key = subkey,
                            secret_key    = nil,
                            auth_key      = "abcd",
                            ssl           = true,
                            origin        = origin
                          }
                 }
    math.randomseed(os.time())
    fntest_connect_and_send_over_single_channel( t_ctx )
    fntest_connect_and_send_over_several_channels( t_ctx )
    fntest_connect_and_receiver_over_single_channel( t_ctx )
    fntest_connect_and_receiver_v2_over_single_channel_no_filter( t_ctx )
    fntest_connect_v2_and_send_over_several_channels_no_filter( t_ctx )
    fntest_connect_v2_and_receive_with_matching_filter_expression( t_ctx )
    fntest_connect_v2_and_receive_with_non_matching_filter_expression( t_ctx )
    if ( t_ctx.failed_tests ~= 0 ) then
        print( t_ctx.failed_tests .. ((1 == t_ctx.failed_tests) and " test" or " tests") .. " failed." )
    end
    if ( t_ctx.indeterminate_tests ~= 0 ) then
        print( t_ctx.indeterminate_tests ..
               ((1 == t_ctx.indeterminate_tests) and " test" or " tests") .. " indeterminate." )
    end
    if ( 0 == t_ctx.failed_tests ) and ( 0 == t_ctx.indeterminate_tests ) then
        print( "All(" .. t_ctx.test_index .. ") tests passed." )
    else
        local passed = t_ctx.test_index- t_ctx.indeterminate_tests - t_ctx.failed_tests
        print( passed .. ((1 == passed) and " test" or " tests") .. " passed." )
    end
    os.exit(t_ctx.failed_tests)
end

run_tests()
