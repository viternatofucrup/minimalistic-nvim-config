-- my alter
vim.g.mapleader = " "                              -- Set leader key to space
vim.g.maplocalleader = " "                         -- Set local leader key (NEW)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename)

local function get_bookmarks()
  local cfg = require("bookmarks.config").config
  local data = cfg.cache and cfg.cache.data or {}
  local lines = {}

  for filepath, marks in pairs(data) do
    for lnum, mark in pairs(marks or {}) do
      -- build a display string; tweak as you like
      local disp = string.format("%s:%s: %s",
        filepath,
        lnum,
        (mark.a or mark.m or ""):gsub("\n", " ")
      )
      table.insert(lines, disp)
    end
  end

  return lines
end

local function fzf(ags)
	local r = {}
	if vim.startswith(ags, "b:") then

	else
		local h = io.popen("fd -t f .")
		if h then
			for l in h:lines() do
				if l:lower():find(ags:lower(), 1, false) then
					table.insert(r, l)
				end
			end
			h:close()
		end
		return r
	end
end

local function vv_hh_tt_common(cmd)
	local function open_files(fs)
		if #fs == 0 then
			return
		end

		local is_empty = vim.api.nvim_buf_get_name(0) == ""

		if is_empty then
			vim.cmd("edit " .. vim.fn.fnameescape(fs[1]))
		else
			vim.cmd(cmd .. vim.fn.fnameescape(fs[1]))
		end

		for i = 2, #fs do
			vim.cmd(cmd .. vim.fn.fnameescape(fs[i]))
		end
	end

	return function(o)
		local fs = o.fargs

		if #fs > 0 then
			open_files(fs)
			return
		else
			local ok, bi = pcall(require, "telescope.builtin")
			if not ok then
				print("telescope.builtin not found")
				return
			end

			bi.find_files({
				cwd = vim.fn.getcwd(),
				attach_mappings = function(prompt_bufnr, map)
					local actions = require("telescope.actions")
					local action_state = require("telescope.actions.state")

					local function open_logic()
						local picker = action_state.get_current_picker(prompt_bufnr)
						local multi = picker:get_multi_selection()
						local selected_files = {}

						-- if nothing is in multi-selection, fall back to the single highlighted entry
						if #multi == 0 then
							local entry = action_state.get_selected_entry()
							if entry then
								multi = { entry }
							end
						end

						for _, entry in ipairs(multi) do
							-- for find_files, `entry.path` is usually the full path
							local path = entry.path or entry.filename or entry.value
							if path then
								table.insert(selected_files, path)
							end
						end

						actions.close(prompt_bufnr)

						-- reuse the same logic as when files come from opts.fargs
						open_files(selected_files)
					end

					-- override <CR> in insert and normal mode to open all selected files
					map("i", "<CR>", open_logic)
					map("n", "<CR>", open_logic)

					return true
				end,
			})
		end
	end
end

