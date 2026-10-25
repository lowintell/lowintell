-- ~/.config/nvim/lua/plugins/duskcoast.lua
-- Dusk Coast: single-file LazyVim colorscheme inspired by a dark, moody
-- coastline at dusk - slate-indigo clouds, hazy purple-blue mountains,
-- a near-black shore.

local transparent = true -- set to false for solid backgrounds

local c = {
  -- backgrounds (only used when transparent = false, or for overlays)
  bg_dark   = "#0e0e17", -- the dark shore
  bg        = "#191a28", -- main background (night sky)
  bg_alt    = "#20212f", -- floating windows, sidebars
  bg_hl     = "#282a3c", -- cursorline
  bg_sel    = "#383b52", -- visual selection
  border    = "#484c68",

  -- foregrounds
  fg        = "#c3c4d6", -- misty cloud-light
  fg_dim    = "#9a9bb3",
  comment   = "#696b86",
  line_nr   = "#43455c",

  -- horizon light
  lamp      = "#dedfef", -- brightest horizon glow
  glow      = "#b9bbda", -- softer light through clouds

  -- accents (cool slate / indigo / periwinkle, low saturation)
  blue       = "#7a84b0",
  sky        = "#9aa3c9",
  cyan       = "#7f9bab",
  teal       = "#7e9b97",
  periwinkle = "#a3a7d9",
  lavender   = "#b2addd",
  snow       = "#8d90b8",

  -- diagnostics
  error     = "#c97b8f",
  warn      = "#cbb584",
  info      = "#9aa3c9",
  hint      = "#7f9bab",
  ok        = "#8eae9d",
}

