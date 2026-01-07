local library = {}

local coregui = game:GetService("CoreGui")
local userinputservice = game:GetService("UserInputService")
local runservice = game:GetService("RunService")
local tweenservice = game:GetService("TweenService")

local colors = {
    main_bg = Color3.fromRGB(17, 17, 17),
    secondary_bg = Color3.fromRGB(22, 22, 22),
    tab_bg = Color3.fromRGB(12, 12, 12),
    accent = Color3.fromRGB(140, 200, 50),
    border = Color3.fromRGB(50, 50, 50),
    hover = Color3.fromRGB(25, 25, 25),
    text = Color3.fromRGB(200, 200, 200),
    text_dark = Color3.fromRGB(150, 150, 150),
    disabled = Color3.fromRGB(80, 80, 80),
}

local screen_gui
local menu_open = true
local menu_keybind = Enum.KeyCode.Insert

local function create_screen_gui()
    if screen_gui then
        screen_gui:Destroy()
    end
    
    screen_gui = Instance.new("ScreenGui")
    screen_gui.Name = "skeet_ui_" .. tostring(math.random(1000, 9999))
    screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen_gui.ResetOnSpawn = false
    screen_gui.Parent = coregui
    
    return screen_gui
end

local function create_outline(parent, color)
    local outline = Instance.new("Frame")
    outline.Name = "outline"
    outline.Size = UDim2.new(1, 2, 1, 2)
    outline.Position = UDim2.new(0, -1, 0, -1)
    outline.BackgroundColor3 = color or Color3.fromRGB(0, 0, 0)
    outline.BorderSizePixel = 0
    outline.ZIndex = parent.ZIndex
    outline.Parent = parent.Parent
    return outline
end

library.windows = {}
library.notifications = {}
library.keybind_list = nil
library.watermark = nil

