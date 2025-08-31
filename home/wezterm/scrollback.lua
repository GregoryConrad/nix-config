local wezterm = require 'wezterm'
local io = require 'io'
local os = require 'os'

-- WezTerm has a pretty minimal PATH,
-- so this will be replaced by the helix executable's path over on the nix side.
local helix_bin = "__HELIX_BIN_PATH__"

wezterm.on('open-hx-with-scrollback', function(window, pane)
  local scrollback_text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)

  local filename = os.tmpname()
  local f = io.open(filename, 'w+')
  f:write(scrollback_text)
  f:flush()
  f:close()

  window:mux_window():spawn_tab {
    args = {helix_bin, filename, '+1000000000'}
  }

  -- Wait "enough" time for the editor to read the file before removing it.
  -- (Reading the file is asynchronous and not awaitable.)
  wezterm.sleep_ms(1000)
  os.remove(filename)
end)
