return {
  'krivahtoo/silicon.nvim',
  run = './install.sh build',
  opts = {
    line_number = true,
    pad_horiz = 60,
    pad_vert = 40,
    gobble = true,
    window_controls = false,
    tab_width = 2,
    font = 'FantasqeSanseMono Nerd Font=26',
    theme = 'catpuccine-mocca',
    window_title = function()
      return vim.fn.fnamemodify(vim.fn.bufname(vim.fn.bufnr()), ':~:.')
    end,
  },
  lazy = true,
  config = function(_, opts)
    require("silicon").setup(opts)
  end,
  cmd = { "Silicon" },
}
