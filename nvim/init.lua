-- Disable netrw (using fzf instead)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.cmd('filetype plugin indent on')
vim.g.pyindent_open_paren = 'shiftwidth()'
vim.opt.confirm = true
vim.opt.number = true
vim.o.mouse = ""

vim.cmd('colorscheme OceanicNext')
vim.opt.colorcolumn = '100'
vim.opt.statusline = "%f %h%m%r%=%-14.(%l,%c%V%) %P"

vim.api.nvim_set_keymap('n', 'Y', '"+y', { noremap = true })
vim.api.nvim_set_keymap('v', 'Y', '"+y', { noremap = true })

vim.api.nvim_set_keymap('i', '<C-f>', '<Right>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('i', '<C-b>', '<Left>', {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', '<C-h>', ':tabprevious<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-l>', ':tabnext<CR>', { noremap = true })

vim.opt.hlsearch = true
vim.api.nvim_set_keymap('n', '<C-[>', ':nohl<CR><C-[>', { noremap = true })

vim.api.nvim_set_keymap('n', '<Leader>h', ':e $HOME/dev/home/home.nix<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>sv', ':source $MYVIMRC<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>cp', ':let @+ = expand("%:p")<CR>', { noremap = true })

vim.api.nvim_set_keymap('n', '<leader>ew', ':e <C-R>=expand("%:p:h") . "/" <CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>ev', ':vsp <C-R>=expand("%:p:h") . "/" <CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>et', ':tabe <C-R>=expand("%:p:h") . "/" <CR>', { noremap = true })

vim.api.nvim_set_keymap('n', '<leader>F', ':Format<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':Files<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>g', ':GFiles<CR>', { noremap = true })

-- Arduino support
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.ino", "*.pde"},
  callback = function()
    vim.bo.filetype = "cpp"
  end
})

-- C++ files use 2 spaces for indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
    vim.bo.tabstop = 2
  end
})
