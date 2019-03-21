local mod = get_mod("HeatIndicator")
--[[
	Heat Indicator
	( Charge Level Indicator. )
	*	When charging the Bolt staff or Fireball staff, a colored marker will be shown on the HUD
		indicating the current 'charge level'.
		The Bolt staff has discrete charge levels, which are shown as: green=1, orange=2, red=3.
		The Fireball staff doesn't have discrete levels and charging just continuously increases
		damage and area, so the levels I've chosen are kind of arbitrary:
		green=(3 <= damage < 5, 0.75 <= area < 2.25), orange=(5 <= damage < 6, 2.25 <= area < 3),
		red=(damage = 6, area = 3). (Where 'damage' means AoE instantaneous damage to normal
		targets, not including impact damage or DoT.)

	Author: walterr
	Ported: grasmann
--]]

local UIResolutionScale = UIResolutionScale or function()
	return RESOLUTION_LOOKUP.scale
end

-- ##### ██████╗  █████╗ ████████╗ █████╗ #############################################################################
-- ##### ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗ ############################################################################
-- ##### ██║  ██║███████║   ██║   ███████║ ############################################################################
-- ##### ██║  ██║██╔══██║   ██║   ██╔══██║ ############################################################################
-- ##### ██████╔╝██║  ██║   ██║   ██║  ██║ ############################################################################
-- ##### ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ############################################################################
local aim_start = nil
mod.anim_state = {
	STARTING = 1,
	ONGOING = 2,
}
mod.current_charge_level = {
	bg_color = Colors.get_color_table_with_alpha("black", 100),
	color = nil,
	fade_out = nil,
	level = nil,
}
mod.widget_settings = {
	-- The charge level indicator is just a rounded rect. The color is set dynamically.
	CHARGE_LEVEL = {
		scenegraph_id = "charge_bar",
		element = {
			passes = {
				{
					pass_type = "rounded_background",
					style_id = "indicator"
				},
			},
		},
		content = {},
		style = {
			indicator = {
				offset = { 230, -45 },
				size = { 48, 48 },
				corner_radius = 24,
			},
		},
	},
}
-- Defines the charge levels for the staffs.
mod.display_info = {
	-- Fireball staff uses this, ActionCharge is defined in
	-- scripts/unit_extensions/weapons/actions/action_charge.lua
	ActionCharge = {
		compute_level_value = function(action)
			if action.overcharge_extension and not action.current_action.vent_overcharge then
				return action.charge_level
			end
			return nil
		end,
		compute_level_color = function(self, charge_value)
			for _, level in ipairs(self.levels) do
				if charge_value >= level.min_value then return level.color end
			end
			return nil
		end,
		levels = {
			{
				min_value = 1,
				color = Colors.get_table("red"),
			},
			{
				min_value = (2/3),
				color = Colors.get_table("orange"),
			},
			{
				min_value = 0,
				color = Colors.get_table("green_yellow"),
			},
		},
	},
	-- Bolt staff uses this, ActionTrueFlightBowAim is defined in
	-- scripts/unit_extensions/weapons/actions/action_true_flight_bow_aim.lua
	ActionTrueFlightBowAim = {
		compute_level_value = function(action)
			return (action.overcharge_extension and action.charge_value) or nil
		end,
		compute_level_color = function(self, charge_value)
			for _, level in ipairs(self.levels) do
				if charge_value >= level.min_value then return level.color end
			end
			return nil
		end,
		levels = {
			{
				min_value = 1,
				color = Colors.get_table("red"),
			},
			{
				min_value = (0.8 / 1.25),
				color = Colors.get_table("orange"),
			},
			{
				min_value = 0,
				color = Colors.get_table("yellow_green"),
			},
		},
	},
	-- Conflag staff uses this, ActionGeiserTargeting is defined in
	-- scripts/unit_extensions/weapons/actions/action_geiser_targeting.lua
	ActionGeiserTargeting = {
		levels = {
			{
				min_value = 1,
				color = Colors.get_table("red"),
			},
			{
				min_value = (1.3 / 1.8),
				color = Colors.get_table("orange"),
			},
			{
				min_value = 0,
				color = Colors.get_table("yellow_green"),
			},
		},
		compute_level_value = function(action)
			return (action.overcharge_extension and action.charge_value) or nil
		end,
		compute_level_color = function(self, charge_value)
			for _, level in ipairs(self.levels) do
				if charge_value >= level.min_value then return level.color end
			end
			return nil
		end,
	},

	ActionAim = {
		compute_level_value = function(action)
			return (action.overcharge_extension and action.charge_value) or nil
		end,
		compute_level_color = function(self, charge_value)
			for _, level in ipairs(self.levels) do
				if charge_value >= level.min_value then return level.color end
			end
			return nil
		end,
		levels = {
			{
				min_value = 1,
				color = Colors.get_table("red"),
			},
			{
				min_value = (2/3),
				color = Colors.get_table("orange"),
			},
			{
				min_value = 0,
				color = Colors.get_table("green_yellow"),
			},
		},
	},
}

