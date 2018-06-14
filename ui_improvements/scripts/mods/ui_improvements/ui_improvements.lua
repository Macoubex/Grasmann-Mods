local mod = get_mod("ui_improvements")
--[[
	Author: grasmann

	Lets you switch equippment of all characters / classes in inventory

	Version: 1.0.3
--]]

-- ##### ██████╗  █████╗ ████████╗ █████╗ #############################################################################
-- ##### ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗ ############################################################################
-- ##### ██║  ██║███████║   ██║   ███████║ ############################################################################
-- ##### ██║  ██║██╔══██║   ██║   ██╔══██║ ############################################################################
-- ##### ██████╔╝██║  ██║   ██║   ██║  ██║ ############################################################################
-- ##### ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ############################################################################
-- Custom theme for highlighting
mod.simple_ui = nil --get_mod("SimpleUI")
mod.custom_theme = nil --table.clone(simple_ui.themes.default.default)
--mod.custom_theme.color_text = mod.custom_theme.color_text_clicked
mod.character_window = nil
mod.career_window = nil
mod.actual_profile_index = nil
mod.profile_index = nil
mod.actual_career_index = nil
mod.career_index = nil
mod.orig_profile_by_peer = nil
mod.orig_get_career = nil
mod.sub_screen = "equipment"
mod.reload_loot = false
mod.characters = {
	{
		name = "Victor Saltzpyre",
		button_width = 145,
		character_index = 1,
	},
	{
		name = "Sienna Fuegonasus",
		button_width = 165,
		character_index = 2,
	},
	{
		name = "Bardin Goreksson",
		button_width = 155,
		character_index = 3,
	},
	{
		name = "Kerillian",
		button_width = 80,
		character_index = 4,
	},
	{
		name = "Markus Kruber",
		button_width = 130,
		character_index = 5,
	},
}
mod.careers = {
	{
		{
			name = "Witch Hunter Captain",
			button_width = 190,
			character_index = 1,
			career_index = 1,
		},
		{
			name = "Bounty Hunter",
			button_width = 130,
			character_index = 1,
			career_index = 2,
		},
		{
			name = "Zealot",
			button_width = 70,
			character_index = 1,
			career_index = 3,
		},
	},
	{
		{
			name = "Battle Wizard",
			button_width = 130,
			character_index = 2,
			career_index = 1,
		},
		{
			name = "Pyromancer",
			button_width = 110,
			character_index = 2,
			career_index = 2,
		},
		{
			name = "Unchained",
			button_width = 100,
			character_index = 2,
			career_index = 3,
		},
	},
	{
		{
			name = "Ranger Veteran",
			button_width = 140,
			character_index = 3,
			career_index = 1,
		},
		{
			name = "Ironbreaker",
			button_width = 110,
			character_index = 3,
			career_index = 2,
		},
		{
			name = "Slayer",
			button_width = 70,
			character_index = 3,
			career_index = 3,
		},
	},
	{
		{
			name = "Waystalker",
			button_width = 110,
			character_index = 4,
			career_index = 1,
		},
		{
			name = "Handmaiden",
			button_width = 120,
			character_index = 4,
			career_index = 2,
		},
		{
			name = "Shade",
			button_width = 70,
			character_index = 4,
			career_index = 3,
		},
	},
	{
		{
			name = "Mercenary",
			button_width = 100,
			character_index = 5,
			career_index = 1,
		},
		{
			name = "Huntsman",
			button_width = 100,
			character_index = 5,
			career_index = 2,
		},
		{
			name = "Foot Knight",
			button_width = 110,
			character_index = 5,
			career_index = 3,
		},
	},
}
mod.window_settings = {
	loadout = "equipment",
	talents = "talents",
	crafting = "forge",
	cosmetics_loadout = "cosmetics",
}

-- ##### ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗ ###################################
-- ##### ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝ ###################################
-- ##### █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗ ###################################
-- ##### ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║ ###################################
-- ##### ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║ ###################################
-- ##### ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝ ###################################
--[[
	Get hero view and check if view is open
--]]
mod.get_hero_view = function(self)
	local matchmaking_manager = Managers.matchmaking
	local ingame_ui = matchmaking_manager and matchmaking_manager._ingame_ui
	local hero_view_active = ingame_ui and ingame_ui.current_view == "hero_view"
	local hero_view = hero_view_active and ingame_ui.views["hero_view"]
	return hero_view
