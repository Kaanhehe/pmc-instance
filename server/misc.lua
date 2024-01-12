-- Idk if it was like a trend to always use _ for every variable name, but I'm not doing that.
-- Its easier to read assembly than it is to read code with _ everywhere.
local GERB = assert(GetEntityRoutingBucket)
local GPRB = assert(GetPlayerRoutingBucket)
local SERB = assert(SetEntityRoutingBucket)
local SPRB = assert(SetPlayerRoutingBucket)

_G.Instances = {}

_G.Utilities = {
	isDebugEnabled = (GetResourceMetadata(GetCurrentResourceName(), 'debug_log') == 'yes'),
	debugFormatted = GetResourceMetadata(GetCurrentResourceName(), 'debug_message') or '[INSTANCE] Player %s entered instance %s'
}
setmetatable(Utilities, {
	__index = {
		DebugMessage = function(self, playerId, instanceId)
			if self.isDebugEnabled then
				print(self.debugFormatted:format(playerId, instanceId))
			end
		end,
		Ensure = function(self, o, t)
			assert(type(o) == t, 'invalid Lua type, expected '..t..', got '..type(o))
			return true
		end,
		EnsureInstance = function(self, instanceId)
			self:Ensure(instanceId, 'number')
			if Instances[instanceId] == nil then
				Instances[instanceId] = {
					players = {},
					entities = {}
				}
			elseif Instances[instanceId].players == nil then
				Instances[instanceId].players = {}
			elseif Instances[instanceId].entities == nil then
				Instances[instanceId].entities = {}
			end
			return true
		end,
		EnsureAddPlayer = function(self, instanceId, playerId)
			if self:Ensure(instanceId, 'number') and self:Ensure(playerId, 'number') then
				if self:EnsureInstance(instanceId) then
					if GPRB(playerId) == 0 then
						table.insert(Instances[instanceId].players, playerId)
						SPRB(playerId, instanceId)
						self:DebugMessage(playerId, instanceId)
					else
						self:EnsureChangePlayer(instanceId, playerId, true) -- add player to garage via invite or jobgarage
					end
				end
			end
		end,
		EnsureRemovePlayer = function(self, instanceId, playerId)
			if self:Ensure(playerId, 'number') then
				self:EnsureChangePlayer(instanceId, playerId, false)
			end
		end,
		EnsureChangePlayer = function(self, instanceId, playerId, addtoInstance)
			if self:Ensure(instanceId, 'number') and self:Ensure(playerId, 'number') then
				local currentInstance = GPRB(playerId)
				if self:EnsureInstance(instanceId) and self:EnsureInstance(currentInstance) then
					if currentInstance ~= 0 then
						if addtoInstance then
							Instances[instanceId].players[#Instances[instanceId].players + 1] = playerId
						else
							for i, v in ipairs(Instances[instanceId].players) do
								if v == playerId then
									Instances[instanceId].players[i] = nil
									break
								end
							end
						end
						instanceId = addtoInstance and instanceId or 0
						SPRB(playerId, instanceId)
						self:DebugMessage(playerId, instanceId)
					end
				end
			end
		end,
	}
})

AddEventHandler('__instance_internal:instance:player:add', function(...) Utilities:EnsureAddPlayer(...) end)
AddEventHandler('__instance_internal:instance:player:remove', function(...) Utilities:EnsureRemovePlayer(...) end)
AddEventHandler('__instance_internal:instance:players:get', function(inIndex, cb)
	if Utilities:Ensure(inIndex, 'number') then
		if Utilities:EnsureInstance(inIndex) then
			cb(Instances[inIndex].players)
		end
	end
end)