function library:create_window(title, size)
    local window = {}
    window.title = title or "window"
    window.size = size or Vector2.new(650, 450)
    window.position = Vector2.new(100, 100)
    window.tabs = {}
    window.current_tab = nil
    
    table.insert(library.windows, window)
    
    local container = Instance.new("Frame")
    container.Name = "window"
    container.Size = UDim2.new(0, window.size.X, 0, window.size.Y)
    container.Position = UDim2.new(0, window.position.X, 0, window.position.Y)
    container.BackgroundColor3 = colors.main_bg
    container.BorderColor3 = colors.border
    container.BorderSizePixel = 1
    container.Active = true
    container.Parent = screen_gui
    window.container = container
    
    create_outline(container, Color3.fromRGB(0, 0, 0))
    
    local title_bar = Instance.new("Frame")
    title_bar.Name = "title_bar"
    title_bar.Size = UDim2.new(1, 0, 0, 24)
    title_bar.BackgroundColor3 = colors.tab_bg
    title_bar.BorderSizePixel = 0
    title_bar.Parent = container
    
    local title_label = Instance.new("TextLabel")
    title_label.Size = UDim2.new(1, -10, 1, 0)
    title_label.Position = UDim2.new(0, 8, 0, 0)
    title_label.BackgroundTransparency = 1
    title_label.Text = title
    title_label.TextColor3 = colors.text
    title_label.TextSize = 12
    title_label.Font = Enum.Font.Code
    title_label.TextXAlignment = Enum.TextXAlignment.Left
    title_label.Parent = title_bar
    
    local dragging = false
    local drag_input, drag_start, start_pos
    
    title_bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            drag_start = input.Position
            start_pos = container.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    title_bar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            drag_input = input
        end
    end)
    
    userinputservice.InputChanged:Connect(function(input)
        if input == drag_input and dragging then
            local delta = input.Position - drag_start
            container.Position = UDim2.new(
                start_pos.X.Scale, start_pos.X.Offset + delta.X,
                start_pos.Y.Scale, start_pos.Y.Offset + delta.Y
            )
        end
    end)
    
    local tab_bar = Instance.new("Frame")
    tab_bar.Name = "tab_bar"
    tab_bar.Size = UDim2.new(1, 0, 0, 28)
    tab_bar.Position = UDim2.new(0, 0, 0, 24)
    tab_bar.BackgroundColor3 = colors.secondary_bg
    tab_bar.BorderSizePixel = 0
    tab_bar.Parent = container
    window.tab_bar = tab_bar
    
    local tab_layout = Instance.new("UIListLayout")
    tab_layout.FillDirection = Enum.FillDirection.Horizontal
    tab_layout.SortOrder = Enum.SortOrder.LayoutOrder
    tab_layout.Padding = UDim.new(0, 1)
    tab_layout.Parent = tab_bar
    
    local content_container = Instance.new("Frame")
    content_container.Name = "content"
    content_container.Size = UDim2.new(1, 0, 1, -52)
    content_container.Position = UDim2.new(0, 0, 0, 52)
    content_container.BackgroundColor3 = colors.main_bg
    content_container.BorderSizePixel = 0
    content_container.Parent = container
    window.content_container = content_container
    
    function window:add_tab(name)
        local tab = {}
        tab.name = name
        tab.columns = {}
        tab.active = false
        
        table.insert(window.tabs, tab)
        
        local tab_button = Instance.new("TextButton")
        tab_button.Name = "tab_" .. name
        tab_button.Size = UDim2.new(0, 90, 1, 0)
        tab_button.BackgroundColor3 = colors.secondary_bg
        tab_button.BorderSizePixel = 0
        tab_button.Text = name
        tab_button.TextColor3 = colors.text_dark
        tab_button.TextSize = 11
        tab_button.Font = Enum.Font.Code
        tab_button.AutoButtonColor = false
        tab_button.Parent = window.tab_bar
        tab.button = tab_button
        
        local tab_content = Instance.new("ScrollingFrame")
        tab_content.Name = "content_" .. name
        tab_content.Size = UDim2.new(1, -10, 1, -10)
        tab_content.Position = UDim2.new(0, 5, 0, 5)
        tab_content.BackgroundTransparency = 1
        tab_content.BorderSizePixel = 0
        tab_content.ScrollBarThickness = 2
        tab_content.ScrollBarImageColor3 = colors.border
        tab_content.CanvasSize = UDim2.new(0, 0, 0, 0)
        tab_content.Visible = false
        tab_content.Parent = window.content_container
        tab.content = tab_content
        
        local tab_layout_inner = Instance.new("UIListLayout")
        tab_layout_inner.FillDirection = Enum.FillDirection.Horizontal
        tab_layout_inner.SortOrder = Enum.SortOrder.LayoutOrder
        tab_layout_inner.Padding = UDim.new(0, 8)
        tab_layout_inner.Parent = tab_content
        
        tab_button.MouseButton1Click:Connect(function()
            for _, t in pairs(window.tabs) do
                t.content.Visible = false
                t.button.BackgroundColor3 = colors.secondary_bg
                t.button.TextColor3 = colors.text_dark
                t.active = false
            end
            tab_content.Visible = true
            tab_button.BackgroundColor3 = colors.tab_bg
            tab_button.TextColor3 = colors.text
            tab.active = true
            window.current_tab = tab
        end)
        
        tab_button.MouseEnter:Connect(function()
            if not tab.active then
                tab_button.BackgroundColor3 = colors.hover
            end
        end)
        
        tab_button.MouseLeave:Connect(function()
            if not tab.active then
                tab_button.BackgroundColor3 = colors.secondary_bg
            end
        end)
        
        if #window.tabs == 1 then
            tab_button.BackgroundColor3 = colors.tab_bg
            tab_button.TextColor3 = colors.text
            tab_content.Visible = true
            tab.active = true
            window.current_tab = tab
        end
        
        function tab:add_column()
            local column = Instance.new("Frame")
            column.Name = "column"
            column.Size = UDim2.new(0, 302, 1, 0)
            column.BackgroundTransparency = 1
            column.Parent = tab_content
            
            local column_layout = Instance.new("UIListLayout")
            column_layout.SortOrder = Enum.SortOrder.LayoutOrder
            column_layout.Padding = UDim.new(0, 8)
            column_layout.Parent = column
            
            table.insert(tab.columns, column)
            return column
        end
        
        function tab:add_groupbox(column, name)
            local groupbox = {}
            groupbox.name = name
            groupbox.height = 0
            
            local group_frame = Instance.new("Frame")
            group_frame.Name = "groupbox"
            group_frame.Size = UDim2.new(1, 0, 0, 200)
            group_frame.BackgroundColor3 = colors.secondary_bg
            group_frame.BorderColor3 = colors.border
            group_frame.BorderSizePixel = 1
            group_frame.Parent = column
            groupbox.frame = group_frame
            
            create_outline(group_frame, Color3.fromRGB(0, 0, 0))
            
            local title_label = Instance.new("TextLabel")
            title_label.Size = UDim2.new(1, -10, 0, 18)
            title_label.Position = UDim2.new(0, 5, 0, 3)
            title_label.BackgroundTransparency = 1
            title_label.Text = name
            title_label.TextColor3 = colors.text
            title_label.TextSize = 11
            title_label.Font = Enum.Font.Code
            title_label.TextXAlignment = Enum.TextXAlignment.Left
            title_label.Parent = group_frame
            
            local content_frame = Instance.new("Frame")
            content_frame.Name = "content"
            content_frame.Size = UDim2.new(1, -10, 1, -25)
            content_frame.Position = UDim2.new(0, 5, 0, 22)
            content_frame.BackgroundTransparency = 1
            content_frame.Parent = group_frame
            groupbox.content = content_frame
            
            local content_layout = Instance.new("UIListLayout")
            content_layout.SortOrder = Enum.SortOrder.LayoutOrder
            content_layout.Padding = UDim.new(0, 4)
            content_layout.Parent = content_frame
            
            content_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                groupbox.height = content_layout.AbsoluteContentSize.Y + 30
                group_frame.Size = UDim2.new(1, 0, 0, groupbox.height)
            end)
            
            function groupbox:add_button(text, callback)
                local button_frame = Instance.new("Frame")
                button_frame.Size = UDim2.new(1, 0, 0, 20)
                button_frame.BackgroundColor3 = colors.tab_bg
                button_frame.BorderColor3 = colors.border
                button_frame.BorderSizePixel = 1
                button_frame.Parent = content_frame
                
                create_outline(button_frame, Color3.fromRGB(0, 0, 0))
                
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, 0, 1, 0)
                button.BackgroundTransparency = 1
                button.Text = text
                button.TextColor3 = colors.text
                button.TextSize = 11
                button.Font = Enum.Font.Code
                button.AutoButtonColor = false
                button.Parent = button_frame
                
                button.MouseButton1Click:Connect(function()
                    button_frame.BackgroundColor3 = colors.accent
                    button.TextColor3 = Color3.fromRGB(0, 0, 0)
                    task.wait(0.1)
                    button_frame.BackgroundColor3 = colors.tab_bg
                    button.TextColor3 = colors.text
                    if callback then
                        task.spawn(callback)
                    end
                end)
                
                button.MouseEnter:Connect(function()
                    button_frame.BackgroundColor3 = colors.hover
                end)
                
                button.MouseLeave:Connect(function()
                    button_frame.BackgroundColor3 = colors.tab_bg
                end)
                
                return button
            end
            
            function groupbox:add_checkbox(text, default, callback)
                local checkbox = {value = default or false}
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 16)
                frame.BackgroundTransparency = 1
                frame.Parent = content_frame
                
                local check_box = Instance.new("Frame")
                check_box.Size = UDim2.new(0, 12, 0, 12)
                check_box.Position = UDim2.new(0, 0, 0, 2)
                check_box.BackgroundColor3 = colors.tab_bg
                check_box.BorderColor3 = colors.border
                check_box.BorderSizePixel = 1
                check_box.Parent = frame
                
                create_outline(check_box, Color3.fromRGB(0, 0, 0))
                
                local check_mark = Instance.new("TextLabel")
                check_mark.Size = UDim2.new(1, 0, 1, 0)
                check_mark.BackgroundTransparency = 1
                check_mark.Text = checkbox.value and "✓" or ""
                check_mark.TextColor3 = colors.accent
                check_mark.TextSize = 14
                check_mark.Font = Enum.Font.Code
                check_mark.Parent = check_box
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -18, 1, 0)
                label.Position = UDim2.new(0, 18, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = colors.text
                label.TextSize = 11
                label.Font = Enum.Font.Code
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = frame
                
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, 0, 1, 0)
                button.BackgroundTransparency = 1
                button.Text = ""
                button.Parent = frame
                
                button.MouseButton1Click:Connect(function()
                    checkbox.value = not checkbox.value
                    check_mark.Text = checkbox.value and "✓" or ""
                    if callback then
                        task.spawn(callback, checkbox.value)
                    end
                end)
                
                button.MouseEnter:Connect(function()
                    check_box.BorderColor3 = colors.accent
                    label.TextColor3 = colors.accent
                end)
                
                button.MouseLeave:Connect(function()
                    check_box.BorderColor3 = colors.border
                    label.TextColor3 = colors.text
                end)
                
                function checkbox:set_value(val)
                    checkbox.value = val
                    check_mark.Text = val and "✓" or ""
                end
                
                return checkbox
            end
            
            function groupbox:add_slider(text, min, max, default, callback)
                local slider = {value = default or min, min = min, max = max}
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 28)
                frame.BackgroundTransparency = 1
                frame.Parent = content_frame
                
                local top_bar = Instance.new("Frame")
                top_bar.Size = UDim2.new(1, 0, 0, 14)
                top_bar.BackgroundTransparency = 1
                top_bar.Parent = frame
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.6, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = colors.text
                label.TextSize = 11
                label.Font = Enum.Font.Code
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = top_bar
                
                local value_label = Instance.new("TextLabel")
                value_label.Size = UDim2.new(0.4, 0, 1, 0)
                value_label.Position = UDim2.new(0.6, 0, 0, 0)
                value_label.BackgroundTransparency = 1
                value_label.Text = tostring(slider.value)
                value_label.TextColor3 = colors.text_dark
                value_label.TextSize = 11
                value_label.Font = Enum.Font.Code
                value_label.TextXAlignment = Enum.TextXAlignment.Right
                value_label.Parent = top_bar
                
                local slider_bg = Instance.new("Frame")
                slider_bg.Size = UDim2.new(1, 0, 0, 10)
                slider_bg.Position = UDim2.new(0, 0, 0, 16)
                slider_bg.BackgroundColor3 = colors.tab_bg
                slider_bg.BorderColor3 = colors.border
                slider_bg.BorderSizePixel = 1
                slider_bg.Parent = frame
                
                create_outline(slider_bg, Color3.fromRGB(0, 0, 0))
                
                local slider_fill = Instance.new("Frame")
                slider_fill.Size = UDim2.new((slider.value - min) / (max - min), 0, 1, 0)
                slider_fill.BackgroundColor3 = colors.accent
                slider_fill.BorderSizePixel = 0
                slider_fill.Parent = slider_bg
                
                local sliding = false
                
                local function update_slider(input)
                    local pos = math.clamp((input.Position.X - slider_bg.AbsolutePosition.X) / slider_bg.AbsoluteSize.X, 0, 1)
                    slider.value = math.floor(min + (max - min) * pos + 0.5)
                    slider_fill.Size = UDim2.new(pos, 0, 1, 0)
                    value_label.Text = tostring(slider.value)
                    if callback then
                        task.spawn(callback, slider.value)
                    end
                end
                
                slider_bg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        update_slider(input)
                    end
                end)
                
                slider_bg.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                
                userinputservice.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        update_slider(input)
                    end
                end)
                
                slider_bg.MouseEnter:Connect(function()
                    slider_bg.BorderColor3 = colors.accent
                end)
                
                slider_bg.MouseLeave:Connect(function()
                    slider_bg.BorderColor3 = colors.border
                end)
                
                function slider:set_value(val)
                    slider.value = math.clamp(val, min, max)
                    local pos = (slider.value - min) / (max - min)
                    slider_fill.Size = UDim2.new(pos, 0, 1, 0)
                    value_label.Text = tostring(slider.value)
                end
                
                return slider
            end
            
            function groupbox:add_dropdown(text, options, callback)
                local dropdown = {value = nil, open = false}
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 18)
                frame.BackgroundTransparency = 1
                frame.ClipsDescendants = false
                frame.Parent = content_frame
                frame.ZIndex = 10
                
                local dropdown_button = Instance.new("TextButton")
                dropdown_button.Size = UDim2.new(1, 0, 1, 0)
                dropdown_button.BackgroundColor3 = colors.tab_bg
                dropdown_button.BorderColor3 = colors.border
                dropdown_button.BorderSizePixel = 1
                dropdown_button.Text = ""
                dropdown_button.AutoButtonColor = false
                dropdown_button.Parent = frame
                
                create_outline(dropdown_button, Color3.fromRGB(0, 0, 0))
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -20, 1, 0)
                label.Position = UDim2.new(0, 4, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = colors.text
                label.TextSize = 11
                label.Font = Enum.Font.Code
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.Parent = dropdown_button
                
                local value_label = Instance.new("TextLabel")
                value_label.Size = UDim2.new(0, 60, 1, 0)
                value_label.Position = UDim2.new(1, -64, 0, 0)
                value_label.BackgroundTransparency = 1
                value_label.Text = "..."
                value_label.TextColor3 = colors.text_dark
                value_label.TextSize = 11
                value_label.Font = Enum.Font.Code
                value_label.TextXAlignment = Enum.TextXAlignment.Right
                value_label.TextTruncate = Enum.TextTruncate.AtEnd
                value_label.Parent = dropdown_button
                
                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 12, 1, 0)
                arrow.Position = UDim2.new(1, -14, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▼"
                arrow.TextColor3 = colors.accent
                arrow.TextSize = 8
                arrow.Font = Enum.Font.Code
                arrow.Parent = dropdown_button
                
                local dropdown_list = Instance.new("ScrollingFrame")
                dropdown_list.Size = UDim2.new(1, 0, 0, math.min(#options * 20 + 4, 120))
                dropdown_list.Position = UDim2.new(0, 0, 1, 2)
                dropdown_list.BackgroundColor3 = colors.secondary_bg
                dropdown_list.BorderColor3 = colors.border
                dropdown_list.BorderSizePixel = 1
                dropdown_list.Visible = false
                dropdown_list.ZIndex = 100
                dropdown_list.ScrollBarThickness = 2
                dropdown_list.ScrollBarImageColor3 = colors.accent
                dropdown_list.CanvasSize = UDim2.new(0, 0, 0, #options * 20)
                dropdown_list.Parent = frame
                
                create_outline(dropdown_list, Color3.fromRGB(0, 0, 0))
                
                local list_layout = Instance.new("UIListLayout")
                list_layout.SortOrder = Enum.SortOrder.LayoutOrder
                list_layout.Parent = dropdown_list
                
                dropdown_button.MouseButton1Click:Connect(function()
                    dropdown.open = not dropdown.open
                    dropdown_list.Visible = dropdown.open
                    arrow.Text = dropdown.open and "▲" or "▼"
                end)
                
                dropdown_button.MouseEnter:Connect(function()
                    dropdown_button.BackgroundColor3 = colors.hover
                    label.TextColor3 = colors.accent
                end)
                
                dropdown_button.MouseLeave:Connect(function()
                    dropdown_button.BackgroundColor3 = colors.tab_bg
                    label.TextColor3 = colors.text
                end)
                
                for _, option in ipairs(options) do
                    local option_button = Instance.new("TextButton")
                    option_button.Size = UDim2.new(1, 0, 0, 20)
                    option_button.BackgroundColor3 = colors.secondary_bg
                    option_button.BorderSizePixel = 0
                    option_button.Text = "  " .. option
                    option_button.TextColor3 = colors.text
                    option_button.TextSize = 10
                    option_button.Font = Enum.Font.Code
                    option_button.TextXAlignment = Enum.TextXAlignment.Left
                    option_button.AutoButtonColor = false
                    option_button.ZIndex = 100
                    option_button.Parent = dropdown_list
                    
                    option_button.MouseButton1Click:Connect(function()
                        dropdown.value = option
                        value_label.Text = option
                        dropdown.open = false
                        dropdown_list.Visible = false
                        arrow.Text = "▼"
                        if callback then
                            task.spawn(callback, option)
                        end
                    end)
                    
                    option_button.MouseEnter:Connect(function()
                        option_button.BackgroundColor3 = colors.hover
                        option_button.TextColor3 = colors.accent
                    end)
                    
                    option_button.MouseLeave:Connect(function()
                        option_button.BackgroundColor3 = colors.secondary_bg
                        option_button.TextColor3 = colors.text
                    end)
                end
                
                function dropdown:set_value(val)
                    dropdown.value = val
                    value_label.Text = val
                end
                
                return dropdown
            end
            
            function groupbox:add_multi_dropdown(text, options, callback)
                local multi = {selected = {}, open = false}
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 18)
                frame.BackgroundTransparency = 1
                frame.ClipsDescendants = false
                frame.Parent = content_frame
                frame.ZIndex = 10
                
                local dropdown_button = Instance.new("TextButton")
                dropdown_button.Size = UDim2.new(1, 0, 1, 0)
                dropdown_button.BackgroundColor3 = colors.tab_bg
                dropdown_button.BorderColor3 = colors.border
                dropdown_button.BorderSizePixel = 1
                dropdown_button.Text = ""
                dropdown_button.AutoButtonColor = false
                dropdown_button.Parent = frame
                
                create_outline(dropdown_button, Color3.fromRGB(0, 0, 0))
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -20, 1, 0)
                label.Position = UDim2.new(0, 4, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = colors.text
                label.TextSize = 11
                label.Font = Enum.Font.Code
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.Parent = dropdown_button
                
                local value_label = Instance.new("TextLabel")
                value_label.Size = UDim2.new(0, 60, 1, 0)
                value_label.Position = UDim2.new(1, -64, 0, 0)
                value_label.BackgroundTransparency = 1
                value_label.Text = "..."
                value_label.TextColor3 = colors.text_dark
                value_label.TextSize = 11
                value_label.Font = Enum.Font.Code
                value_label.TextXAlignment = Enum.TextXAlignment.Right
                value_label.TextTruncate = Enum.TextTruncate.AtEnd
                value_label.Parent = dropdown_button
                
                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 12, 1, 0)
                arrow.Position = UDim2.new(1, -14, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▼"
                arrow.TextColor3 = colors.accent
                arrow.TextSize = 8
                arrow.Font = Enum.Font.Code
                arrow.Parent = dropdown_button
                
                local dropdown_list = Instance.new("ScrollingFrame")
                dropdown_list.Size = UDim2.new(1, 0, 0, math.min(#options * 24 + 4, 120))
                dropdown_list.Position = UDim2.new(0, 0, 1, 2)
                dropdown_list.BackgroundColor3 = colors.secondary_bg
                dropdown_list.BorderColor3 = colors.border
                dropdown_list.BorderSizePixel = 1
                dropdown_list.Visible = false
                dropdown_list.ZIndex = 100
                dropdown_list.ScrollBarThickness = 2
                dropdown_list.ScrollBarImageColor3 = colors.accent
                dropdown_list.CanvasSize = UDim2.new(0, 0, 0, #options * 24)
                dropdown_list.Parent = frame
                
                create_outline(dropdown_list, Color3.fromRGB(0, 0, 0))
                
                local list_layout = Instance.new("UIListLayout")
                list_layout.SortOrder = Enum.SortOrder.LayoutOrder
                list_layout.Parent = dropdown_list
                
                local function update_text()
                    if #multi.selected == 0 then
                        value_label.Text = "..."
                    else
                        value_label.Text = table.concat(multi.selected, ", ")
                    end
                end
                
                dropdown_button.MouseButton1Click:Connect(function()
                    multi.open = not multi.open
                    dropdown_list.Visible = multi.open
                    arrow.Text = multi.open and "▲" or "▼"
                end)
                
                dropdown_button.MouseEnter:Connect(function()
                    dropdown_button.BackgroundColor3 = colors.hover
                    label.TextColor3 = colors.accent
                end)
                
                dropdown_button.MouseLeave:Connect(function()
                    dropdown_button.BackgroundColor3 = colors.tab_bg
                    label.TextColor3 = colors.text
                end)
                
                for _, option in ipairs(options) do
                    local option_frame = Instance.new("Frame")
                    option_frame.Size = UDim2.new(1, 0, 0, 24)
                    option_frame.BackgroundColor3 = colors.secondary_bg
                    option_frame.BorderSizePixel = 0
                    option_frame.ZIndex = 100
                    option_frame.Parent = dropdown_list
                    
                    local check_box = Instance.new("Frame")
                    check_box.Size = UDim2.new(0, 12, 0, 12)
                    check_box.Position = UDim2.new(0, 5, 0.5, -6)
                    check_box.BackgroundColor3 = colors.tab_bg
                    check_box.BorderColor3 = colors.border
                    check_box.BorderSizePixel = 1
                    check_box.ZIndex = 100
                    check_box.Parent = option_frame
                    
                    local check_mark = Instance.new("TextLabel")
                    check_mark.Size = UDim2.new(1, 0, 1, 0)
                    check_mark.BackgroundTransparency = 1
                    check_mark.Text = ""
                    check_mark.TextColor3 = colors.accent
                    check_mark.TextSize = 14
                    check_mark.Font = Enum.Font.Code
                    check_mark.ZIndex = 100
                    check_mark.Parent = check_box
                    
                    local option_label = Instance.new("TextLabel")
                    option_label.Size = UDim2.new(1, -25, 1, 0)
                    option_label.Position = UDim2.new(0, 22, 0, 0)
                    option_label.BackgroundTransparency = 1
                    option_label.Text = option
                    option_label.TextColor3 = colors.text
                    option_label.TextSize = 10
                    option_label.Font = Enum.Font.Code
                    option_label.TextXAlignment = Enum.TextXAlignment.Left
                    option_label.ZIndex = 100
                    option_label.Parent = option_frame
                    
                    local option_button = Instance.new("TextButton")
                    option_button.Size = UDim2.new(1, 0, 1, 0)
                    option_button.BackgroundTransparency = 1
                    option_button.Text = ""
                    option_button.ZIndex = 100
                    option_button.Parent = option_frame
                    
                    option_button.MouseButton1Click:Connect(function()
                        local found = false
                        for i, v in ipairs(multi.selected) do
                            if v == option then
                                table.remove(multi.selected, i)
                                found = true
                                break
                            end
                        end
                        
                        if not found then
                            table.insert(multi.selected, option)
                        end
                        
                        check_mark.Text = (not found) and "✓" or ""
                        update_text()
                        
                        if callback then
                            task.spawn(callback, multi.selected)
                        end
                    end)
                    
                    option_button.MouseEnter:Connect(function()
                        option_frame.BackgroundColor3 = colors.hover
                        option_label.TextColor3 = colors.accent
                    end)
                    
                    option_button.MouseLeave:Connect(function()
                        option_frame.BackgroundColor3 = colors.secondary_bg
                        option_label.TextColor3 = colors.text
                    end)
                end
                
                return multi
            end
            
            function groupbox:add_keybind(text, default, callback)
                local keybind = {key = default or Enum.KeyCode.Unknown, binding = false, enabled = false}
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 16)
                frame.BackgroundTransparency = 1
                frame.Parent = content_frame
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -60, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = colors.text
                label.TextSize = 11
                label.Font = Enum.Font.Code
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = frame
                
                local keybind_button = Instance.new("TextButton")
                keybind_button.Size = UDim2.new(0, 55, 1, 0)
                keybind_button.Position = UDim2.new(1, -55, 0, 0)
                keybind_button.BackgroundColor3 = colors.tab_bg
                keybind_button.BorderColor3 = colors.border
                keybind_button.BorderSizePixel = 1
                keybind_button.Text = keybind.key.Name
                keybind_button.TextColor3 = colors.text
                keybind_button.TextSize = 10
                keybind_button.Font = Enum.Font.Code
                keybind_button.AutoButtonColor = false
                keybind_button.Parent = frame
                
                create_outline(keybind_button, Color3.fromRGB(0, 0, 0))
                
                keybind_button.MouseButton1Click:Connect(function()
                    keybind.binding = true
                    keybind_button.Text = "..."
                    keybind_button.TextColor3 = colors.accent
                end)
                
                keybind_button.MouseEnter:Connect(function()
                    keybind_button.BorderColor3 = colors.accent
                end)
                
                keybind_button.MouseLeave:Connect(function()
                    keybind_button.BorderColor3 = colors.border
                end)
                
                userinputservice.InputBegan:Connect(function(input)
                    if keybind.binding and input.UserInputType == Enum.UserInputType.Keyboard then
                        keybind.key = input.KeyCode
                        keybind_button.Text = input.KeyCode.Name
                        keybind_button.TextColor3 = colors.text
                        keybind.binding = false
                    elseif not keybind.binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keybind.key then
                        keybind.enabled = not keybind.enabled
                        if callback then
                            task.spawn(callback, keybind.enabled)
                        end
                    end
                end)
                
                return keybind
            end
            
            function groupbox:add_color_picker(text, default, callback)
                local color_picker = {color = default or Color3.fromRGB(255, 255, 255)}
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 16)
                frame.BackgroundTransparency = 1
                frame.Parent = content_frame
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -20, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = colors.text
                label.TextSize = 11
                label.Font = Enum.Font.Code
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = frame
                
                local color_box = Instance.new("Frame")
                color_box.Size = UDim2.new(0, 16, 0, 16)
                color_box.Position = UDim2.new(1, -16, 0, 0)
                color_box.BackgroundColor3 = color_picker.color
                color_box.BorderColor3 = colors.border
                color_box.BorderSizePixel = 1
                color_box.Parent = frame
                
                create_outline(color_box, Color3.fromRGB(0, 0, 0))
                
                local color_button = Instance.new("TextButton")
                color_button.Size = UDim2.new(1, 0, 1, 0)
                color_button.BackgroundTransparency = 1
                color_button.Text = ""
                color_button.Parent = color_box
                
                local picker_open = false
                
                color_button.MouseButton1Click:Connect(function()
                    picker_open = not picker_open
                end)
                
                color_box.MouseEnter:Connect(function()
                    color_box.BorderColor3 = colors.accent
                end)
                
                color_box.MouseLeave:Connect(function()
                    color_box.BorderColor3 = colors.border
                end)
                
                function color_picker:set_color(col)
                    color_picker.color = col
                    color_box.BackgroundColor3 = col
                end
                
                return color_picker
            end
            
            return groupbox
        end
        
        return tab
    end
    
    function window:toggle()
        container.Visible = not container.Visible
    end
    
    return window
end

function library:create_notification(title, message, duration)
    local notif = {}
    notif.title = title or "notification"
    notif.message = message or ""
    notif.duration = duration or 3
    
    local notif_frame = Instance.new("Frame")
    notif_frame.Size = UDim2.new(0, 300, 0, 0)
    notif_frame.Position = UDim2.new(1, -320, 1, -20 - (#library.notifications * 80))
    notif_frame.BackgroundColor3 = colors.main_bg
    notif_frame.BorderColor3 = colors.border
    notif_frame.BorderSizePixel = 1
    notif_frame.Parent = screen_gui
    
    create_outline(notif_frame, Color3.fromRGB(0, 0, 0))
    
    local title_label = Instance.new("TextLabel")
    title_label.Size = UDim2.new(1, -10, 0, 18)
    title_label.Position = UDim2.new(0, 5, 0, 3)
    title_label.BackgroundTransparency = 1
    title_label.Text = title
    title_label.TextColor3 = colors.accent
    title_label.TextSize = 12
    title_label.Font = Enum.Font.Code
    title_label.TextXAlignment = Enum.TextXAlignment.Left
    title_label.Parent = notif_frame
    
    local message_label = Instance.new("TextLabel")
    message_label.Size = UDim2.new(1, -10, 0, 40)
    message_label.Position = UDim2.new(0, 5, 0, 22)
    message_label.BackgroundTransparency = 1
    message_label.Text = message
    message_label.TextColor3 = colors.text
    message_label.TextSize = 10
    message_label.Font = Enum.Font.Code
    message_label.TextXAlignment = Enum.TextXAlignment.Left
    message_label.TextYAlignment = Enum.TextYAlignment.Top
    message_label.TextWrapped = true
    message_label.Parent = notif_frame
    
    table.insert(library.notifications, notif_frame)
    
    notif_frame:TweenSize(UDim2.new(0, 300, 0, 70), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    
    task.delay(notif.duration, function()
        notif_frame:TweenSize(UDim2.new(0, 300, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
        task.wait(0.3)
        notif_frame:Destroy()
        for i, v in ipairs(library.notifications) do
            if v == notif_frame then
                table.remove(library.notifications, i)
                break
            end
        end
    end)
    
    return notif
end

function library:create_watermark(text)
    local watermark = {}
    watermark.text = text or "skeet.cc"
    watermark.visible = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 22)
    frame.Position = UDim2.new(0.5, -100, 0, 10)
    frame.BackgroundColor3 = colors.main_bg
    frame.BorderColor3 = colors.border
    frame.BorderSizePixel = 1
    frame.Parent = screen_gui
    library.watermark = frame
    
    create_outline(frame, Color3.fromRGB(0, 0, 0))
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -28, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = watermark.text
    label.TextColor3 = colors.text
    label.TextSize = 11
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local close_button = Instance.new("TextButton")
    close_button.Size = UDim2.new(0, 18, 0, 18)
    close_button.Position = UDim2.new(1, -20, 0, 2)
    close_button.BackgroundColor3 = colors.secondary_bg
    close_button.BorderSizePixel = 0
    close_button.Text = "X"
    close_button.TextColor3 = colors.text
    close_button.TextSize = 11
    close_button.Font = Enum.Font.Code
    close_button.AutoButtonColor = false
    close_button.Parent = frame
    
    close_button.MouseButton1Click:Connect(function()
        watermark.visible = false
        frame.Visible = false
    end)
    
    close_button.MouseEnter:Connect(function()
        close_button.BackgroundColor3 = colors.accent
        close_button.TextColor3 = Color3.fromRGB(0, 0, 0)
    end)
    
    close_button.MouseLeave:Connect(function()
        close_button.BackgroundColor3 = colors.secondary_bg
        close_button.TextColor3 = colors.text
    end)
    
    function watermark:set_text(new_text)
        watermark.text = new_text
        label.Text = new_text
    end
    
    function watermark:toggle()
        watermark.visible = not watermark.visible
        frame.Visible = watermark.visible
    end
    
    return watermark
end

function library:create_keybind_list()
    local keybind_list = {}
    keybind_list.keybinds = {}
    keybind_list.visible = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 25)
    frame.Position = UDim2.new(1, -220, 0, 100)
    frame.BackgroundColor3 = colors.main_bg
    frame.BorderColor3 = colors.border
    frame.BorderSizePixel = 1
    frame.Parent = screen_gui
    library.keybind_list = frame
    
    create_outline(frame, Color3.fromRGB(0, 0, 0))
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 18)
    title.Position = UDim2.new(0, 5, 0, 3)
    title.BackgroundTransparency = 1
    title.Text = "keybinds"
    title.TextColor3 = colors.text
    title.TextSize = 11
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -25)
    content.Position = UDim2.new(0, 5, 0, 23)
    content.BackgroundTransparency = 1
    content.Parent = frame
    
    local content_layout = Instance.new("UIListLayout")
    content_layout.SortOrder = Enum.SortOrder.LayoutOrder
    content_layout.Padding = UDim.new(0, 2)
    content_layout.Parent = content
    
    content_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.Size = UDim2.new(0, 200, 0, 25 + content_layout.AbsoluteContentSize.Y + 5)
    end)
    
    function keybind_list:add_keybind(name, key)
        local kb_frame = Instance.new("Frame")
        kb_frame.Size = UDim2.new(1, 0, 0, 16)
        kb_frame.BackgroundTransparency = 1
        kb_frame.Parent = content
        
        local kb_name = Instance.new("TextLabel")
        kb_name.Size = UDim2.new(0.6, 0, 1, 0)
        kb_name.BackgroundTransparency = 1
        kb_name.Text = name
        kb_name.TextColor3 = colors.text
        kb_name.TextSize = 10
        kb_name.Font = Enum.Font.Code
        kb_name.TextXAlignment = Enum.TextXAlignment.Left
        kb_name.Parent = kb_frame
        
        local kb_state = Instance.new("TextLabel")
        kb_state.Size = UDim2.new(0.4, 0, 1, 0)
        kb_state.Position = UDim2.new(0.6, 0, 0, 0)
        kb_state.BackgroundTransparency = 1
        kb_state.Text = "[on]"
        kb_state.TextColor3 = colors.accent
        kb_state.TextSize = 10
        kb_state.Font = Enum.Font.Code
        kb_state.TextXAlignment = Enum.TextXAlignment.Right
        kb_state.Parent = kb_frame
        
        keybind_list.keybinds[name] = {frame = kb_frame, active = true, label = kb_state}
        
        return kb_frame
    end
    
    function keybind_list:remove_keybind(name)
        if keybind_list.keybinds[name] then
            keybind_list.keybinds[name].frame:Destroy()
            keybind_list.keybinds[name] = nil
        end
    end
    
    function keybind_list:toggle_keybind(name, state)
        if keybind_list.keybinds[name] then
            keybind_list.keybinds[name].active = state
            keybind_list.keybinds[name].label.Text = state and "[on]" or "[off]"
            keybind_list.keybinds[name].label.TextColor3 = state and colors.accent or colors.disabled
        end
    end
    
    function keybind_list:toggle()
        keybind_list.visible = not keybind_list.visible
        frame.Visible = keybind_list.visible
    end
    
    return keybind_list
end

function library:set_menu_keybind(key)
    menu_keybind = key
end

function library:init()
    create_screen_gui()
    
    userinputservice.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == menu_keybind then
            menu_open = not menu_open
            for _, window in pairs(library.windows) do
                window.container.Visible = menu_open
            end
        end
    end)
end

library:init()

return library

