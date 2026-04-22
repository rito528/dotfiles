local function label(m)
  return m.desc or m.rhs or "<lua>"
end

local function group_by_lhs(maps)
  return vim.iter(maps)
    :filter(function(m) return not m.lhs:match("^<Plug>") end)
    :fold({}, function(acc, m)
      acc[m.lhs] = acc[m.lhs] or {}
      table.insert(acc[m.lhs], m)
      return acc
    end)
end

local function find_duplicates(mode)
  return vim.iter(group_by_lhs(vim.api.nvim_get_keymap(mode)))
    :filter(function(_, ms) return #ms > 1 end)
    :map(function(lhs, ms) return { mode = mode, lhs = lhs, maps = ms } end)
    :totable()
end

local duplicates = vim.iter({ "n", "v", "x", "i", "o", "s", "c", "t" })
  :map(find_duplicates)
  :flatten()
  :totable()

for _, d in ipairs(duplicates) do
  io.stderr:write(string.format(
    "[DUPLICATE] mode=%s  key=%s\n  (1) %s\n  (2) %s\n",
    d.mode,
    d.lhs,
    label(d.maps[1]),
    label(d.maps[2])
  ))
end

if #duplicates > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("quitall")
end
