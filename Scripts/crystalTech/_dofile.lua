if sm.isServerMode() then return end
print("MAC dofile init...")
if localPlayer == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_localPlayer.lua") -- 获取玩家操作
end
if MLines == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_MLines.lua") -- 适应多语言文本
    MLines:init()
end
if CE == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_createEffects.lua") -- self:create_aplq()
    CE:init()
end
if SS == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_selectSystem.lua") -- 用于编辑贴花（选择、对称）
    SS:init()
end
if TEST_POINT == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_testPoint.lua") -- 测试用的debug_draw
    TEST_POINT:init()
    TEST_POINT:set_description(1,"align_flag")
    TEST_POINT:set_description(2,"mirrorVecSt")
    TEST_POINT:set_description(3,"mirrorVecEd")
    TEST_POINT:set_description(4,"dragPoint")
    TEST_POINT:set_description(5,"centerPoint")
end
if MACP == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_MAC_Parameter.lua") -- 记录同一玩家的编辑参数
    MACP:init()
end
if MTt == nil then
    dofile("$MOD_DATA/Scripts/crystalTech/_MAGtutorial.lua")
    MTt:init()
end
print("MAC init done")