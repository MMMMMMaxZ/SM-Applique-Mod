-- MAXZ666 --
-- Max's applique creator tutorial!
MACT = class(nil)

dofile("$MOD_DATA/Scripts/crystalTech/_dofile.lua")

function MACT.client_onCreate(self)
end

function MACT.client_onInteract(self,character,state)
	if state then
        local maxPage = #MTt.book.titles
		self.gui = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/MAGtutorial_V2.layout')
        self.gui:createDropDown("DropDown","cl_onDropDownInteract",MTt.book.titles)
        self.gui:setButtonCallback("TypeButtonUp","cl_onUpMAC")
        self.gui:setButtonCallback("TypeButtonDown","cl_onDownMAC")
        self.gui:createVerticalSlider("ScrollDown",MTt.book.contentLen-9,(MTt.book.contentLen-9) - (MTt.book.contentIdx-1) - 1,"client_onSliderChangeContent")
        for i=1,10 do
            self.gui:setButtonCallback("TypeButton"..tostring(i),"cl_setPage")
        end
        self:refreshPage()
        self.gui:setOnCloseCallback("client_onClose")
		self.gui:open()
	end
end

function MACT.findPage(self , title)
    return MTt.book.titlePage[title]
end

function MACT.cl_setPage(self,button)
    local buttonId = tonumber(button:match("(%d+)"))
    MTt.book.page = MTt.book.contentIdx + buttonId - 1
    self:refreshPage()
end


function MACT.client_onSliderChangeContent(self,sliderPos)
    MTt.book.contentIdx = (MTt.book.contentLen-9) - (sliderPos+1) + 1
    self:refreshPage()
end

function MACT.refreshPage(self)
    self.gui:setText("Title",MTt.book.titles[MTt.book.page])
    self.gui:setText("TextBox",MTt.book.scripts[MTt.book.page])
    self.gui:setSelectedDropDownItem("DropDown", MTt.book.titles[MTt.book.page])
    self.gui:setImage("ImageBox","$MOD_DATA/Gui/Layouts/MACT3/"..MTt.book.images[MTt.book.page])

    self.gui:setSliderPosition("ScrollDown",(MTt.book.contentLen-9) - (MTt.book.contentIdx-1) - 1)
    for i=1,10 do
        self.gui:setText("TypeButton"..tostring(i),MTt.book.titles[MTt.book.contentIdx+i-1])
        self.gui:setButtonState("TypeButton"..tostring(i),false)
        self.gui:setIconImage("TypeI"..tostring(i),sm.uuid.new(MTt.book.titlesImage[MTt.book.contentIdx+i-1]))
    end
    self.gui:setButtonState("TypeButton"..tostring(MTt.book.page-MTt.book.contentIdx+1),true)
end

function MACT.cl_locatePage(self)
    if MTt.book.page < MTt.book.contentIdx then
        MTt.book.contentIdx = MTt.book.page
    elseif MTt.book.page > MTt.book.contentIdx+9 then
        MTt.book.contentIdx = MTt.book.page - 9
    end
end

function MACT.cl_onDropDownInteract(self,DDname)
    MTt.book.page = self:findPage(DDname)
    self:cl_locatePage()
    self:refreshPage()
end

function MACT.cl_onUpMAC(self,button)
    if MTt.book.page <= 1 then return end
    MTt.book.page = MTt.book.page - 1
    self:cl_locatePage()
    self:refreshPage()
end

function MACT.cl_onDownMAC(self,button)
    if MTt.book.page >= MTt.book.contentLen then return end
    MTt.book.page = MTt.book.page + 1
    self:cl_locatePage()
    self:refreshPage()
end

function MACT.client_onClose(self)
    if self.gui then
        self.gui:close()
        self.gui:destroy()
        self.gui = nil
    end
end

function MACT.client_canInteract(self)
	sm.gui.setInteractionText("",sm.gui.getKeyBinding("Use",true),MLines.lines["Mtutorial"][MLines.currentLanguage][1],"")
	return true
end