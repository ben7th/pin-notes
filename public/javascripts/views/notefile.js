/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
(function(){

  jQuery(".new_notefile").click(function(evt){
    var ids = jQuery(".notefiles .notefile").map(function(){
      return jQuery(this).attr("data-notefile_id")
    }).get();
    var next_id = Math.max.apply( Math, ids ) + 1
    jQuery.ajax({
      type: "POST",
      url: "/notes/new_file",
      data: {
        "next_id" : next_id
      },
      success: function(dom_str){
        jQuery(".notefiles").append(dom_str)
      }
    });
    evt.preventDefault();
  });

  jQuery(".delete_notefile").click(function(evt){
    if(confirm("确定要删除吗？")){
      var notefile = jQuery(this).closest(".notefile")
      notefile.find(".notefile_form").remove()
      notefile.find(".notefile_delete_tip").removeClass("hide")
      notefile.find(".delete_notefile").addClass("hide")
      hide_delete_notefile()
    }
    evt.preventDefault();
  });

  function hide_delete_notefile(){
    if(jQuery(".notefiles .notefile_form").size() == 1){
      jQuery(".notefiles .notefile").each(function(){
        jQuery(this).find(".delete_notefile").addClass("hide")
      })
    }
  }
})();


