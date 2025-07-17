return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      -- local function map(mode, l, r, opts)
      --   opts = opts or {}
      --   opts.buffer = bufnr
      --   vim.keymap.set(mode, l, r, opts)
      -- end
      --
      -- -- Navigation
      -- map('n', ']c', function()
      --   if vim.wo.diff then
      --     vim.cmd.normal({']c', bang = true})
      --   else
      --     gs.next_hunk()
      --   end
      -- end, { desc = 'Next git hunk' })
      --
      -- map('n', '[c', function()
      --   if vim.wo.diff then
      --     vim.cmd.normal({'[c', bang = true})
      --   else
      --     gs.prev_hunk()
      --   end
      -- end, { desc = 'Previous git hunk' })
      --
      -- -- Actions
      -- map('n', '<leader>gs', gs.stage_hunk, { desc = 'Stage hunk' })
      -- map('n', '<leader>gr', gs.reset_hunk, { desc = 'Reset hunk' })
      --
      -- map('v', '<leader>gs', function()
      --   gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      -- end, { desc = 'Stage selected hunk' })
      --
      -- map('v', '<leader>gr', function()
      --   gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      -- end, { desc = 'Reset selected hunk' })
      --
      -- map('n', '<leader>gS', gs.stage_buffer, { desc = 'Stage buffer' })
      -- map('n', '<leader>gR', gs.reset_buffer, { desc = 'Reset buffer' })
      -- map('n', '<leader>gp', gs.preview_hunk, { desc = 'Preview hunk' })
      -- map('n', '<leader>gi', gs.preview_hunk_inline, { desc = 'Preview hunk inline' })
      --
      -- map('n', '<leader>gb', function()
      --   gs.blame_line({ full = true })
      -- end, { desc = 'Blame line' })
      --
      -- map('n', '<leader>gd', gs.diffthis, { desc = 'Diff this' })
      --
      -- map('n', '<leader>gD', function()
      --   gs.diffthis('~')
      -- end, { desc = 'Diff this ~' })
      --
      -- map('n', '<leader>gQ', function() gs.setqflist('all') end, { desc = 'Send all hunks to quickfix' })
      -- map('n', '<leader>gq', gs.setqflist, { desc = 'Send hunks to quickfix' })
      --
      -- -- Toggles
      -- map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'Toggle current line blame' })
      -- map('n', '<leader>td', gs.toggle_deleted, { desc = 'Toggle deleted' })
      -- map('n', '<leader>tw', gs.toggle_word_diff, { desc = 'Toggle word diff' })
      --
      -- -- Text object
      -- map({'o', 'x'}, 'ih', gs.select_hunk, { desc = 'Select hunk' })
    end,
  },
}
