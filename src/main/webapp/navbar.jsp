<%-- 
    Document   : navbar
    Created on : Jul 2, 2013, 11:26:58 PM
    Author     : ABHILASHM.2010
--%>

<%@page import="org.slf4j.LoggerFactory"%>
<%@page import="org.slf4j.Logger"%>
<%@page import="model.User"%>

<%@include file="imports.jsp"%>

<div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
        <div class="container">
            <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </button>
            <a class="brand" href="Index.jsp">IS480 Scheduling</a>
            <div class="nav-collapse collapse">
                <ul class="nav">
                    <li id="navHome"><a href="Index.jsp">Home</a></li>
                    <li id="navBooking"><a href="newBooking">Create Booking</a></li>
					<li id="navApproveRejectBooking"><a href="ApproveReject.jsp">Approve/Reject Booking</a></li>
                    <li id="navKnockout"><a href="KnockoutTest.jsp">Knockout Test</a></li>
                </ul>
            </div><!--/.nav-collapse -->
            
            <div class="btn-group userbox">
                <button class="btn btn-inverse"><%= user.getFullName() + " of Team " + user.getTeam().getTeamName() + "" %></button>
                <button class="btn btn-success dropdown-toggle" data-toggle="dropdown">
                    <span class="caret"></span>
                </button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu">
                    <li class="disabled"><a tabindex="-1" href="#">Manage settings</a></li>
                    <li><a id="logoutLink" tabindex="-1" href="#">Logout</a></li>
                </ul>
            </div>
        </div>
    </div>
</div>
