local get_hovered_name = ya.sync(function()
  local h = cx.active.current.hovered
  return h and tostring(h.name) or nil
end)

return {
  entry = function()
    local name = get_hovered_name()
    if not name then return end

    local cand = ya.which {
      cands = {
        { on = "o", desc = "Open file" },
        { on = "O", desc = "Open with..." },
        { on = "e", desc = "Edit in $EDITOR" },
        { on = "z", desc = "Zip selection" },
        { on = "u", desc = "Unzip archive" },
        {
          on = { "y", "c" },
          desc = "Copy / Cut / Paste",
        },
        { on = "r", desc = "Rename" },
        { on = "d", desc = "Delete (trash)" },
        { on = "h", desc = "Toggle hidden files" },
        { on = "q", desc = "Quit Yazi" },
      },
    }

    if cand == 1 then
      ya.emit("open", {})
    elseif cand == 2 then
      ya.emit("open", { interactive = true })
    elseif cand == 3 then
      ya.emit("shell", { '$EDITOR "$@"', block = true })
    elseif cand == 4 then
      local archive, ev = ya.input {
        title = "Zip archive name:",
        value = "archive.zip",
      }
      if ev == 1 then
        ya.emit("shell", {
          'zip -r ' .. ya.quote(archive) .. ' "$@"',
          block = true,
        })
      end
    elseif cand == 5 then
      if name:match("%.zip$") then
        local dir = name:gsub("%.zip$", "")
        ya.emit("shell", {
          "mkdir -p " .. ya.quote(dir) .. " && unzip "
            .. ya.quote(name) .. " -d " .. ya.quote(dir),
          block = true,
        })
      else
        ya.notify {
          title = "Unzip",
          content = "Hovered file is not a .zip archive",
          level = "warn",
          timeout = 3,
        }
      end
    elseif cand == 6 then
      local sub = ya.which {
        cands = {
          { on = "y", desc = "Copy" },
          { on = "x", desc = "Cut" },
          { on = "p", desc = "Paste" },
        },
      }
      if sub == 1 then
        ya.emit("yank", {})
      elseif sub == 2 then
        ya.emit("yank", { cut = true })
      elseif sub == 3 then
        ya.emit("paste", {})
      end
    elseif cand == 7 then
      ya.emit("rename", {})
    elseif cand == 8 then
      ya.emit("remove", {})
    elseif cand == 9 then
      ya.emit("hidden", { "toggle" })
    elseif cand == 10 then
      ya.emit("quit", {})
    end
  end,
}
