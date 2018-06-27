-- 
-- TEXT OUT - Quick Print

-- 

module(..., package.seeall)

function table.in_table(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

local fontSize = display.contentWidth/25
local tempTxt = display.newText("Ty", 0, 0, nil, fontSize)
local starty = 0
local spacing = tempTxt.height * 0.25
tempTxt:removeSelf()
local currenty = starty

function set_starty(newy)
	starty = newy
	currenty = starty
end

function textout(text)

    if type(text) == "table" then
        text = table.tostring(text)
    end

    print(text)

    if currenty > display.contentHeight * 0.8 then currenty = starty end
    if currenty == starty then
        local background = display.newRect(
            display.contentWidth/2,
            display.contentHeight/2,
            display.contentWidth,
            display.contentHeight
        )
        background:setFillColor(0.9, 0.9, 0.8)
    end

    local myText = display.newText( text, 0, currenty, display.contentWidth, 0, nil, fontSize )

    myText:setTextColor(0.3, 0.3, 0.6)
	myText.anchorX = 0
	myText.anchorY = 0
	currenty = currenty + myText.height + spacing

end
