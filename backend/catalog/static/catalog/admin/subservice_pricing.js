// SubService admin — pricing field UX.
//
// When `is_fixed_price` is checked, the max_price field is meaningless
// (backend stores it as NULL — see SubServiceAdmin.save_model). Hide
// the row so the operator doesn't have to think about it; show it back
// when unchecked.
(function () {
  function $(sel) { return document.querySelector(sel); }

  function syncMaxPriceVisibility(fixedCheckbox) {
    var maxRow = $('.form-row.field-max_price') || $('.form-row.max_price');
    if (!maxRow) return;
    if (fixedCheckbox.checked) {
      maxRow.style.display = 'none';
      // Blank the input so the server-side save_model has nothing stale to drop.
      var maxInput = maxRow.querySelector('input[name="max_price"]');
      if (maxInput) maxInput.value = '';
    } else {
      maxRow.style.display = '';
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    var fixed = document.querySelector('input[name="is_fixed_price"]');
    if (!fixed) return;
    syncMaxPriceVisibility(fixed);
    fixed.addEventListener('change', function () { syncMaxPriceVisibility(fixed); });
  });
})();
