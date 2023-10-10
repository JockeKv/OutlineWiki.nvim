local opts = {}
return require("telescope").register_extension({
	setup = function(ext_config, config)
		-- access extension config and user config
		ext_config = ext_config or {}
		config = config or {}
		for key, value in pairs(config) do
			opts[key] = value
		end
	end,
	exports = {
		list = function()
			print("Start")
		end,
		save = function()
      print("Save")
		end,
	},
})
