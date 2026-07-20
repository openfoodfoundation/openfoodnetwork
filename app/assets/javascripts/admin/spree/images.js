document.addEventListener('DOMContentLoaded', function() {
  var table = document.querySelector('#images table.sortable');
  if (!table) return;

  function checkEmpty() {
    var visibleRows = table.querySelectorAll('tbody tr:not([style*="display: none"])');
    if (visibleRows.length === 0) {
      table.style.display = 'none';
      var msg = document.querySelector('#no-images-found');
      if (msg) msg.style.display = '';
      var btn = document.querySelector('#new_image_link_wrapper');
      if (btn) btn.style.display = '';
    }
  }

  var observer = new MutationObserver(checkEmpty);
  observer.observe(table.querySelector('tbody'), {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['style']
  });
});
