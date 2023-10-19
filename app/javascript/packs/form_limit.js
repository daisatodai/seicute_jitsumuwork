$(function() {
  // limits the number of invoice_details
  $('#invoice_details').on('cocoon:after-insert', function() {
    check_to_hide_or_show_add_link();
  });

  $('#invoice_details').on('cocoon:after-remove', function() {
    check_to_hide_or_show_add_link();
  });

  check_to_hide_or_show_add_link();

  function check_to_hide_or_show_add_link() {
    if ($('#invoice_details .nested-fields:visible').length == 5) {
      $('#links a').hide();
    } else {
      $('#links a').show();
    }
  }
})