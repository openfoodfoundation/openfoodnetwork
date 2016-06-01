angular.module("admin.indexUtils").component 'showMore',
  templateUrl: 'admin/show_more.html'
  bindings:
    data: "="
    limit: "="
    increment: "="

# For now, this component is not being used.
# Something about binding "data" to a variable on the parent scope that is continually refreshed by
# being assigned within an ng-repeat means that we get $digest iteration errors. Seems to be solved
# by using the new "as" syntax for ng-repeat to assign and alias the outcome of the filters, but this
# has the limitation of not being able to be limited AFTER the assignment has been made, which we need
