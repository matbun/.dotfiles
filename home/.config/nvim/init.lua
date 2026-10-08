vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.cmd.colorscheme("sorbet")

-- nvim-tree replaces netrw (it needs netrw disabled before it loads)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- built-in terminal in a bottom split; <Esc><Esc> returns to normal mode
vim.keymap.set("n", "<leader>t", "<cmd>botright 15split | terminal<CR>i", { desc = "Open terminal" })
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>q", "<cmd>qa<CR>", { desc = "Quit all" })

vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

require("lazy").setup({
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files)
            vim.keymap.set("n", "<leader>fg", builtin.live_grep)
            vim.keymap.set("n", "<leader>fb", builtin.buffers)
            vim.keymap.set("n", "<leader>fh", builtin.help_tags)
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install({ "python", "lua", "bash", "json", "yaml", "markdown", "markdown_inline" })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "python", "lua", "sh", "json", "yaml", "markdown" },
                callback = function()
                    vim.treesitter.start()
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
    },
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                on_attach = function(bufnr)
                    local gs = require("gitsigns")
                    local function map(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                    end

                    map("n", "]h", gs.next_hunk, "Next git hunk")
                    map("n", "[h", gs.prev_hunk, "Prev git hunk")

                    map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
                    map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
                    map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
                    map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
                    map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
                    map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
                    map("n", "<leader>hd", gs.diffthis, "Diff file vs index")
                    map("n", "<leader>hb", gs.blame_line, "Blame line")
                    map("n", "<leader>hq", gs.setqflist, "Hunks to quickfix (repo-wide)")
                end,
            })
        end,
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        keys = {
            { "<leader>gd", "<cmd>DiffviewOpen -u<CR>", desc = "Diffview: open repo diff (incl. untracked)" },
            { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "Diffview: close" },
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        lazy = false,
        keys = {
            { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
        },
        config = function()
            require("nvim-tree").setup({
                view = { width = 30 },
                git = { enable = true, ignore = false },
                renderer = {
                    highlight_git = "name",
                    icons = { show = { file = false, folder = false, folder_arrow = false } },
                },
            })
        end,
    },
})
