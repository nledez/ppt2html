$(function () {
    $("#sommaire")
    .bind("loaded.jstree", function (event, data) {
      when_tree_is_ready();
    })
    .jstree({
      "themes" : {
      "theme" : "classic",
      "icons" : false
      },
      "plugins" : [ "themes", "html_data" ]
      });
    });
