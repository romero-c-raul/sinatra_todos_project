$(function() {

  //$("form") -> Return an array of all forms on page

  //-> Returns an array of only class=delete forms
  $("form.delete").submit(function(event) {
    event.preventDefault();   //Prevents default behavior from occuring
    event.stopPropagation();  //Prevents event from being interpreted by another part of page

    var ok = confirm("Are you sure? This cannot be undone!")
    if(ok) {
      this.submit();
    }

  });

});