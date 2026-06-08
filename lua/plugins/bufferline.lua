return {
	{
		"akinsho/bufferline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- Ensure devicons is loaded as a dependency
		opts = function()
			-- Define your color palette here
			local active_bg = "#0077b6"   -- Solid blue for active tab
			local active_fg = "#ffffff"   -- White text for active tab
			local inactive_bg = "#001824" -- Dark navy blue (simulating ~15% opacity of your active blue over black)
			local inactive_fg = "#6e8294" -- Desaturated, dimmed blue-gray for inactive text
			local fill_bg = "#000000"     -- Pure black for the rest of the tabline

			-- Helper function to apply matching backgrounds to all elements of a tab
			local function generate_uniform_highlights()
				local hl = {
					fill = { fg = fill_bg, bg = fill_bg },
				}

				-- Elements for inactive buffers
				local inactive_elements = {
					"background", "numbers", "close_button", "modified", "duplicate", "pick", 
					"separator", "indicator_visible", "tab", "tab_separator", "tab_close",
					"diagnostic", "error", "error_diagnostic", "warning", "warning_diagnostic", 
					"info", "info_diagnostic", "hint", "hint_diagnostic"
				}

				for _, el in ipairs(inactive_elements) do
					hl[el] = { bg = inactive_bg }
					if el == "background" or el == "numbers" or el == "close_button" or el == "modified" then
						hl[el].fg = inactive_fg
					elseif el == "duplicate" then
						hl[el].fg = inactive_fg
						hl[el].italic = true
					elseif el == "pick" then
						hl[el].fg = inactive_fg
						hl[el].bold = true
					elseif el == "separator" then
						hl[el].fg = fill_bg -- The slant glyph foreground matches the black fill background
					elseif el == "indicator_visible" then
						hl[el].fg = inactive_bg
					end
				end

				-- Elements for visible (but unselected) buffers
				local visible_elements = {
					"buffer_visible", "numbers_visible", "close_button_visible", "modified_visible", 
					"duplicate_visible", "pick_visible", "separator_visible",
					"diagnostic_visible", "error_visible", "error_diagnostic_visible", 
					"warning_visible", "warning_diagnostic_visible", "info_visible", 
					"info_diagnostic_visible", "hint_visible", "hint_diagnostic_visible"
				}

				for _, el in ipairs(visible_elements) do
					hl[el] = { bg = inactive_bg }
					if el == "buffer_visible" or el == "numbers_visible" or el == "close_button_visible" or el == "modified_visible" then
						hl[el].fg = inactive_fg
					elseif el == "duplicate_visible" then
						hl[el].fg = inactive_fg
						hl[el].italic = true
					elseif el == "pick_visible" then
						hl[el].fg = inactive_fg
						hl[el].bold = true
					elseif el == "separator_visible" then
						hl[el].fg = fill_bg
					end
				end

				-- Elements for selected (active) buffers
				local selected_elements = {
					"buffer_selected", "numbers_selected", "close_button_selected", "modified_selected", 
					"duplicate_selected", "pick_selected", "separator_selected", "indicator_selected",
					"tab_selected", "tab_separator_selected",
					"diagnostic_selected", "error_selected", "error_diagnostic_selected", 
					"warning_selected", "warning_diagnostic_selected", "info_selected", 
					"info_diagnostic_selected", "hint_selected", "hint_diagnostic_selected"
				}

				for _, el in ipairs(selected_elements) do
					hl[el] = { bg = active_bg }
					if el == "buffer_selected" or el == "numbers_selected" then
						hl[el].fg = active_fg
						hl[el].bold = true
					elseif el == "close_button_selected" or el == "modified_selected" then
						hl[el].fg = active_fg
					elseif el == "duplicate_selected" then
						hl[el].fg = active_fg
						hl[el].italic = true
					elseif el == "pick_selected" then
						hl[el].fg = active_fg
						hl[el].bold = true
					elseif el == "separator_selected" then
						hl[el].fg = fill_bg -- The empty line background cuts into the active tab to make the slant shape
					elseif el == "indicator_selected" then
						hl[el].fg = active_bg -- Blends the vertical indicator bar away, leaving only the slant shape as the active highlight
					end
				end

				return hl
			end

			return {
				options = {
					separator_style = "slant",
				},
				highlights = generate_uniform_highlights(),
			}
		end,
		config = function(_, opts)
			require("bufferline").setup(opts)
		end,
	},
}
