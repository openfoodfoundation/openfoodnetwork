angular.module('admin.enterpriseFees').directive 'spreeDeleteResource', ->
  (scope, element, attrs) ->
    if scope.enterprise_fee.id
      url = '/admin/enterprise_fees/' + scope.enterprise_fee.id
      html = '<a href="' + url + '" class="delete-resource icon_link icon-trash no-text" data-action="remove" data-confirm="Are you sure?" url="' + url + '"></a>'
      #var html = '<a href="'+url+'" class="delete-resource" data-confirm="Are you sure?"><img alt="Delete" src="/assets/admin/icons/delete.png" /> Delete</a>';
      element.append html
    return
