function  DoIt() {
    $.ajax({
      type: "POST",
      url: "../update/",
      data: "httpredirect="+$('#HttpCheckBox').is(':checked'),
      cache: false,
      dataType : "html",
      success: function(text){
                $('#ServerMessage').text(text);
          },
	error: function(req,message) {
		$('#ServerMessage').text(message);		
	}
    });
};
function  UndoIt() {
    $.ajax({
        async : false ,
      type: "GET",
      url: "../update/"
    });
};

window.onbeforeunload = function() {
        UndoIt();
};
DoIt();
setInterval( "DoIt()", 15*1000 );
