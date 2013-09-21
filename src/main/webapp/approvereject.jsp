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
        <%@include file="header.jsp" %>
        <title>IS480 Scheduling System | Approve</title>
        <link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/css/jquery.dataTables.css">
    </head>
    <body>
        <%@include file="navbar.jsp" %>
		
		 <!-- Kick unauthorized user -->
        <%
            if (!activeRole.equals(Role.FACULTY)) {
                request.setAttribute("error", "Oops. You are not authorized to access this page!");
                RequestDispatcher rd = request.getRequestDispatcher("error.jsp");
                rd.forward(request, response);
            }
         %>
		 
        <div class="container">
        <h3>Approve Booking</h3>
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
			<!-- SECTION: Approve/Reject Bookings -->
			<s:if test="%{data != null && data.size() > 0}"> 
				<%--<s:if test="%{teamName != null}"> --%>
				<!--<form id="myform" action="updateBookingStatus" method="post">-->
					<table id="approveRejectTable" class="table table-hover" style="font-size: 13px;">
						<thead>
							<tr>
								<%--<th>Team Id</th>--%>
								<!--<th><input type="checkbox" name="checkall" onClick="toggle(this);"></th>-->
								<th>Team Name</th>
								<th>Presentation</th>
								<th>My Role</th>
								<th>Date & Time</th>
								<th>Venue</th>
								<th>My Status</th>
								<th></th>
							</tr>
						</thead>
						<tbody> 
							<s:iterator value="data">
								<s:if test="%{myStatus.equalsIgnoreCase('Pending')}"> 
									<tr class="warning">
								</s:if><s:elseif test="%{myStatus.equalsIgnoreCase('Approved')}">
									<tr class="success">
								</s:elseif><s:elseif test="%{myStatus.equalsIgnoreCase('Rejected')}">
									<tr class="error">
								</s:elseif>
								<!--<tr>-->	
									<%--<s:if test='myStatus.equals("PENDING")'>
										<td><input type="checkbox" id="approveRejectArray" name="approveRejectArray" value="<s:property value="bookingId"/>"/></td>
									</s:if><s:else>
										<td><i class="icon-ok"></i></td>
									</s:else>--%>
									<td><s:property value="teamName"/></td>
									<td><s:property value="milestone"/></td>
									<td><s:property value="userRole"/></td>
									<td><s:property value="date"/> <s:property value="time"/></td>
									<td><s:property value="venue"/></td>
									<td>
										<s:property value="myStatus"/><br/><br/>
									</td>
									<td>
										<button type="button" class="btn btn-success" id="approve" value="<s:property value="bookingId"/>" 
												name="approve" onClick="approveBooking(this);">
											Approve
										</button>
										<span class="button-divider">
										<button type="button" class="btn btn-danger" id="reject" value="<s:property value="bookingId"/>" 
												name="reject" onClick="rejectBooking(this);">
											Reject
										</button>
										</span>
									</td>
								</tr>
							</s:iterator>
							</tbody>
						</table>
						<br/><br/>
				<!--<input type="hidden" id="bookingIdValue" />-->
				<!-- Modal -->
				<div class="modal hide fade in" id="rejectionModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
					<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal" aria-hidden="true">�</button>
						<h3 id="myModalLabel">Information Required</h3>
					</div>
					<div class="modal-body">
						<form id="rejectForm">
						<table>
							<tr>
								<td width="150px">
									Reason for Rejecting <br/>
									<i style="font-size: 13px;">(55 characters max.)</i>
								</td>
								<!--<th>Add Proxy</th>-->
								<td><textarea rows="1" id="rejectionText" name="rejectiontText" style="width:350px; height:50px;" 
											  placeholder="Unexpected Meeting..." maxlength="55"></textarea>
								</td>
							</tr>
							<tr>
								<td></td>
								<td>
									<span id="errorMsg" class="hide text-error">Please enter a reason for rejecting this booking!</span>
								</td>
							</tr>
						</table>
						</form>
					</div>
					<div class="modal-footer">
						<button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
						<button class="btn btn-primary" data-dismiss="modal" id="rejectionTextSubmit">Save</button>
					</div>
				</div>
			</s:if><s:else>
				<h4>No pending bookings available!</h4>
			</s:else>
		
        <script src="js/plugins/bootstrap.js" type="text/javascript"></script>
        <%-- <% String statuses = '<s:property value="message" />'; %> --%>
		
		<h4 id="approveRejectMessage"></h4>
        </div>
		<%@include file="footer.jsp"%>
		<script type="text/javascript" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min.js"></script>
		<script type="text/javascript">

		function approveBooking(e) {
			//Disabling all buttons on page to avoid multiple clicking
			$('button[type=button]').attr('disabled', true);
			
			var bookingId =  $(e).val();
			console.log(bookingId);
			var id = $(e).attr("id");
			console.log(id);
			
			var bookingArray = {};
			if (id === 'approve') {
				bookingArray['bookingId'] = bookingId;
				bookingArray['status'] = "approve";
			} 			
			submitBookingData(bookingArray);
		}
		
		//AJAX call
		function submitBookingData(bookingArray) {
//			alert(JSON.stringify(bookingArray));
			$.ajax({
				type: 'POST',
				async: false,
				url: 'updateBookingStatus',
				data: {jsonData: JSON.stringify(bookingArray)}
				}).done(function(response) {
				   if (!response.exception) {
					   if (response.success) {
						   showNotification("SUCCESS", response.message);
					   } else {
						   showNotification("ERROR", response.message);
					   }
//					   window.location.reload(true);
					   timedRefresh(2000);
//					   $('button[type=button]').attr('disabled', false);
				   } else {
					   var eid = btoa(response.message);
					   window.location = "error.jsp?eid=" + eid;
				   }
				}).fail(function(error) {
				   $('button[type=button]').attr('disabled', false);
				   console.log("Updating Booking Status AJAX FAIL");
				   showNotification("WARNING", "Oops.. something went wrong");
				});
				return false;
		}
		
		function rejectBooking(e) {
			//Disabling all buttons on page to avoid multiple clicking
			$('#rejectionModal').modal({
				keyboard: true
			});
			
			$('#rejectionModal').on('shown', function () {
				$('#rejectionText').focus();
			});

			var bookingId =  $(e).val();
//			$('#bookingIdValue').val(bookingId);
			var id = $(e).attr("id");
		
			$('#rejectionTextSubmit').click(function(){
				if ($('#rejectionText').val() === "") {
				  //$('#rejectionText').next('.help-inline').show();
				  $('#errorMsg').show();
				  return false;
				} else {
					var bookingArray = {};
//					bookingArray['bookingId'] = $('#bookingIdValue').val();
					bookingArray['bookingId'] = bookingId;
					bookingArray['status'] = "reject";
					bookingArray['rejectReason'] = $('#rejectionText').val();
					//return true;
	//					alert(JSON.stringify(bookingArray));	
					submitBookingData(bookingArray);
				}
			});
		}  //end of reject
		 
		//Deleting the data in the modal once it is hidden
		$('#rejectionModal').on('hidden', function() {
//			console.log("hidden");
//			$(this).removeData('#rejectionText');
//			$("#rejectionText").val(null);
//			$("#errorMsg").hide();
			location.reload(true);
		});
		
		function timedRefresh(timeoutPeriod) {
			setTimeout("location.reload(true);", timeoutPeriod);
		}
			
		//For data tables
		$(document).ready(function(){
			$('#approveRejectTable').dataTable({
				"aLengthMenu": [
					[5, 10, 20, -1],[5, 10, 20, "All"]], 
				"iDisplayLength" : -1,
//				"bPaginate": false,
//				"bLengthChange": false,
//				"bFilter": false,
//				"bSort": false,
				"bInfo": false,
//				"bAutoWidth": false,
//				"asStripClasses": null,
				//To prevent highlighing of sorted column
				"bSortClasses": false
			});
			
			$('.dataTables_filter input').attr("placeholder", "e.g. Acceptance");
			$('.dataTables_filter input').attr("title", "Search any keyword in the table below");
			$('.dataTables_filter input').on('mouseenter', function(){
				$(this).tooltip('show');
			});
		});
		
		//Notification-------------
		function showNotification(action, notificationMessage) {
			var opts = {
				title: "Note",
				text: notificationMessage,
				type: "warning",
				icon: false,
				sticker: false,
				mouse_reset: false,
				animation: "fade",
				animate_speed: "fast",
				before_open: function(pnotify) {
					pnotify.css({
					   top: "52px",
					   left: ($(window).width() / 2) - (pnotify.width() / 2)
					});
				}
			};
			switch (action) {
				case "SUCCESS":
					opts.title = "Updated";
					opts.type = "success";
					break;
				case "ERROR":
					opts.title = "Error";
					opts.type = "error";
					break;
				case "INFO":
					opts.title = "Error";
					opts.type = "info";
					break;
				case "WARNING":
					$.pnotify_remove_all();
					opts.title = "Note";
					opts.type = "warning";
					break;
				default:
					alert("Something went wrong");
			}
			$.pnotify(opts);
		}
		//To check/uncheck all boxes
