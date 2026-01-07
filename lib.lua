local library = {}

local coregui = game:GetService("CoreGui")
local userinputservice = game:GetService("UserInputService")
local runservice = game:GetService("RunService")
local tweenservice = game:GetService("TweenService")

local main_color = Color3.fromRGB(20, 20, 20)
local accent_color = Color3.fromRGB(0, 255, 0)
local secondary_color = Color3.fromRGB(15, 15, 15)
local border_color = Color3.fromRGB(0, 200, 0)
local text_color = Color3.fromRGB(255, 255, 255)
local disabled_color = Color3.fromRGB(100, 100, 100)

local screen_gui
local dragging = false
local drag_input
local drag_start
local start_pos
local current_menu
local menu_open = true
local menu_keybind = Enum.KeyCode.Insert
local notifications = {}
local keybind_ui_visible = true
local watermark_visible = true
local active_keybinds = {}

local function create_screen_gui()
    if screen_gui then
        screen_gui:Destroy()
    end
    
    screen_gui = Instance.new("ScreenGui")
    screen_gui.Name = "skeet_ui_" .. tostring(math.random(1000, 9999))
    screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen_gui.Parent = coregui
    
    return screen_gui
end

local function create_drawing_object(class, properties)
    local obj = Drawing.new(class)
    for prop, value in pairs(properties) do
        obj[prop] = value
    end
    return obj
end

local function is_mouse_over(pos, size)
    local mouse = userinputservice:GetMouseLocation()
    return mouse.X >= pos.X and mouse.X <= pos.X + size.X and
           mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
end

library.window_count = 0
library.windows = {}
library.keybinds = {}

