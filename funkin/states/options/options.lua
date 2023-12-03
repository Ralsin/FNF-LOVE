local OptionsState = State:extend("OptionsState")

local tabs = {
    Gameplay = require "funkin.states.options.gameplay",
    Graphic = require "funkin.states.options.graphic",
    Controls = require "funkin.states.options.controls"
}

function OptionsState:enter()

    -- Update Presence
    if love.system.getDevice() == "Desktop" then
        Discord.changePresence({details = "In the Menus"})
    end

    self.curTab = 1
    self.curSelect = 1
    self.controls = table.clone(ClientPrefs.controls)
    self.changingOption = false

    self.bg = Sprite()
    self.bg:loadTexture(paths.getImage('menus/menuBGBlue'))
    self.bg.color = {0.5, 0.5, 0.5}
    self.bg:screenCenter()
    self:add(self.bg)

    self.optionsTab = {
        'Gameplay',
        'Graphic',
        'Controls'
    }

    self.titleTabBG = Sprite(0, 20):make(game.width * 0.8, 65, {0, 0, 0})
    self.titleTabBG.alpha = 0.7
    self.titleTabBG:screenCenter('x')
    self:add(self.titleTabBG)

    self.tabBG = Sprite(0, 105):make(game.width * 0.8, game.height * 0.75,
                                     {0, 0, 0})
    self.tabBG.alpha = 0.7
    self.tabBG:screenCenter('x')
    self:add(self.tabBG)

    self.optionsCursor = Sprite():make((game.width * 0.78), 39, {1, 1, 1})
    self.optionsCursor.alpha = 0.1
    self.optionsCursor.visible = false
    self.optionsCursor:screenCenter('x')
    self:add(self.optionsCursor)

    self.curBindSelect = 1

    self.controlsCursor = Sprite(377):make(148, 39, {1, 1, 1})
    self.controlsCursor.alpha = 0.2
    self.controlsCursor.visible = false
    self:add(self.controlsCursor)

    self.titleTxt = Text(0, 30, '', paths.getFont('phantommuff.ttf', 40),
                         {1, 1, 1}, "center", game.width)
    self:add(self.titleTxt)

    self.allTabs = Group()
    self:add(self.allTabs)

    self.textGroup = Group()
    self:add(self.textGroup)

    self.spriteGroup = Group()
    self:add(self.spriteGroup)

    self.timerHold = 0
    self.waiting_input = false
    self.block_input = false
    self.onTab = false

    self:reset_Tabs()

    self:changeTab()

    self.blackFG = Sprite():make(game.width, game.height, {0, 0, 0})
    self.blackFG.alpha = 0
    self:add(self.blackFG)

    self.waitInputTxt = Text(0, 0, 'Rebinding..',
                             paths.getFont('phantommuff.ttf', 60), {1, 1, 1},
                             "center", game.width)
    self.waitInputTxt:screenCenter('y')
    self.waitInputTxt.visible = false
    self:add(self.waitInputTxt)
end

function OptionsState:reset_Tabs()
    for _, idk in ipairs({self.allTabs, self.textGroup,
                                            self.spriteGroup}) do
        idk:clear()
    end

    for _, tab in next, self.optionsTab do
        tabs[tab].add(self)
    end

    for _, idk in ipairs({self.allTabs, self.textGroup, self.spriteGroup}) do
        for _, grp in ipairs(idk.members) do
            for _, obj in ipairs(grp.members) do
                obj.visible = (grp.name == self.optionsTab[self.curTab])
            end
        end
    end
    self.allTabs:add(controlsTab)
end

