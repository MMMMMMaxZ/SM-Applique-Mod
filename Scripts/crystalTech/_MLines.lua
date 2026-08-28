-- MAXZ666
-- for lines in different languages
MLines = class(nil)

MLines.currentLanguage = nil
MLines.lines = {}
MLines.availableLans = {
    Chinese = true,
    English = true
}

function MLines.init(self)
    self.currentLanguage = sm.gui.getCurrentLanguage()
    if not self.availableLans[self.currentLanguage] then
        self.currentLanguage = "English" -- default to English 默认英文咯
    end
    self.lines = {
        Mtutorial = {
            Chinese = {
                "查看自定义贴花装置使用教程",
                "1-自定义贴花装置",
                "B站教程：https://www.bilibili.com/video/BV14M4m127RG/ \n 自由贴贴花、自定义贴花。\n\n\n 温馨提示：#00ffbcE键#fcfcfc关闭GUI界面\n\n更多问题可反馈至B站：MaxZ666\nhttps://space.bilibili.com/551042531\n模组反馈群：630586951",
                "2-激活贴花编辑",
                [[#fcfcfc接入非红色信号并启动来激活装置的编辑模式
仅由最近的玩家放置贴花。最多可贴270个贴花
关闭来保存贴花，
关闭输入信号会自动检测重叠的贴花并删除。
平时不编辑的话不激活也是会显示贴花的哦
#ff2222-1. 如果贴贴花没有显示的话关掉开关重新启动装置
-2. 如果操作失效且开关也失效时，无法发送数据到服务端就无法保存
    此时对装置按e即可保存
                ]],
                "3-贴花的运作原理",
                [[#fcfcfc贴花的运动状态与装置始终保持一致
即如图中贴花装置上升后仍跟随装置上升。
                ]],
                "4-放置与删除贴花",
                [[#fcfcfc手持MAG贴花工具
#00ffbc左键#fcfcfc：放置贴花，
按住时拖动一定距离后再往其他方向旋转可以旋转黏上的贴花。

#00ffbc右键#fcfcfc：按住右键时开启删除模式，
此时靠近要删除的会出现箭头标记所选住的贴花（该贴花会浮起），
再按左键就能删除了。
如果删除一个被包含在选择框中的贴花那么
会把所有选中的贴花都删除（具体见选择工具）。
                ]],
                "5-按R改贴花造型",
                [[#fcfcfc选择贴花。
手持MAG贴花工具
按#00ffbcR键（换弹键）#fcfcfc
左侧栏①与下面②选择类别，
右侧框③点击选择贴花。
自定义贴花类“Saved保存的图”能选择所保存的贴花和复制的贴花
                ]],
                "6-按Q改旋转大小颜色",
                [[#fcfcfc编辑贴花颜色、拉升、图层、发光。
手持MAG贴花工具按#00ffbcQ键（旋转键）#fcfcfc
1：竖直拉升
2：水平拉升
3：浮起拉升（图层）
4：旋转
5：10种颜色，如果是自定义贴花会全部上色
6：颜色栏的滚动条，切换颜色栏
7：重置，恢复拉升和旋转到如图所示
8：镜像翻转，同样适用于自定义贴花
9：发光
10：法线锁定，当遇到贴花朝向没有贴合预想的面时，
    可以先到贴合的部分开启法线锁定，再移到不贴合的地方
11：对齐精度，使贴花对齐网格
                ]],
                "7-吸色上色自定色",
                [[#fcfcfc颜色工具
#00ffbc左键#fcfcfc：
读取颜色，并存储在颜色编辑器的“当前颜色”
（即右侧可编辑可预览的颜色）中。

#00ffbc右键#fcfcfc：
按住右键时开启上色模式，
此时靠近要上色的会出现箭头标记所选住的贴花（该贴花会浮起），
再按左键就能上色了。
如果上色一个被包含在选择框中的贴花那么
会把所有选中的贴花都上色（具体见选择工具）

按#00ffbcQ键（旋转键）#fcfcfc
打开颜色编辑器，除了已给的40个颜色（原版），
还开放了10个自定义颜色，在第5页。
点击颜色①可以读取到右侧当前颜色，
调整下面RGB轨道③或通过工具左键读取颜色可以调整当前颜色，
在第5页点击颜色下面的set②可以设置颜色。
④：在贴花工具中右侧颜色栏拉到最下面是自定义颜色栏

                ]],
                "8-选择工具",
                [[#fcfcfc选择工具，上色、删除、移动、旋转、镜像的操作
均会对被选中的贴花操作。

#00ffbc左键#fcfcfc：选择贴花，
靠近要选择的贴花会出现箭头标记所选住的贴花（该贴花会浮起），
再按左键就能将贴花框选住了。对已选的贴花再点击就是取消选择，
靠近被选择的贴花选择框会变红色。

#00ffbc右键#fcfcfc：按住右键能拖动选择框，
松开后会将选择框内所有的贴花都添加到选择中，
已被选择的会被取消选择。

#00ffbcQ键#fcfcfc：清空选择
                ]],
                "9-浮空选择",
                [[
#00ffbcR键#fcfcfc：开启浮空选择
由于贴花本身无碰撞，原射线是无法勾选上浮空的贴花的
而开启浮空选择，将能勾选浮空的贴花
同时也是为了部件虚化的勾选
                ]],
                "10-编辑工具[复制]",
                [[#fcfcfc#00ffbc右键#fcfcfc：复制所选贴花

#00ffbcQ键#fcfcfc：编辑贴花颜色、拉升、图层、发光。
                ]],
                "11-编辑工具[黏贴]",
                [[#fcfcfc复制完直接左键能黏贴
如果做其他事之后想重新召回复制继续黏贴
可在保存的贴花中选择MaxCopy_079685746352413来调出复制的贴花
                ]],
                "12-编辑工具[保存]",
                [[#fcfcfc按#00ffbcR键#fcfcfc开启
操作对象在未选择贴花时默认全体贴花，否则为选择的贴花
具体保存类型、原理和运用在“14-16自定义贴画”中展开
                ]],
                "13-镜像工具",
                [[#fcfcfc#00ffbc左键#fcfcfc：
按住左键拖动，红色为镜像面所在中点，面的法向为拉伸的始末向量
即镜像面为始末线段的中垂面

#00ffbc右键#fcfcfc：
镜像翻转所选贴花
没有选择贴花时翻转所有贴花

按#00ffbcQ键（旋转键）#fcfcfc
取消镜面

按#00ffbcR键（换弹键）#fcfcfc
镜像复制所选贴花，即镜像翻转后保留翻转前的贴花
没有选择贴花时翻转复制所有贴花
                ]],
                "14-移动、拉伸与旋转",
                [[#00ffbc右键#fcfcfc：
切换模式：移动、拉伸、旋转

#00ffbc左键#fcfcfc：
（在无选择贴花下，直接点击贴花即可操作）
移动：按住左键拖动，拖动所选贴花
旋转：按住时拖动一定距离后再往其他方向旋转
    可以旋转所选贴花
拉伸：按住左键拖动，放缩所选贴花

#00ffbcQ#fcfcfc：
切换轴：无、x、y、z、xy、yz、xz

#00ffbcR#fcfcfc：
切换轴相对：相对装置or相对所选贴花
（相对贴花仅适用于单一所选对象）

                ]],
                "15-部件转换贴花",
                [[#00ffbc左键#fcfcfc：
转换部件为贴花

#00ffbc右键#fcfcfc：
删除已经转化为贴花的部件（一次删除全部已转化的）
                ]],
                "16-流程控制（撤销、重做）",
                [[#00ffbc Q #fcfcfc：
撤销上次的操作

#00ffbc R #fcfcfc：
重做（取消上次的撤销）
                ]],
                "17-贴花控制（控制台）",
                [[#fcfcfc对贴花进行具体数值控制
1：取消选择
2：选择贴花
3：编辑贴花数据（仅会接受可修改的内容）
        可修改的内容包括：id（正数是贴花编号，负数是已经转为贴花的部件的编号），
        state（控制是否发光，普通是origin，发光是glow），color，
        position，rotation，scale
4：隐藏贴花（隐藏贴花不会删除贴花）
        隐藏已被选择的贴花时会将被选择的贴花全部隐藏
        隐藏后正常编辑是无法被选择的，只有控制台显示或者将贴花装置关闭重启才会显示
5：批量选择
        将左侧数字区间内的贴花都勾选上，如1-33就是将列表中1-33都选上
                ]],
                "18-自定义贴花①",
                [[#fcfcfc保存贴花组合为自定义贴花，
相当于可以直接黏贴一系列贴花组合
所保存的自定义贴花不保留其相对装置的坐标与旋转
而是会重新计算中心和旋转，
以便于直接当作一个新的贴花造型使用

选择要保存的贴花
（没选择默认全选）
然后用#00ffbc贴花编辑工具#fcfcfc的#00ffbcR键#fcfcfc打开自定义贴花面板
选择#00ffbc自定义贴花#fcfcfc
输入名称并按保存

保存后会生成一个自定义贴花备份装置，
详见“-21- 自定义贴花④贴花备份”
                ]],
                "19-自定义贴花②",
                [[#fcfcfc自定义贴花的使用

手持MAG贴花工具
按#00ffbcR键（换弹键）#fcfcfc
选“Saved保存的图”，然后退出贴画选择界面，
再#00ffbc左键#fcfcfc出现“MAC File”的选择界面
选择所保存的自定义贴花即可

默认里保存的是我做的一部分自定义贴画
                ]],
                "20-自定义贴花③",
                [[#fcfcfc保存作品整体贴花
即保留贴花相对装置的坐标和旋转
这可以使用在不同作品同一型号、或者一系列相同的地方

选择贴花（没选择那么认为全选）
保存时选择作品整体贴花
按保存

而读取时直接在#00ffbc自定义贴花面板#fcfcfc中
右上角列表选择所要读取的贴花
按左下角open
                ]],
                "21-自定义贴花④",
                [[#fcfcfc自定义贴画的备份

由于游戏限制，所保存的贴花文件只能保存在模组文件夹里
而每次更新会把负责保存贴花文件的文件夹还原
因此这个贴花备份装置会利用内部储存保存所有贴花

每次保存时会自动生成一个，保存到蓝图即可
从蓝图取出时会自动检测游戏文件和内部储存的差异
并将缺失的贴花文件补充生成。

直接从部件栏中找到它并搭建出来也是会自动备份的
然后就能将其保存到蓝图中。
                ]]
            },


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


            English = {
                "check custom applique device tutorial",
                "1-Custom Applique Device",
                "tutorial: https://www.bilibili.com/video/BV14M4m127RG/ \n attach applique!!\n\n\n Tips:#00ffbcE#fcfcfc to turn off GUIinterface\nMod_Feedback_QQChat:630586951",
                "2-Activate",
                [[#fcfcfcA non-red input can activate the device
It can only be activated by the nearest player
Maximum applique amount is 270
Turning off the device can save
It can also delete overlapping applique
Appliques will be shown whether it's on or not
#ff2222-1. You can fix the bugged-invisible applique by turning off and on again
-2. If you find yourself unable to edit any applique 
    and turning off the switch won't send data to server
    you may press #00ffbcE#ff2222 to save the data
                ]],
                "3-Mechanism",
                [[#fcfcfcAppliques' motion are attached to the device
Just like those shown in the picture
                ]],
                "4-Place&Del",
                [[#fcfcfcUsing MAG tool
#00ffbcLeft Button#fcfcfc: place applique
drag and rotate while holding the button can rotate the applique

#00ffbcRight Button#fcfcfc: holding to activate Delete_Mode
In this case, when the cross is near the applique 
will show an arrow to point out the aimed applique
then press #00ffbcLeft Button#fcfcfc can delete it
Selected appliques will be deleted as a whole
(know more in SelectTool)
                ]],
                "5-R-Applique",
                [[#fcfcfcSelect Applique
Using MAG tool
Press #00ffbcR (reload)#fcfcfc
(1)(2)select type
(3)choose applique
"Saved保存的图"is the type of customized applique
(know more in CustomAplq)
                ]],
                "6-Q-Edit",
                [[#fcfcfcEdit applique's size,color,rotation,glow,mirror
Using MAG tool
Press #00ffbcQ (toggle)#fcfcfc
(1)vertical stretch
(2)horizonal stretch
(3)layer
(4)rotation
(5)color plate of 10 color
(6)color plate's scrollbar
(7)reset (scale and rotation)
(8)mirror(can also be used to mirror custom_applique)
(9)glow
(10)normal lock(lock rotation)
(11)align accuracy
                ]],
                "7-Color",
                [[#fcfcfcUsing MAG Color reader
#00ffbcLeftButton#fcfcfc:
Read color and save it in the color editor as Current_Color
(which is the color shown on the right)

#00ffbcRight Button#fcfcfc:
Holding can activate Color_Mode
Just as the Delete_Mode, Left click can re-color applique

#00ffbcQ(toggle)#fcfcfc
Turning on the color editor
which gives 5 colorplate containing 50 color
40 are the original color
the last 10 are custom color
(1)read color - click to read color
(2)set color as Current_Color
(3)RGB slider or the tool can change Current_Color
(4)the last color plate (5th) is the custom colors
                ]],
                "8-Selector",
                [[#fcfcfcSelect Tool

#00ffbcLeft Button#fcfcfc: select applique
applique pointed will be selected
click on a selected applique will cancel its selection
aiming a selected applique will make the select box red

#00ffbcRight Button#fcfcfc:drag selecting box
a dragable select box

#00ffbcQ#fcfcfc: clear selction
                ]],
                "9-floating selecting",
                [[
#00ffbcR#fcfcfc: select floating appliques
also for converted parts' selecting
                ]],
                "10-Editor[Copy]",
                [[#fcfcfc#00ffbcRight Button#fcfcfc:copy selected applique

#00ffbcQ#fcfcfc:edit copied applique's status
                ]],
                "11-Editor[Past]",
                [[#fcfcfcLeft Button can paste copied applique
If you want to recall and paste the copied applique
after you do something else and you loss the copied applique,
You can recall it in the "Saved保存的图" 
and choose"MaxCopy_079685746352413"
                ]],
                "12-Editor[Save]",
                [[#00ffbcR#fcfcfc:open Save_GUI
process selected applique(default to all applique)
More to know in 14-17Custom Applique
                ]],
                "13-Mirror",
                [[#00ffbcLeft Button#fcfcfc:
holding left button and drag
the red block is the middle point of the mirror
mirror's facing is the vector of your draging

#00ffbcRight Button#fcfcfc:
Mirror flip selected applique
default to all

#00ffbcQ#fcfcfc
Cancel Mirror

#00ffbcR#fcfcfc
Mirror and copy (which means keeping the origin applique)
                ]],
                "14-Mover",
                [[#fcfcfc#00ffbcLeft Button#fcfcfc:
Drag selected appliques

#00ffbcRight Button#fcfcfc:
Drag and rotate
                ]],
                "15-convertor",
                [[#00ffbcLeft Button#fcfcfc:
Convert part to applique

#00ffbcRight Button#fcfcfc:
Delete parts that have been converted]],
                "16-step control",
                [[#00ffbc Q #fcfcfc:
Undo

#00ffbc R #fcfcfc:
Redo]],
                "17-control panel",
                [[#fcfcfc
1: cancel selection
2: select applique
3: edit applique's data
        including: id,
        state("origin"->dont glow;"glow"->glow), color,
        position, rotation, scale
4: hide applique
        hide applique that is selected
5:multiSelect
        selecting all the appliques that are in the range
]],
                "18-Custom Aplq 1",
                [[#fcfcfcSaving selected appliques as a customized applique
which can be used in the last type of applique called "saved保存的图"
the saving process will recalculate center point
(select nothing = all)

#00ffbcEditor#fcfcfc's#00ffbcR button#fcfcfccan open the Custom Aplq GUI
Select#00ffbcCustom#fcfcfc
type its name and press "save"

There will generate a back up device
More in "Chapter 21"
                ]],
                "19-Custom Aplq 2",
                [[#fcfcfcHow to use

"MAG tool"
Press #00ffbcR#fcfcfc
Choose "Saved保存的图" and close GUI
Then press#00ffbcLeft Button#fcfcfc which will show a MAC File GUI
from there you can choose your Custom Applique
                ]],
                "20-Custom Aplq 3",
                [[#fcfcfcSaving all appliques that are contained in this devise,
the position and the rotation will be reserved

default to all
Select#00ffbcCreation#fcfcfc
type its name and press "save"

You can load Creation Applique by:
choose and press "open" in the CustomAplq GUI
                ]],
                "21-Custom Aplq 4",
                [[#fcfcfcBack Up
Due to game limits, files can only be saved in the mod files
which will be cleaned everytime it update
That is why this backup device can save CustomAplq in its memory

Everytime you save will generate a backup device
When you call it from your blueprint,
it'll check and fix your files automatically

You can also build it from Parts and save it as a blueprint
]]
            }
        },
        Mtools = {
            Chinese = {
                deviceOn = "无贴花装置启动",
                GunLc = "放置/删除贴花",
                GunRc = "删除模式",
                GunQ = "编辑旋转、大小、颜色",
                GunR = "设置贴花类型",
                GunWarning = "#fc1010不在同一body，贴花不会跟随所瞄准的部件",
                GunDes = [[
    #fcfcfc
    MAG处理工具

    #00ffbc左键#fcfcfc放置贴花
    #00ffbc按住右键#fcfcfc时为删除模式
        此时再#00ffbc左键#fcfcfc可以删除贴花
    #00ffbcR#fcfcfc 切换贴花
    #00ffbcQ#fcfcfc 设置旋转、大小和颜色
                ]],
                PaintLc = "读取颜色/上色",
                PaintRc = "上色模式",
                PaintQ = "设置颜色",
                PaintDes = [[
    #fcfcfc
    MAG颜色工具

    #00ffbc左键#fcfcfc添加颜色
    #00ffbc按住右键#fcfcfc时为上色模式
    #00ffbcQ#fcfcfc 设置颜色
                ]],
                SelectorLc = "选择贴花",
                SelectorRc = "框取选择",
                SelectorQ = "取消选择",
                SelectorR = "切换浮空选择模式",
                SelectorState = {"关","开"},
                SelectorDes = [[
    #fcfcfc
    MAG选择工具

    #00ffbc左键#fcfcfc选择贴花
    #00ffbc右键#fcfcfc框取选择
    #00ffbcQ#fcfcfc 取消选择
                ]],
                EditorLc = "黏贴",
                EditorRc = "复制所选贴花",
                EditorQ = "编辑旋转、大小、颜色",
                EditorR = "保存所选贴花为自定义贴花",
                EditorDes = [[
    #fcfcfc
    MAG编辑工具

    #00ffbc左键#fcfcfc黏贴
    #00ffbc右键#fcfcfc复制所选贴花
    #00ffbcR#fcfcfc 保存所选贴花为自定义贴花
    #00ffbcQ#fcfcfc 编辑旋转、大小、颜色
    可在保存的贴花中选择MaxCopy_079685746352413来调出复制的贴花
                ]],
                MirrorLc = "设置镜像面",
                MirrorRc = "对称所选贴花",
                MirrorQ = "取消",
                MirrorR = "黏贴镜像的所选贴花",
                MirrorDes = [[
    #fcfcfc
    MAG镜像工具

    #00ffbc左键#fcfcfc设置镜像面
    #00ffbc右键#fcfcfc对称所选贴花
    #00ffbcR#fcfcfc 取消
    #00ffbcQ#fcfcfc 黏贴镜像的所选贴花
                ]],
                MoverLc = "贴花",
                MoverMode0 = "移动",
                MoverMode1 = "旋转",
                MoverMode2 = "缩放",
                MoverRc = "切换模式",
                MoverQ = "切换轴/面",
                MoverR = "启用相对模式",
                MoverDes = [[
    #fcfcfc
    MAG镜像工具

    #00ffbc左键#fcfcfc移动贴花
    #00ffbc右键#fcfcfc旋转贴花
    #00ffbcR#fcfcfc -
    #00ffbcQ#fcfcfc -
                ]],
                ConvertorLc = "转化部件",
                ConvertorRc = "删除已转化部件",
                ConvertorQ = "-",
                ConvertorR = "-",
                ConvertorDes = [[
    #fcfcfc
    MAG部件转化工具
    将部件转化为贴花，无碰撞但可以任意移动旋转拉伸

    #00ffbc左键#fcfcfc转化部件
    #00ffbc右键#fcfcfc-
    #00ffbcR#fcfcfc -
    #00ffbcQ#fcfcfc -
                ]],
                StepLc = "打开列表",
                StepRc = "-",
                StepQ = "撤销",
                StepR = "恢复",
                StepDes = [[
    #fcfcfc
    MAG步骤操控

    #00ffbc左键#fcfcfc-
    #00ffbc右键#fcfcfc-
    #00ffbcR#fcfcfc 回退
    #00ffbcQ#fcfcfc 恢复
                ]]
            },
            English = {
                deviceOn = "No applique device is on",
                GunLc = "place/erase applique",
                GunRc = "erase mode",
                GunQ = "edit rotation,scale,color",
                GunR = "set shape",
                GunWarning = "#fc1010not on the same body",
                GunDes = [[
    #fcfcfc
    MAG's operator tool!!

    #00ffbcleft click#fcfcfc to put on applique
    #00ffbcholding right click#fcfcfc is erase mode
        then #00ffbcleft click#fcfcfc to delete applique
    #00ffbcR#fcfcfc to switch applique
    #00ffbcQ#fcfcfc to set its rotation, scale and color
                ]],
                PaintLc = "scan/paint color",
                PaintRc = "paint mode",
                PaintQ = "set color",
                PaintDes = [[
    #fcfcfc
    MAG's paint tool!!

    #00ffbcleft click#fcfcfc to add color
    #00ffbcQ#fcfcfc to set its rotation, scale and color
                ]],
                SelectorLc = "select applique",
                SelectorRc = "select applique",
                SelectorQ = "cancel selection",
                SelectorR = "switch to floating selection mode",
                SelectorState = {"off","on"},
                SelectorDes = [[
    #fcfcfc
    MAG select tool

    #00ffbcleft click #fcfcfcselect applique
    #00ffbcright click #fcfcfcselect applique
    #00ffbcQ#fcfcfc #00ffbcQ#fcfcfc edit rotation,scale,color
                ]],
                EditorLc = "Paste",
                EditorRc = "Copy",
                EditorQ = "edit rotation,scale,color",
                EditorR = "save selected as custom_applique",
                EditorDes = [[
    #fcfcfc
    MAG editor

    #00ffbcLeft #fcfcfcto paste
    #00ffbcRight #fcfcfcto copy
    #00ffbcR#fcfcfc save selected as custom_applique
    #00ffbcQ#fcfcfc edit rotation,scale,color
    copied appliques are saved in the file "MaxCopy_079685746352413"
                ]],
                MirrorLc = "Set mirror plane",
                MirrorRc = "Mirror selected appliques",
                MirrorQ = "Cancel",
                MirrorR = "Paste mirrored selected appliques",
                MirrorDes = [[
    #fcfcfc
    MAG mirror

    #00ffbcLeft #fcfcfcto Set mirror plane
    #00ffbcRight #fcfcfcto mirror selected appliques
    #00ffbcR#fcfcfc Cancel
    #00ffbcQ#fcfcfc Paste mirrored selected appliques
                ]],
                MoverLc = " applique",
                MoverMode0 = "move",
                MoverMode1 = "rotate",
                MoverMode2 = "scale",
                MoverRc = "next mode",
                MoverQ = "nextAxis",
                MoverR = "relativeMode",
                MoverDes = [[
    #fcfcfc
    MAG mover

    #00ffbcLeft #fcfcfcto move applique
    #00ffbcRight #fcfcfcto rotate applique
    #00ffbcR#fcfcfc -
    #00ffbcQ#fcfcfc -
                ]],
                ConvertorLc = "Convert Part",
                ConvertorRc = "Delete Converted Part",
                ConvertorQ = "-",
                ConvertorR = "-",
                ConvertorDes = [[
    #fcfcfc
    MAG convertor
    convert part to applique, no collision but can be moved,rotated,scaled

    #00ffbcLeft#fcfcfc convert part to applique
    #00ffbcRight#fcfcfc -
    #00ffbcR#fcfcfc -
    #00ffbcQ#fcfcfc -
                ]],
                StepLc = "open list",
                StepRc = "-",
                StepQ = "undo",
                StepR = "redo",
                StepDes = [[
    #fcfcfc
    MAG step controller

    #00ffbcLeft#fcfcfc -
    #00ffbcRight#fcfcfc -
    #00ffbcR#fcfcfc undo
    #00ffbcQ#fcfcfc redo
                ]]
            }
        },
        MAC = {
            Chinese = {
                "同步数据到服务端中",
                "旋转 ",
                " 大小 ",
                "MACFileSystem",
                "文件不存在！",
                "文件导入成功！",
                "警告",
                "文件已存在，是否覆盖？",
                "文件保存成功！",
                "超出极限270，请另用另一个贴花装置",
                "颜色",
                "该贴花保存于另一个模组中，无法覆盖",
                "重置",
                "镜像翻转",
                "发光",
                "法线锁定",
                "对齐精度",
                "点击颜色可读取\n点击Set可覆盖颜色",
                "Set",
                "作品整体贴花",
                "作品整体贴花\n保存作品整体贴花，\n贴花相对于装置的坐标和旋转将被保留。",
                "自定义贴花",
                "自定义贴花\n将所选贴花保存为自定义贴花组合，\n并能在“saved保存的图”这一贴花类型中调用。\n保存过程中会重新计算中心与旋转\n（未选择则是所有装置包含的贴花）",
                recovert_warning_content = "部件已转化，是否重新转化？",
                warning_delete_converted = "删除已转化部件"
            },
            English = {
                "sending data to server",
                "rotation ",
                " scaleXYZ ",
                "MAC file system",
                "File doesn't exist!",
                "File loaded successfully!",
                "WARNING",
                "File existed! Still overwrite?",
                "File saved successfully!",
                "Over the limit of 270, please use another applique device",
                "Colors",
                "File existed in another Mod that cant be saved",
                "Reset",
                "Mirror",
                "Glow",
                "normal lock",
                "align accuracy",
                "click to read color\nclick the Set button to set the color",
                "Set",
                "Creation",
                "Saving all appliques that are contained in this devise,\n the position and the rotation will be reserved",
                "Custom",
                "Saving selected appliques as a customized applique\nwhich can be used in the last type of applique called \"saved保存的图\"\nthe saving process will recalculate center point\n(select nothing = all)",
                recovert_warning_content = "Have converted this part, re-convert?",
                warning_delete_converted = "Delete converted part?"
            }
        },
        CBK = {
            Chinese = {
                "用于房主备份贴花到蓝图中，下次更新后只需从蓝图取出就能恢复"
            },
            English = {
                "Appliques back up , reload your saved appliques when it is created from blueprint"
            }
        },
        UpdateContent = {
            Chinese = {
                Title = "徽标实验室  更新通知",
                Content = [[    v0.3.9
        模组反馈群QQ群号：630586951
        贴花变暗的bug修复了
                ]]
            },
            English = {
                Title = "Logo Lab Update Notice",
                Content = [[    v0.3.8
        Added QQ group number for feedback:630586951
        The bug of appliques becoming dark has been fixed
                ]]
            }
        }
    }
end