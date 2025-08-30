local query = vim.treesitter.query.parse("nix", [[
  ; query
  (
    (attrset_expression (binding_set
      binding: (binding 
        attrpath: (attrpath) @owner_path
        expression: (string_expression (string_fragment) @owner_value)
      )
      binding: (binding
        attrpath: (attrpath) @repo_path
        expression: (string_expression (string_fragment) @repo_value)
      )
      binding: (binding
        attrpath: (attrpath) @rev_path
        expression: (string_expression (string_fragment) @rev_value)
      )?
    ))

    (#eq? @owner_path "owner")
    (#eq? @repo_path "repo")
    (#eq? @rev_path "rev")
  )
]]
)

local function first_attrset_parent(node) 
  while node ~= nil and node:type() ~= "attrset_expression" do
    node = node:parent()
  end

  return node
end

local root = vim.treesitter.get_parser():parse()[1]:root()

if root == nil then
  vim.notify(
    "Couldn't find parent attrset node",
    vim.log.levels.ERROR
  )
  return
end

local owner = nil
local repo = nil
local rev = nil
local indent_count = nil

for id, node, metadata, match in query:iter_captures(root, 0) do
  root = first_attrset_parent(node) 

  local name = query.captures[id]
  if name == "owner_value" then
    owner = vim.treesitter.get_node_text(node, 0)
  end
  if name == "repo_value" then
    repo = vim.treesitter.get_node_text(node, 0)
  end
  if name == "rev_value" then
    rev = vim.treesitter.get_node_text(node, 0)
  end

  if name == "owner_path" or name == "repo_path" or name == "rev_path" then
    local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, 0)
    indent_count = start_col
  end
  

end

local function cursor_in_node_range(node)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1] - 1
  local col = pos[2]
  local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node, 0)

  if row > start_row and row < end_row then
    return true
  elseif row == start_row then
    return col >= start_col
  elseif row == end_row then
    return col < end_col
  else 
    return false
  end
end

if not cursor_in_node_range(root) then 
  vim.notify(
    "Couldn't find parent attrset node",
    vim.log.levels.ERROR
  )
  return
end

if rev == nil then
  vim.notify(
    "Please specify a `rev`",
    vim.log.levels.ERROR
  )
  return
end

local prefetch_result = vim.system(
  {
    "nix-prefetch-url",
    "https://github.com/" .. owner .. "/" .. repo .. "/commit/" .. rev
  },
  { text = true }
):wait()

local hash = string.sub(prefetch_result.stdout, 0, string.len(prefetch_result.stdout) - 1)
local line = string.rep(" ", indent_count) .. "hash = \"" .. hash .. "\";\n"
vim.fn.setreg("+", line)
vim.notify(
  "Hash copied to clipboard",
  vim.log.levels.INFO
)