-- ##### ██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗ ###################################################################
-- ##### ██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝ ###################################################################
-- ##### ███████║██║   ██║██║   ██║█████╔╝ ███████╗ ###################################################################
-- ##### ██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║ ###################################################################
-- ##### ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║ ###################################################################
-- ##### ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ###################################################################
--[[
	Staff Update widget
--]]
mod:hook_safe(ActionCharge, "client_owner_post_update", function(self)
	local display_info = mod.display_info["ActionCharge"]
	local charge_value = display_info.compute_level_value(self)
	if charge_value then
		mod.current_charge_level.color = display_info:compute_level_color(charge_value)
		mod.current_charge_level.level = charge_value
		mod.current_charge_level.fade_out = nil
	end
end)
--[[
	Staff Start fade out
--]]
mod:hook(ActionCharge, "finish", function(func, self, reason, ...)
	local result = func(self, reason, ...)

	local display_info = mod.display_info["ActionCharge"]
	if reason == "new_interupting_action" then
		local charge_value = display_info.compute_level_value(self)
		if charge_value then
			mod.current_charge_level.color = display_info:compute_level_color(charge_value)
			mod.current_charge_level.level = charge_value
			mod.current_charge_level.fade_out = mod.anim_state.STARTING
		end
	else
		mod.current_charge_level.color = nil
	end

	return result
end)
--[[
	Trueflight update widget
--]]
mod:hook_safe(ActionTrueFlightBowAim, "client_owner_post_update", function (self)
	local display_info = mod.display_info["ActionTrueFlightBowAim"]
	local charge_value = display_info.compute_level_value(self)
	if charge_value then
		mod.current_charge_level.color = display_info:compute_level_color(charge_value)
		mod.current_charge_level.level = charge_value
		mod.current_charge_level.fade_out = nil
	end
end)
--[[
	Truflight start fade out
--]]
mod:hook(ActionTrueFlightBowAim, "finish", function(func, self, reason, ...)
	local result = func(self, reason, ...)

	local display_info = mod.display_info["ActionTrueFlightBowAim"]
	if reason == "new_interupting_action" then
		local charge_value = display_info.compute_level_value(self)
		if charge_value then
			mod.current_charge_level.color = display_info:compute_level_color(charge_value)
			mod.current_charge_level.level = charge_value
			mod.current_charge_level.fade_out = mod.anim_state.STARTING
		end
	else
		mod.current_charge_level.color = nil
	end

	return result
end)
--[[
	Geiser update widget
--]]
mod:hook_safe(ActionGeiserTargeting, "client_owner_post_update", function (self)
	local display_info = mod.display_info["ActionGeiserTargeting"]
	local charge_value = display_info.compute_level_value(self)
	if charge_value then
		mod.current_charge_level.color = display_info:compute_level_color(charge_value)
		mod.current_charge_level.level = charge_value
		mod.current_charge_level.fade_out = nil
	end
end)
--[[
	Geiser start fade out
--]]
mod:hook(ActionGeiserTargeting, "finish", function(func, self, reason, ...)
	local result = func(self, reason, ...)

	local display_info = mod.display_info["ActionGeiserTargeting"]
	if reason == "new_interupting_action" then
		local charge_value = display_info.compute_level_value(self)
		if charge_value then
			mod.current_charge_level.color = display_info:compute_level_color(charge_value)
			mod.current_charge_level.level = charge_value
			mod.current_charge_level.fade_out = mod.anim_state.STARTING
		end
	else
		mod.current_charge_level.color = nil
	end

	return result
end)
--[[
	Fix for vt2 bolt staff
--]]
if not VT1 then
	--[[
		Bolt staff update widget
	--]]
	mod:hook_safe(ActionAim, "client_owner_post_update", function(self, dt_, t)
		if self.item_name == "bw_skullstaff_spear" then
			if not aim_start then aim_start = t end
			local aim_time = t - aim_start
			if aim_time < 0 then aim_time = 0 end
			if aim_time > 2.25 then aim_time = 2.25 end

			local display_info = mod.display_info["ActionAim"]
			-- local charge_value = display_info.compute_level_value(self)
			local charge_value = aim_time / 2.25
			if charge_value then
				self.charge_value = charge_value
				mod.current_charge_level.color = display_info:compute_level_color(charge_value)
				mod.current_charge_level.level = charge_value
				mod.current_charge_level.fade_out = nil
			end
		end
	end)
	--[[
		Bolt staff start fade out
	--]]
	mod:hook(ActionAim, "finish", function(func, self, reason, ...)
		local result = func(self, reason, ...)

		if self.item_name == "bw_skullstaff_spear" then
			if aim_start then aim_start = nil end

			local display_info = mod.display_info["ActionAim"]
			if reason == "new_interupting_action" then
				local charge_value = self.charge_value
				if charge_value then
					mod.current_charge_level.color = display_info:compute_level_color(charge_value)
					mod.current_charge_level.level = charge_value
					mod.current_charge_level.fade_out = mod.anim_state.STARTING
				end
			else
				mod.current_charge_level.color = nil
			end
		end

		return result
	end)