function library:create_window(title, size)
    local window = {}
    window.title = title or "window"
    window.size = size or Vector2.new(600, 400)
    window.position = Vector2.new(100 + (library.window_count * 50), 100 + (library.window_count * 50))
    window.visible = true
    window.tabs = {}
    window.current_tab = nil
    window.objects = {}
    
    library.window_count = library.window_count + 1
    table.insert(library.windows, window)
    
    local container = Instance.new("Frame")
    container.Name = "window_container"
    container.Size = UDim2.new(0, window.size.X, 0, window.size.Y)
    container.Position = UDim2.new(0, window.position.X, 0, window.position.Y)
    container.BackgroundColor3 = main_color
    container.BorderColor3 = border_color
    container.BorderSizePixel = 2
    container.Parent = screen_gui
    window.container = container
    
    local title_bar = Instance.new("Frame")
    title_bar.Name = "title_bar"
    title_bar.Size = UDim2.new(1, 0, 0, 30)
    title_bar.BackgroundColor3 = secondary_color
    title_bar.BorderSizePixel = 0
    title_bar.Parent = container
    
    local title_label = Instance.new("TextLabel")
    title_label.Name = "title"
    title_label.Size = UDim2.new(1, -10, 1, 0)
    title_label.Position = UDim2.new(0, 10, 0, 0)
    title_label.BackgroundTransparency = 1
    title_label.Text = title
    title_label.TextColor3 = accent_color
    title_label.TextSize = 14
    title_label.Font = Enum.Font.Code
    title_label.TextXAlignment = Enum.TextXAlignment.Left
    title_label.Parent = title_bar
    
    local tab_container = Instance.new("Frame")
    tab_container.Name = "tab_container"
    tab_container.Size = UDim2.new(0, 120, 1, -30)
    tab_container.Position = UDim2.new(0, 0, 0, 30)
    tab_container.BackgroundColor3 = secondary_color
    tab_container.BorderSizePixel = 0
    tab_container.Parent = container
    window.tab_container = tab_container
    
    local content_container = Instance.new("Frame")
    content_container.Name = "content"
    content_container.Size = UDim2.new(1, -120, 1, -30)
    content_container.Position = UDim2.new(0, 120, 0, 30)
    content_container.BackgroundColor3 = main_color
    content_container.BorderSizePixel = 0
    content_container.Parent = container
    window.content_container = content_container
    
    local scroll_frame = Instance.new("ScrollingFrame")
    scroll_frame.Name = "scroll"
    scroll_frame.Size = UDim2.new(1, 0, 1, 0)
    scroll_frame.BackgroundTransparency = 1
    scroll_frame.BorderSizePixel = 0
    scroll_frame.ScrollBarThickness = 4
    scroll_frame.ScrollBarImageColor3 = accent_color
    scroll_frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll_frame.Parent = content_container
    window.scroll_frame = scroll_frame
    
    local ui_list = Instance.new("UIListLayout")
    ui_list.SortOrder = Enum.SortOrder.LayoutOrder
    ui_list.Padding = UDim.new(0, 5)
    ui_list.Parent = scroll_frame
    
    local function update_dragging(input)
        local delta = input.Position - drag_start
        container.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
    end
    
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
            update_dragging(input)
        end
    end)
    
    function window:add_tab(name)
        local tab = {}
        tab.name = name
        tab.elements = {}
        tab.y_offset = 10
        
        table.insert(window.tabs, tab)
        
        local tab_button = Instance.new("TextButton")
        tab_button.Name = "tab_" .. name
        tab_button.Size = UDim2.new(1, 0, 0, 35)
        tab_button.BackgroundColor3 = secondary_color
        tab_button.BorderSizePixel = 0
        tab_button.Text = name
        tab_button.TextColor3 = text_color
        tab_button.TextSize = 13
        tab_button.Font = Enum.Font.Code
        tab_button.Parent = tab_container
        tab.button = tab_button
        
        local tab_content = Instance.new("Frame")
        tab_content.Name = "content_" .. name
        tab_content.Size = UDim2.new(1, 0, 1, 0)
        tab_content.BackgroundTransparency = 1
        tab_content.Visible = false
        tab_content.Parent = scroll_frame
        tab.content = tab_content
        
        local tab_list = Instance.new("UIListLayout")
        tab_list.SortOrder = Enum.SortOrder.LayoutOrder
        tab_list.Padding = UDim.new(0, 5)
        tab_list.Parent = tab_content
        
        tab_button.MouseButton1Click:Connect(function()
            for _, t in pairs(window.tabs) do
                t.content.Visible = false
                t.button.BackgroundColor3 = secondary_color
                t.button.TextColor3 = text_color
            end
            tab_content.Visible = true
            tab_button.BackgroundColor3 = main_color
            tab_button.TextColor3 = accent_color
            window.current_tab = tab
        end)
        
        if #window.tabs == 1 then
            tab_button.BackgroundColor3 = main_color
            tab_button.TextColor3 = accent_color
            tab_content.Visible = true
            window.current_tab = tab
        end
        
        function tab:add_button(text, callback)
            local button_frame = Instance.new("Frame")
            button_frame.Name = "button"
            button_frame.Size = UDim2.new(1, -20, 0, 30)
            button_frame.BackgroundColor3 = secondary_color
            button_frame.BorderColor3 = border_color
            button_frame.BorderSizePixel = 1
            button_frame.Parent = tab_content
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 1, 0)
            button.BackgroundTransparency = 1
            button.Text = text
            button.TextColor3 = text_color
            button.TextSize = 12
            button.Font = Enum.Font.Code
            button.Parent = button_frame
            
            button.MouseButton1Click:Connect(function()
                button_frame.BackgroundColor3 = accent_color
                wait(0.1)
                button_frame.BackgroundColor3 = secondary_color
                if callback then
                    callback()
                end
            end)
            
            button.MouseEnter:Connect(function()
                button_frame.BorderColor3 = accent_color
            end)
            
            button.MouseLeave:Connect(function()
                button_frame.BorderColor3 = border_color
            end)
            
            return button
        end
        
        function tab:add_checkbox(text, default, callback)
            local checkbox_data = {value = default or false}
            
            local checkbox_frame = Instance.new("Frame")
            checkbox_frame.Name = "checkbox"
            checkbox_frame.Size = UDim2.new(1, -20, 0, 25)
            checkbox_frame.BackgroundTransparency = 1
            checkbox_frame.Parent = tab_content
            
            local check_box = Instance.new("Frame")
            check_box.Size = UDim2.new(0, 15, 0, 15)
            check_box.Position = UDim2.new(0, 5, 0.5, -7.5)
            check_box.BackgroundColor3 = secondary_color
            check_box.BorderColor3 = border_color
            check_box.BorderSizePixel = 1
            check_box.Parent = checkbox_frame
            
            local check_mark = Instance.new("Frame")
            check_mark.Size = UDim2.new(0, 9, 0, 9)
            check_mark.Position = UDim2.new(0, 3, 0, 3)
            check_mark.BackgroundColor3 = accent_color
            check_mark.BorderSizePixel = 0
            check_mark.Visible = checkbox_data.value
            check_mark.Parent = check_box
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Position = UDim2.new(0, 25, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = text_color
            label.TextSize = 12
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = checkbox_frame
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 1, 0)
            button.BackgroundTransparency = 1
            button.Text = ""
            button.Parent = checkbox_frame
            
            button.MouseButton1Click:Connect(function()
                checkbox_data.value = not checkbox_data.value
                check_mark.Visible = checkbox_data.value
                if callback then
                    callback(checkbox_data.value)
                end
            end)
            
            button.MouseEnter:Connect(function()
                check_box.BorderColor3 = accent_color
            end)
            
            button.MouseLeave:Connect(function()
                check_box.BorderColor3 = border_color
            end)
            
            function checkbox_data:set_value(val)
                checkbox_data.value = val
                check_mark.Visible = val
            end
            
            return checkbox_data
        end
        
        function tab:add_slider(text, min, max, default, callback)
            local slider_data = {value = default or min}
            
            local slider_frame = Instance.new("Frame")
            slider_frame.Name = "slider"
            slider_frame.Size = UDim2.new(1, -20, 0, 40)
            slider_frame.BackgroundTransparency = 1
            slider_frame.Parent = tab_content
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 15)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. tostring(slider_data.value)
            label.TextColor3 = text_color
            label.TextSize = 12
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = slider_frame
            
            local slider_bg = Instance.new("Frame")
            slider_bg.Size = UDim2.new(1, 0, 0, 15)
            slider_bg.Position = UDim2.new(0, 0, 0, 20)
            slider_bg.BackgroundColor3 = secondary_color
            slider_bg.BorderColor3 = border_color
            slider_bg.BorderSizePixel = 1
            slider_bg.Parent = slider_frame
            
            local slider_fill = Instance.new("Frame")
            slider_fill.Size = UDim2.new((slider_data.value - min) / (max - min), 0, 1, 0)
            slider_fill.BackgroundColor3 = accent_color
            slider_fill.BorderSizePixel = 0
            slider_fill.Parent = slider_bg
            
            local sliding = false
            
            local function update_slider(input)
                local pos = (input.Position.X - slider_bg.AbsolutePosition.X) / slider_bg.AbsoluteSize.X
                pos = math.clamp(pos, 0, 1)
                slider_data.value = math.floor(min + (max - min) * pos)
                slider_fill.Size = UDim2.new(pos, 0, 1, 0)
                label.Text = text .. ": " .. tostring(slider_data.value)
                if callback then
                    callback(slider_data.value)
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
                slider_bg.BorderColor3 = accent_color
            end)
            
            slider_bg.MouseLeave:Connect(function()
                slider_bg.BorderColor3 = border_color
            end)
            
            function slider_data:set_value(val)
                slider_data.value = math.clamp(val, min, max)
                slider_fill.Size = UDim2.new((slider_data.value - min) / (max - min), 0, 1, 0)
                label.Text = text .. ": " .. tostring(slider_data.value)
            end
            
            return slider_data
        end
        
        function tab:add_dropdown(text, options, callback)
            local dropdown_data = {value = nil, open = false}
            
            local dropdown_frame = Instance.new("Frame")
            dropdown_frame.Name = "dropdown"
            dropdown_frame.Size = UDim2.new(1, -20, 0, 25)
            dropdown_frame.BackgroundTransparency = 1
            dropdown_frame.Parent = tab_content
            dropdown_frame.ZIndex = 10
            
            local dropdown_button = Instance.new("TextButton")
            dropdown_button.Size = UDim2.new(1, 0, 0, 25)
            dropdown_button.BackgroundColor3 = secondary_color
            dropdown_button.BorderColor3 = border_color
            dropdown_button.BorderSizePixel = 1
            dropdown_button.Text = text .. ": none"
            dropdown_button.TextColor3 = text_color
            dropdown_button.TextSize = 12
            dropdown_button.Font = Enum.Font.Code
            dropdown_button.TextXAlignment = Enum.TextXAlignment.Left
            dropdown_button.TextTruncate = Enum.TextTruncate.AtEnd
            dropdown_button.Parent = dropdown_frame
            
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -20, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "v"
            arrow.TextColor3 = accent_color
            arrow.TextSize = 12
            arrow.Font = Enum.Font.Code
            arrow.Parent = dropdown_button
            
            local dropdown_list = Instance.new("Frame")
            dropdown_list.Size = UDim2.new(1, 0, 0, 0)
            dropdown_list.Position = UDim2.new(0, 0, 0, 27)
            dropdown_list.BackgroundColor3 = secondary_color
            dropdown_list.BorderColor3 = border_color
            dropdown_list.BorderSizePixel = 1
            dropdown_list.Visible = false
            dropdown_list.ZIndex = 20
            dropdown_list.Parent = dropdown_frame
            
            local list_layout = Instance.new("UIListLayout")
            list_layout.SortOrder = Enum.SortOrder.LayoutOrder
            list_layout.Parent = dropdown_list
            
            dropdown_button.MouseButton1Click:Connect(function()
                dropdown_data.open = not dropdown_data.open
                dropdown_list.Visible = dropdown_data.open
                arrow.Text = dropdown_data.open and "^" or "v"
                
                if dropdown_data.open then
                    dropdown_frame.Size = UDim2.new(1, -20, 0, 25 + #options * 25 + 2)
                else
                    dropdown_frame.Size = UDim2.new(1, -20, 0, 25)
                end
            end)
            
            dropdown_button.MouseEnter:Connect(function()
                dropdown_button.BorderColor3 = accent_color
            end)
            
            dropdown_button.MouseLeave:Connect(function()
                dropdown_button.BorderColor3 = border_color
            end)
            
            for _, option in ipairs(options) do
                local option_button = Instance.new("TextButton")
                option_button.Size = UDim2.new(1, 0, 0, 25)
                option_button.BackgroundColor3 = secondary_color
                option_button.BorderSizePixel = 0
                option_button.Text = option
                option_button.TextColor3 = text_color
                option_button.TextSize = 11
                option_button.Font = Enum.Font.Code
                option_button.TextXAlignment = Enum.TextXAlignment.Left
                option_button.ZIndex = 20
                option_button.Parent = dropdown_list
                
                option_button.MouseButton1Click:Connect(function()
                    dropdown_data.value = option
                    dropdown_button.Text = text .. ": " .. option
                    dropdown_data.open = false
                    dropdown_list.Visible = false
                    arrow.Text = "v"
                    dropdown_frame.Size = UDim2.new(1, -20, 0, 25)
                    if callback then
                        callback(option)
                    end
                end)
                
                option_button.MouseEnter:Connect(function()
                    option_button.BackgroundColor3 = main_color
                    option_button.TextColor3 = accent_color
                end)
                
                option_button.MouseLeave:Connect(function()
                    option_button.BackgroundColor3 = secondary_color
                    option_button.TextColor3 = text_color
                end)
            end
            
            dropdown_list.Size = UDim2.new(1, 0, 0, #options * 25)
            
            return dropdown_data
        end
        
        function tab:add_multi_dropdown(text, options, callback)
            local multi_data = {selected = {}, open = false}
            
            local dropdown_frame = Instance.new("Frame")
            dropdown_frame.Name = "multi_dropdown"
            dropdown_frame.Size = UDim2.new(1, -20, 0, 25)
            dropdown_frame.BackgroundTransparency = 1
            dropdown_frame.Parent = tab_content
            dropdown_frame.ZIndex = 10
            
            local dropdown_button = Instance.new("TextButton")
            dropdown_button.Size = UDim2.new(1, 0, 0, 25)
            dropdown_button.BackgroundColor3 = secondary_color
            dropdown_button.BorderColor3 = border_color
            dropdown_button.BorderSizePixel = 1
            dropdown_button.Text = text .. ": none"
            dropdown_button.TextColor3 = text_color
            dropdown_button.TextSize = 12
            dropdown_button.Font = Enum.Font.Code
            dropdown_button.TextXAlignment = Enum.TextXAlignment.Left
            dropdown_button.TextTruncate = Enum.TextTruncate.AtEnd
            dropdown_button.Parent = dropdown_frame
            
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -20, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "v"
            arrow.TextColor3 = accent_color
            arrow.TextSize = 12
            arrow.Font = Enum.Font.Code
            arrow.Parent = dropdown_button
            
            local dropdown_list = Instance.new("Frame")
            dropdown_list.Size = UDim2.new(1, 0, 0, 0)
            dropdown_list.Position = UDim2.new(0, 0, 0, 27)
            dropdown_list.BackgroundColor3 = secondary_color
            dropdown_list.BorderColor3 = border_color
            dropdown_list.BorderSizePixel = 1
            dropdown_list.Visible = false
            dropdown_list.ZIndex = 20
            dropdown_list.Parent = dropdown_frame
            
            local list_layout = Instance.new("UIListLayout")
            list_layout.SortOrder = Enum.SortOrder.LayoutOrder
            list_layout.Parent = dropdown_list
            
            local function update_text()
                if #multi_data.selected == 0 then
                    dropdown_button.Text = text .. ": none"
                else
                    dropdown_button.Text = text .. ": " .. table.concat(multi_data.selected, ", ")
                end
            end
            
            dropdown_button.MouseButton1Click:Connect(function()
                multi_data.open = not multi_data.open
                dropdown_list.Visible = multi_data.open
                arrow.Text = multi_data.open and "^" or "v"
                
                if multi_data.open then
                    dropdown_frame.Size = UDim2.new(1, -20, 0, 25 + #options * 25 + 2)
                else
                    dropdown_frame.Size = UDim2.new(1, -20, 0, 25)
                end
            end)
            
            dropdown_button.MouseEnter:Connect(function()
                dropdown_button.BorderColor3 = accent_color
            end)
            
            dropdown_button.MouseLeave:Connect(function()
                dropdown_button.BorderColor3 = border_color
            end)
            
            for _, option in ipairs(options) do
                local option_frame = Instance.new("Frame")
                option_frame.Size = UDim2.new(1, 0, 0, 25)
                option_frame.BackgroundColor3 = secondary_color
                option_frame.BorderSizePixel = 0
                option_frame.ZIndex = 20
                option_frame.Parent = dropdown_list
                
                local check_box = Instance.new("Frame")
                check_box.Size = UDim2.new(0, 12, 0, 12)
                check_box.Position = UDim2.new(0, 5, 0.5, -6)
                check_box.BackgroundColor3 = main_color
                check_box.BorderColor3 = border_color
                check_box.BorderSizePixel = 1
                check_box.ZIndex = 20
                check_box.Parent = option_frame
                
                local check_mark = Instance.new("Frame")
                check_mark.Size = UDim2.new(0, 8, 0, 8)
                check_mark.Position = UDim2.new(0, 2, 0, 2)
                check_mark.BackgroundColor3 = accent_color
                check_mark.BorderSizePixel = 0
                check_mark.Visible = false
                check_mark.ZIndex = 20
                check_mark.Parent = check_box
                
                local option_label = Instance.new("TextLabel")
                option_label.Size = UDim2.new(1, -25, 1, 0)
                option_label.Position = UDim2.new(0, 22, 0, 0)
                option_label.BackgroundTransparency = 1
                option_label.Text = option
                option_label.TextColor3 = text_color
                option_label.TextSize = 11
                option_label.Font = Enum.Font.Code
                option_label.TextXAlignment = Enum.TextXAlignment.Left
                option_label.ZIndex = 20
                option_label.Parent = option_frame
                
                local option_button = Instance.new("TextButton")
                option_button.Size = UDim2.new(1, 0, 1, 0)
                option_button.BackgroundTransparency = 1
                option_button.Text = ""
                option_button.ZIndex = 20
                option_button.Parent = option_frame
                
                option_button.MouseButton1Click:Connect(function()
                    local found = false
                    for i, v in ipairs(multi_data.selected) do
                        if v == option then
                            table.remove(multi_data.selected, i)
                            found = true
                            break
                        end
                    end
                    
                    if not found then
                        table.insert(multi_data.selected, option)
                    end
                    
                    check_mark.Visible = not found
                    update_text()
                    
                    if callback then
                        callback(multi_data.selected)
                    end
                end)
                
                option_button.MouseEnter:Connect(function()
                    option_frame.BackgroundColor3 = main_color
                    option_label.TextColor3 = accent_color
                end)
                
                option_button.MouseLeave:Connect(function()
                    option_frame.BackgroundColor3 = secondary_color
                    option_label.TextColor3 = text_color
                end)
            end
            
            dropdown_list.Size = UDim2.new(1, 0, 0, #options * 25)
            
            return multi_data
        end
        
        function tab:add_keybind(text, default, callback)
            local keybind_data = {key = default or Enum.KeyCode.Unknown, binding = false}
            
            local keybind_frame = Instance.new("Frame")
            keybind_frame.Name = "keybind"
            keybind_frame.Size = UDim2.new(1, -20, 0, 25)
            keybind_frame.BackgroundTransparency = 1
            keybind_frame.Parent = tab_content
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -80, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = text_color
            label.TextSize = 12
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = keybind_frame
            
            local keybind_button = Instance.new("TextButton")
            keybind_button.Size = UDim2.new(0, 75, 0, 25)
            keybind_button.Position = UDim2.new(1, -75, 0, 0)
            keybind_button.BackgroundColor3 = secondary_color
            keybind_button.BorderColor3 = border_color
            keybind_button.BorderSizePixel = 1
            keybind_button.Text = keybind_data.key.Name
            keybind_button.TextColor3 = text_color
            keybind_button.TextSize = 11
            keybind_button.Font = Enum.Font.Code
            keybind_button.Parent = keybind_frame
            
            keybind_button.MouseButton1Click:Connect(function()
                keybind_data.binding = true
                keybind_button.Text = "..."
                keybind_button.TextColor3 = accent_color
            end)
            
            keybind_button.MouseEnter:Connect(function()
                keybind_button.BorderColor3 = accent_color
            end)
            
            keybind_button.MouseLeave:Connect(function()
                keybind_button.BorderColor3 = border_color
            end)
            
            userinputservice.InputBegan:Connect(function(input)
                if keybind_data.binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    keybind_data.key = input.KeyCode
                    keybind_button.Text = input.KeyCode.Name
                    keybind_button.TextColor3 = text_color
                    keybind_data.binding = false
                elseif not keybind_data.binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keybind_data.key then
                    if callback then
                        callback(keybind_data.key)
                    end
                end
            end)
            
            return keybind_data
        end
        
        function tab:add_color_picker(text, default, callback)
            local color_data = {color = default or Color3.fromRGB(255, 255, 255)}
            
            local picker_frame = Instance.new("Frame")
            picker_frame.Name = "color_picker"
            picker_frame.Size = UDim2.new(1, -20, 0, 25)
            picker_frame.BackgroundTransparency = 1
            picker_frame.Parent = tab_content
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -35, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = text_color
            label.TextSize = 12
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = picker_frame
            
            local color_box = Instance.new("Frame")
            color_box.Size = UDim2.new(0, 25, 0, 25)
            color_box.Position = UDim2.new(1, -25, 0, 0)
            color_box.BackgroundColor3 = color_data.color
            color_box.BorderColor3 = border_color
            color_box.BorderSizePixel = 1
            color_box.Parent = picker_frame
            
            local color_button = Instance.new("TextButton")
            color_button.Size = UDim2.new(1, 0, 1, 0)
            color_button.BackgroundTransparency = 1
            color_button.Text = ""
            color_button.Parent = color_box
            
            local picker_open = false
            local picker_window
            
            color_button.MouseButton1Click:Connect(function()
                if picker_open then
                    if picker_window then
                        picker_window:Destroy()
                    end
                    picker_open = false
                    return
                end
                
                picker_open = true
                picker_window = Instance.new("Frame")
                picker_window.Size = UDim2.new(0, 200, 0, 200)
                picker_window.Position = UDim2.new(0, color_box.AbsolutePosition.X, 0, color_box.AbsolutePosition.Y + 30)
                picker_window.BackgroundColor3 = main_color
                picker_window.BorderColor3 = border_color
                picker_window.BorderSizePixel = 2
                picker_window.ZIndex = 100
                picker_window.Parent = screen_gui
                
                local h_slider = Instance.new("Frame")
                h_slider.Size = UDim2.new(1, -20, 0, 20)
                h_slider.Position = UDim2.new(0, 10, 0, 10)
                h_slider.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                h_slider.BorderColor3 = border_color
                h_slider.BorderSizePixel = 1
                h_slider.ZIndex = 100
                h_slider.Parent = picker_window
                
                local s_slider = Instance.new("Frame")
                s_slider.Size = UDim2.new(1, -20, 0, 20)
                s_slider.Position = UDim2.new(0, 10, 0, 40)
                s_slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                s_slider.BorderColor3 = border_color
                s_slider.BorderSizePixel = 1
                s_slider.ZIndex = 100
                s_slider.Parent = picker_window
                
                local v_slider = Instance.new("Frame")
                v_slider.Size = UDim2.new(1, -20, 0, 20)
                v_slider.Position = UDim2.new(0, 10, 0, 70)
                v_slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                v_slider.BorderColor3 = border_color
                v_slider.BorderSizePixel = 1
                v_slider.ZIndex = 100
                v_slider.Parent = picker_window
                
                local preview = Instance.new("Frame")
                preview.Size = UDim2.new(1, -20, 0, 80)
                preview.Position = UDim2.new(0, 10, 0, 100)
                preview.BackgroundColor3 = color_data.color
                preview.BorderColor3 = border_color
                preview.BorderSizePixel = 1
                preview.ZIndex = 100
                preview.Parent = picker_window
                
                local h, s, v = 0, 1, 1
                
                local function update_color()
                    color_data.color = Color3.fromHSV(h, s, v)
                    color_box.BackgroundColor3 = color_data.color
                    preview.BackgroundColor3 = color_data.color
                    if callback then
                        callback(color_data.color)
                    end
                end
                
                local h_dragging = false
                h_slider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        h_dragging = true
                    end
                end)
                
                h_slider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        h_dragging = false
                    end
                end)
                
                userinputservice.InputChanged:Connect(function(input)
                    if h_dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local pos = (input.Position.X - h_slider.AbsolutePosition.X) / h_slider.AbsoluteSize.X
                        h = math.clamp(pos, 0, 1)
                        h_slider.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        update_color()
                    end
                end)
            end)
            
            color_box.MouseEnter:Connect(function()
                color_box.BorderColor3 = accent_color
            end)
            
            color_box.MouseLeave:Connect(function()
                color_box.BorderColor3 = border_color
            end)
            
            return color_data
        end
        
        return tab
    end
    
    function window:toggle()
        window.visible = not window.visible
        container.Visible = window.visible
    end
    
    return window
end

function library:create_notification(title, message, duration)
    local notification = {}
    notification.title = title or "notification"
    notification.message = message or ""
    notification.duration = duration or 3
    
    local notif_frame = Instance.new("Frame")
    notif_frame.Size = UDim2.new(0, 300, 0, 0)
    notif_frame.Position = UDim2.new(1, -320, 1, -20)
    notif_frame.BackgroundColor3 = main_color
    notif_frame.BorderColor3 = border_color
    notif_frame.BorderSizePixel = 2
    notif_frame.Parent = screen_gui
    
    local title_label = Instance.new("TextLabel")
    title_label.Size = UDim2.new(1, -10, 0, 20)
    title_label.Position = UDim2.new(0, 5, 0, 5)
    title_label.BackgroundTransparency = 1
    title_label.Text = title
    title_label.TextColor3 = accent_color
    title_label.TextSize = 13
    title_label.Font = Enum.Font.Code
    title_label.TextXAlignment = Enum.TextXAlignment.Left
    title_label.Parent = notif_frame
    
    local message_label = Instance.new("TextLabel")
    message_label.Size = UDim2.new(1, -10, 0, 40)
    message_label.Position = UDim2.new(0, 5, 0, 25)
    message_label.BackgroundTransparency = 1
    message_label.Text = message
    message_label.TextColor3 = text_color
    message_label.TextSize = 11
    message_label.Font = Enum.Font.Code
    message_label.TextXAlignment = Enum.TextXAlignment.Left
    message_label.TextYAlignment = Enum.TextYAlignment.Top
    message_label.TextWrapped = true
    message_label.Parent = notif_frame
    
    table.insert(notifications, notif_frame)
    
    local target_height = 70
    notif_frame:TweenSize(UDim2.new(0, 300, 0, target_height), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    
    task.delay(notification.duration, function()
        notif_frame:TweenSize(UDim2.new(0, 300, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
        task.wait(0.3)
        notif_frame:Destroy()
        for i, v in ipairs(notifications) do
            if v == notif_frame then
                table.remove(notifications, i)
                break
            end
        end
    end)
    
    return notification
end

function library:create_watermark(text)
    local watermark = {}
    watermark.text = text or "skeet.cc"
    watermark.visible = true
    
    local watermark_frame = Instance.new("Frame")
    watermark_frame.Size = UDim2.new(0, 200, 0, 25)
    watermark_frame.Position = UDim2.new(0.5, -100, 0, 10)
    watermark_frame.BackgroundColor3 = main_color
    watermark_frame.BorderColor3 = border_color
    watermark_frame.BorderSizePixel = 2
    watermark_frame.Parent = screen_gui
    watermark.frame = watermark_frame
    
    local watermark_label = Instance.new("TextLabel")
    watermark_label.Size = UDim2.new(1, -30, 1, 0)
    watermark_label.Position = UDim2.new(0, 5, 0, 0)
    watermark_label.BackgroundTransparency = 1
    watermark_label.Text = watermark.text
    watermark_label.TextColor3 = accent_color
    watermark_label.TextSize = 13
    watermark_label.Font = Enum.Font.Code
    watermark_label.TextXAlignment = Enum.TextXAlignment.Left
    watermark_label.Parent = watermark_frame
    
    local close_button = Instance.new("TextButton")
    close_button.Size = UDim2.new(0, 20, 0, 20)
    close_button.Position = UDim2.new(1, -23, 0, 2.5)
    close_button.BackgroundColor3 = secondary_color
    close_button.BorderSizePixel = 0
    close_button.Text = "X"
    close_button.TextColor3 = text_color
    close_button.TextSize = 12
    close_button.Font = Enum.Font.Code
    close_button.Parent = watermark_frame
    
    close_button.MouseButton1Click:Connect(function()
        watermark.visible = false
        watermark_frame.Visible = false
    end)
    
    close_button.MouseEnter:Connect(function()
        close_button.BackgroundColor3 = accent_color
    end)
    
    close_button.MouseLeave:Connect(function()
        close_button.BackgroundColor3 = secondary_color
    end)
    
    function watermark:set_text(new_text)
        watermark.text = new_text
        watermark_label.Text = new_text
    end
    
    function watermark:toggle()
        watermark.visible = not watermark.visible
        watermark_frame.Visible = watermark.visible
    end
    
    return watermark
end

function library:create_keybind_list()
    local keybind_list = {}
    keybind_list.keybinds = {}
    keybind_list.visible = true
    
    local list_frame = Instance.new("Frame")
    list_frame.Size = UDim2.new(0, 200, 0, 25)
    list_frame.Position = UDim2.new(1, -220, 0, 100)
    list_frame.BackgroundColor3 = main_color
    list_frame.BorderColor3 = border_color
    list_frame.BorderSizePixel = 2
    list_frame.Parent = screen_gui
    keybind_list.frame = list_frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 20)
    title.Position = UDim2.new(0, 5, 0, 3)
    title.BackgroundTransparency = 1
    title.Text = "keybinds"
    title.TextColor3 = accent_color
    title.TextSize = 13
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = list_frame
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -25)
    content.Position = UDim2.new(0, 5, 0, 25)
    content.BackgroundTransparency = 1
    content.Parent = list_frame
    
    local content_layout = Instance.new("UIListLayout")
    content_layout.SortOrder = Enum.SortOrder.LayoutOrder
    content_layout.Padding = UDim.new(0, 2)
    content_layout.Parent = content
    
    function keybind_list:add_keybind(name, key)
        local kb_frame = Instance.new("Frame")
        kb_frame.Size = UDim2.new(1, 0, 0, 18)
        kb_frame.BackgroundTransparency = 1
        kb_frame.Parent = content
        
        local kb_name = Instance.new("TextLabel")
        kb_name.Size = UDim2.new(0.6, 0, 1, 0)
        kb_name.BackgroundTransparency = 1
        kb_name.Text = name
        kb_name.TextColor3 = text_color
        kb_name.TextSize = 11
        kb_name.Font = Enum.Font.Code
        kb_name.TextXAlignment = Enum.TextXAlignment.Left
        kb_name.Parent = kb_frame
        
        local kb_key = Instance.new("TextLabel")
        kb_key.Size = UDim2.new(0.4, 0, 1, 0)
        kb_key.Position = UDim2.new(0.6, 0, 0, 0)
        kb_key.BackgroundTransparency = 1
        kb_key.Text = "[on]"
        kb_key.TextColor3 = accent_color
        kb_key.TextSize = 11
        kb_key.Font = Enum.Font.Code
        kb_key.TextXAlignment = Enum.TextXAlignment.Right
        kb_key.Parent = kb_frame
        
        keybind_list.keybinds[name] = {frame = kb_frame, active = true, label = kb_key}
        
        list_frame.Size = UDim2.new(0, 200, 0, 25 + #keybind_list.keybinds * 20)
        
        return kb_frame
    end
    
    function keybind_list:remove_keybind(name)
        if keybind_list.keybinds[name] then
            keybind_list.keybinds[name].frame:Destroy()
            keybind_list.keybinds[name] = nil
            list_frame.Size = UDim2.new(0, 200, 0, 25 + #keybind_list.keybinds * 20)
        end
    end
    
    function keybind_list:toggle_keybind(name, state)
        if keybind_list.keybinds[name] then
            keybind_list.keybinds[name].active = state
            keybind_list.keybinds[name].label.Text = state and "[on]" or "[off]"
            keybind_list.keybinds[name].label.TextColor3 = state and accent_color or disabled_color
        end
    end
    
    function keybind_list:toggle()
        keybind_list.visible = not keybind_list.visible
        list_frame.Visible = keybind_list.visible
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