vim.api.nvim_create_user_command(
	"Hh",
	vv_hh_tt_common("horizontal split "),
	{ nargs = "*", complete = fzf, }
)
vim.cmd([[
cnoreabbrev <expr> hh (getcmdtype() == ':' && getcmdline() ==# 'hh') ? 'Hh' : 'hh'
]])
vim.keymap.set("n", "<leader>hh", "<cmd>Hh<cr>", { desc = "Hh" })

vim.api.nvim_create_user_command(
	"Vv",
	vv_hh_tt_common("vertical split "),
	{ nargs = "*", complete = fzf, }
)
vim.cmd([[
cnoreabbrev <expr> vv (getcmdtype() == ':' && getcmdline() ==# 'vv') ? 'Vv' : 'vv'
]])
vim.keymap.set("n", "<leader>vv", "<cmd>Vv<cr>", { desc = "Vv" })

vim.api.nvim_create_user_command(
	"Tt",
	vv_hh_tt_common("tabnew "),
	{ nargs = "*", complete = fzf, }
)
vim.cmd([[
cnoreabbrev <expr> tt (getcmdtype() == ':' && getcmdline() ==# 'tt') ? 'Tt' : 'tt'
]])
vim.keymap.set("n", "<leader>tt", "<cmd>Tt<cr>", { desc = "Tt" })

vim.api.nvim_create_user_command(
	"Th",
	function(o)
		vim.cmd("tabnew")
		vv_hh_tt_common("horizontal split ")(o)
	end,
	{ nargs = "*", complete = fzf, }
)
vim.cmd([[
cnoreabbrev <expr> th (getcmdtype() == ':' && getcmdline() ==# 'th') ? 'Th' : 'th'
]])
vim.keymap.set("n", "<leader>th", "<cmd>Th<cr>", { desc = "Th" })

vim.keymap.set("n", "<leader>bb", "<cmd>ls<CR>", { desc = "Buffer list" })
vim.keymap.set("n", "<leader>bj", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bk", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bq", "<cmd>bn | confirm bd #<CR>", { desc = "Close buffer" })

vim.keymap.set("n", "<A-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<A-k>", "<C-w>k", { desc = "Move to top window" })

vim.keymap.set("n", "<A-h>", function()
	local curwin = vim.api.nvim_get_current_win()
	vim.cmd("wincmd h")                      -- try to move right
	if vim.api.nvim_get_current_win() == curwin then
		vim.cmd("tabprev")                     -- if window didn't change → go to next tab
	end
end, { desc = "Left window or prev tab" })
vim.keymap.set("n", "<A-l>", function()
	local curwin = vim.api.nvim_get_current_win()
	vim.cmd("wincmd l")                      -- try to move right
	if vim.api.nvim_get_current_win() == curwin then
		vim.cmd("tabnext")                     -- if window didn't change → go to next tab
	end
end, { desc = "Right window or next tab" })

vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", { fg="white" })
		vim.wo.winhighlight = ""
	end,
})
vim.api.nvim_create_autocmd("WinLeave", {
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", { fg="gray" })
		vim.wo.winhighlight = "Normal:DimNormal"
	end,
})
vim.api.nvim_set_hl(0, "DimNormal", { bg = "#1e1e1e" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
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

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "plugins" },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "habamax" } },
	-- automatically check for plugin updates
	checker = { enabled = false },
})

-- ================================================================================================
-- title : Suckless NeoVim Config
-- author: Radley E. Sidwell-lewis
-- ================================================================================================

-- transparency
-- vim.api.nvim_set_hl(0, "Normal", {bg="none"})
-- vim.api.nvim_set_hl(0, "NormalNC", {bg="none"})
-- vim.api.nvim_set_hl(0, "EndOfBuffer", {bg="none"})

-- Basic settings
vim.opt.number = true                             -- Line numbers
vim.opt.relativenumber = true                      -- Relative line numbers
vim.opt.cursorline = true                          -- Highlight current line
vim.opt.wrap = false                               -- wrap lines that exceed window
vim.opt.scrolloff = 5                              -- Keep lines above/below cursor 
vim.opt.sidescrolloff = 5                          -- Keep columns left/right of cursor

-- Indentation
vim.opt.tabstop = 4                                -- Tab width
vim.opt.shiftwidth = 4                             -- Indent width
vim.opt.softtabstop = 4                            -- Soft tab stop
vim.opt.expandtab = false                          -- Using spaces instead of tabs
vim.opt.smartindent = true                         -- Smart auto-indenting
vim.opt.autoindent = true                          -- Copy indent from current line

-- Search settings
vim.opt.ignorecase = true                          -- Case insensitive search
-- vim.opt.smartcase = true                           -- Case sensitive if uppercase in search
vim.opt.hlsearch = true                            -- Highlight search results 
vim.opt.incsearch = true                           -- Show matches as you type

-- Visual settings
vim.opt.termguicolors = true                       -- Enable 24-bit colors
vim.opt.signcolumn = "number"                         -- Always show sign column
vim.opt.colorcolumn = "102"                        -- Show column at 100 characters
vim.opt.showmatch = true                           -- Highlight matching brackets
vim.opt.matchtime = 2                              -- How long to show matching bracket
vim.opt.cmdheight = 1                              -- Command line height
vim.opt.completeopt = "menuone,noinsert,noselect"  -- Completion options 
vim.opt.showmode = false                           -- Don't show mode in command line 
vim.opt.pumheight = 10                             -- Popup menu height 
vim.opt.pumblend = 10                              -- Popup menu transparency 
vim.opt.winblend = 0                               -- Floating window transparency 
vim.opt.conceallevel = 1                           -- hiding markup 
vim.opt.concealcursor = "i"                       -- Hiding cursor line markup 
vim.opt.lazyredraw = true                          -- redrawing during macros
vim.opt.synmaxcol = 300