end
--[[
	Render widget
--]]
mod:hook_safe(OverchargeBarUI, "update", function(self, dt, t_, player)
	
	local do_update = VT1 and self:_update_overcharge(player, dt) or 
		mod.current_charge_level.level and mod.current_charge_level.level > 0

	if mod.current_charge_level.color and do_update then
		local widget = self._hudmod_charge_level_indicator
		if not widget then
			-- First use of the charge level indicator, create it now.
			widget = UIWidget.init(mod.widget_settings.CHARGE_LEVEL)
			self._hudmod_charge_level_indicator = widget
		end

		-- Background
		local widget_bg = nil
		if mod:get("mode") == 2 then
			widget_bg = self._hudmod_charge_level_indicator_bg
			if not widget_bg then
				-- First use of the charge level indicator, create it now.
				widget_bg = UIWidget.init(mod.widget_settings.CHARGE_LEVEL)
				self._hudmod_charge_level_indicator_bg = widget_bg
			end
		else
			self._hudmod_charge_level_indicator_bg = nil
		end

		if mod.current_charge_level.fade_out == mod.anim_state.ONGOING and not UIWidget.has_animation(widget) then
			-- Fade-out animation just finished.
			mod.current_charge_level.color = nil
			mod.current_charge_level.fade_out = nil
		else
			if mod.current_charge_level.fade_out == mod.anim_state.STARTING then
				-- Start the fade-out animation.
				local color = table.clone(mod.current_charge_level.color)
				widget.style.indicator.color = color
				UIWidget.animate(widget, UIAnimation.init(UIAnimation.function_by_time, color, 1, 255, 0, 1, math.easeInCubic))

				if widget_bg then
					local bg_color = table.clone(mod.current_charge_level.bg_color)
					widget_bg.style.indicator.color = bg_color
					UIWidget.animate(widget_bg, UIAnimation.init(UIAnimation.function_by_time, bg_color, 1, 100, 0, 1, math.easeInCubic))
				end

				mod.current_charge_level.fade_out = mod.anim_state.ONGOING

			elseif not mod.current_charge_level.fade_out then
				if UIWidget.has_animation(widget) then
					-- A new charge has begun while we're still fading out the last one, cancel animation.
					UIWidget.stop_animations(widget)
				end
				widget.style.indicator.color = mod.current_charge_level.color

				if widget_bg then
					if UIWidget.has_animation(widget_bg) then
						UIWidget.stop_animations(widget_bg)
					end
					widget_bg.style.indicator.color = mod.current_charge_level.bg_color
				end
			end

			-- Change size and appearance
			if mod:get("mode") == 1 then
				-- Rectangle
				widget.style.indicator.size[1] = 48
				widget.style.indicator.size[2] = 48
				if VT1 then
					widget.style.indicator.offset[1] = 232
					widget.style.indicator.offset[2] = -45
				else
					widget.style.indicator.offset[1] = 105
					widget.style.indicator.offset[2] = -65
				end
				widget.style.indicator.corner_radius = 5
			elseif mod:get("mode") == 2 then
				-- Line
				local screen_w, screen_h = UIResolution()
				local scale = UIResolutionScale()
				local length = (screen_w * mod:get("line_size")) * mod.current_charge_level.level
				local height = 4 * scale
				widget.style.indicator.size[1] = length
				widget.style.indicator.size[2] = height
				if VT1 then
					widget.style.indicator.offset[1] = 255 - (length / 2)
					widget.style.indicator.offset[2] = 0 - (height / 2)
				else
					widget.style.indicator.offset[1] = 130 - (length / 2)
					widget.style.indicator.offset[2] = -50 - (height / 2)
				end
				-- widget.style.indicator.offset[1] = 255 - (length / 2)
				-- widget.style.indicator.offset[2] = 0 - (height / 2)
				widget.style.indicator.corner_radius = 2
				-- Background
				if widget_bg then
					length = (screen_w * mod:get("line_size")) + 4
					height = 8 * scale
					widget_bg.style.indicator.size[1] = length
					widget_bg.style.indicator.size[2] = height
					if VT1 then
						widget_bg.style.indicator.offset[1] = 255 - (length / 2)
						widget_bg.style.indicator.offset[2] = 0 - (height / 2)
					else
						widget_bg.style.indicator.offset[1] = 130 - (length / 2)
						widget_bg.style.indicator.offset[2] = -50 - (height / 2)
					end
					widget_bg.style.indicator.corner_radius = 2
				end
			end

			-- Draw the charge level indicator.
			local input_service = self.input_manager:get_service("ingame_menu")
			local ui_renderer = self.ui_renderer
			UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt, nil, self.render_settings)
			if widget_bg then
				UIRenderer.draw_widget(ui_renderer, widget_bg)
			end
			UIRenderer.draw_widget(ui_renderer, widget)
			UIRenderer.end_pass(ui_renderer)
		end
	end

end)

-- ##### ███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗ #########################################################
-- ##### ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝ #########################################################
-- ##### █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗ #########################################################
-- ##### ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║ #########################################################
-- ##### ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║ #########################################################
-- ##### ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ #########################################################
--[[
	Mod Setting changed
--]]
mod.on_setting_changed = function(setting_name)
	mod._hudmod_charge_level_indicator = nil
	mod._hudmod_charge_level_indicator_bg = nil
end

mod._hudmod_charge_level_indicator = nil
mod._hudmod_charge_level_indicator_bg = nil