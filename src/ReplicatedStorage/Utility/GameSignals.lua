local SignalsToMake = {
	"AbilityUsed",
	"Charge"
}


local GameSignals = {}
GameSignals.Signals = {}

function GameSignals:Fire(signal, ...)
	if self.Signals[signal] then
		self.Signals[signal]:Fire(...)
	end
end

function GameSignals:Get(signal)
	return self.Signals[signal]
end

for _,signal in ipairs(SignalsToMake) do
	local event = Instance.new("BindableEvent")
	event.Name = signal
	event.Parent = script
	
	GameSignals.Signals[signal] = event
end
return GameSignals