-- File handling
vim.opt.backup = true                             
vim.opt.backupdir = '/Games/backup//'
vim.opt.writebackup = false                        -- Don't create backup before writing
vim.opt.swapfile = false                           -- Don't create swap files
vim.opt.undofile = true                            -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")  -- Undo directory
vim.opt.updatetime = 1000                           -- Faster completion
vim.opt.timeoutlen = 1000                           -- Key timeout duration
vim.opt.ttimeoutlen = 0                            -- Key code timeout
vim.opt.autoread = true                            -- Auto reload files changed outside vim
vim.opt.autowrite = false                          -- Don't auto save

-- Behavior settings
vim.opt.hidden = true                              -- Allow hidden buffers
vim.opt.errorbells = false                         -- No error bells
vim.opt.backspace = "indent,eol,start"             -- Better backspace behavior
vim.opt.autochdir = false                          -- Don't auto change directory
vim.opt.iskeyword:append("-")                      -- Treat dash as part of word
vim.opt.path:append("**")                          -- include subdirectories in search
vim.opt.selection = "exclusive"                    -- Selection behavior
vim.opt.mouse = "a"                                -- Enable mouse support
-- vim.opt.clipboard:append("unnamedplus")            -- Use system clipboard
vim.opt.modifiable = true                          -- Allow buffer modifications
vim.opt.encoding = "UTF-8"                         -- Set encoding

-- Cursor settings
-- vim.opt.guicursor = "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Split behavior
vim.opt.splitbelow = true                          -- Horizontal splits go below
vim.opt.splitright = true                          -- Vertical splits go right

-- Normal mode mappings
vim.keymap.set("n", "<leader>c", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Delete without yanking
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Splitting & Resizing
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Move lines up/down
vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Quick file navigation
vim.keymap.set("n", "<leader>ee", ":Explore<CR>", { desc = "Open file explorer" })
vim.keymap.set("n", "<leader>ff", ":find ", { desc = "Find file" })

-- Better J behavior
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Quick config editing
vim.keymap.set("n", "<leader>ec", ":e ~/.config/nvim/config/lazy.lua<CR>", { desc = "Edit config" })

-- ============================================================================
-- USEFUL FUNCTIONS
-- ============================================================================

-- Copy Full File-Path
vim.keymap.set("n", "<leader>pa", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("file:", path)
end)

-- Basic autocommands
local augroup = vim.api.nvim_create_augroup("UserConfig", {})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Set filetype-specific settings
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "lua", "python" },
	callback = function()
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "javascript", "typescript", "json", "html", "css" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
	end,
})

-- Auto-close terminal when process exits
vim.api.nvim_create_autocmd("TermClose", {
	group = augroup,
	callback = function()
		if vim.v.event.status == 0 then
			vim.api.nvim_buf_delete(0, {})
		end
	end,
})

-- Disable line numbers in terminal
vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

-- Auto-resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
	group = augroup,
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- Create directories when saving files
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	callback = function()
		local dir = vim.fn.expand('<afile>:p:h')
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, 'p')
		end
	end,
})

-- Command-line completion
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })

-- Better diff options
vim.opt.diffopt:append("linematch:60")

-- Performance improvements
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end

-- ============================================================================
-- FLOATING TERMINAL
-- ============================================================================

-- terminal
local terminal_state = {
	buf = nil,
	win = nil,
	is_open = false
}

local function FloatingTerminal()
	-- If terminal is already open, close it (toggle behavior)
	if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
		return
	end

	-- Create buffer if it doesn't exist or is invalid
	if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
		terminal_state.buf = vim.api.nvim_create_buf(false, true)
		-- Set buffer options for better terminal experience
		vim.api.nvim_buf_set_option(terminal_state.buf, 'bufhidden', 'hide')
	end

	-- Calculate window dimensions
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create the floating window
	terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
		relative = 'editor',
		width = width,
		height = height,
		row = row,
		col = col,
		style = 'minimal',
		border = 'rounded',
	})

	-- Set transparency for the floating window
	vim.api.nvim_win_set_option(terminal_state.win, 'winblend', 0)

	-- Set transparent background for the window
	vim.api.nvim_win_set_option(terminal_state.win, 'winhighlight',
	'Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder')

	-- Define highlight groups for transparency
	vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none", })

	-- Start terminal if not already running
	local has_terminal = false
	local lines = vim.api.nvim_buf_get_lines(terminal_state.buf, 0, -1, false)
	for _, line in ipairs(lines) do
		if line ~= "" then
			has_terminal = true
			break
		end
	end

	if not has_terminal then
		vim.fn.termopen(os.getenv("SHELL"))
	end

	terminal_state.is_open = true
	vim.cmd("startinsert")

	-- Set up auto-close on buffer leave 
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = terminal_state.buf,
		callback = function()
			if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
				vim.api.nvim_win_close(terminal_state.win, false)
				terminal_state.is_open = false
			end
		end,
		once = true
	})
