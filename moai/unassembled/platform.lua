

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

    function self:_request ( args )

    	local task = MOAIHttpTask.new ()

    	function done(err)
    		task:setCallback(function() end)
    		task:setTimeout(1)
    	end

        print(args.url)
		task:setUrl(args.url)
		task:setHeader 			( "V", "VERSION" )
		if args.timeout then
			task:setTimeout     	(args.timeout)
		end
		task:setHeader 			( "User-Agent", "PLATFORM" )
		task:setFollowRedirects 	(true)
		task:setFailOnError		(false)

		task:setCallback	( function ( response )
			--print(response:getString())
			if task:getResponseCode() ~= 200 then 
				return args.fail()
			end
			status, message = pcall ( MOAIJsonParser.decode, response:getString() )

			if status then
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
