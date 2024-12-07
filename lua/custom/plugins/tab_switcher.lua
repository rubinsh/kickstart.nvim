-- Author: rubinsh
--
-- Description: A simple tab switcher for neovim using telescope.
-- This script creates a new command `SwitchTabs` which opens a telescope picker
-- showing all the tabs and their windows. The user can then select a tab to switch to.
-- The picker shows the tab number and the name of the first window in the tab.
-- The user can also use the keybinding `<leader>st` to open the picker.
--
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local previewers = require 'telescope.previewers'

local function switch_tabs()
  local tabs = vim.api.nvim_list_tabpages()
  local tab_entries = {}

  for _, tab in ipairs(tabs) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local wins = vim.api.nvim_tabpage_list_wins(tab)
    local win_entries = {}
    local tabname = ''

    for _, win in ipairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      local bufname = vim.api.nvim_buf_get_name(buf)
      table.insert(win_entries, bufname)
      if tabname == '' then
        tabname = bufname
      end
    end

    table.insert(tab_entries, { tab = tab, tabnr = tabnr, tabname = tabname, win_entries = win_entries })
  end

  local function previewer_maker(entry, bufnr)
    local output = string.format('Tab page %d\n', entry.tabnr)
    for _, bufname in ipairs(entry.win_entries) do
      output = output .. '    ' .. bufname .. '\n'
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(output, '\n'))
  end

  pickers
    .new({}, {
      prompt_title = 'Switch Tabs',
      finder = finders.new_table {
        results = tab_entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format('Tab %d: %s', entry.tabnr, entry.tabname),
            ordinal = tostring(entry.tabnr),
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        define_preview = function(self, entry, status)
          previewer_maker(entry.value, self.state.bufnr)
        end,
      },
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.api.nvim_set_current_tabpage(selection.value.tab)
        end)
        return true
      end,
    })
    :find()
end

vim.api.nvim_create_user_command('SwitchTabs', switch_tabs, {})
vim.api.nvim_set_keymap('n', '<leader>st', ':SwitchTabs<CR>', { desc = '[S]witch [T]abs', noremap = true, silent = true })
