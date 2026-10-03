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

-- netrw file explorer (:30Lex to open on the left)
vim.g.netrw_winsize = -30
vim.keymap.set("n", "<leader>e", ":Lex<CR>", { desc = "Open file explorer (netrw)" })

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
        branch = "master",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "python", "lua", "bash", "json", "yaml", "markdown" },
                highlight = { enable = true },
                indent = { enable = true },
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
            { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview: open repo diff" },
            { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "Diffview: close" },
        },
    },
})