local function apply()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.g.colors_name = "duskcoast"

  -- surfaces: NONE when transparent so the terminal background shows through
  local bg      = transparent and "NONE" or c.bg
  local bg_dark = transparent and "NONE" or c.bg_dark
  local bg_alt  = transparent and "NONE" or c.bg_alt

  local groups = {
    -- Editor UI ---------------------------------------------------------
    Normal       = { fg = c.fg, bg = bg },
    NormalNC     = { fg = c.fg, bg = bg },
    NormalFloat  = { fg = c.fg, bg = bg_alt },
    FloatBorder  = { fg = c.border, bg = bg_alt },
    FloatTitle   = { fg = c.glow, bg = bg_alt, bold = true },
    SignColumn   = { bg = bg },
    ColorColumn  = { bg = c.bg_alt },
    Cursor       = { fg = c.bg, bg = c.lamp },
    lCursor      = { link = "Cursor" },
    CursorLine   = { bg = c.bg_hl },
    CursorColumn = { bg = c.bg_hl },
    CursorLineNr = { fg = c.glow, bold = true },
    LineNr       = { fg = c.line_nr },
    FoldColumn   = { fg = c.comment, bg = bg },
    Folded       = { fg = c.periwinkle, bg = c.bg_alt },
    EndOfBuffer  = { fg = c.bg },
    NonText      = { fg = c.border },
    Whitespace   = { fg = c.border },
    SpecialKey   = { fg = c.border },
    Conceal      = { fg = c.comment },
    MatchParen   = { fg = c.lamp, bg = c.bg_sel, bold = true },
    Search       = { fg = c.bg_dark, bg = c.snow },
    IncSearch    = { fg = c.bg_dark, bg = c.lamp },
    CurSearch    = { fg = c.bg_dark, bg = c.lamp, bold = true },
    Substitute   = { fg = c.bg_dark, bg = c.warn },
    Visual       = { bg = c.bg_sel },
    VisualNOS    = { bg = c.bg_sel },
    Pmenu        = { fg = c.fg, bg = c.bg_alt },
    PmenuSel     = { fg = c.lamp, bg = c.bg_sel, bold = true },
    PmenuSbar    = { bg = c.bg_hl },
    PmenuThumb   = { bg = c.border },
    StatusLine   = { fg = c.fg, bg = bg_alt },
    StatusLineNC = { fg = c.comment, bg = bg_dark },
    TabLine      = { fg = c.comment, bg = bg_dark },
    TabLineFill  = { bg = bg_dark },
    TabLineSel   = { fg = c.lamp, bg = bg, bold = true },
    WinSeparator = { fg = c.border },
    VertSplit    = { fg = c.border },
    WinBar       = { fg = c.fg_dim, bg = bg },
    WinBarNC     = { fg = c.comment, bg = bg },
    Title        = { fg = c.glow, bold = true },
    Directory    = { fg = c.blue },
    MsgArea      = { fg = c.fg, bg = bg },
    ErrorMsg     = { fg = c.error, bold = true },
    WarningMsg   = { fg = c.warn },
    ModeMsg      = { fg = c.glow, bold = true },
    MoreMsg      = { fg = c.ok },
    Question     = { fg = c.sky },
    WildMenu     = { bg = c.bg_sel },
    SpellBad     = { sp = c.error, undercurl = true },
    SpellCap     = { sp = c.warn, undercurl = true },
    SpellLocal   = { sp = c.info, undercurl = true },
    SpellRare    = { sp = c.hint, undercurl = true },
    QuickFixLine = { bg = c.bg_sel },
    Bold         = { bold = true },
    Italic       = { italic = true },
    Underlined   = { underline = true },

    -- Diff --------------------------------------------------------------
    DiffAdd    = { bg = "#1d322c" },
    DiffChange = { bg = "#20283f" },
    DiffDelete = { bg = "#352233" },
    DiffText   = { bg = "#303e63" },
    Added      = { fg = c.ok },
    Changed    = { fg = c.blue },
    Removed    = { fg = c.error },

    -- Syntax ------------------------------------------------------------
    Comment        = { fg = c.comment, italic = true },
    Constant       = { fg = c.lavender },
    String         = { fg = c.teal },
    Character      = { fg = c.teal },
    Number         = { fg = c.periwinkle },
    Boolean        = { fg = c.periwinkle },
    Float          = { fg = c.periwinkle },
    Identifier     = { fg = c.fg },
    Function       = { fg = c.sky },
    Statement      = { fg = c.blue },
    Conditional    = { fg = c.blue },
    Repeat         = { fg = c.blue },
    Label          = { fg = c.blue },
    Operator       = { fg = c.snow },
    Keyword        = { fg = c.blue, italic = true },
    Exception      = { fg = c.blue },
    PreProc        = { fg = c.cyan },
    Include        = { fg = c.cyan },
    Define         = { fg = c.cyan },
    Macro          = { fg = c.cyan },
    PreCondit      = { fg = c.cyan },
    Type           = { fg = c.glow },
    StorageClass   = { fg = c.glow },
    Structure      = { fg = c.glow },
    Typedef        = { fg = c.glow },
    Special        = { fg = c.cyan },
    SpecialChar    = { fg = c.cyan },
    Tag            = { fg = c.blue },
    Delimiter      = { fg = c.fg_dim },
    SpecialComment = { fg = c.comment, bold = true },
    Debug          = { fg = c.warn },
    Error          = { fg = c.error },
    Todo           = { fg = c.bg_dark, bg = c.glow, bold = true },

    -- Treesitter ----------------------------------------------------------
    ["@variable"]              = { fg = c.fg },
    ["@variable.builtin"]      = { fg = c.lavender, italic = true },
    ["@variable.parameter"]    = { fg = c.fg_dim, italic = true },
    ["@variable.member"]       = { fg = c.snow },
    ["@property"]              = { fg = c.snow },
    ["@field"]                 = { fg = c.snow },
    ["@constant"]              = { fg = c.lavender },
    ["@constant.builtin"]      = { fg = c.periwinkle },
    ["@module"]                = { fg = c.glow },
    ["@string"]                = { fg = c.teal },
    ["@string.escape"]         = { fg = c.cyan },
    ["@string.regexp"]         = { fg = c.cyan },
    ["@function"]              = { fg = c.sky },
    ["@function.builtin"]      = { fg = c.cyan },
    ["@function.call"]         = { fg = c.sky },
    ["@function.method"]       = { fg = c.sky },
    ["@constructor"]           = { fg = c.glow },
    ["@keyword"]               = { fg = c.blue, italic = true },
    ["@keyword.function"]      = { fg = c.blue, italic = true },
    ["@keyword.return"]        = { fg = c.blue, italic = true },
    ["@keyword.operator"]      = { fg = c.snow },
    ["@operator"]              = { fg = c.snow },
    ["@type"]                  = { fg = c.glow },
    ["@type.builtin"]          = { fg = c.glow, italic = true },
    ["@attribute"]             = { fg = c.cyan },
    ["@punctuation"]           = { fg = c.fg_dim },
    ["@punctuation.bracket"]   = { fg = c.fg_dim },
    ["@punctuation.delimiter"] = { fg = c.snow },
    ["@comment"]               = { fg = c.comment, italic = true },
    ["@tag"]                   = { fg = c.blue },
    ["@tag.attribute"]         = { fg = c.snow, italic = true },
    ["@tag.delimiter"]         = { fg = c.fg_dim },
    ["@markup.heading"]        = { fg = c.glow, bold = true },
    ["@markup.strong"]         = { bold = true },
    ["@markup.italic"]         = { italic = true },
    ["@markup.link"]           = { fg = c.sky, underline = true },
    ["@markup.raw"]            = { fg = c.teal },
    ["@markup.list"]           = { fg = c.blue },

    -- Diagnostics / LSP ---------------------------------------------------
    DiagnosticError            = { fg = c.error },
    DiagnosticWarn             = { fg = c.warn },
    DiagnosticInfo             = { fg = c.info },
    DiagnosticHint             = { fg = c.hint },
    DiagnosticOk               = { fg = c.ok },
    DiagnosticUnderlineError   = { sp = c.error, undercurl = true },
    DiagnosticUnderlineWarn    = { sp = c.warn, undercurl = true },
    DiagnosticUnderlineInfo    = { sp = c.info, undercurl = true },
    DiagnosticUnderlineHint    = { sp = c.hint, undercurl = true },
    DiagnosticVirtualTextError = { fg = c.error, bg = "#2e2030" },
    DiagnosticVirtualTextWarn  = { fg = c.warn, bg = "#2c2a2e" },
    DiagnosticVirtualTextInfo  = { fg = c.info, bg = "#1e2236" },
    DiagnosticVirtualTextHint  = { fg = c.hint, bg = "#1c2831" },
    LspReferenceText           = { bg = c.bg_hl },
    LspReferenceRead           = { bg = c.bg_hl },
    LspReferenceWrite          = { bg = c.bg_sel },
    LspInlayHint               = { fg = c.comment },
    LspSignatureActiveParameter = { fg = c.lamp, bold = true },

    -- Plugins (LazyVim defaults) ------------------------------------------
    GitSignsAdd    = { fg = c.ok },
    GitSignsChange = { fg = c.blue },
    GitSignsDelete = { fg = c.error },

    IblIndent         = { fg = "#1f2030" },
    IblScope          = { fg = c.border },
    SnacksIndent      = { fg = "#1f2030" },
    SnacksIndentScope = { fg = c.border },

    SnacksPicker          = { fg = c.fg, bg = bg_alt },
    SnacksPickerBorder    = { fg = c.border, bg = bg_alt },
    SnacksPickerTitle     = { fg = c.glow, bold = true },
    SnacksDashboardHeader = { fg = c.glow },
    SnacksDashboardKey    = { fg = c.sky },
    SnacksDashboardIcon   = { fg = c.blue },
    SnacksDashboardDesc   = { fg = c.fg },
    SnacksDashboardFooter = { fg = c.comment },
    SnacksNotifierBorderInfo  = { fg = c.info },
    SnacksNotifierBorderWarn  = { fg = c.warn },
    SnacksNotifierBorderError = { fg = c.error },

    TelescopeNormal      = { fg = c.fg, bg = bg_alt },
    TelescopeBorder      = { fg = c.border, bg = bg_alt },
    TelescopeSelection   = { fg = c.lamp, bg = c.bg_sel },
    TelescopeMatching    = { fg = c.glow, bold = true },
    TelescopePromptTitle = { fg = c.bg_dark, bg = c.sky, bold = true },

    WhichKey          = { fg = c.sky },
    WhichKeyGroup     = { fg = c.blue },
    WhichKeyDesc      = { fg = c.fg },
    WhichKeySeparator = { fg = c.comment },
    WhichKeyNormal    = { bg = bg_alt },

    BlinkCmpMenu          = { fg = c.fg, bg = c.bg_alt },
    BlinkCmpMenuBorder    = { fg = c.border, bg = c.bg_alt },
    BlinkCmpMenuSelection = { fg = c.lamp, bg = c.bg_sel },
    BlinkCmpLabelMatch    = { fg = c.glow, bold = true },
    BlinkCmpDoc           = { bg = c.bg_alt },
    BlinkCmpDocBorder     = { fg = c.border, bg = c.bg_alt },
    CmpItemAbbrMatch      = { fg = c.glow, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.glow, bold = true },
    CmpItemKindFunction   = { fg = c.sky },
    CmpItemKindVariable   = { fg = c.fg },
    CmpItemKindKeyword    = { fg = c.blue },

    NeoTreeNormal        = { fg = c.fg, bg = bg_dark },
    NeoTreeNormalNC      = { fg = c.fg, bg = bg_dark },
    NeoTreeDirectoryName = { fg = c.blue },
    NeoTreeDirectoryIcon = { fg = c.snow },
    NeoTreeRootName      = { fg = c.glow, bold = true },
    NeoTreeGitAdded      = { fg = c.ok },
    NeoTreeGitModified   = { fg = c.blue },
    NeoTreeGitDeleted    = { fg = c.error },
    NeoTreeIndentMarker  = { fg = "#1f2030" },

    FlashLabel    = { fg = c.bg_dark, bg = c.lamp, bold = true },
    FlashMatch    = { fg = c.sky, bg = c.bg_sel },
    FlashCurrent  = { fg = c.bg_dark, bg = c.snow },
    FlashBackdrop = { fg = c.comment },

    NoiceCmdlinePopupBorder = { fg = c.border },
    NoiceCmdlineIcon        = { fg = c.sky },
    NotifyINFOBorder  = { fg = c.info },
    NotifyWARNBorder  = { fg = c.warn },
    NotifyERRORBorder = { fg = c.error },

    BufferLineFill = { bg = bg_dark },

    MiniIndentscopeSymbol     = { fg = c.border },
    MiniStatuslineModeNormal  = { fg = c.bg_dark, bg = c.blue, bold = true },
    MiniStatuslineModeInsert  = { fg = c.bg_dark, bg = c.glow, bold = true },
    MiniStatuslineModeVisual  = { fg = c.bg_dark, bg = c.periwinkle, bold = true },
    MiniStatuslineModeReplace = { fg = c.bg_dark, bg = c.error, bold = true },
    MiniStatuslineModeCommand = { fg = c.bg_dark, bg = c.teal, bold = true },

    TodoBgTODO = { fg = c.bg_dark, bg = c.info, bold = true },
    TodoBgFIX  = { fg = c.bg_dark, bg = c.error, bold = true },
    TodoBgWARN = { fg = c.bg_dark, bg = c.warn, bold = true },
    TodoBgNOTE = { fg = c.bg_dark, bg = c.hint, bold = true },
  }

  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end

  -- Terminal colors (for :terminal, lazygit, etc.)
  local term = {
    c.bg_dark, c.error, c.ok, c.warn, c.blue, c.periwinkle, c.cyan, c.fg,
    c.comment, c.error, c.ok, c.warn, c.sky, c.lavender, c.glow, c.lamp,
  }
  for i, color in ipairs(term) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end
end

vim.api.nvim_create_user_command("DuskCoast", apply, { desc = "Apply the Dusk Coast colorscheme" })

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = apply,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = "auto"
    end,
  },
}
