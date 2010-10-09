/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
jQuery(".new_notefile").click(function(evt){
  order = jQuery(".notefiles .notefile").size() + 1
  jQuery.ajax({
   type: "POST",
   url: "/notes/new_file",
   data: {"order" : order},
   success: function(dom_str){
     jQuery(".notefiles").append(dom_str)
   }
  });
  evt.preventDefault();
});


