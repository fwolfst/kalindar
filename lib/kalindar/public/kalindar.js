"a#new_event_link".onClick(function () {
  console.log(this);
  //$('hidden_new_event_mask').fade();
  this.parent().parent().first('.hidden_new_event_mask').fade();
  // Do not follow link.
  return false;
});

"#event_day".onClick( function() {
  console.log(this.parent());
  this.first("#hidden_description").fade();
});