end
--[[
	Create character selection window
--]]
mod.create_character_window = function(self)

	if mod.simple_ui and not self.character_window then

		local feedback = function(self)
			local hero_view = mod:get_hero_view()

			if hero_view then

				local ingame_ui_context = hero_view.ingame_ui_context

				-- Set selected profile index
				local index = self.params
				mod.profile_index = index

				-- Backup orig profile function
				if not mod.orig_profile_by_peer then
					mod.orig_profile_by_peer = ingame_ui_context.profile_synchronizer.profile_by_peer
				end

				-- Set selected career index
				local profile_settings = SPProfiles[index]
				local display_name = profile_settings.display_name
				local hero_attributes = Managers.backend:get_interface("hero_attributes")
				local career_index = not mod.orig_get_career and hero_attributes:get(display_name, "career") or mod.orig_get_career(hero_attributes, display_name, "career")
				mod.career_index = career_index

				-- Overwrite profile function
				ingame_ui_context.profile_synchronizer.profile_by_peer = function(self, peer_id, local_player_id)
					return index
				end

				-- Backup original career function
				if not mod.orig_get_career then
					mod.orig_get_career = Managers.backend._interfaces["hero_attributes"].get
				end

				-- Overwrite career function
				Managers.backend._interfaces["hero_attributes"].get = function(self, hero_name, attribute_name)
					if attribute_name == "career" then
						return career_index
					end
					return mod.orig_get_career(self, hero_name, attribute_name)
				end

				-- Reopen view
				--hero_view:_change_screen_by_index(mod.window_index)
				hero_view:_change_screen_by_name("overview", mod.sub_screen)

				-- Reload career window
				mod.career_window:destroy()
				mod.career_window = nil
				mod:create_career_window(index)

				-- Update button highlighting
				for _, button in pairs(mod.character_window.widgets) do
					if button.params == index then
						button.theme = mod.custom_theme
					else
						button:refresh_theme()
					end
				end

			end
		end

		-- Get some shit
		local scale = UIResolutionScale()
		local screen_width, screen_height = UIResolution()
		local window_size = {705, 40}
		local window_position = {120, screen_height - window_size[2] - 5}
		local player = Managers.player:local_player()
		local profile_index = player:profile_index()

		-- Create window
		self.character_window = mod.simple_ui:create_window("ui_improvements_character", window_position, window_size)

		self.character_window.position = {120*scale, screen_height - window_size[2]*scale - 5}

		-- Create buttons
		local pos_x = 5
		for _, character in pairs(self.characters) do

			local button = self.character_window:create_button("ui_improvements_character_"..character.name, {pos_x, 5}, {character.button_width, 30}, nil, character.name, character.character_index)
			button.on_click = feedback
			if profile_index == character.character_index then
				button.theme = mod.custom_theme
			end

			pos_x = pos_x + character.button_width + 5

		end

		self.character_window.on_hover_enter = function(window)
			window:focus()
		end

		-- Initialize window
		self.character_window:init()

	end

end
--[[
	Create career selection window
--]]
mod.create_career_window = function(self, profile_index)

	if mod.simple_ui and not self.career_window then

		local feedback = function(self)
			local hero_view = mod:get_hero_view()

			if hero_view then

				local ingame_ui_context = hero_view.ingame_ui_context

				-- Set selected profile index
				local index = self.params[1]
				mod.profile_index = index

				-- Set selected career index
				local career_index = self.params[2]
				mod.career_index = career_index

				-- Backup orig profile function
				if not mod.orig_profile_by_peer then
					mod.orig_profile_by_peer = ingame_ui_context.profile_synchronizer.profile_by_peer
				end

				-- Overwrite profile function
				ingame_ui_context.profile_synchronizer.profile_by_peer = function(self, peer_id, local_player_id)
					return index
				end

				-- Backup original career function
				if not mod.orig_get_career then
					mod.orig_get_career = Managers.backend._interfaces["hero_attributes"].get
				end

				-- Overwrite career function
				Managers.backend._interfaces["hero_attributes"].get = function(self, hero_name, attribute_name)
					if attribute_name == "career" then
						return career_index
					end
					return mod.orig_get_career(self, hero_name, attribute_name)
				end

				-- Reopen view
				--hero_view:_change_screen_by_index(mod.window_index)
				hero_view:_change_screen_by_name("overview", mod.sub_screen)

				-- Reload career window
				mod.career_window:destroy()
				mod.career_window = nil
				mod:create_career_window(index)

			end
		end


		-- Get real career index
		local player = Managers.player:local_player()
		local career_index = player:career_index()
		local careers = self.careers[profile_index]

		-- Get some shit
		local scale = UIResolutionScale()
		local screen_width, screen_height = UIResolution()
		-- local screen_width = RESOLUTION_LOOKUP.res_w
		-- local screen_height = RESOLUTION_LOOKUP.res_h
		local window_width = 5
		-- Get size
		if careers then
			for _, career in pairs(careers) do
				window_width = window_width + career.button_width + 5
			end
		end
		local window_size = {window_width, 40}
		local window_position = {120, screen_height - window_size[2]*2 - 5}

		-- Create window
		self.career_window = mod.simple_ui:create_window("ui_improvements_career", window_position, window_size)

		self.career_window.position = {120*scale, screen_height - (window_size[2]*2)*scale - 5}

		-- Create buttons

		if careers then

			local pos_x = 5
			local index = 1
			for _, career in pairs(careers) do

				local button = self.career_window:create_button("ui_improvements_career_"..career.name, {pos_x, 5}, {career.button_width, 30}, nil, career.name, {career.character_index, career.career_index})
				button.on_click = feedback
				if index == career_index then
					button.theme = mod.custom_theme
				end

				pos_x = pos_x + career.button_width + 5
				index = index + 1

			end

		end

		self.career_window.on_hover_enter = function(window)
			window:focus()
		end

		-- Initialize window
		self.career_window:init()

	end

