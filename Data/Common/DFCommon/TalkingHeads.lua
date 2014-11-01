local DFGraphics = require "DFCommon.Graphics"

local m = {}

function m.doSequence(sequenceData, pictureSize, borderSize, textHeight, textWidth, viewport, layer)
    local sequence = {}
    
    sequence.sequenceData = sequenceData
    sequence.pictureSize = pictureSize
    sequence.borderSize = borderSize
    sequence.textHeight = textHeight
    sequence.textWidth = textWidth
    sequence.viewport = viewport
    sequence.layer = layer
    sequence.advance = false
    sequence.isDone = false
    
    function sequence:main()
        -- Create the visuals for the talking heads
        self.characters = {}
        for name,character in pairs(self.sequenceData.characters) do
            local talkingHead = MOAIProp2D.new()
            talkingHead.name = name
            talkingHead.dialogFont = DFGraphics.fontLibrary[character.dialogFont]
            talkingHead.spriteSheet = DFGraphics.loadSpriteSheet(character.spriteSheet)
            
            for key,val in pairs(talkingHead.spriteSheet.names) do
                DFGraphics.alignSprite(talkingHead.spriteSheet, key, 'center', 'center' ) 
            end
            
            talkingHead:setDeck( talkingHead.spriteSheet )
            talkingHead:setIndex( talkingHead.spriteSheet.names['Normal'] )
            sequence.characters[name] = talkingHead
        end
      
        -- Play out the dialog sequence in full
        for i, line in pairs(self.sequenceData.lines) do
            -- Setup talkers
            local bottom = self.viewport.sizeY * -0.5 + self.borderSize
            local speakers = {'talker', 'listener'}
            for i,role in pairs(speakers) do
                if line[role].name ~= nil then
                    local talkingHead = self.characters[line[role].name]
                    local spriteIndex = talkingHead.spriteSheet.names[line[role].expression]
                    talkingHead:setIndex( spriteIndex )
                    self.layer:insertProp( talkingHead )
                    
                    local headRect = talkingHead.spriteSheet.rects[spriteIndex]
                    local scale = self.pictureSize / headRect.height
                    local halfScale = scale * 0.5
                    talkingHead:setScl( scale, scale )
                    if line[role].align == 'left' then
                        talkingHead:setLoc( self.viewport.sizeX * -0.5 + self.borderSize + headRect.width * halfScale, bottom + headRect.height * halfScale )
                    elseif line[role].align == 'right' then
                        talkingHead:setLoc( self.viewport.sizeX * 0.5 - self.borderSize - headRect.width * halfScale, bottom + headRect.height * halfScale )
                    else
                        -- Warning for bad data?
                    end
                    
                    self[role] = talkingHead 
                end
            end
            
            -- Setup textbox
            local textbox = nil
            if line.text ~= nil then
                local talkingHead = self['talker']
            
                textbox = MOAITextBox.new()
                textbox:setFont( talkingHead.dialogFont )
                textbox:setTextSize( talkingHead.dialogFont:getScale() )
                textbox:setString( line.text )
                textbox:setYFlip(true)
                
                local talkingHeadLocX, talkingHeadLocY = talkingHead:getLoc()
                local headRect = talkingHead.spriteSheet.rects[ talkingHead.spriteSheet.names[line.talker.expression] ]
                local scale = pictureSize / headRect.height
                local halfScale = scale * 0.5
                local textPad = self.pictureSize / 8
                if line.talker.align == 'left' then
                    local startX =  talkingHeadLocX + headRect.width * halfScale + textPad
                    local startY = talkingHeadLocY
                    textbox:setRect( startX, startY - self.textHeight * 0.5, startX + self.textWidth, startY + self.textHeight * 0.5 )
                    textbox:setAlignment( MOAITextBox.LEFT_JUSTIFY )
                elseif line.talker.align == 'right' then
                    local start =  talkingHeadLocX - headRect.width * halfScale - textPad
                    local startY = talkingHeadLocY
                    textbox:setRect( start - self.textWidth, startY - self.textHeight * 0.5, start, startY + self.textHeight * 0.5 )
                    textbox:setAlignment( MOAITextBox.RIGHT_JUSTIFY )
                else
                    -- Warning for bad data?
                end
                
                layer:insertProp( textbox )
                textbox:spool()
            end
            
            -- wait for timer or input
            local timer = MOAITimer.new()
            timer:setSpan( line.deliveryTime )
            timer:start()
            
            while true do
                coroutine.yield()
                if textbox ~= nil and line.color ~= nil then
                    textbox:setStringColor( 1, string.len(line.text), line.color[1], line.color[2], line.color[3], line.color[4] )
                end
                if timer:isDone() then
                    if self.advance or line.autoAdvance then
                        break
                    end
                else
                    if self.advance then
                        if textbox ~= nil and not textbox:isDone() then
                            textbox:stop()
                            textbox:revealAll()
                            self.advance = false
                        else
                            timer:stop()
                            break
                        end
                    end
                end
            end
            
            if textbox ~= nil then
                self.layer:removeProp(textbox)
            end
            
            for i,role in pairs(speakers) do
                if self[role] ~= nil then
                    self.layer:removeProp(self[role])
                    self[role] = nil
                end
            end
            
            self.advance = false
        end
        
        -- Decriment ref count of loaded assets after dialog is done
        for name,character in pairs(self.characters) do
            DFGraphics.unloadSpriteSheet(character.spriteSheet.path)
        end
        
        sequence.isDone = true
    end
    
    sequence.thread = MOAICoroutine.new ()
	sequence.thread:run( sequence.main, sequence )
	return sequence
end

return m
