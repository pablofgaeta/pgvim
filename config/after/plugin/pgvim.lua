local extension = rawget(_G, 'pgvim_extension')
if extension and extension.after then
  extension.after()
end