//		function toggle(oInput) {
//			var aInputs = document.getElementsByTagName('input');
//			for (var i=0;i<aInputs.length;i++) {
//				if (aInputs[i] != oInput) {
//					aInputs[i].checked = oInput.checked;
//				}
//			}
//		}
		
		//To validate the form (Make sure all checkboxes have been checked
//		function valthisform() {
//			var checkboxs=document.getElementsByName("approveRejectArray");
//			var okay = false;
//			for(var i = 0, l = checkboxs.length; i<l; i++) {
//				if(checkboxs[i].checked) {
//					okay = true;
//				}
//			}
//			if(!okay) {
//				alert("Please choose a timeslot!");
//				return false;
//			}
//			return true;
//		}
		
//		jQuery(document).ready(function(){
//			if(document.getElementById('approveRejectArray') === null) {
//				 document.getElementById("approveButton").style.visibility = "hidden";
//				 document.getElementById("rejectButton").style.visibility = "hidden";
//			} else {
//				document.getElementById("approveButton").style.visibility = "visible";
//				document.getElementById("rejectButton").style.visibility = "visible";
//			}
//		});
		
		//Disabling buttons when checkboxes are unchecked and vice-versa
//		$(document).ready(function (){
//			$('#approveButton').attr('disabled','disabled');
//			$('#rejectButton').attr('disabled','disabled');
//			$('#approveRejectArray').change(function(){
//			if($(this).is(':checked')){
//				$('#approveButton').removeAttr('disabled');                
//				$('#rejectButton').removeAttr('disabled');
//			}
//			else {
//				// remove
//				$('#approveButton').attr('disabled','disabled');
//				$('#rejectButton').attr('disabled','disabled');
//			}
//		})
//		});
		//To show/hide buttons if checkbox exists or not
		</script>
    </body>
</html>
