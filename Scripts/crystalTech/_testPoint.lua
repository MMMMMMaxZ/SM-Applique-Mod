TEST_POINT = class(nil)

TEST_POINT.test_points = {}
TEST_POINT.description = {}

function TEST_POINT.init(self)
    print("TEST_POINT initiating")
    for k=1,10 do
        self:Add_test_point()
    end
end

function TEST_POINT.Add_test_point(self) -- return the index
    self.test_points[#self.test_points+1] = sm.effect.createEffect("ShapeRenderable")
    self.test_points[#self.test_points]:setParameter("uuid",sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"))
    self.test_points[#self.test_points]:setParameter("color",sm.color.new("00fcfc"))
    self.test_points[#self.test_points]:setScale(sm.vec3.new(0.03,0.03,0.03))
    self.description[#self.test_points] = ""
    return #self.test_points
end

function TEST_POINT.set_description(self,idx,des)
    self.description[idx] = des
end

function TEST_POINT.get_description(self,idx)
    return self.description[idx]
end

function TEST_POINT.get_all_description(self)
    return TEST_POINT.description
end

function TEST_POINT.show_test_point(self,idx)
    if self.test_points[idx]:isPlaying() then return end
    self.test_points[idx]:start()
end

function TEST_POINT.stop_test_point(self,idx)
    self.test_points[idx]:stop()
end

function TEST_POINT.set_test_point(self,idx,worldP)
    self.test_points[idx]:setPosition(worldP)
end

function TEST_POINT.set_test_point_rotation(self,idx,worldR)
    self.test_points[idx]:setRotation(worldR)
end

function TEST_POINT.set_test_point_scale(self,idx,scale)
    self.test_points[idx]:setScale(scale)
end

function TEST_POINT.set_test_point_color(self,idx,color)
    self.test_points[idx]:setParameter("color",color)
end

function TEST_POINT.clear(self)
    for k = 1,#self.test_points do
        self.test_points[k]:stop()
    end
end