<%@page import="model.User"%>

<!-- CSS imports -->
<link href="css/app.css" rel="stylesheet">
<link href="css/redmond/jquery-ui-1.10.3.custom.min.css" rel="stylesheet">
<link href="css/redmond/jquery.timepicker.css" rel="stylesheet">
<link href="css/bootstrap.css" rel="stylesheet" media="screen">
<link href="css/jquery.pnotify.default.css" rel="stylesheet">

<!-- Ensure user has logged in -->
<% User user = (User) session.getAttribute("user");
if (session.getAttribute("user") == null) {
	response.sendRedirect("login.jsp");
	return; 
}
%>

<script type="text/javascript">
    //This is used for multiple window.onload's
    function addLoadEvent(func) {
        var oldonload = window.onload;
        if (typeof window.onload !== 'function') {
            window.onload = func;
        } else {
            window.onload = function() {
                if (oldonload) {
                    oldonload();
                }
                func();
            };
        }
    }
</script>