localPlayer = class(nil)

localPlayer.state = {
    left = false,
    right = false,
    q = false,
    r = false,
    sameBody = false,
    deviceOn = false
}

localPlayer.tool = "Null"

function localPlayer.reset(self)
    self.state = {
        left = false,
        right = false,
        q = false,
        r = false,
        sameBody = self.state.sameBody,
        deviceOn = self.state.deviceOn
    }
    self.tool = "Null"
end