end

-- Function to explicitly close the terminal
local function CloseFloatingTerminal()
	if terminal_state.is_open and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
	end
end

-- Key mappings
vim.keymap.set("n", "<leader>t", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc>", function()
	if terminal_state.is_open then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
	end
end, { noremap = true, silent = true, desc = "Close floating terminal from terminal mode" })

-- ============================================================================
-- TABS
-- ============================================================================

-- Tab display settings
vim.opt.showtabline = 1  -- Always show tabline (0=never, 1=when multiple tabs, 2=always)
vim.opt.tabline = ''     -- Use default tabline (empty string uses built-in)

-- Transparent tabline appearance
vim.cmd([[
hi TabLineFill guibg=NONE ctermfg=242 ctermbg=NONE
]])

-- Function to close buffer but keep tab if it's the only buffer in tab
local function smart_close_buffer()
	local buffers_in_tab = #vim.fn.tabpagebuflist()
	if buffers_in_tab > 1 then
		vim.cmd('bdelete')
	else
		-- If it's the only buffer in tab, close the tab
		vim.cmd('tabclose')
	end
end
vim.keymap.set('n', '<leader>bd', smart_close_buffer, { desc = 'Smart close buffer/tab' })

-- ============================================================================
-- STATUSLINE
-- ============================================================================

-- Git branch function
local function git_branch()
	local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
	if branch ~= "" then
		return "  " .. branch .. " "
	end
	return ""
end

-- File type with icon
local function file_type()
	local ft = vim.bo.filetype
	local icons = {
		lua = "[LUA]",
		python = "[PY]",
		javascript = "[JS]",
		html = "[HTML]",
		css = "[CSS]",
		json = "[JSON]",
		markdown = "[MD]",
		vim = "[VIM]",
		sh = "[SH]",
	}

	if ft == "" then
		return "  "
	end

	return (icons[ft] or ft)
end

-- LSP status
local function lsp_status()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients > 0 then
		return "  LSP "
	end
	return ""
end

-- Word count for text files
local function word_count()
	local ft = vim.bo.filetype
	if ft == "markdown" or ft == "text" or ft == "tex" then
		local words = vim.fn.wordcount().words
		return "  " .. words .. " words "
	end
	return ""
end

-- File size
local function file_size()
	local size = vim.fn.getfsize(vim.fn.expand('%'))
	if size < 0 then return "" end
	if size < 1024 then
		return size .. "B "
	elseif size < 1024 * 1024 then
		return string.format("%.1fK", size / 1024)
	else
		return string.format("%.1fM", size / 1024 / 1024)
	end
end

-- Mode indicators with icons
local function mode_icon()
	local mode = vim.fn.mode()
	local modes = {
		n = "NORMAL",
		i = "INSERT",
		v = "VISUAL",
		V = "V-LINE",
		["\22"] = "V-BLOCK",  -- Ctrl-V
		c = "COMMAND",
		s = "SELECT",
		S = "S-LINE",
		["\19"] = "S-BLOCK",  -- Ctrl-S
		R = "REPLACE",
		r = "REPLACE",
		["!"] = "SHELL",
		t = "TERMINAL"
	}
	return modes[mode] or "  " .. mode:upper()
end

_G.mode_icon = mode_icon
_G.git_branch = git_branch
_G.file_type = file_type
_G.file_size = file_size
_G.lsp_status = lsp_status

vim.cmd([[
highlight StatusLineBold gui=bold cterm=bold
]])

-- Function to change statusline based on window focus
local function setup_dynamic_statusline()
	vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {
		callback = function()
			vim.opt_local.statusline = table.concat {
				"  ",
				"%#StatusLineBold#",
				"%{v:lua.mode_icon()}",
				"%#StatusLine#",
				" │ %f %h%m%r",
				"%{v:lua.git_branch()}",
				" │ ",
				"%{v:lua.file_type()}",
				" | ",
				"%{v:lua.file_size()}",
				" | ",
				"%{v:lua.lsp_status()}",
				"%=",                     -- Right-align everything after this
				"%l:%c  %P ",             -- Line:Column and Percentage
			}
		end
	})
	vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })

	vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {
		callback = function()
			vim.opt_local.statusline = "  %f %h%m%r │ %{v:lua.file_type()} | %=  %l:%c   %P "
		end
	})
end

setup_dynamic_statusline()

