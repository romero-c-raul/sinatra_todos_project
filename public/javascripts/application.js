$(function() {

  //$("form") -> Return an array of all forms on page

  //-> Returns an array of only class=delete forms
  $("form.delete").submit(function(event) {
    event.preventDefault();   //Prevents default behavior from occuring
    event.stopPropagation();  //Prevents event from being interpreted by another part of page

    var ok = confirm("Are you sure? This cannot be undone!")
    if(ok) {
      //this.submit();
      
      var form = $(this);     // Wraps form in jquery object; can use methods on it to pull out values
      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").remove()
        } else if (jqXHR.status == 200) {
          document.location = data;
        }
      });
    }

  });

});