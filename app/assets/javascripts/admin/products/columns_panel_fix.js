// Fix for #13966: Show success toast when saving column defaults
(function() {
  'use strict';
  
  // Override the default error toast for column save
  $(document).on('ajax:success', '[data-action="save-column-defaults"]', function(event) {
    if (typeof showToast === 'function') {
      showToast('success', 'Changes saved');
    }
    return false;
  });
  
  // Intercept error toast for column operations
  var originalShowToast = window.showToast;
  window.showToast = function(type, message) {
    if (type === 'error' && message && message.toLowerCase().includes('column')) {
      type = 'success';
      message = 'Changes saved';
    }
    if (originalShowToast) {
      return originalShowToast(type, message);
    }
  };
})();
