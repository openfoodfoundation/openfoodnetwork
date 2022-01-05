root = exports ? this

root.taxon_tree_menu = (obj, context) ->

  base_url = Spree.url(Spree.routes.taxonomy_taxons)
  admin_base_url = Spree.url(Spree.routes.admin_taxonomy_taxons)
  edit_url = Spree.url(Spree.routes.admin_taxonomy_taxons + '/' + obj.attr("id") + "/edit");

  create:
    label: "<i class='icon-plus'></i> " + Spree.translations.add,
    action: (obj) -> context.create(obj)
  rename:
    label: "<i class='icon-pencil'></i> " + Spree.translations.rename,
    action: (obj) -> context.rename(obj)
  remove:
    label: "<i class='icon-trash'></i> " + Spree.translations.remove,
    action: (obj) -> context.remove(obj)
  edit:
    separator_before: true,
    label: "<i class='icon-edit'></i> " + Spree.translations.edit,
    action: (obj) -> window.location = edit_url.toString()
