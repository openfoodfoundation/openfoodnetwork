attributes :name, :id, :permalink

node :icon do |taxon|
  taxon.icon(:original)
end
