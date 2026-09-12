function Entity:click(event, up)
  if up then return end
  ya.emit("reveal", { self._file.url })
  if event.is_middle then
    ya.emit("open", { interactive = true })
  elseif event.is_right then
    ya.emit("plugin", { "context-menu" })
  end
end
