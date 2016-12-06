angular.module('admin.utils').service 'FormState', ->
  #Simple service to share form state across different controllers/scopes
  { isDirty: false }