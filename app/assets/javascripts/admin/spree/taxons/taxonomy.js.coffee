handle_ajax_error = (XMLHttpRequest, textStatus, errorThrown) ->
  $.jstree.rollback(last_rollback)
  $("#ajax_error").show().html("<strong>" + server_error + "</strong><br />" + taxonomy_tree_error)

handle_move = (e, data) ->
  last_rollback = data.rlbk
  position = data.rslt.cp
  node = data.rslt.o
  new_parent = data.rslt.np

  url = new URL(Spree.routes.admin_taxonomy_taxons)
  url.pathname = url.pathname + '/' + node.attr("id") 
  data = {
    _method: "put",
    "taxon[position]": position,
    "taxon[parent_id]": if !isNaN(new_parent.attr("id")) then new_parent.attr("id") else undefined
  }
  $.ajax
    type: "POST",
    dataType: "json",
    url: url.toString(),
    data: data,
    error: handle_ajax_error

  true

handle_create = (e, data) ->
  last_rollback = data.rlbk
  node = data.rslt.obj
  name = data.rslt.name
  position = data.rslt.position
  new_parent = data.rslt.parent

  data = {
    "taxon[name]": name,
    "taxon[position]": position
    "taxon[parent_id]": if !isNaN(new_parent.attr("id")) then new_parent.attr("id") else undefined
  }
  $.ajax
    type: "POST",
    dataType: "json",
    url: base_url.toString(),
    data: data,
    error: handle_ajax_error,
    success: (data,result) ->
      node.attr('id', data.id)

handle_rename = (e, data) ->
  last_rollback = data.rlbk
  node = data.rslt.obj
  name = data.rslt.new_name
  # change the name inside the main input field as well if taxon is the root one
  document.getElementById("taxonomy_name").value = name if node.parents("[id]").attr("id") == "taxonomy_tree"

  url = new URL(base_url)
  url.pathname = url.pathname + '/' + node.attr("id")

  $.ajax
    type: "POST",
    dataType: "json",
    url: url.toString(),
    data: {_method: "put", "taxon[name]": name },
    error: handle_ajax_error

handle_delete = (e, data) ->
  last_rollback = data.rlbk
  node = data.rslt.obj
  delete_url = new URL(base_url)
  delete_url.pathname = delete_url.pathname + '/' + node.attr("id")
  if confirm(Spree.translations.are_you_sure_delete)
    $.ajax
      type: "POST",
      dataType: "json",
      url: delete_url.toString(),
      data: {_method: "delete"},
      error: handle_ajax_error
  else
    $.jstree.rollback(last_rollback)
    last_rollback = null

root = exports ? this
root.setup_taxonomy_tree = (taxonomy_id) ->
  if taxonomy_id != undefined
    # this is defined within admin/taxonomies/edit
    root.base_url = Spree.url(Spree.routes.taxonomy_taxons)

    $.ajax
      url: base_url.pathname.replace("/taxons", "/jstree"),
      success: (taxonomy) ->
        last_rollback = null

        conf =
          json_data:
            data: taxonomy,
            ajax:
              url: (e) ->
                base_url.pathname + '/' + e.attr('id') + '/jstree'
          themes:
            theme: "apple",
            url: "/assets/jquery.jstree/themes/apple/style.css"
          strings:
            new_node: new_taxon,
            loading: Spree.translations.loading + "..."
          crrm:
            move:
              check_move: (m) ->
                position = m.cp
                node = m.o
                new_parent = m.np

                # no parent or cant drag and drop
                if !new_parent || node.attr("rel") == "root"
                  return false

                # can't drop before root
                if new_parent.attr("id") == "taxonomy_tree" && position == 0
                  return false

                true
          contextmenu:
            items: (obj) ->
              taxon_tree_menu(obj, this)
          plugins: ["themes", "json_data", "dnd", "crrm", "contextmenu"]

        $("#taxonomy_tree").jstree(conf)
          .bind("move_node.jstree", handle_move)
          .bind("remove.jstree", handle_delete)
          .bind("create.jstree", handle_create)
          .bind("rename.jstree", handle_rename)
          .bind "loaded.jstree", ->
            $(this).jstree("core").toggle_node($('.jstree-icon').first())

    $("#taxonomy_tree a").on "dblclick", (e) ->
      $("#taxonomy_tree").jstree("rename", this)

    # surpress form submit on enter/return
    $(document).keypress (e) ->
      if e.keyCode == 13
        e.preventDefault()