function OptionsState:update(dt)
    OptionsState.super.update(self, dt)

    if game.sound.music:getVolume() <= 0.5 then
        game.sound.music:setVolume(game.sound.music:getVolume() + 0.05)
    end

    if controls:pressed('back') then
        game.sound.play(paths.getSound('cancelMenu'))
        if self.waiting_input then
            self.waiting_input = false
            self.blackFG.alpha = 0
            self.waitInputTxt.visible = false
        elseif self.onTab then
            if self.changingOption then
                if self.optionsTab[self.curTab] == 'Gameplay' or
                    self.optionsTab[self.curTab] == 'Graphic' then
                    tabs[self.optionsTab[self.curTab]].selectOption(self.curSelect)
                    self:reset_Tabs()
                    self.changingOption = false
                end
            else
                self.onTab = false
                self.titleTxt.content = '< ' .. self.optionsTab[self.curTab] .. ' >'
                self.optionsCursor.visible = false
                self.controlsCursor.visible =
                    (self.optionsTab[self.curTab] == 'Controls' and false)
            end
        else
            game.switchState(MainMenuState())
        end
    end

    if not self.waiting_input then
        if not self.onTab then
            if controls:pressed('ui_left') then
                self:changeTab(-1)
            elseif controls:pressed('ui_right') then
                self:changeTab(1)
            end

            if Keyboard.justPressed.ENTER then
                self.onTab = true
                self.titleTxt.content = self.optionsTab[self.curTab]
                self.curSelect = 1
                self:changeSelection(nil, self.allTabs.members[self.curTab])
                self.optionsCursor.visible = true

                if self.optionsTab[self.curTab] == 'Controls' then
                    self.controlsCursor.visible = true
                end
            end
        else
            local selectedTab = self.optionsTab[self.curTab]

            if Keyboard.justPressed.ENTER then
                if selectedTab == 'Controls' then
                    if not self.waiting_input then
                        self.waiting_input = true
                        self.blackFG.alpha = 0.5
                        self.waitInputTxt.visible = true
                    end
                elseif selectedTab == 'Gameplay' or
                        selectedTab == 'Graphic' then
                    if not self.changingOption then
                        tabs[selectedTab].selectOption(self.curSelect, true)
                        self:reset_Tabs()
                        self.changingOption = true
                    end
                end
            end
            if controls:pressed('ui_left') then
                if self.optionsTab[self.curTab] == 'Controls' then
                    self:changeBindSelection(-1)
                end
                if self.changingOption then
                    if self.optionsTab[self.curTab] == 'Gameplay' or
                        self.optionsTab[self.curTab] == 'Graphic' then
                        tabs[selectedTab].changeSelection(-1)
                        self:reset_Tabs()

                        if selectedTab == 'Graphic' then
                            self.bg = ClientPrefs.data.antialiasing
                        end
                    end
                end
                self.timerHold = 0
            end
            if controls:pressed('ui_right') then
                if self.optionsTab[self.curTab] == 'Controls' then
                    self:changeBindSelection(1)
                end
                if self.changingOption then
                    if self.optionsTab[self.curTab] == 'Gameplay' or
                        self.optionsTab[self.curTab] == 'Graphic' then
                        tabs[selectedTab].changeSelection(1)
                        self:reset_Tabs()

                        if selectedTab == 'Graphic' then
                            self.bg = ClientPrefs.data.antialiasing
                        end
                    end
                end
                self.timerHold = 0
            end
            if controls:down('ui_left') or controls:down('ui_right') then
                self.timerHold = self.timerHold + dt
                if self.timerHold > 0.5 then
                    self.timerHold = 0.45
                    if self.changingOption then
                        if self.optionsTab[self.curTab] == 'Gameplay' or
                            self.optionsTab[self.curTab] == 'Graphic' then
                            tabs[selectedTab].changeSelection((controls:down('ui_left')
                                                                and -1 or 1))
                            self:reset_Tabs()

                            if selectedTab == 'Graphic' then
                                self.bg = ClientPrefs.data.antialiasing
                            end
                        end
                    end
                end
            end
            if not self.changingOption then
                if controls:pressed('ui_up') then
                    self:changeSelection(-1, self.allTabs.members[self.curTab])
                    self.timerHold = 0
                elseif controls:pressed('ui_down') then
                    self:changeSelection(1, self.allTabs.members[self.curTab])
                    self.timerHold = 0
                end
                if controls:down('ui_up') or controls:down('ui_down') then
                    self.timerHold = self.timerHold + dt
                    if self.timerHold > 0.5 then
                        self.timerHold = 0.4
                        self:changeSelection((controls:down('ui_up') and -1 or 1),
                                             self.allTabs.members[self.curTab])
                    end
                end
            end
        end
    elseif Keyboard.input and self.waiting_input and not self.block_input then
        game.sound.play(paths.getSound('confirmMenu'))
        self.block_input = true

        local arrow = {
            'note_left', 'note_down', 'note_up', 'note_right', 'ui_left',
            'ui_down', 'ui_up', 'ui_right', 'accept', 'back', 'pause'
        }
        local text = arrow[self.curSelect]

        local newBind = 'key:' .. Keyboard.input:lower()
        self.controls[text][self.curBindSelect] = newBind

        self:reset_Tabs()

        self.waitInputTxt.content = 'Configuring..\nPlease Wait'
        Timer.after(1, function()
            self.block_input = false
            self.waiting_input = false
            self.blackFG.alpha = 0
            self.waitInputTxt.visible = false
            self.waitInputTxt.content = 'Rebinding..'

            ClientPrefs.controls = table.clone(self.controls)
            controls = (require "lib.baton").new({
                controls = table.clone(self.controls)
            })
        end)
    end
end

function OptionsState:changeBindSelection(huh)
    huh = huh or 0

    game.sound.play(paths.getSound('scrollMenu'))
    self.curBindSelect = self.curBindSelect + huh
    if self.curBindSelect > 2 then
        self.curBindSelect = 1
    elseif self.curBindSelect < 1 then
        self.curBindSelect = 2
    end

    self.controlsCursor.x = (self.curBindSelect == 1 and 382 or
                                self.curBindSelect == 2 and 542) - 5
end

function OptionsState:changeSelection(huh, tab)
    huh = huh or 0

    game.sound.play(paths.getSound('scrollMenu'))
    self.curSelect = self.curSelect + huh
    if self.curSelect > #tab.members then
        self.curSelect = 1
    elseif self.curSelect < 1 then
        self.curSelect = #tab.members
    end

    local yPos = tab.members[self.curSelect].members[1].y - 2
    self.optionsCursor.y = yPos
    if self.optionsTab[self.curTab] == 'Controls' then
        self.controlsCursor.y = yPos
    end
end

function OptionsState:changeTab(huh)
    huh = huh or 0

    game.sound.play(paths.getSound('scrollMenu'))
    self.curTab = self.curTab + huh
    if self.curTab > #self.optionsTab then
        self.curTab = 1
    elseif self.curTab < 1 then
        self.curTab = #self.optionsTab
    end

    self.titleTxt.content = '< ' .. self.optionsTab[self.curTab] .. ' >'

    for _, idk in ipairs({self.allTabs, self.textGroup, self.spriteGroup}) do
        for _, grp in ipairs(idk.members) do
            for _, obj in ipairs(grp.members) do
                obj.visible = (grp.name == self.optionsTab[self.curTab])
            end
        end
    end
end

return OptionsState
