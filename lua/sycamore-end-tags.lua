local tsutils = require'nvim-treesitter.ts_utils'
local set = {}

set.test = function()
	local function i(value)
		print(vim.inspect(value))
	end

	local ns_id = vim.api.nvim_create_namespace('sycamore_end_tags')

	local bufnr = vim.api.nvim_get_current_buf()
	local root = vim.treesitter.get_parser(bufnr, 'rust'):parse()[1]:root()

	local function get_text(node)
		return vim.treesitter.get_node_text(node, bufnr)
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local view_query = vim.treesitter.query.parse('rust', [[
		(macro_invocation
			macro: (identifier) @macro_name (#eq? @macro_name "view")
			(token_tree) @view_token_tree
		)
	]])

	local html_query = vim.treesitter.query.parse('rust', [[
		(
			(identifier) @html_tag_name
			.
			(
				(token_tree 
					(identifier)? @identifier (#any-of? @identifier "class" "id")
					.
					(string_literal)? @literal)
				.
				(token_tree) @html_token_tree
			)
		)
	]])

	local nodes = {}

	for _, node in view_query:iter_matches(root, bufnr, 0, -1) do
		local macro_name = vim.treesitter.get_node_text(node[1], bufnr)
		local range = {node[2]:range()}
		vim.api.nvim_buf_set_extmark(bufnr, ns_id, range[3], range[4], {
			virt_text = {{'/' .. macro_name, 'Comment'}},
			virt_text_pos = 'eol',
		})

		for _, html_node in html_query:iter_matches(node[2], bufnr, 0, -1) do
			local html_tag_name = get_text(html_node[1])
			local html_identifier = nil
			local html_literal = nil
			local html_token_tree_range = {html_node[4]:range()}

			if html_node[3] ~= nil then
				html_identifier = get_text(html_node[2])
				html_literal = get_text(html_node[3])
			end

			local found = false
			for _, n in ipairs(nodes) do
				if n.html_tag_name == html_tag_name
					and n.html_token_tree_range[1] == html_token_tree_range[1]
					and n.html_token_tree_range[2] == html_token_tree_range[2]
					and n.html_token_tree_range[3] == html_token_tree_range[3]
					and n.html_token_tree_range[4] == html_token_tree_range[4]
				then
					found = true
					for _, literal in ipairs(n.attributes) do
						if literal[1] == html_identifier and literal[2] == html_literal then
							goto continue
						end
					end
					table.insert(n.attributes, {html_identifier, html_literal})
				end
			end

			if not found then
				if html_identifier == nil then
					table.insert(nodes, {
						html_tag_name = html_tag_name,
						html_token_tree_range = html_token_tree_range,
						attributes = {},
					})
				else
					table.insert(nodes, {
						html_tag_name = html_tag_name,
						html_token_tree_range = html_token_tree_range,
						attributes = {{html_identifier, html_literal}},
					})
				end
			end
			::continue::
		end
	end

	for _, node in ipairs(nodes) do
		local range = node.html_token_tree_range
		local attributes = ''
		for _, attribute in ipairs(node.attributes) do
			if attribute[1] == 'id' then
				attributes = attributes .. '#' .. string.gsub(attribute[2], '"', '')
			elseif attribute[1] == 'class' then
				attributes = attributes .. '.' .. string.gsub(string.gsub(attribute[2], '% ', '.'), '"', '')
			end
		end
		vim.api.nvim_buf_set_extmark(bufnr, ns_id, range[3], range[4], {
			virt_text = {{'/' .. node.html_tag_name .. attributes, 'Comment'}},
			virt_text_pos = 'eol',
		})
	end
end

vim.api.nvim_create_autocmd({
	'BufWritePost', 'BufReadPost', 'BufEnter', 'BufWinEnter',
	'TabEnter', 'TextChanged', 'TextChangedI'}, {
	pattern = "*.rs",
	command = "lua require'sycamore-end-tags'.test()",
})

return set
