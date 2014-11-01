local Util = require('DFCommon.Util')
local GameRules = require('GameRules')

local SeqCommand = require('SeqCommand')
local Class = require('Class')
local ScLockControls = Class.create(SeqCommand)

ScLockControls.LockControls = true

local DFSchema = require('DFCommon.DFSchema')
local tFields = Util.deepCopy(SeqCommand.rSchema.tFieldSchemas)
tFields['LockControls'] = DFSchema.bool(true, "Specifies whether this command locks player controls.")

ScLockControls.rSchema = DFSchema.object(tFields, "Enables or disables player controls.")
SeqCommand.addEditorSchema('ScLockControls', ScLockControls.rSchema)

function ScLockControls:onExecute()     
    if ( self.LockControls and GameRules.isInteractionAllowed() ) or not self.LockControls then
        self._bDoCleanup = true
        GameRules:setLockPlayerControls(self.LockControls)
    end
end

function ScLockControls:onCleanup()
    if self._bDoCleanup then
        self._bDoCleanup = false
        GameRules:setLockPlayerControls(not self.LockControls)
    end
end

return ScLockControls
