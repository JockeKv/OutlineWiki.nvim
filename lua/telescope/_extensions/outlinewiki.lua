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
		open = function()
		  require("outlinewiki.telescope").open(opts)
		end,
		create = function()
      print("create")
		end,
	},
})

