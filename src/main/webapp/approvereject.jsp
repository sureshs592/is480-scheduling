<%--
    Document   : ApproveReject
    Created on : Jul 2, 2013, 11:14:06 PM
    Author     : Tarlochan
--%>

<%@page import="com.opensymphony.xwork2.ActionContext"%>
<%@page import="com.opensymphony.xwork2.util.ValueStack"%>
<%@page import="model.*"%>
<%@page import="java.util.Date"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="windows-1252"%>
<%@ taglib prefix="s" uri="/struts-tags" %>
<!DOCTYPE html>
<html>
    <head>
        <title>Approve/Reject Booking</title>
		<%@include file="footer.jsp"%>
		<script type="text/javascript">
		//To check/uncheck all boxes
		checked = false;
		function checkedAll () {
		  if (checked == false) {
			  checked = true
		  } else {
			  checked = false
		  }
		  for (var i = 0; i < document.getElementById('myform').elements.length; i++) {
			document.getElementById('myform').elements[i].checked = checked;
		  }
		}
		
		//To validate the form (Make sure all checkboxes have been checked
		function valthisform() {
			var checkboxs=document.getElementsByName("approveRejectArray");
			var okay = false;
			for(var i = 0,l = checkboxs.length; i<l; i++) {
				if(checkboxs[i].checked) {
					okay = true;
				}
			}
			if(!okay) {
				alert("Please choose a timeslot!");
			}
			return false;
		}
		</script>
		
    </head>
    <body>
        <%@include file="navbar.jsp" %>
        <div class="container">
        <h3>Approve/Reject Booking</h3>
        <!--<form action="approveReject" method="post">
			<!-- Putting default values for testing purposes 
            Choose Term <select name="termId"> 
							<option value="1">1</option>
							<option value="2">2</option>
						</select> <br/>
            Enter User Id <input type="text" name="userId" value="6"/> <br/>
			<p style=text-indent:16.5em;>
			   <input type="submit" class="btn btn-primary" value="Search"/>
			</p>
        </form> -->
		
		<div id ="confirmBookings"> 
			<%-- Tab to view Accept/Reject Bookings --%>
			<ul id="approveBookingTab" class="nav nav-tabs">
				<li class="active">
					<a id="acceptReject" data-toggle="tab">Accept/Reject</a>
				</li>
			</ul>

			<!-- SECTION: Approve/Reject Bookings -->
			<s:if test="%{data.size() > 0 && data != null}"> 
				<%--<s:if test="%{teamName != null}"> --%>
				<form id="myform" action="updateBookingStatus" method="post">
					<table class="table table-hover">
						<thead>
							<tr>
								<%--<th>Team Id</th>--%>
								<th><input type="checkbox" name="checkall" onclick="checkedAll();"></th>
								<th>Team Name</th>
								<th>Presentation Type</th>
								<th>Start Time</th>
								<th>End Time</th>
								<th>Venue</th>
								<th>Your Status</th>
							</tr>
						</thead>
						<tbody> 
							<s:iterator value="data">
								<tr>	
									<%--<td><s:property value="teamId"/></td> --%>
									<s:if test='myStatus.equals("PENDING")'>
										<td><input type="checkbox" name="approveRejectArray" value="<s:property value="timeslotId"/>"/></td>
									</s:if><s:else>
										<td>-</td>
									</s:else>
									<td><s:property value="teamName"/></td>
									<td><s:property value="milestoneName"/></td>
									<td><s:property value="startTime"/></td>
									<td><s:property value="endTime"/></td>
									<td><s:property value="venue"/></td>
									<td><s:property value="myStatus"/></td>
								</tr>
							</tbody>
						</table>
						<table>
							<tr>
								<td><input type="submit" class="btn btn-success" value="Approve" name="Approve" onclick='valthisform();'/></td>
								<td><span class="button-divider"><input type="submit" class="btn btn-danger" value="Reject" name="Reject" onclick='valthisform();'/></span></td>
								<!--<td><input type="hidden" name="approveRejectArray" id="approveRejectArray" value="approveRejectArray" /></td> -->
							</tr>
						</table>
					</form>
				</s:iterator>
			</s:if><s:else>
				<h4>No pending bookings available for Approve/Reject!</h4>
			</s:else>
		</div>
		
		
        <script src="js/plugins/bootstrap.js" type="text/javascript"></script>
        <%-- <% String statuses = '<s:property value="message" />'; %> --%>
		
		<br/>
        </div>
    </body>
</html>
