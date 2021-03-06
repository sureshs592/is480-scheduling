<%-- 
    Document   : milestoneconfig
    Created on : Aug 23, 2013, 10:09:25 PM
    Author     : Prakhar
--%>

<%@ taglib prefix="s" uri="/struts-tags" %>

<!DOCTYPE html>
<html>
    <head>
        <%@include file="header.jsp" %>
        <title>IS480 Scheduling System | Milestones </title>
    </head>
    <body>
        <%@include file="navbar.jsp" %>
        <div class="container">
            <h3>Milestone Configuration <span class="muted" style="font-style: italic; font-size: 14px;">(Affects only future schedules)</span></h3>
            <!-- Kick unauthorized user -->
            <% if (!activeRole.equals(Role.ADMINISTRATOR) && !activeRole.equals(Role.COURSE_COORDINATOR)) {
                    request.setAttribute("error", "Oops. You are not authorized to access this page!");
                    RequestDispatcher rd = request.getRequestDispatcher("error.jsp");
                    rd.forward(request, response);
			} %>

            <!-- SECTION: Booking History -->
			<table class="milestoneConfigTable table table-hover zebra-striped" cellspacing="0">
				<thead>
					<tr>
						<th style="width: 5px;">Order</th>
						<th style="width: 10px;">Milestone</th>
						<th style="width: 5px;">Duration (Mins)</th>
						<th style="width: 100px;">Required Attendees</th>
						<th style="width: 10px;"></th>
						<th style="width: 10px;"></th>
					</tr>
				</thead>
				<tbody> 
            <s:if test="%{data.size() > 0 && data != null}"> 
                        <s:iterator value="data">
                            <tr class='milestoneRow' id='row_<s:property value="id"/>'>
                                <td class='orderNum'></td>
                                <td><input type='text' id='name_<s:property value="id"/>' class='milestoneNameInput' style="width:90px; height:20px" value='<s:property value="milestone"/>'/></td>
                                <td class='fuelux'>
									<div id='duration_<s:property value="id"/>' class="durationSpinnerInput spinner">
										<input class="durationInput spinner-input" type="text" style='width: 50px !important'/>
										<div class="spinner-buttons btn-group btn-group-vertical">
											<button class="btn spinner-up" type="button">
												<i class="fa fa-chevron-up"></i>
											</button>
											<button class="btn spinner-down" type="button">
												<i class="fa fa-chevron-down"></i>
											</button>
										</div>
									</div>
                                </td>
                                <td>
									<select id='attendees_<s:property value="id"/>' class='attendeesMultiselect multiselect' multiple='multiple'>
										<option value='supervisor'>Supervisor</option>
										<option value='reviewer1'>Reviewer1</option>
										<option value='reviewer2'>Reviewer2</option>
									</select>
                                </td>
                                <td>
                                    <button type="button" title="Delete Milestone" class="deleteMilestoneBtn btn btn-danger">
                                        <i class='fa fa-trash-o fa-white'></i>
                                    </button>
									<i class='fa moveIcon fa-move fa-black'></i>
                                </td>
                            </tr>
                        </s:iterator>
					</s:if>
				<s:else>
					<tr><h4 class="noMilestoneMsg">No default milestones to set!</h4></tr>
				</s:else>
				</tbody>
			</table>
				
			<table id='milestoneConfigButtons'>
				<tr>
					<td><button type="button" class="btn btn-primary saveMilestonesBtn" style="width:80px; height:30px;"><b>Save</b></button></td>
					<td><button class="btn btn-warning addMilestoneBtn" style="width:160px; height:30px"><i class="fa fa-black fa-plus-circle"></i><b>Add Milestone</b></button></td>
				</tr>
			</table>
				
        </div>
		
		<%@include file="footer.jsp"%>
        <script type="text/javascript">
			milestoneConfigLoad = function() {
				var milestones = {};
				
				loadMilestones();
				resetPlugins();
				
				function loadMilestones() {
					<s:iterator value="data">
						var milestoneName = "<s:property value="milestone"/>";
						milestoneName = milestoneName.replace(' ', '').toLowerCase();
						milestones[milestoneName] = {
							duration: "<s:property value="duration"/>",
							order: "<s:property value="order"/>",
							attendees: JSON.parse('<s:property escape="false" value="attendeesJson"/>')
						};
					</s:iterator>
//					console.log('JSON: ' + JSON.stringify(milestones));
				}
				
				//Delete milestone
				$('body').on('click', '.deleteMilestoneBtn', function(e){
					if (uatMode) recordHumanInteraction(e);
					var $milestoneTr = $(this).closest('tr');
					$milestoneTr.fadeOut('slow', function(){
						$milestoneTr.remove();
						resetPlugins();
					});
					return false;
				});
				
				//Add milestone
				$(".addMilestoneBtn").on('click', function(e){
					if (uatMode) recordHumanInteraction(e);
					$(".noMilestoneMsg").fadeOut('slow', function(){
						$(this).remove();
					});
					$(document.createElement('tr'))
						.addClass('milestoneRow')
						.append(
							//OrderNum
							$(document.createElement('td'))
								.addClass('orderNum')
						)
						.append(
							//Milestone name
							$(document.createElement('td'))
								.append(
									$(document.createElement('input'))
										.attr('type', 'text')
										.addClass('milestoneNameInput')
										.css({'width': '90px', 'height':'20px'})
								)
						)
						.append(
							//Duration
							$(document.createElement('td'))
								.addClass('fuelux')
								.append(
									$(document.createElement('div'))
										.addClass('durationSpinnerInput spinner')
										.append(
											$(document.createElement('input'))
												.attr('type', 'text')
												.addClass('durationInput spinner-input')
												.css('cssText', 'width: 50px !important')
										)
										.append(
											$(document.createElement('div'))
												.addClass('spinner-buttons btn-group btn-group-vertical')
												.append(
													$(document.createElement('button'))
														.attr('type', 'button')
														.addClass('btn spinner-up')
														.append($(document.createElement('i')).addClass('fa fa-chevron-up'))
												)
												.append(
													$(document.createElement('button'))
														.attr('type', 'button')
														.addClass('btn spinner-down')
														.append($(document.createElement('i')).addClass('fa fa-chevron-down'))
												)
										)
								)
						)	
						.append(
							//Attendees
							$(document.createElement('td'))
								.append(
									$(document.createElement('select'))
										.addClass('attendeesMultiselect multiselect')
										.attr('multiple', 'multiple')
										.append(function() {
												var optionsArray = new Array();
												optionsArray.push($(document.createElement('option')).attr('value', 'supervisor').html('Supervisor'));
												optionsArray.push($(document.createElement('option')).attr('value', 'reviewer1').html('Reviewer1'));
												optionsArray.push($(document.createElement('option')).attr('value', 'reviewer2').html('Reviewer2'));
												return optionsArray;
											}
										)
								)
						)
						.append(
							//Delete Button
							$(document.createElement('td'))
								.append(
									$(document.createElement('button'))
										.attr('type', 'button')
										.attr('title', 'Delete Milestone')
										.addClass('deleteMilestoneBtn btn btn-danger')
										.append($(document.createElement('i')).addClass('fa fa-trash-o fa-white'))
								)
								.append($(document.createElement('i')).addClass('moveIcon fa fa-move fa-black'))
						)
						.appendTo('.milestoneConfigTable tbody');
						resetPlugins();
					return false;
				});
				
				//Save milestones
				$('.saveMilestonesBtn').on('click', function(e){
					if (uatMode) recordHumanInteraction(e);
					$(".noMilestoneMsg").fadeOut('slow', function(){
						$(this).remove();
					});
					$('button').attr('disabled', true);
					var updatedMilestones = new Array();
					$('.milestoneRow').each(function(){
						var $this = $(this);
						updatedMilestones.push({
							newOrderNumber: $this.find('.orderNum').text().toString(),
							newMilestoneName: $this.find('.milestoneNameInput').val(),
							newDuration: $this.find('.durationSpinnerInput').spinner('value').toString(),
							newAttendees: $this.find('.attendeesMultiselect').next().find('.dropdown-toggle').attr('title').replace(' ', '')
						});
					});
					console.log('Submitting: ' + JSON.stringify(updatedMilestones));
					$.ajax({
						type: 'POST',
						async: false,
						url: 'updateMilestoneSettings',
						data: {jsonData: JSON.stringify(updatedMilestones)}
					})
					.done(function(response) {
						if (!response.exception) {
							if (response.success) {
								showNotification("SUCCESS", response.message);
							} else {
								showNotification("INFO", response.message);
							}
						} else {
							var eid = btoa(response.message);
							window.location = "error.jsp?eid=" + eid;
						}
					})
					.fail(function(response) {
						$(".saveMilestonesBtn").button('reset');
						showNotification("WARNING", "Oops.. something went wrong");
					});
					$('button').attr('disabled', false);
					return false;
				});
				
				/** Notification **/
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
				
				function resetPlugins() {
					//Attendees Multiselect
					$('.attendeesMultiselect').multiselect('rebuild');
					$('.attendeesMultiselect').each(function(){
						if ($(this).attr('id')) {
							var milestoneName = $(this).attr('id').split('_')[1].toLowerCase();
							var attendees = milestones[milestoneName].attendees;
							for (var i = 0; i < attendees.length; i++) {
								$(this).multiselect('select', attendees[i].toLowerCase().replace(' ', ''));
							}
						}
					});

					//Duration Spinner
					$('.spinner').each(function(){
						$(this).spinner({
							min: 30,
							max: 180,
							step: 30
						});
						if (!$(this).attr('id')) {
							$(this).spinner('value', 30);
							return true;
						}
						var milestoneName = $(this).attr('id').split('_')[1].toLowerCase();
						var duration = parseInt(milestones[milestoneName].duration);
						$(this).spinner('value', duration);
					});
					$('.spinner').on('focusout', function(){
						var value = $(this).spinner('value');
						if (value % 30 !== 0) {
							$(this).spinner('value', value - (value % 30) === 0?30:value - (value % 30));
						}
					});
					
					//Drag and Drop milestones
					$('tbody').find('td.orderNum').each(function(i){
						$(this).empty();
						$(this).append(i + 1);
					});
					
					$(".milestoneConfigTable tbody").sortable({
						helper: function(e, $tr) {
							var $originals = $tr.children();
							var $helper = $tr.clone();
							$helper.children().each(function(index) {
								$(this).width($originals.eq(index).width());
							});
							return $helper;
						},
						stop: function(e, ui) {
							ui.item.parent().find('td.orderNum').each(function(i){
								$(this).empty();
								$(this).append(i + 1);
							});
						}
					});
					
					$(".milestoneConfigTable tbody").sortable('refresh');
				}
				
			};
			
			addLoadEvent(milestoneConfigLoad);
        </script>
    </body> 
</html>