end
--[[
	Reload windows
--]]
mod.reload_windows = function(self)
	self:destroy_windows()
	-- Character
	self:create_character_window()
	-- Career
	local player = Managers.player:local_player()
	local profile_index = player:profile_index()
	self:create_career_window(profile_index)
end
--[[
	Destroy windows
--]]
mod.destroy_windows = function(self)
	if self.character_window then
		self.character_window:destroy()
		self.character_window = nil
	end
	if self.career_window then
		self.career_window:destroy()
		self.career_window = nil
	end
end

-- ##### ██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗ ###################################################################
-- ##### ██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝ ###################################################################
-- ##### ███████║██║   ██║██║   ██║█████╔╝ ███████╗ ###################################################################
-- ##### ██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║ ###################################################################
-- ##### ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║ ###################################################################
-- ##### ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ###################################################################
--[[
	Delete windows when opening loot window
--]]
mod:hook_safe(HeroViewStateLoot, "on_enter", function()
	mod:destroy_windows()
end)
--[[
	Set current sub screen in hero view
--]]
mod:hook_safe(HeroViewStateOverview, "_change_window", function(self, window_index_, window_name)
	mod.sub_screen = mod.window_settings[window_name] or mod.sub_screen
end)
--[[
	Render correct item tooltips
--]]
mod:hook(UIPasses.item_tooltip, "draw", function(func, ...)
	local player = Managers.player:local_player()
	local orig_profile_index, orig_career_index

	-- Overwrite profile function
	orig_profile_index = player.profile_index
	player.profile_index = function(self)
		return mod.profile_index or orig_profile_index(self)
	end

	-- Overwrite career function
	orig_career_index = player.career_index
	player.career_index = function(self)
		return mod.career_index or orig_career_index(self)
	end

	-- Original function
	func(...)

	-- Reset functions
	player.profile_index = orig_profile_index
	player.career_index = orig_career_index

end)
--[[
	Prevent equipment to be destroyed and spawned when not active character
--]]
mod:hook(SimpleInventoryExtension, "create_equipment_in_slot", function(func, ...)
	local player = Managers.player:local_player()
	-- If profile / career doesn't equal actual value cancel
	if mod.profile_index ~= mod.actual_profile_index or mod.career_index ~= mod.actual_career_index then
		return
	end
	func(...)
end)
--[[
	Get correct items for selected character
--]]
mod:hook(ItemGridUI, "_get_items_by_filter", function(func, self, ...)
	local player = Managers.player:local_player()
	local orig_profile_index, orig_career_index

	-- Backup profile function
	orig_profile_index = player.profile_index
	player.profile_index = function(self)
		return mod.profile_index or orig_profile_index(self)
	end

	-- Backup career function
	orig_career_index = player.career_index
	player.career_index = function(self)
		return mod.career_index or orig_career_index(self)
	end

	-- Orig function
	local items = func(self, ...)

	-- Reset functions
	player.profile_index = orig_profile_index
	player.career_index = orig_career_index

	return items
end)
--[[
	Create window when opening hero view
--]]
mod:hook_safe(HeroView, "on_enter", function()
	-- Set values
	local player = Managers.player:local_player()
	mod.actual_profile_index = player:profile_index()
	mod.profile_index = mod.actual_profile_index
	mod.actual_career_index = player:career_index()
	mod.career_index = mod.actual_career_index
	-- Reload window
	mod:reload_windows()
end)
--[[
	Create window when unsuspending hero view
--]]
mod:hook_safe(HeroView, "unsuspend", function()
	-- Reload window
	mod:reload_windows()
end)
--[[
	Destroy window when closing hero view
--]]
mod:hook(HeroView, "on_exit", function(func, self)
	-- Reset profile function
	if mod.orig_profile_by_peer then
		self.ingame_ui_context.profile_synchronizer.profile_by_peer = mod.orig_profile_by_peer
		mod.orig_profile_by_peer = nil
	end
	-- Reset career function
	if mod.orig_get_career then
		Managers.backend._interfaces["hero_attributes"].get = mod.orig_get_career
		mod.orig_get_career = nil
	end
	mod.profile_index = nil
	mod.career_index = nil
	-- Orig function
	func(self)
	-- Destroy window
	mod:destroy_windows()
end)

-- ##### ███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗ #########################################################
-- ##### ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝ #########################################################
-- ##### █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗ #########################################################
-- ##### ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║ #########################################################
-- ##### ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║ #########################################################
-- ##### ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ #########################################################
mod.on_all_mods_loaded = function()
	mod.simple_ui = get_mod("SimpleUI")
	mod.custom_theme = table.clone(mod.simple_ui.themes.default.default)
	mod.custom_theme.color_text = mod.custom_theme.color_text_clicked
end
