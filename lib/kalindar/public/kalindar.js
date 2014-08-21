"a#new_event_link".onClick(function () {
  console.log(this);
  //$('hidden_new_event_mask').fade();
  this.parent().first('.hidden_new_event_mask').fade();
  // Do not follow link.
  return false;
});

"#event_day".onClick( function() {
  console.log(this.parent());
  this.first("#hidden_description").fade();
});

"#cancel".onClick(function() {
  this.parent.parent().fade();
});

"#show_new_event_link".onClick(function() {
  console.log(this.parent().first('#day_hidden_input').value());
  day = this.parent().first('#day_hidden_input').value();
  /*
   * this.parent().first('.new_event_mask').load('/event/new/' + day);
   */
  this.parent().first('.hidden_new_event_mask').fade();
  return false;
});

"#new_event_form".onSubmit(function(event) {
  event.stop();
  var me = this;
  this.send({
    /*onComplete: function() {alert("complete");}*/
    onSuccess: function(resp) {
      console.log(resp);
      $('main').html(resp.responseText);
    },
    onFailure: function(resp) {alert(resp.responseText);},
  });
});
