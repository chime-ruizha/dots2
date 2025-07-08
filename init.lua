require 'table'
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    {'nvim-telescope/telescope.nvim',
    	tag = '0.1.8',
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" }},
    {'neovim/nvim-lspconfig'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'hrsh7th/nvim-cmp'},
    {"kylechui/nvim-surround",
        version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
    },
    -- tree
    {"nvim-tree/nvim-tree.lua"},
    -- formatting
    {'darrikonn/vim-gofmt'},
    -- themes
    {"vague2k/vague.nvim"},
    {"neanias/everforest-nvim"},
    {"shaunsingh/nord.nvim"},
})

vim.cmd("colorscheme everforest")

require("nvim-tree").setup()

require('nvim-treesitter.configs').setup({
    ensure_installed = {
        'lua', 'vim', 'vimdoc', 'query', 'markdown',
        'c', 'cpp', 'c_sharp',
        'rust', 'go', 'python', 'java', 'json',
        'terraform', 'yaml'},
    auto_install = true,
    highlight = {
        enable = true,
    }
})

function _G.put(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

function trim(s)
    local str = s
    str = string.gsub(str, "^%s+", "")
    str = string.gsub(str, "%s+$", "")
    return str
end

function gitTopLevel()
    local handle = io.popen('git rev-parse --show-toplevel')
    local topDir = handle:read("*a")
    handle:close()
    return trim(topDir)
end

function getSearchDirectory()
    local gitTop = gitTopLevel()
    if gitTop ~= "" then
        return gitTop
    end
    return vim.loop.cwd()
end

function concat(t1, t2)
    local joined = {}
    for _, i in ipairs(t1) do
        table.insert(joined, i)
    end
    for _, i in ipairs(t2) do
        table.insert(joined, i)
    end
    return joined
end

vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting
vim.o.number = true
vim.o.swapfile = false
vim.g.mapleader = ","

-- [[ telescopes ]]--
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fs', builtin.grep_string, { desc = 'Telescope search for string under cursor' })

-- [[ nvim-tree ]]--
vim.keymap.set('n', '<leader>tt', ":NvimTreeToggle<CR>", { desc = "Toggle nvim-tree" })

function currWord()
    return vim.fn.expand("<cword>")
end

-- [[ LSP ]] --
vim.opt.signcolumn = 'yes'

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lspconfig_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)

-- This is where you enable features that only work
-- if there is a language server active in the file
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = {buffer = event.buf}

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
  end,
})

require('lspconfig').csharp_ls.setup({})
require('lspconfig').gopls.setup({})
require('lspconfig').pylsp.setup({})
-- require('lspconfig').terraform.setup({})

local cmp = require('cmp')

cmp.setup({
    sources = {
        {name = 'nvim_lsp'},
        {name = 'buffer'},
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), 
    }),
})

vim.keymap.set('n', 'fmt', '<cmd>GoFmt<cr>', { desc = 'gofmt' })
