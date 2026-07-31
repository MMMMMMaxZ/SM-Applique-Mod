t = class(nil)

function t.server_onCreate(self)
    self.lastState = false
end

function t.server_onFixedUpdate(self , dt)
    self.input = getState()
    if self.input and not self.lastState then
        doStuff()
    end
    self.lastState = self.input
end
