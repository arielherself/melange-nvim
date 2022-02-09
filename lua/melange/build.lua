--- Templates for various terminal configuration formats

vim.cmd("packadd lush.nvim")
local lush = require("lush")
local uv = vim.loop

-- Reload melange module
local function get_colorscheme(variant)
    package.loaded["melange"] = nil
    vim.opt.background = variant
    return require("melange")
end

-- Get the directory where the melange plugin is located
local function get_melange_dir()
    return debug.getinfo(1).source:match("@?(.*/)"):gsub("/lua/melange/$", "")
end

-- Write a string to a file
local function fwrite(str, file)
    local fd = assert(uv.fs_open(get_melange_dir() .. file, 'w', 420))
    uv.fs_write(fd, str, -1)
    assert(uv.fs_close(fd))
end

-- Perl-like interpolation
local function interpolate(str, tbl)
    return str:gsub("%$([%w_]+)", function(k) return tostring(tbl[k]) end)
end

-- Turn melange naming conventions into more common ANSI names
local function get_palette16(variant)
        local colors = get_colorscheme(variant).Melange.lush
        return {
            bg        = colors.a.bg,
            fg        = colors.a.fg,
            black     = colors.a.overbg,
            red       = colors.c.red,
            green     = colors.c.green,
            yellow    = colors.b.yellow,
            blue      = colors.b.blue,
            magenta   = colors.c.magenta,
            cyan      = colors.c.cyan,
            white     = colors.a.com,
            brblack   = colors.a.sel,
            brred     = colors.b.red,
            brgreen   = colors.b.green,
            bryellow  = colors.b.yellow,
            brblue    = colors.b.blue,
            brmagenta = colors.b.magenta,
            brcyan    = colors.b.cyan,
            brwhite   = colors.a.faded,
        }
end

local vim_term_colors = [[
let g:terminal_color_0  = '$black'
let g:terminal_color_1  = '$red'
let g:terminal_color_2  = '$green'
let g:terminal_color_3  = '$yellow'
let g:terminal_color_4  = '$blue'
let g:terminal_color_5  = '$magenta'
let g:terminal_color_6  = '$cyan'
let g:terminal_color_7  = '$white'
let g:terminal_color_8  = '$brblack'
let g:terminal_color_9  = '$brred'
let g:terminal_color_10 = '$brgreen'
let g:terminal_color_11 = '$bryellow'
let g:terminal_color_12 = '$brblue'
let g:terminal_color_13 = '$brmagenta'
let g:terminal_color_14 = '$brcyan'
let g:terminal_color_15 = '$brwhite'
]]

local viml_template = [[
" THIS FILE WAS AUTOMATICALLY GENERATED
hi clear
syntax reset
set t_Co=256
let g:colors_name = 'melange'
if &background == 'dark'
$dark_term
$dark
else
$light_term
$light
endif
]]

local function viml_build(l)
    local vimcolors = {}
    for _,l in ipairs{"dark", "light"} do
        -- Compile lush table, concatenate to a single string, and remove blend property
        vimcolors[l] = table.concat(vim.fn.sort(lush.compile(get_colorscheme(l), {exclude_keys={"blend"}})), "\n")
        vimcolors[l .. '_term'] = interpolate(vim_term_colors, get_palette16(l))
    end
    return fwrite(interpolate(viml_template, vimcolors), "/colors/melange.vim")
end



local function build(terminals)
    for _, l in ipairs{"dark", "light"} do
        local palette = get_palette16(l)
        for term, attrs in pairs(terminals) do
            fwrite(
                interpolate(attrs.template, palette),
                string.format("/term/%s/melange_%s%s", term, l, attrs.ext)
            )
        end
    end
end

local terminals = {
    alacritty = {ext=".yml"},
    kitty     = {ext=".conf"},
    termite   = {ext=""},
    wezterm   = {ext=".toml"},
}

terminals.alacritty.template = [[
colors:
  primary:
    foreground: '$fg'
    background: '$bg'
  normal:
    black:   '$black'
    red:     '$red'
    green:   '$green'
    yellow:  '$yellow'
    blue:    '$blue'
    magenta: '$magenta'
    cyan:    '$cyan'
    white:   '$white'
  bright:
    black:   '$brblack'
    red:     '$brred'
    green:   '$brgreen'
    yellow:  '$bryellow'
    blue:    '$brblue'
    magenta: '$brmagenta'
    cyan:    '$brcyan'
    white:   '$brwhite'
]]

terminals.kitty.template = [[
background $bg
foreground $fg
cursor     $fg
url_color  $blue
selection_background    $brblack
selection_foreground    $fg
tab_bar_background      $black
active_tab_background   $black
active_tab_foreground   $yellow
inactive_tab_background $black
inactive_tab_foreground $brwhite
color0  $black
color1  $red
color2  $green
color3  $yellow
color4  $blue
color5  $magenta
color6  $cyan
color7  $white
color8  $brblack
color9  $brred
color10 $brgreen
color11 $bryellow
color12 $brblue
color13 $brmagenta
color14 $brcyan
color15 $brwhite
]]

terminals.termite.template = [[
[colors]
foreground = $fg
background = $bg
color0     = $black
color1     = $red
color2     = $green
color3     = $yellow
color4     = $blue
color5     = $magenta
color6     = $cyan
color7     = $white
color8     = $brblack
color9     = $brred
color10    = $brgreen
color11    = $bryellow
color12    = $brblue
color13    = $brmagenta
color14    = $brcyan
color15    = $brwhite
highlight  = $sel
]]

terminals.wezterm.template = [[
[colors]
foreground    = "$fg"
background    = "$bg"
cursor_bg     = "$fg"
cursor_border = "$fg"
cursor_fg     = "$bg"
selection_bg  = "$brblack"
selection_fg  = "$fg"
ansi = ["$black", "$red", "$green", "$yellow", "$blue", "$magenta", "$cyan", "$white"]
brights = ["$brblack", "$brred", "$brgreen", "$bryellow", "$brblue", "$brmagenta", "$brcyan", "$brwhite"]
]]

return {build = function() build(terminals); viml_build() end}
