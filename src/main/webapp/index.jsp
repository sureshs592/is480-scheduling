<%@page import="manager.UserManager"%>
<%@page import="model.role.Student"%>
<%@page import="model.Team"%>
<%@page import="model.Term"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ taglib prefix="s" uri="/struts-tags" %>
<!DOCTYPE HTML>
<%
    Term activeTerm = (Term) session.getAttribute("currentActiveTerm");
%>
<html>
    <head>
        <%@include file="header.jsp" %>
        <title>IS480 Scheduling System</title>
		<style>
			 .bootbox-width {width: 480px !important;}
		</style>
    </head>
    <body>
        <!-- Navigation -->
        <%@include file="navbar.jsp" %>
        <%
            Team team = null;
            String fullName = null;
            if (activeRole.equals(Role.STUDENT)) {
                Student studentUser = UserManager.getUser(user.getId(), Student.class);
                team = studentUser.getTeam();
                fullName = studentUser.getFullName();
            }
        %>

        <!-- Welcome Text -->
        <div class="container page">
            <!--<h3 id="activeTermName"><%= ((Term)session.getAttribute("currentActiveTerm")).getDisplayName() %></h3>-->
				<div class='indexItem pull-left termPicker'>
					<div class="btn-group" style="float: left;">
						<a class="btn btn-large dropdown-toggle" data-toggle="dropdown" href="#" >
							<b><%= ((Term)session.getAttribute("currentActiveTerm")).getDisplayName() %></b> <span class="caret"></span>
						</a>
						<ul class="dropdown-menu">
							<form id="activeTermForm" action="index" method="post">
									<s:iterator value="data">
										<li>
											<button type="submit" class="btn btn-link" name="termId" value="<s:property value="termId"/>">
												<s:property value="termName"/>
											</button>
										</li>
									</s:iterator>
							</form>
						</ul>
					</div>
				</div>
					
			<!-- To display number of pending bookings for supervisor/reviewer -->
            <% if (activeRole.equals(Role.FACULTY)) {%>
            <s:if test="%{pendingBookingCount > 0}">
                <div class="indexItem pendingBookings alert">
                    <button type="button" class="close" data-dismiss="alert">×</button>
                    <a href="approveReject" style="color:#B88A00;">
                        <s:if test="%{pendingBookingCount > 1}">
                            <u>You have <s:property value="pendingBookingCount"/> pending bookings!</u>
                        </s:if><s:else>
							<u>You have <s:property value="pendingBookingCount"/> pending booking!</u>
                        </s:else>
                    </a>
                </div>
            </s:if>
            <% } %>
			
			<div class="settingsView indexItem">
				<button id="downloadICSBtn" class="btn btn-primary" style="margin-right: 10px; text-align: left"><i class="fa fa-calendar" style="margin-right: 4px"></i>Download Calendar</button>
				<span id="settingsViewLabel">Select View: </span>
				<div id="weekView" data-on="primary" data-off="info" data-on-label="Full" data-off-label="Week" class="make-switch switch-small">
					<input type="checkbox" checked>
				</div>
				<i id='previousWeek' class='traverseWeek fa fa-arrow-circle-o-left' style='color: #5bc0de; display: none; cursor: pointer'></i>
				<i id='nextWeek' class='traverseWeek fa fa-arrow-circle-o-right' style='color: #5bc0de; display: none; cursor: pointer'></i>
            </div>

            <!-- To display legend for the calendar -->
            <table class="indexItem legend">
                <tr>
                    <td class="legendBox unbookedTimeslot" style="border-width:1px!important;width:17px;"></td><td>&nbsp;Available</td> 
                    <td style="width:15px"></td>
                    <td class="legendBox pendingBooking" style="border-width:1px!important;width:17px;"></td><td>&nbsp;Pending</td> 
                    <td style="width:15px"></td>
                    <td class="legendBox approvedBooking" style="border-width:1px!important;width:17px;"></td><td>&nbsp;Approved</td> 
                    <td style="width:15px"></td>
					<% if (activeRole.equals(Role.STUDENT)) {%>
                    <td class="legendBox rejectedBooking" style="border-width:1px!important;width:17px;"></td><td>&nbsp;Rejected</td> 
                    <td style="width:15px"></td>
					<% } %>
					<% if (activeRole.equals(Role.STUDENT) || activeRole.equals(Role.FACULTY)) {%>
                    <td class="legendBox unbookedTimeslot unavailableTimeslot" style="border-width:1px!important;width:17px;"></td><td>&nbsp;Not Available</td> 
					<% } else if (activeRole.equals(Role.TA)) { %>
					<td class="legendBox unbookedTimeslot taChosenTimeslot" style="border-width:1px!important;width:19px;"></td><td style="padding-right: 5px;">&nbsp;Your video signup</td>
					<td class="legendBox unbookedTimeslot otherTATimeslot" style="border-width:1px!important;width:19px;"></td><td>&nbsp;Another TA signup</td>
					<% } %>
                </tr>
            </table>
        </div>

        <!-- Main schedule navigation -->
        <div class="scheduleContainer container page">
            <ul id="milestoneTab" class="nav nav-tabs">
                <!-- milestone tabs populated dynamically -->
            </ul>
            <div id="milestoneTabContent" class="tab-content" hidden="">
                <!-- milestone tables populated dynamically -->
            </div>
            <div id="scheduleProgressBar" class="progress progress-striped active">
                <div class="bar" style="width: 100%;"></div>
            </div>
        </div>

        <%@include file="footer.jsp"%>
        <!-- View Schedule Javascript -->
        <script type="text/javascript">
            //Makes use of footer.jsp's jQuery and bootstrap imports
            viewScheduleLoad = function() {
                //Index page stuff
				
                /*****************************
                    DECLARE COMMON VARIABLES
                ******************************/
               
                //Default milestone is ACCEPTANCE
                var milestone = null;
                var year = "<%= activeTerm.getAcademicYear()%>";
                var semester = "<%= activeTerm.getSemester()%>";
                var scheduleData = null; //This state shall be stored here
                var weekView = null;
				var maxWeekView = null;
				var myEmail = "<%= user.getEmail() %>";
				var myFullName = "<%= user.getFullName() %>";
                
                //Student-specific variables
                var teamName = "<%= team != null ? team.getTeamName() : null%>"; //Student's active team name
				if (teamName === "null") teamName = null;
                
                //Admin specific variables
				var teams = null;
				var milestonesJson = null;
				if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) || activeRole.equals(Role.FACULTY) %>) {
					teams = JSON.parse('<s:property escape= "false" value= "allTeamsJson"/>');
					milestonesJson = JSON.parse('<s:property escape= "false" value= "milestonesJson"/>');
				}
                var $teamDropDownSelect = null;
                var createBookingOutputForAdmin = null;
				
                //TA specific variables
                var loggedInTa = <%= user.getId() %>;
                
                //Booking specific variables
                var self = null;
                var users = JSON.parse('<s:property escape= "false" value= "allUsersJson"/>');
                
                populateMilestones();
                
                //Build the base of the page (Milestone tabs and tables)
                function populateMilestones() {
                    var milestones = getScheduleData(null, year, semester).milestones;
					//Sort milestones by order
                    function compare(a, b) {
                        if (a.milestoneOrder < b.milestoneOrder) {
                            return -1;
                        } else if (a.milestoneOrder > b.milestoneOrder) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
					milestones.sort(compare);
					var setAsActive = true;
					var now = new Date();
                    for (var i = 0; i < milestones.length; i++) {
						$('ul#milestoneTab') //Add the milestone tab
							.append(
								$(document.createElement('li'))
									.addClass(setAsActive?'active':'')
									.append(
										$(document.createElement('a'))
											.attr('id', milestones[i].name.toLowerCase())
											.attr('href', '#' + milestones[i].name.toLowerCase())
											.attr('data-toggle', 'tab')
											.html(milestones[i].name)
									)
							);
						$('div#milestoneTabContent') //Add the milestone table
							.append(
								$(document.createElement('div'))
									.attr('id', milestones[i].name.toLowerCase() + "Content")
									.addClass('tab-pane fade')
									.addClass(setAsActive?'active in':'')
									.append(
										$(document.createElement('table'))
											.attr('id', milestones[i].name.toLowerCase() + "ScheduleTable")
											.addClass('scheduleTable table-condensed table-hover table-bordered')
									)
							);
						if (now >= Date.parse(milestones[i].startDate) && now <= Date.parse(milestones[i].endDate)) milestone = milestones[i].name.toUpperCase();
						else if (milestones[i + 1] && now >= Date.parse(milestones[i].endDate)) milestone = milestones[i + 1].name.toUpperCase();
						else if (setAsActive) milestone = milestones[i].name.toUpperCase();
						setAsActive = false;
                    }
                }

                //Function to change schedule based on selected milestone tab
                $('#milestoneTab a').on('click', function(e) {
                    if (uatMode) recordHumanInteraction(e);
					$("#milestoneTab").removeClass('active in');
                    $(this).tab('show');
                    milestone = $(this).attr('id').toUpperCase();
                    year = "<%= activeTerm.getAcademicYear()%>";
                    semester = "<%= activeTerm.getSemester()%>";
                    populateSchedule(milestone, year, semester);
					$("#weekView").bootstrapSwitch('setState', true);
                    return false;
                });
				//Select active milestone
				$('.nav-tabs a#' + milestone.toLowerCase()).trigger('click');
                
                //GetScheduleAction data
                function getScheduleData(milestone, year, semester) {
                    var toReturn = null;
                    var data = {
						milestone: milestone,
                        year: year,
                        semester: semester
                    };
                    //Get schedule action
                    $.ajax({
                        type: 'GET',
                        data: data,
                        async: false,
                        url: 'getSchedule',
                        cache: false,
                        dataType: 'json'
                    }).done(function(response) {
                        if (response.success) {
                            toReturn = response;
                        } else {
                            var eid = btoa(response.message);
                            window.location = "error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        toReturn = "AJAX fail";
                    });
                    return toReturn;
                }

                //View Schedule stuff
                //Function to populate schedule data based on ACTIVE TERM
                function populateSchedule(milestone, year, semester) {
                    $(".scheduleTable").empty();
					$(".timeslotCell").remove();
                    //Hide schedule tab and show progress bar
                    $("#milestoneTabContent").hide();
                    $("#scheduleProgressBar").show();
                    //Generate schedule table
                    scheduleData = getScheduleData(milestone, year, semester);
                    if (scheduleData.success) {
                        //Convert scheduleData timeslots
                        convertScheduleData();
                        //Draw the schedule table
                        renderSchedule();
						setTimeout(function(){renderTimeslots();}, 0);
						//Append popovers
						setTimeout(function(){appendPopovers();}, 0);	
						//Setup mouse events
						setTimeout(function(){setupMouseEvents();}, 0);
						//Add drag and drop
						if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) %>) {
							setTimeout(function(){initDragNDrop();}, 0);
							setTimeout(function(){initDashboards();}, 0);
						} else if (<%= activeRole.equals(Role.FACULTY)%>) {
							setTimeout(function(){initDashboards();}, 0);
						}
                    } else {
                        var eid = btoa(scheduleData.message);
                        window.location = "error.jsp?eid=" + eid;
                    }
                    $("#scheduleProgressBar").hide();
                    $("#milestoneTabContent").show();
                }
                
                //Convert scheduleData to better JSON object
                function convertScheduleData() {
                    var timeslots = scheduleData.timeslots;
                    var newTimeslots = {};
                    for (var i = 0; i < timeslots.length; i++) {
                        var timeslot = timeslots[i];
                        var key = timeslot.datetime;
                        newTimeslots[key] = timeslot;
                    }
                    scheduleData["timeslots"] = newTimeslots;
                }
                
                //Append popover data
                function appendPopovers() {
                    //Show progress bar
                    $('#milestoneTabContent').hide();
                    $('#scheduleProgressBar').show();
                    
                    //Delete all old popovers
                    $('.timeslotCell').trigger('mouseleave').popover('destroy');
                    
                    refreshScheduleData();

                    //Add View Booking popovers
                    $('.bookedTimeslot').each(function() {
                        appendViewBookingPopover($(this));
                    });

                    //Add Create Booking popover for all timeslots if is student, admin, or course coordinator
                    if (<%= activeRole.equals(Role.STUDENT) || activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
                        $('.unbookedTimeslot, .unavailableTimeslot').each(function() {
                            appendCreateBookingPopover($(this));
                        });
                    }
                    if (<%= activeRole.equals(Role.FACULTY) %>) {
                        $('.timeslotCell').each(function() {
                            appendChangeAvailabilityPopover($(this));
                        });
                    }
                    if (<%= activeRole.equals(Role.TA) %>) {
                        $('.timeslotCell').each(function() {
                            appendChangeSignupPopover($(this));
                        });
                    }
                    //Show progress bar
                    $('#scheduleProgressBar').hide();
                    $('#milestoneTabContent').show();
                }
                
                function appendViewBookingPopover($td) {
                    var timeslot = scheduleData.timeslots[$td.attr('value')];
                    var $bookingDetailsTable = $(document.createElement('table'));
                    $bookingDetailsTable.attr('id', 'viewTimeslotTable');
                    $bookingDetailsTable.addClass('table-condensed table-hover table-bordered');
					var outputData = {
						Team: timeslot.wiki ? '<u><a id="wikiLink" href="' + timeslot.wiki + '">' + timeslot.team + '</a></u>':timeslot.team,
						Status: timeslot.status,
						Date: timeslot.startDate,
						Time: timeslot.time,
						Venue: timeslot.venue,
						Students: function(){
							var studentList = '';
							for (var i = 0; i < timeslot.students.length; i++) {
								studentList += (timeslot.students[i].name + "<br/>");
							}
							return studentList;
						},
						Faculty: function(){
							var facultyList = '';
							for (var i = 0; i < timeslot.faculties.length; i++) {
								facultyList += (timeslot.faculties[i].name + " " + (timeslot.faculties[i].status.toLowerCase() ==='pending'?$(document.createElement('i')).addClass('fa fa-cog fa-spin muted').outerHTML():$(document.createElement('i')).addClass('fa fa-check').css('color', '#A9DBA9').outerHTML()) + "<br/>");
							}
							return facultyList;
						},
						TA: timeslot.TA,
						"Invite Others": $(document.createElement('input')).attr('id', 'updateAttendees').addClass('optionalAttendees popoverInput'),
						"": "" //For buttons
					};

                    //Allow team to edit booking
                    if (timeslot.team !== null && timeslot.team === teamName) {
                        outputData[""] += (
							$(document.createElement('button'))
								.attr('id', 'deleteBookingBtn')
								.addClass('popoverBtn btn btn-small btn-danger')
								.append($(document.createElement('i')).addClass('fa fa-trash-o fa-white'))
								.append('Delete')
								.outerHTML()
							+
							$(document.createElement('button'))
								.attr('id', 'updateBookingBtn')
								.addClass('popoverBtn btn btn-small btn-info')
								.append($(document.createElement('i')).addClass('fa fa-pencil fa-white'))
								.append('Save')
								.css('float', 'right')
								.attr('disabled', true)
								.outerHTML()
						);
                    }
					
                    //Allow supervisor to update booking and approve/reject/cancel booking
                    if (<%= activeRole.equals(Role.FACULTY) %> && timeslot.isMyTeam) {
						for (var i = 0; i < timeslot.faculties.length; i++) {
							if (timeslot.faculties[i].name === myFullName) {
								if (timeslot.faculties[i].status === "PENDING") {
									outputData[""] += (
										$(document.createElement('button'))
											.attr('id', 'rejectBookingBtn')
											.addClass('popoverBtn btn btn-small btn-danger')
											.append($(document.createElement('i')).addClass('fa fa-times-circle fa-white'))
											.append('Reject')
											.css('float', 'right')
											.outerHTML()
									);
									outputData[""] += (
										$(document.createElement('button'))
											.attr('id', 'approveBookingBtn')
											.addClass('popoverBtn btn btn-small btn-success')
											.append($(document.createElement('i')).addClass('fa fa-check-circle fa-white'))
											.append('Approve')
											.css('float', 'right')
											.outerHTML()
									);
								} else {
									outputData[""] += (
										$(document.createElement('button'))
											.attr('id', 'cancelBookingBtn')
											.addClass('popoverBtn btn btn-small btn-danger')
											.append($(document.createElement('i')).addClass('fa fa-times-circle fa-white'))
											.append('Cancel')
											.css('float', 'right')
											.outerHTML()
									);
								} ////
								break;
							}
						}
						if (timeslot.status === "APPROVED") {
							outputData[""] += (
								$(document.createElement('button'))
									.attr('id', 'updateBookingBtn')
									.addClass('popoverBtn btn btn-small btn-info')
									.append($(document.createElement('i')).addClass('fa fa-pencil fa-white'))
									.append('Save')
									.css('float', 'right')
									.attr('disabled', true)
									.outerHTML()
							);
						}
                    }
					
					//Allow faculty to change availability on view booking popover
                    if (<%= activeRole.equals(Role.FACULTY) %>) {
						if ($td.closest('.timeslotCell').is('.unavailableTimeslot')) {
							outputData[""] += (
								$(document.createElement('button'))
										.attr('id', 'availableTimeslotBtn')
										.addClass('popoverBtn btn btn-small btn-primary')
										.css('float', 'right')
										.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
										.append("Available")
										.outerHTML()
							);
						} else {
							outputData[""] += (
								$(document.createElement('button'))
										.attr('id', 'unavailableTimeslotBtn')
										.addClass('popoverBtn btn btn-small btn-primary')
										.css('float', 'right')
										.append($(document.createElement('i')).addClass('fa fa-minus-circle fa-white'))
										.append("Unavailable")
										.outerHTML()
							);
						}
                    }
					
					//Allow TA's to change signup on view booking popover
					if (<%= activeRole.equals(Role.TA) %> && !$td.closest('.timeslotCell').is('.otherTATimeslot')) {
						if ($td.closest('.timeslotCell').is('.taChosenTimeslot')) {
							outputData[""] += (
								$(document.createElement('button'))
										.attr('id', 'unsignupTimeslotBtn')
										.addClass('popoverBtn btn btn-small btn-primary')
										.css('float', 'right')
										.append($(document.createElement('i')).addClass('fa fa-minus-circle fa-white'))
										.append("Cancel Signup")
										.outerHTML()
							);
						} else {
							outputData[""] += (
								$(document.createElement('button'))
										.attr('id', 'signupTimeslotBtn')
										.addClass('popoverBtn btn btn-small btn-primary')
										.css('float', 'right')
										.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
										.append("Signup")
										.outerHTML()
							);
						}
                    }

                    //Allow admin to edit fields
                    if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
						outputData.Venue =
								$(document.createElement('input'))
									.attr('id', 'updateFormVenue')
									.attr('type', 'text')
									.attr('placeholder', outputData.Venue)
									.addClass('updateFormVenue popoverInput')
									.val(outputData.Venue).change();
						outputData.Date = 
								$(document.createElement('input'))
									.attr('id', 'updateFormDate')
									.attr('type', 'text')
									.attr('placeholder', outputData.Date)
									.attr('title', 'Enter a new date (YYYY-MM-DD)')
									.addClass('updateFormDate popoverInput')
									.val(outputData.Date).change();
						outputData.Time = 
								$(document.createElement('input'))
									.attr('id', 'updateFormStartTime')
									.attr('type', 'text')
									.attr('placeholder', outputData.Time)
									.attr('title', 'Enter a new start time (HH:MM)')
									.addClass('updateFormDate popoverInput')
									.val(outputData.Time).change();	
                        outputData[""] += (
							$(document.createElement('button'))
								.attr('id', 'deleteBookingBtn')
								.addClass('popoverBtn btn btn-small btn-danger')
								.append($(document.createElement('i')).addClass('fa fa-trash-o fa-white'))
								.append("Delete")
								.outerHTML()
							+
							$(document.createElement('button'))
								.attr('id', 'updateBookingBtn')
								.addClass('popoverBtn btn btn-small btn-info')
								.append($(document.createElement('i')).addClass('fa fa-pencil fa-white'))
								.append("Save")
								.attr('disabled', true)
								.outerHTML()
						);
                    } else if (<%= activeRole.equals(Role.STUDENT) %> && timeslot.team !== teamName || <%= activeRole.equals(Role.FACULTY) %> && !timeslot.isMyTeam || <%= activeRole.equals(Role.TA) %> && loggedInTa !== timeslot.taId || <%= activeRole.equals(Role.GUEST) %>) {
						//Subscribe and Unscribe buttons
						if (timeslot.status === 'APPROVED') {
							var subscribe = true;
							if (timeslot.subscribedUsers) {
								for (var i = 0; i < timeslot.subscribedUsers.length; i++) {
									if (myEmail === timeslot.subscribedUsers[i]) {
										subscribe = false;
											outputData[""] += (
												$(document.createElement('button'))
													.attr('id', 'unsubscribeBtn')
													.addClass('popoverBtn btn btn-small')
													.append($(document.createElement('i')).addClass('fa fa-calendar-o fa-black'))
													.append("Cancel RSVP")
													.outerHTML()
											);
										break;
									}
								}
							}
							if (subscribe) {
								outputData[""] += (
									$(document.createElement('button'))
										.attr('id', 'subscribeBtn')
										.addClass('popoverBtn btn btn-small')
										.append($(document.createElement('i')).addClass('fa fa-calendar fa-black'))
										.append("RSVP")
										.outerHTML()
								);
							}
						}
					}

                    //Append all fields
					for (var key in outputData) {
						if (outputData.hasOwnProperty(key)) {
							$bookingDetailsTable
								.append(
									$(document.createElement('tr'))
										.append($(document.createElement('td')).html(key))
										.append($(document.createElement('td')).html(outputData[key]))
								);
						}
					}

                    //Popover
                    makePopover($td.children('.booking'), timeslot.team !== null && timeslot.team === teamName?"<b>Your Booking</b>":"<b>Team Booking</b>", $bookingDetailsTable);
                }
                
                function appendCreateBookingPopover($td) {
                    if ($td.hasClass('legendBox')) return;
                    var timeslot = scheduleData.timeslots[$td.attr('value')];
                    var $createBookingTable = $(document.createElement('table'));
                    $createBookingTable.attr('id', 'createTimeslotTable');
					$createBookingTable.addClass('table-condensed table-hover table-bordered');
					var outputData = {
						Team: <%= activeRole.equals(Role.STUDENT) %>?teamName:<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) %>?$teamDropDownSelect.outerHTML():'',
						Date: Date.parse($td.attr('value')).toString("dd MMM"),
						Time: Date.parse($td.attr('value')).toString('HH:mm')+ " - " + Date.parse($td.attr('value')).addMinutes(scheduleData.duration).toString('HH:mm'),
						Venue: timeslot.venue,
						Milestone: milestone,
						TA: timeslot.TA,
						"Auto Approve": "",
						Unavailable: "",
						"": "" //For buttons
					};
                   
				   if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) %>) {
					   //Make fields editable for admin
					   outputData.Venue = 
							$(document.createElement('input'))
								.attr('id', 'updateFormVenue')
								.attr('type', 'text')
								.attr('placeholder', outputData.Venue)
								.addClass('updateFormVenue popoverInput')
								.val(outputData.Venue).change();
						outputData[""] += 
							$(document.createElement('button'))
								.attr('id', 'createBookingBtn')
								.addClass('popoverBtn btn btn-small btn-primary')
								.append($(document.createElement('i')).addClass('fa fa-plus-circle  fa-white'))
								.append("Book")
								.outerHTML()
							+
							$(document.createElement('button'))
								.attr('id', 'updateTimeslotBtn')
								.css('float', 'right')
								.addClass('popoverBtn btn btn-small btn-info')
								.append($(document.createElement('i')).addClass('fa fa-pencil fa-white'))
								.append("Save")
								.attr('disabled', true)
								.outerHTML();
						//Override approval of supervisors
						outputData["Auto Approve"] = 
								$(document.createElement('div'))
									.attr('id', 'autoApprove')
									.addClass('make-switch switch-small')
									.attr('data-on', 'success')
									.attr('data-off', 'danger')
									.attr('data-on-label', 'Yes')
									.attr('data-off-label', 'No')
									.attr('padding-left', '30px')
									.append($(document.createElement('input')).attr('type', 'checkbox').attr('name', 'autoApprove').attr('checked', false));
				   } else {
					   delete outputData["Auto Approve"];
				   }
				   
				   if (<%= activeRole.equals(Role.STUDENT)%>) {
					   //For students
					   if ($td.is('.unavailableTimeslot')) {
						   outputData["Unavailable"] = function() {
							   var unavailableList = '';
							   for (var i = 0; i < timeslot.unavailable.length; i++) {
								   unavailableList += timeslot.unavailable[i] + "<br/>";
							   }
							   return unavailableList;
						   };
						outputData[""] += 
							$(document.createElement('button'))
								.attr('id', 'createAnywayBookingBtn')
								.addClass('popoverBtn btn btn-small btn-warning')
								.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
								.append("Book Anyway")
								.outerHTML();
					   } else {
						delete outputData["Unavailable"];
						outputData[""] += 
							$(document.createElement('button'))
								.attr('id', 'createBookingBtn')
								.addClass('popoverBtn btn btn-small btn-primary')
								.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
								.append("Book")
								.outerHTML();
					   }	
				   } else {
						delete outputData["Unavailable"];
				   }
					
                    //Append all fields
					for (var key in outputData) {
						if (outputData.hasOwnProperty(key)) {
							$createBookingTable
								.append(
									$(document.createElement('tr'))
										.append($(document.createElement('td')).html(key))
										.append($(document.createElement('td')).html(outputData[key]))
								);
						}
					}
					
					//Popover
					makePopover($td, $td.is('.unavailableTimeslot')?"Unavailable Timeslot":"Available Timeslot", $createBookingTable);
                }
                
                function appendChangeAvailabilityPopover($td) {
                    if ($td.hasClass('legendBox')) return;
                    var $changeAvailabilityTable = $(document.createElement('table')).attr('id', 'createTimeslotTable');
					$changeAvailabilityTable.addClass('table-condensed table-hover table-bordered');
                    var outputData = {};
					
					outputData["You Are"] = function() {
						if ($td.is('.unavailableTimeslot')) {
							return $(document.createElement('button'))
										.attr('id', 'availableTimeslotBtn')
										.addClass('popoverBtn btn btn-small btn-primary')
										.css('float', 'right')
										.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
										.append("Available")
										.outerHTML();
						} else {
							return $(document.createElement('button'))
										.attr('id', 'unavailableTimeslotBtn')
										.addClass('popoverBtn btn btn-small btn-primary')
										.css('float', 'right')
										.append($(document.createElement('i')).addClass('fa fa-minus-circle fa-white'))
										.append("Unavailable")
										.outerHTML();
						}
					};
					
                    //Append all fields
					for (var key in outputData) {
						if (outputData.hasOwnProperty(key)) {
							$changeAvailabilityTable
								.append(
									$(document.createElement('tr'))
										.append($(document.createElement('td')).html(key))
										.append($(document.createElement('td')).html(outputData[key]))
								);
						}
					}
                    
					//Popover
					makePopover($td, "Change Availability", $changeAvailabilityTable, 'changeSelectedPopover');
                }
				
                function appendChangeSignupPopover($td) {
                    if ($td.hasClass('legendBox')) return;
					var timeslot = scheduleData.timeslots[$td.attr('value')];
					var $changeSignupTable = $(document.createElement('table')).attr('id', 'createTimeslotTable');
					$changeSignupTable.addClass('table-condensed table-hover table-bordered');
					var outputData = {};
					var title = "Sign Up For Filming";
					if ($td.is('.otherTATimeslot')) {
						title = null;
						outputData["TA"] = timeslot.TA;
					} else {
						outputData["Filming"] = function() {
							if ($td.is('.taChosenTimeslot')) {
								return $(document.createElement('button'))
											.attr('id', 'unsignupTimeslotBtn')
											.addClass('popoverBtn btn btn-small btn-primary')
											.css('float', 'right')
											.append($(document.createElement('i')).addClass('fa fa-minus-circle fa-white'))
											.append("Cancel")
											.outerHTML();
							} else {
								return $(document.createElement('button'))
											.attr('id', 'signupTimeslotBtn')
											.addClass('popoverBtn btn btn-small btn-primary')
											.css('float', 'right')
											.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
											.append("Sign Up")
											.outerHTML();
							}
						};
					}
					
                    //Append all fields
					for (var key in outputData) {
						if (outputData.hasOwnProperty(key)) {
							$changeSignupTable
								.append(
									$(document.createElement('tr'))
										.append($(document.createElement('td')).html(key))
										.append($(document.createElement('td')).html(outputData[key]))
								);
						}
					}
                    
					//Popover
					makePopover($td, title, $changeSignupTable, 'changeSelectedPopover');
                }
                
                //Function to refresh booking exists
                function refreshScheduleData() {
                    var toReturn = null;
                    var bookingExists = 0;
                    var $existingTimeslot = null;
                    var teamsPendingBooking = null;
                    if (<%= activeRole.equals(Role.STUDENT) %>) {
                        for (var key in scheduleData.timeslots) {
                            if (scheduleData.timeslots.hasOwnProperty(key)) {
                                var timeslot = scheduleData.timeslots[key];
                                if (timeslot.team && timeslot.team === teamName) {
                                    bookingExists = 1;
                                    $existingTimeslot = $(document.createElement('div'))
										.attr('value', timeslot.datetime)
										.addClass('existingTimeslot');
                                    break;
                                }
                            }
                        }
                        toReturn = {bookingExists:bookingExists, existingTimeslot: $existingTimeslot};
                    } else if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) %>) {
                        teamsPendingBooking = new Array();
                        $teamDropDownSelect = $(document.createElement('select'))
							.attr('name', 'team')
							.attr('id', 'createTeamSelect')
							.addClass('popoverSelect');
                        outerTeams: 
                        for (var t = 0; t < teams.length; t++) { //Append only teams without bookings
                            var adminTeamName = teams[t].teamName;
                            for (var key in scheduleData.timeslots) {
                                if (scheduleData.timeslots.hasOwnProperty(key)) {
                                    var timeslot = scheduleData.timeslots[key];
                                    if (timeslot.team && timeslot.team === adminTeamName) {
                                        continue outerTeams;
                                    }
                                }
                            }
                            $teamDropDownSelect
								.append($(document.createElement('option'))
									.attr('value', teams[t].teamId)
									.html(adminTeamName)
								);
                            teamsPendingBooking.push(adminTeamName);
                        }
                        toReturn = {teamsPendingBooking:teamsPendingBooking};
                    }
                    return toReturn;
                }

                //Function to create mouse UI events
                function setupMouseEvents() {
                    
                    /*****************************
                     CALENDAR UI INTERACTION
                     ****************************/
					
					//Highlighting of row and column
					$('.timeslotCell').mouseenter(function(){
						var $this = $(this);
						var $td = $('body').find('.tdCell[value="' + $this.attr('value') + '"]');
						var cols = $td.closest('table').find('tr:first').children('td').length;
						var $tr = $td.closest('tr');
						$tr.addClass('calendarHighlighted');
						if ($tr.children('td').length !== cols) {
							$td.closest('table').find('tr:first td:nth-child(' + ($td.index() + 2) + ')').addClass('calendarHighlighted');
							$td.closest('table').find('tr:even:not(:first) td:nth-child(' + ($td.index() + 1) + ')').addClass('calendarHighlighted');
							$td.closest('table').find('tr:odd td:nth-child(' + ($td.index() + 2) + ')').addClass('calendarHighlighted');
						} else {
							$td.closest('table').find('tr:first td:nth-child(' + ($td.index() + 1) + ')').addClass('calendarHighlighted');
							$td.closest('table').find('tr:even:not(:first) td:nth-child(' + $td.index() + ')').addClass('calendarHighlighted');
							$td.closest('table').find('tr:odd td:nth-child(' + ($td.index() + 1) + ')').addClass('calendarHighlighted');
						}
					});
					$('.timeslotCell').mouseleave(function(){
						$('tr, td').removeClass('calendarHighlighted');
					});
                    
                    //Hide other popovers when others clicked
                    $('body').off('click', '.timeslotCell, .booking');
                    $('body').on('click', '.timeslotCell, .booking', function(e) {
						if (uatMode) recordHumanInteraction(e);
						self = <%= activeRole.equals(Role.FACULTY) || activeRole.equals(Role.TA) %>?$(this):$(this).children('.booking').length?$(this).children('.booking'):$(this);
						$('.timeslotCell, .booking').not(self).not(self.parents()).find('#updateBookingBtn').attr('disabled', true);
						$('.timeslotCell, .booking').not(self).not(self.parents()).find('#updateTimeslotBtn').attr('disabled', true);
						$('.timeslotCell, .booking').not(self).popover('hide');
						$(".hasDatepicker").datepicker('destroy');
						$.pnotify_remove_all();
                        return false;
                    });

                    //Popover for booked timeslot
                    $('body').off('click', '.bookedTimeslot:not(.unavailableTimeslot), .bookedTimeslot > .booking');
                    $('body').on('click', '.bookedTimeslot:not(.unavailableTimeslot), .bookedTimeslot > .booking', function(e) {
						if (e.target === this) {
							if (uatMode) recordHumanInteraction(e);
							if ($(this).hasClass('timeslotCell') && <%= activeRole.equals(Role.FACULTY) || activeRole.equals(Role.TA) %>) {
								$(this).popover('show');
								if ($(this).find('tr:last').length && $(this).find('tr:last').offset().top - $(window).scrollTop() > window.innerHeight){
									$('body').animate({scrollTop: $(this).find('tr:last').offset().top - $(window).scrollTop()}, 500);
								}
								return false;
							}
							self = ($(this).is('.booking')) ? $(this) : $(this).children('.booking');
							var timeslot = scheduleData.timeslots[self.closest('.timeslotCell').attr('value')];
							self.popover('show');
							if (self.find('tr:last').length && self.find('tr:last').offset().top - $(window).scrollTop() > window.innerHeight){
								$('body').animate({scrollTop: self.find('tr:last').offset().top - $(window).scrollTop()}, 500);
							}
							self.find("#updateFormDate").val(timeslot.startDate).change();
							self.find("#updateFormStartTime").val(timeslot.time).change();
							self.find('ul').remove();
							appendTokenInput(self); //Optional attendees
						} else if ($(e.target).attr('id') === 'wikiLink') {
							if (uatMode) recordHumanInteraction(e);
							window.open($(e.target).attr('href'), '_blank');
						}
                        return false;
                    });
                    
                    //Popover for unbooked timeslot
                    $('body').off('click', '.unbookedTimeslot:not(.unavailableTimeslot)');
                    $('body').on('click', '.unbookedTimeslot:not(.unavailableTimeslot)', function(e) {
						if (e.target === this) {
							if (uatMode) recordHumanInteraction(e);
							self = $(this).is('.booking') ? $(this).parent('.timeslotCell') : $(this);
                            var timeslot = scheduleData.timeslots[self.attr('value')];
                            var refreshData = refreshScheduleData();
                            if (<%= activeRole.equals(Role.STUDENT) %>) {
                                if (teamName === null) {
                                    showNotification("WARNING", self, "You don't have a team for this term!");
                                    return false;
								}
								if (refreshData.bookingExists !== 0) {
                                    showNotification("WARNING", refreshData.existingTimeslot, "You already have a booking!");
                                    return false;
                                }
                                var teamTerm = "<% try {out.print(!team.getTerm().equals(activeTerm)?team.getTerm().getAcademicYear() + " " + team.getTerm().getSemester():"thisTerm");} catch (Exception e) {out.print("thisTerm");} %>";
                                if (teamTerm !== "thisTerm") {
                                    showNotification("WARNING", self, "You can only book for " + teamTerm);
                                    return false;
                                }
                                if (timeslot.lastBookingComment) showNotification("ERROR", self, timeslot.lastBookingEditedBy + ": <br/>" + timeslot.lastBookingComment);
                            }
                            if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
                                //Make a dropdown of all teams that have not booked yet if user is admin
                                if (teams.length === 0) {
                                    createBookingOutputForAdmin = "There are no teams for this term";
                                } else if (refreshData.teamsPendingBooking.length === 0) {
                                    createBookingOutputForAdmin = "All teams have bookings!";
                                }
                                if (createBookingOutputForAdmin) {
                                    showNotification("WARNING", self, createBookingOutputForAdmin);
                                    createBookingOutputForAdmin = null;
                                    return false;
                                }
                            }
							self.tooltip('hide');
                            self.popover('show');
							if (self.find('tr:last').length && self.find('tr:last').offset().top - $(window).scrollTop() > window.innerHeight){
								$('body').animate({scrollTop: self.find('tr:last').offset().top - $(window).scrollTop()}, 500);
							}
							if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
								self.find("#autoApprove")
									.empty()
									.append(
										$(document.createElement('input'))
											.attr('type', 'checkbox')
											.attr('name', 'autoApprove')
											.attr('checked', false)
									).bootstrapSwitch();
							}
                        }
                        return false;
                    });
					
                    //Popover for unavailable timeslot
                    $('body').off('click', '.unavailableTimeslot');
                    $('body').on('click', '.unavailableTimeslot', function(e) {
						if (e.target === this) {
							if (uatMode) recordHumanInteraction(e);
							var timeslot = scheduleData.timeslots[self.attr('value')];
							self = $(this);
							var refreshData = refreshScheduleData();
							if (<%= activeRole.equals(Role.STUDENT) %>) {
								if (refreshData.bookingExists !== 0) {
									showNotification("WARNING", refreshData.existingTimeslot, "You already have a booking!");
									return false;
								}
								var teamTerm = "<% try {out.print(!team.getTerm().equals(activeTerm)?team.getTerm().getAcademicYear() + " " + team.getTerm().getSemester():"thisTerm");} catch (Exception e) {out.print("thisTerm");} %>";
								if (teamTerm !== "thisTerm") {
									showNotification("WARNING", self, "You can only book for " + teamTerm);
									return false;
								}
								if (timeslot.lastBookingComment) showNotification("ERROR", self, timeslot.lastBookingEditedBy + ": <br/>" + timeslot.lastBookingComment);
							}
							if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
								//Make a dropdown of all teams that have not booked yet if user is admin
								if (teams.length === 0) {
									createBookingOutputForAdmin = "There are no teams for this term";
								} else if (refreshData.teamsPendingBooking.length === 0) {
									createBookingOutputForAdmin = "All teams have bookings!";
								}
								if (createBookingOutputForAdmin) {
									showNotification("WARNING", self, createBookingOutputForAdmin);
									createBookingOutputForAdmin = null;
									return false;
								}
							}
							self.popover('show');
							if (self.find('tr:last').length && self.find('tr:last').offset().top - $(window).scrollTop() > window.innerHeight){
								$('body').animate({scrollTop: self.find('tr:last').offset().top - $(window).scrollTop()}, 500);
							}
							self.find('ul').remove();
							appendTokenInput(self); //Optional attendees
						}
                        return false;
                    });
                    
                    /*****************************
                     POPOVER INTERACTION
                     ****************************/
					 
					 /*** BUTTONS ***/

                    //Close Booking Button
                    $('.timeslotCell').off('click', '.close');
                    $('.timeslotCell').on('click', '.close', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        self.popover('hide');
                        self.trigger('mouseleave');
                        return false;
                    });

                    //Create Booking Button
                    $('.timeslotCell').off('click', '#createBookingBtn');
                    $('.timeslotCell').on('click', '#createBookingBtn', function(e) {
						if (uatMode) recordHumanInteraction(e);
                        var returnData = createBooking(self);
						if (returnData && returnData.success) {
							var booking = returnData.booking;
							self.popover('destroy');
							self.tooltip('destroy');
							self.removeClass();
							self.addClass('timeslotCell bookedTimeslot');
							var $deletedDiv = self.children('.deletedBookingOnTimeslot, .rejectedBooking');
							if ($deletedDiv) $deletedDiv.remove();
							var bookingDiv = $(document.createElement('div'));
							bookingDiv.addClass('booking myTeamBooking');
							bookingDiv.addClass(returnData.overrideApproval?'approvedBooking':'pendingBooking');
							bookingDiv.html(booking.team);
							bookingDiv.css('display', 'none');
							bookingDiv.css ({
								height: self.innerHeight(),
								width: self.outerWidth()
							});
							self.append(bookingDiv);
							showNotification('SUCCESS', self, null);
							scheduleData.timeslots[self.attr('value')] = booking;
							if (<%= activeRole.equals(Role.STUDENT)%>) {
								appendViewBookingPopover(self);
							} else if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
								//Update teams JSON
								var team = null;
								for (var i = 0; i < teams.length; i++) {
									if (parseInt(teams[i].teamId) === parseInt(booking.teamId)) {
										team = teams[i];
										break;
									}
								}
								team.bookings.push({
									datetime: Date.parse(booking.datetime).toString('dd MMM yyyy HH:mm'),
									milestone: milestone,
									scheduleId: scheduleData.id,
									bookingStatus: booking.status.toLowerCase()
								});
								//Change page view
								appendPopovers();
								initDragNDrop();
							}
							bookingDiv.show('clip', 'slow');
						} else {
							showNotification("ERROR", self, returnData.message);
						}
                        return false;
                    });
					
                    //Create Anyway Booking Button
                    $('.timeslotCell').off('click', '#createAnywayBookingBtn');
                    $('.timeslotCell').on('click', '#createAnywayBookingBtn', function(e) {
						if (uatMode) recordHumanInteraction(e);
						var timeslot = scheduleData.timeslots[self.attr('value')];
						bootbox.confirm({
							title: "Faculty Unavailable",
							message: function(){
								var unavailableFaculty = "";
								for (var i = 0; i < timeslot.unavailable.length; i++) {
									unavailableFaculty += timeslot.unavailable[i] + ", ";
								}
								unavailableFaculty = $.trim(unavailableFaculty).toString();
								return unavailableFaculty.substring(0, unavailableFaculty.length - 1) + " unavailable<br/>" + "Create Booking Anyway?";
							},
							callback: function(result) {
								if (result) {
									var returnData = createBooking(self);
									//REFRESH STATE OF scheduleData
									if (returnData && returnData.success) {
										self.popover('destroy');
										self.tooltip('destroy');
										self.removeClass('unbookedTimeslot');
										self.addClass('bookedTimeslot');
										var $deletedDiv = self.children('.deletedBookingOnTimeslot, .rejectedBooking');
										if ($deletedDiv) $deletedDiv.remove();
										var bookingDiv = $(document.createElement('div'));
										bookingDiv.addClass('booking pendingBooking myTeamBooking');
										bookingDiv.html(returnData.booking.team);
										bookingDiv.css('display', 'none');
										bookingDiv.css ({
											height: self.innerHeight(),
											width: self.outerWidth()
										});
										self.append(bookingDiv);
										showNotification('SUCCESS', self, null);
										for (var key in returnData.booking) {
											if (returnData.booking.hasOwnProperty(key)) {
												timeslot[key] = returnData.booking[key];
											}
										}
										if (<%= activeRole.equals(Role.STUDENT)%>) {
											appendViewBookingPopover(self);
										} else if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
											appendPopovers();
										}
										bookingDiv.show('clip', 'slow');
									} else {
										showNotification("ERROR", self, returnData.message);
									}
								}
							}
						});
                        return false;
                    });

                    //Delete Booking Button
                    $('.timeslotCell').off('click', '#deleteBookingBtn');
                    $('.timeslotCell').on('click', '#deleteBookingBtn', function(e) {
						if (uatMode) recordHumanInteraction(e);
						var $timeslot = self.parents('.timeslotCell');
						var timeslot = scheduleData.timeslots[$timeslot.attr('value')];
						bootbox.prompt({
							className : "bootbox-width",
							title: "Delete Booking",
							callback: function(result) {
								if (result) {
									deleteBooking($timeslot, result);
									setTimeout(function(){showNotification("ERROR", $timeslot, null);},500);
									$timeslot.removeClass('bookedTimeslot');
									$timeslot.addClass('unbookedTimeslot');
									$timeslot.popover('destroy');
									if (<%= activeRole.equals(Role.STUDENT)%>) {
										self.effect('clip', 'slow', function(){
											self.remove();
											var deletedDiv = $(document.createElement('div'))
												.addClass('deletedBookingOnTimeslot')
												.addClass('fa fa-info-circle');
											makeTooltip(deletedDiv, 'Removed by ' + "<%= user.getFullName() %>");
											$timeslot.append(deletedDiv);
											timeslot.lastBookingStatus = 'deleted';
											timeslot.lastBookingComment = result;
											timeslot.lastBookingEditedBy = "<%= user.getFullName() %>";
											delete timeslot.team;
											appendCreateBookingPopover($timeslot);
										});
									} else if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
										self.effect('clip', 'slow', function(){
											self.remove();
											//Update teams json
											var team = null;
											for (var i = 0; i < teams.length; i++) {
												if (teams[i].teamName === timeslot.team) {
													team = teams[i];
													break;
												}
											}
											for (var i = 0; i < team.bookings.length; i++) {
												if (parseInt(team.bookings[i].scheduleId) === parseInt(scheduleData.id)) {
													team.bookings.splice(team.bookings.indexOf(team.bookings[i]), 1);
													break;
												}
											}
											delete timeslot.team;
											//Change page view
											refreshScheduleData();
											appendPopovers();
										});
									}
								}
							}
						});
						$('.modal-footer button:not(:first)').attr('disabled', true);
						$('.modal-body').prepend(
							$(document.createElement('div'))
								.addClass('customPrompt')
								.append('Reason to delete booking (max 55 chars)')
						);
						$('input.bootbox-input').on('keyup', function(){
							if ($(this).val() && $(this).val().length > 55) {
								$('.modal-footer button:not(:first)').attr('disabled', true);
								showNotification("WARNING", $timeslot, "Please enter max 55 chars");
							} else if ($(this).val()) {
								$('.modal-footer button:not(:first)').attr('disabled', false);
							} else {
								$('.modal-footer button:not(:first)').attr('disabled', true);
							}
							return false;
						});
                        return false;
                    });
					
					//Make Update Booking Button visible on clicking an input
					$('.timeslotCell').off('click focus', 'input');
					$('.timeslotCell').on('click focus', 'input', function(){
						$(this).closest('table').find('#updateBookingBtn, #updateTimeslotBtn').attr('disabled', false);
					});
                    
                    //Update Booking Button
                    $('.timeslotCell').off('click', '#updateBookingBtn');
                    $('.timeslotCell').on('click', '#updateBookingBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        var startDateVal = $('#updateFormDate').val();
                        var startTimeVal = $('#updateFormStartTime').val();
                        var newDateTime = "";
                        if (startDateVal && startTimeVal) {
                            var newDate = Date.parse(startDateVal);
                            var newTime = Date.parse($.trim(startTimeVal.split(" - ")[0]));
                            if (newDate && newTime) {
                                newDateTime = newDate.toString("yyyy-MM-dd") + " " + newTime.toString("HH:mm:ss");
                            }
                        }
                        var newVenue = $('#updateFormVenue').val();
                        var attendees = $(".optionalAttendees").tokenInput('get');
                        var $timeslot = self.parents('.timeslotCell');
						var timeslot = scheduleData.timeslots[$timeslot.attr('value')];
                        var returnData = updateBooking($timeslot, newDateTime, newVenue, attendees);
                        if (returnData && returnData.success) {
                            showNotification("INFO", $timeslot, null);
                            if (newDateTime !== "" && newDateTime !== $timeslot.attr('value')) {
								//Update teams json
								var team = null;
								for (var i = 0; i < teams.length; i++) {
									if (teams[i].teamName === timeslot.team) {
										team = teams[i];
										break;
									}
								}
								for (var i = 0; i < team.bookings.length; i++) {
									if (parseInt(team.bookings[i].scheduleId) === parseInt(scheduleData.id)) {
										team.bookings[i].datetime = Date.parse(returnData.booking.datetime).toString('dd MMM yyyy HH:mm');
										break;
									}
								}
								//Change page view
                                var newTimeslot = $("#timeslot_" + returnData.booking.id);
                                newTimeslot.popover('destroy');
                                newTimeslot.removeClass();
                                newTimeslot.addClass('timeslotCell bookedTimeslot');
                                var bookingDiv = $(document.createElement('div'));
                                bookingDiv.addClass(self.attr('class'));
                                bookingDiv.html(returnData.booking.team);
                                bookingDiv.css('display', 'none');
								bookingDiv.css ({
									height: newTimeslot.innerHeight(),
									width: newTimeslot.outerWidth()
								});
                                newTimeslot.append(bookingDiv);
                                scheduleData.timeslots[newTimeslot.attr('value')] = returnData.booking;
                                appendViewBookingPopover(newTimeslot);
                                $timeslot.removeClass('bookedTimeslot');
                                $timeslot.addClass('unbookedTimeslot');
                                $timeslot.popover('destroy');
                                self.effect('clip', 'slow', function(){
                                   self.remove(); 
                                });
                                delete scheduleData.timeslots[$timeslot.attr('value')];
                                scheduleData.timeslots[$timeslot.attr('value')] = {id:$timeslot.attr('id').split("_")[1], venue:"SIS Seminar Room 2-1", datetime: $timeslot.attr('value')}; //TODO: Change SIS Seminar Room 2-1
                                appendCreateBookingPopover($timeslot);
                                bookingDiv.show('clip', 'slow');
                            } else {
                                scheduleData.timeslots[$timeslot.attr('value')] = returnData.booking;
                                self.popover('destroy');
                                appendViewBookingPopover($timeslot);
                            }
                        } else {
                            showNotification("WARNING", $timeslot, returnData.message);
                        }
						refreshScheduleData();
                        return false;
                    });
					
                    //Update Timeslot Button
                    $('.timeslotCell').off('click', '#updateTimeslotBtn');
                    $('.timeslotCell').on('click', '#updateTimeslotBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        var newVenue = $('#updateFormVenue').val();
                        var $timeslot = self.closest('.timeslotCell');
                        var returnData = updateTimeslot($timeslot, newVenue);
                        if (returnData && returnData.success) {
							showNotification("INFO", $timeslot, null);
							scheduleData.timeslots[$timeslot.attr('value')].venue = newVenue;
							appendCreateBookingPopover($timeslot);
                        } else {
                            showNotification("WARNING", $timeslot, returnData.message);
                        }
                        return false;
                    });
                    
                    //Faculty Set Available Button
                    $('.timeslotCell').off('click', '#availableTimeslotBtn');
                    $('.timeslotCell').on('click', '#availableTimeslotBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        changeAvailability(self, true);
                        showNotification("WARNING", self.closest('.timeslotCell'), "Set as available");
                        self.popover('destroy');
						if (self.is('.booking')) appendViewBookingPopover(self.closest('.timeslotCell'));
                        else appendChangeAvailabilityPopover(self);
                        return false;
                    });
                    
                    //Faculty Set Unavailable Button
                    $('.timeslotCell').off('click', '#unavailableTimeslotBtn');
                    $('.timeslotCell').on('click', '#unavailableTimeslotBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        changeAvailability(self, false);
                        showNotification("WARNING", self.closest('.timeslotCell'), "Set as unavailable");
                        self.popover('destroy');
						if (self.is('.booking')) appendViewBookingPopover(self.closest('.timeslotCell'));
                        else appendChangeAvailabilityPopover(self);
                        return false;
                    });
					
					//Faculty Approve Button
                    $('.timeslotCell').off('click', '#approveBookingBtn');
                    $('.timeslotCell').on('click', '#approveBookingBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
						var $timeslot = self.closest('.timeslotCell');
						var timeslot = scheduleData.timeslots[$timeslot.attr('value')];
                        var returnData = updateBookingStatus(self, "approve");
						if (returnData && returnData.success) {
							var approveCount = 0;
							for (var i = 0; i < timeslot.faculties.length; i++) {
								if (timeslot.faculties[i].name === myFullName) {
									timeslot.faculties[i].status = "APPROVED";
									++approveCount;
									break;
								}
								if (timeslot.faculties[i].status === "APPROVED") ++approveCount;
							}
							if (approveCount === timeslot.faculties.length) {
								timeslot.status = "APPROVED";
								self.removeClass('pendingBooking');
								self.addClass('approvedBooking');
								//Update teams JSON
								for (var i = 0; i < teams.length; i++) {
									if (parseInt(teams[i].teamId) === parseInt(timeslot.teamId)) {
										var team = teams[i];
										for (var j = 0; j < team.bookings.length; j++) {
											if (Date.parse(team.bookings[j].datetime).toString('yyyy-MM-dd HH:mm') === Date.parse($timeslot.attr('value')).toString('yyyy-MM-dd HH:mm')) {
												team.bookings[j].bookingStatus = "approved";
												break;
											}
										}
										break;
									}
								}
							}
							var pendingBookingCount = $('.pendingBookings u').text().split(" ")[2];
							if (--pendingBookingCount === 0) {
								$('.pendingBookings').css('opacity', '0');
							} else {
								$('.pendingBookings u').html('You have ' + pendingBookingCount + ' pending ' + (pendingBookingCount === 1?'booking':'bookings'));
							}
							showNotification("SUCCESS", self.closest('.timeslotCell'), "Booking approved");
							self.popover('destroy');
							appendViewBookingPopover(self.closest('.timeslotCell'));
						}
                        return false;
                    });
					
					//Faculty Reject Button
                    $('.timeslotCell').off('click', '#rejectBookingBtn, #cancelBookingBtn');
                    $('.timeslotCell').on('click', '#rejectBookingBtn, #cancelBookingBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
						var $timeslot = self.closest('.timeslotCell');
						var $booking = self.closest('.booking');
						var timeslot = scheduleData.timeslots[self.closest('.timeslotCell').attr('value')];
						var action = $(this).is('#rejectBookingBtn')?"Reject":"Cancel";
						bootbox.prompt({
							className : "bootbox-width",
							title: action + ' Booking',
							callback: function(result) {
								if (result) {
									var returnData = updateBookingStatus(self, "reject", result);
									if (returnData && returnData.success) {
										$timeslot.removeClass('bookedTimeslot');
										$timeslot.addClass('unbookedTimeslot');
										$booking.popover('destroy');
										$booking.effect('clip', 'slow', function(){
											$booking.remove();
										});
										var team = null;
										for (var i = 0; i < teams.length; i++) {
											if (teams[i].teamName === timeslot.team) {
												team = teams[i];
												break;
											}
										}
										for (var i = 0; i < team.bookings.length; i++) {
											if (parseInt(team.bookings[i].scheduleId) === parseInt(scheduleData.id)) {
												team.bookings.splice(team.bookings.indexOf(team.bookings[i]), 1);
												break;
											}
										}
										delete timeslot.team;
										setTimeout(function(){showNotification("ERROR", $timeslot, null);},500);
										if (action === 'Reject') {
											var pendingBookingCount = $('.pendingBookings u').text().split(" ")[2];
											if (--pendingBookingCount === 0) {
												$('.pendingBookings').effect('clip', 'slow', function(){
													$(this).remove();
												});
											} else {
												$('.pendingBookings u').html('You have ' + pendingBookingCount + ' pending ' + (pendingBookingCount === 1?'booking':'bookings'));
											}
										}
										setTimeout(function(){repositionTimeslots();},1000);
									}
								}
							}
						});
						$('.modal-footer button:not(:first)').attr('disabled', true);
						$('.modal-body').prepend(
							$(document.createElement('div'))
								.addClass('customPrompt')
								.append('Reason to ' + action.toLowerCase() + ' booking (max 55 chars)')
						);
						$('input.bootbox-input').on('keyup', function(){
							if ($(this).val() && $(this).val().length > 55) {
								$('.modal-footer button:not(:first)').attr('disabled', true);
								showNotification("WARNING", $timeslot, "Please enter max 55 chars");
							} else if ($(this).val()) {
								$('.modal-footer button:not(:first)').attr('disabled', false);
							} else {
								$('.modal-footer button:not(:first)').attr('disabled', true);
							}
							return false;
						});
                        return false;
                    });
					
					//Faculty Cancel Button
                    $('.timeslotCell').off('click', '#availableTimeslotBtn');
                    $('.timeslotCell').on('click', '#availableTimeslotBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        changeAvailability(self, true);
                        showNotification("WARNING", self.closest('.timeslotCell'), "Set as available");
                        self.popover('destroy');
						if (self.is('.booking')) appendViewBookingPopover(self.closest('.timeslotCell'));
                        else appendChangeAvailabilityPopover(self);
                        return false;
                    });
					
                    //TA Sign Up Button
                    $('.timeslotCell').off('click', '#signupTimeslotBtn');
                    $('.timeslotCell').on('click', '#signupTimeslotBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
                        changeSignup(self, true);
                        showNotification("WARNING", self.closest('.timeslotCell'), "Signed up for filming");
                        self.popover('destroy');
						if (self.is('.booking')) appendViewBookingPopover(self.closest('.timeslotCell'));
                        else appendChangeSignupPopover(self);
						var timeslot = scheduleData.timeslots[self.closest('.timeslotCell').attr('value')];
						timeslot.taId = loggedInTa;
						timeslot.TA = "<%= user.getFullName() %>";
						if (timeslot.subscribedUsers && timeslot.subscribedUsers.indexOf(myEmail) !== -1) {
							subscribeBooking(self.closest('.timeslotCell'), false);
							timeslot.subscribedUsers.splice(timeslot.subscribedUsers.indexOf(myEmail), 1);
						}
						self.closest('.timeslotCell').children('.booking').popover('destroy');
						if (self.closest('.timeslotCell').children('.booking').length) appendViewBookingPopover(self.closest('.timeslotCell'));
                        return false;
                    });
					
                    //TA Cancel Sign Up Button
                    $('.timeslotCell').off('click', '#unsignupTimeslotBtn');
                    $('.timeslotCell').on('click', '#unsignupTimeslotBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
						var timeslot = scheduleData.timeslots[self.attr('value')];
                        changeSignup(self, false);
                        showNotification("WARNING", self.closest('.timeslotCell'), "Cancelled for filming");
                        self.popover('destroy');
						if (self.is('.booking')) appendViewBookingPopover(self.closest('.timeslotCell'));
                        else appendChangeSignupPopover(self);
						var timeslot = scheduleData.timeslots[self.closest('.timeslotCell').attr('value')];
						delete timeslot.taId;
						timeslot.TA = ' - ';
						self.closest('.timeslotCell').children('.booking').popover('destroy');
						if (self.closest('.timeslotCell').children('.booking').length) appendViewBookingPopover(self.closest('.timeslotCell'));
                        return false;
                    });
                    
                    //Subscribe Button
                    $('.timeslotCell').off('click', '#subscribeBtn');
                    $('.timeslotCell').on('click', '#subscribeBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
						self = self.is('.booking') ? self.parent('.timeslotCell') : self;
						var timeslot = scheduleData.timeslots[self.attr('value')];
                        var returnData = subscribeBooking(self, true);
						if (returnData && returnData.success) {
							self.children('.booking').addClass('myTeamBooking');
							showNotification("WARNING", self, returnData.message);
							self.find('#subscribeBtn').after(
								$(document.createElement('button'))
									.attr('id', 'unsubscribeBtn')
									.addClass('popoverBtn btn btn-small')
									.append($(document.createElement('i')).addClass('fa fa-calendar-o fa-black'))
									.append("Cancel RSVP")
							);
							self.find('#subscribeBtn').remove();
							if (self.find('#signupTimeslotBtn')) self.find('#signupTimeslotBtn').remove();
							timeslot.subscribedUsers.push(myEmail);
						} else {
							showNotification("ERROR", self, returnData.message);
						}
                        return false;
                    });
					
                    //Unsubscribe Button
                    $('.timeslotCell').off('click', '#unsubscribeBtn');
                    $('.timeslotCell').on('click', '#unsubscribeBtn', function(e) {
                        if (uatMode) recordHumanInteraction(e);
						self = self.is('.booking') ? self.parent('.timeslotCell') : self;
						var timeslot = scheduleData.timeslots[self.attr('value')];
                        var returnData = subscribeBooking(self, false);
						if (returnData && returnData.success) {
							self.children('.booking').removeClass('myTeamBooking');
							showNotification("WARNING", self, returnData.message);
							self.find('#unsubscribeBtn').after(
								$(document.createElement('button'))
									.attr('id', 'subscribeBtn')
									.addClass('popoverBtn btn btn-small')
									.append($(document.createElement('i')).addClass('fa fa-calendar fa-black'))
									.append("RSVP")
							);
							if (<%= activeRole.equals(Role.TA) %> && !self.is('.otherTATimeslot')) self.find('#unsubscribeBtn').after(
								$(document.createElement('button'))
											.attr('id', 'signupTimeslotBtn')
											.addClass('popoverBtn btn btn-small btn-primary')
											.css('float', 'right')
											.append($(document.createElement('i')).addClass('fa fa-plus-circle fa-white'))
											.append("Sign Up")
								);
							self.find('#unsubscribeBtn').remove();
							if (timeslot.subscribedUsers && timeslot.subscribedUsers.indexOf(myEmail) !== -1) timeslot.subscribedUsers.splice(timeslot.subscribedUsers.indexOf(myEmail), 1);
						} else {
							showNotification("ERROR", self, returnData.message);
						}
                        return false;
                    });
					
					/*** NON-BUTTONS ***/
                    
                    //Datepicker
                    $('body').off('click', '#updateFormDate');
                    $('body').on('click', '#updateFormDate', function(e){
                        //Add date and timepickers
                        if (e.target === this) {
							if (uatMode) recordHumanInteraction(e);
                            $(this)
								.datepicker({
									dateFormat: "yy-mm-dd"
								})
								.datepicker('setDate', Date.parse($(this).val()))
								.datepicker('show');
                        }
                        return false;
                    });
                    
                    //Timepicker
                    $('body').off('click', '#updateFormStartTime');
                    $('body').on('click', '#updateFormStartTime', function(e){
                        //Add timepicker
                        if (e.target === this) {
							if (uatMode) recordHumanInteraction(e);
                            $(this)
								.timepicker({
									minTime: Date.parse(scheduleData.dayStartTime + ":00").toString("HH:mm"),
									maxTime: Date.parse(scheduleData.dayEndTime + ":00").addHours(-2).toString("HH:mm"),
									step: 30,
									forceRoundTime: true,
									timeFormat: 'H:i'
								});
							$(this).timepicker('setTime', $(this).val().split(" - ")[0]);
							$(this).timepicker('show');
                        }	
                        return false;
                    });
                    
                    //Update Booking Validation
                    $(".timeslotCell").on('mouseover', '#updateBookingBtn', function(){
                        var inputDate = $("#updateFormDate").val();
                        if (inputDate) {
                            inputDate = inputDate.replace(/ /g, '-');
                            var date = Date.parse(inputDate);
                            if (!date) {
                                $("#updateFormDate").val("").change();
                                showNotification("WARNING", self, "Please enter a proper date");
                                return false;
                            }
                            var wellFormedDate = date.toString("yyyy-MM-dd");
                            $("#updateFormDate").val(wellFormedDate).change();
                        }
                        var inputTime = $("#updateFormStartTime").val();
                        if (inputTime) {
                            inputTime = inputTime.split(" - ")[0];
                            var time = Date.parse(inputTime);
                            if (!time) {
                                $("#updateFormStartTime").val("").change();
                                showNotification("WARNING", self, "Please enter a proper time");
                                return false;
                            }
                            var wellFormedTime = time.toString("HH:mm");
                            $("#updateFormStartTime").val(wellFormedTime).change();
                        }
                        return false;
                    });
                    $(".timeslotCell").on('mouseleave', '#updateBookingBtn', function(){
                        var inputDate = $("#updateFormDate").val();
                        if (inputDate) {
                            inputDate = inputDate.replace(/ /g, '-');
                            var date = Date.parse(inputDate);
                            if (!date) {
                                $("#updateFormDate").val("").change();
                                showNotification("WARNING", self, "Please enter a proper date");
                                return false;
                            }
                            var wellFormedDate = date.toString("ddd, dd MMM yyyy");
                            $("#updateFormDate").val(wellFormedDate).change();
                        }
                        var inputTime = $("#updateFormStartTime").val();
                        if (inputTime) {
                            inputTime = inputTime.split(" - ")[0];
                            var time = Date.parse(inputTime);
                            if (!time) {
                                $("#updateFormStartTime").val("").change();
                                showNotification("WARNING", self, "Please enter a proper time");
                                return false;
                            }
                            var wellFormedTime = time.toString("HH:mm") + " - " + time.addMinutes(scheduleData.duration).toString("HH:mm");
                            $("#updateFormStartTime").val(wellFormedTime).change();
                        }
                        return false;
                    });
                    
                    //Week view functions
					$("#weekView").off('switch-change');
                    $("#weekView").on('switch-change', function(e, data){
						setTimeout(function(){
							if (uatMode) recordHumanInteraction(e);
							if (data.value) {
								//Full View
								weekView = null;
								$(".weekNum").remove();
								$(".traverseWeek").hide();
							} else {
								//Week View
								$(".traverseWeek").css('opacity', '100');
								weekView = 0;
								$("#previousWeek").css('opacity', '0');
								if (maxWeekView === 1) $("#nextWeek").css('opacity', '0');
								$(".weekNum").remove();
								$(".traverseWeek").show();
								$("#previousWeek").after($(document.createElement('div')).addClass('weekNum').html('Week ' + (weekView + 1)));
							}
							populateSchedule(milestone, year, semester);
						}, 500);
                        return false;
                    });
					$("#nextWeek").off('click');
                    $("#nextWeek").on('click', function(){
						$(".traverseWeek").css('opacity', '100');
						if (uatMode) recordHumanInteraction(e);
                        if (weekView + 1 < maxWeekView) {
                            ++weekView;
                            $(".weekNum").remove();
                            $("#previousWeek").after($(document.createElement('div')).addClass('weekNum').html('Week ' + (weekView + 1)));
                            populateSchedule(milestone, year, semester);
                        }
						if (weekView + 1 === maxWeekView) $(this).css('opacity', '0');
                        return false;
                    });
					$("#previousWeek").off('click');
                    $("#previousWeek").on('click', function(){
						$(".traverseWeek").css('opacity', '100');
						if (uatMode) recordHumanInteraction(e);
                        if (weekView <= 0) {
                            return false;
                        } else {
                            --weekView;
                            $(".weekNum").remove();
                            $("#previousWeek").after($(document.createElement('div')).addClass('weekNum').html('Week ' + (weekView + 1)));
                            populateSchedule(milestone, year, semester);
                        }
						if (weekView === 0) $(this).css('opacity', '0');
                        return false;
                    });
                }
                
                /***************************
                    AJAX CALL FUNCTIONS
                 ***************************/
                 
                function createBooking(bodyTd) {
                    var toReturn = null;
                    var data = null;
                    var tName = null;
                    if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)%>) {
                            tName = $("#createTeamSelect option:selected").text();
                            var tId = $("#createTeamSelect").val();
                            data = {
                                timeslotId: bodyTd.attr('id').split("_")[1],
                                teamId: tId,
								overrideApproval: $('#autoApprove').bootstrapSwitch('status')
                            };
                    } else if (<%= activeRole.equals(Role.STUDENT)%>) {
                        tName = teamName;
                        data = {
                            timeslotId: bodyTd.attr('id').split("_")[1]
                        };
                    }
                    console.log("Submitting create booking data: " + JSON.stringify(data));
                    //Create Booking AJAX
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'createBookingJson',
                        data: data,
                        cache: false,
                        dataType: 'json'
                    }).done(function(response) {
                        if (!response.exception) {
                            toReturn = response;
                        } else {
                            var eid = btoa(response.message);
                            window.location = "error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        alert("Oops. There was an error: " + JSON.stringify(error));
                    });
                    return toReturn;
                }

                function deleteBooking(bodyTd, comment) {
                    //get the timeslotID for that cell and send as request
                    var cellId = $(bodyTd).attr('id').split("_")[1];
                    var data = {timeslotId: cellId, comment: comment};
                    console.log("Submitting delete booking data: " + JSON.stringify(data));
                    //Delete Booking AJAX
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'deleteBookingJson',
                        data: data,
                        cache: false,
                        dataType: 'json'
                    }).done(function(response) {
                        if (response.exception) {
                            var eid = btoa(response.message);
                            window.location = "error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        alert("Oops. There was an error: " + error);
                    });
                }

                //update booking function
                function updateBooking(bodyTd, newDateTime, newVenue, attendees) {
                    //getfunction up the timeslotID for that cell and send as request
                    var toReturn = null;
                    var cellId = bodyTd.attr('id').split("_")[1];
                    var attendeesArray = new Array();
					if (attendees) {
						for (var i = 0; i < attendees.length; i++) {
							attendeesArray.push(attendees[i].id?attendees[i].id:attendees[i].name);
						}
					}
                    var data = {timeslotId: cellId, attendees: attendeesArray};
                    if (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) %>) {
                        data["newDateTime"] = newDateTime;
                        data["newVenue"] = newVenue;
                    }
                    console.log("Submitting update booking data: " + JSON.stringify(data));
                    //Update booking AJAX
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'updateBookingJson',
                        data: {jsonData: JSON.stringify(data)},
                        cache: false,
                        dataType: 'json'
                    }).done(function(response) {
                        toReturn = response;
                        if (response.exception) {
                            var eid = btoa(response.message);
                            window.location = "error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        alert("Oops. There was an error: " + error);
                    });
                    return toReturn;
                }
				
                //Update timeslot function
                function updateTimeslot(bodyTd, newVenue) {
                    //getfunction up the timeslotID for that cell and send as request
                    var toReturn = null;
                    var cellId = bodyTd.attr('id').split("_")[1];
                    var data = {timeslotId: cellId, venue: newVenue};
                    console.log("Submitting update timeslot data: " + JSON.stringify(data));
                    //Update timeslot AJAX
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'updateTimeslotJson',
                        data: {jsonData: JSON.stringify(data)},
                        cache: false,
                        dataType: 'json'
                    }).done(function(response) {
                        toReturn = response;
                        if (response.exception) {
                            var eid = btoa(response.message);
                            window.location = "error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        alert("Oops. There was an error: " + error);
                    });
                    return toReturn;
                }
                
                //Update Faculty Availability AJAX Call            
                function changeAvailability(bodyTd, available) {
                    var timeslotsData = {};
                    var timeslot_data = new Array();
                    var allTimeslots = $(".unavailableTimeslot").get();
                    var timeslotsSet = new HashSet();
                    for (var i = 0; i < allTimeslots.length; i++) {
                        var $obj = $(allTimeslots[i]);
						if ($obj.is('.legendBox')) continue;
                        timeslotsSet.add($obj.attr('id'));
                    }
                    timeslot_data = timeslotsSet.values().sort();
                    if (!available) {
                        timeslot_data.push(bodyTd.is('.timslotCell')?bodyTd.attr('id'):bodyTd.closest('.timeslotCell').attr('id'));
                    } else {
                        var index = timeslot_data.indexOf(bodyTd.is('.timslotCell')?bodyTd.attr('id'):bodyTd.closest('.timeslotCell').attr('id'));
                        timeslot_data.splice(index, 1);
                    }
                    timeslotsData["timeslot_data[]"] = timeslot_data;
                    timeslotsData["scheduleId"] = scheduleData.id;
                    console.log('Submitting availability data: ' + JSON.stringify(timeslotsData));
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'setAvailabilityJson',
                        data: timeslotsData,
                        dataType: 'json'
                    }).done(function(response) {
                        if (!response.exception) {
                            if (response.success) {
                                if (!available) {
                                    bodyTd.closest('.timeslotCell').removeClass('availableTimeslot');
                                    bodyTd.closest('.timeslotCell').addClass('unavailableTimeslot');
                                } else {
                                    bodyTd.closest('.timeslotCell').removeClass('unavailableTimeslot');
                                    bodyTd.closest('.timeslotCell').addClass("availableTimeslot");
                                }
                            } else {
                                var eid = btoa(response.message);
                                window.location = "error.jsp?eid=" + eid;
                            }
                        } else {
                            var eid = btoa(response.message);
                            window.location="error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        var eid = btoa("Something went wrong");
                        window.location="error.jsp?eid=" + eid;
                    });
                    return false;
                }
				
				//Update Booking Status AJAX Call
				function updateBookingStatus(self, action, comment) {
					var toReturn = null;
					var timeslot = scheduleData.timeslots[self.closest('.timeslotCell').attr('value')];
					var data = {
						bookingId: timeslot.bookingId,
						status: action
					};
					if (comment) data["comment"] = comment;
					console.log('Submitting: ' + JSON.stringify(data));
					$.ajax({
						type: 'POST',
						async: false,
						url: 'updateBookingStatus',
						data: {jsonData: JSON.stringify(data)}
					})
					.done(function(response) {
						if (!response.exception) {
							if (response.success) {
								toReturn = response;
							} else {
								showNotification("ERROR", response.message);
							}
						} else {
							var eid = btoa(response.message);
							window.location = "error.jsp?eid=" + eid;
						}
					}).fail(function(error) {
						   showNotification("WARNING", "Oops.. something went wrong");
					});
					return toReturn;
				}
				
                //Update TA Signup AJAX Call            
                function changeSignup(bodyTd, taChosen) {
                    var timeslotsData = {};
                    var timeslot_data = new Array();
                    var allTimeslots = $(".taChosenTimeslot").get();
                    var timeslotsSet = new HashSet();
                    for (var i = 0; i < allTimeslots.length; i++) {
                        var $obj = $(allTimeslots[i]);
						if ($obj.is('.legendBox')) continue;
                        timeslotsSet.add($obj.attr('id').split("_")[1]);
                    }
                    timeslot_data = timeslotsSet.values().sort();
                    if (taChosen) {
                        timeslot_data.push(bodyTd.is('.timslotCell')?bodyTd.attr('id').split("_")[1]:bodyTd.closest('.timeslotCell').attr('id').split('_')[1]);
                    } else {
                        var index = timeslot_data.indexOf(bodyTd.is('.timslotCell')?bodyTd.attr('id').split("_")[1]:bodyTd.closest('.timeslotCell').attr('id').split('_')[1]);
                        timeslot_data.splice(index, 1);
                    }
                    timeslotsData["timeslots"] = timeslot_data;
                    timeslotsData["scheduleId"] = scheduleData.id;
                    console.log('Submitting availability data: ' + JSON.stringify(timeslotsData));
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'taSignupJson',
                        data: {jsonData: JSON.stringify(timeslotsData)},
                        dataType: 'json'
                    }).done(function(response) {
                        if (!response.exception) {
                            if (response.success) {
                                if (taChosen) {
                                    bodyTd.closest('.timeslotCell').addClass('taChosenTimeslot');
									if (bodyTd.closest('.timeslotCell').children('.booking').length) {
										bodyTd.closest('.timeslotCell').children('.booking').addClass('myTeamBooking');
									}
                                } else {
                                    bodyTd.closest('.timeslotCell').removeClass('taChosenTimeslot');
									if (bodyTd.closest('.timeslotCell').children('.booking').length) {
										bodyTd.closest('.timeslotCell').children('.booking').removeClass('myTeamBooking');
									}
                                }
                            } else {
                                var eid = btoa(response.message);
                                window.location = "error.jsp?eid=" + eid;
                            }
                        } else {
                            var eid = btoa(response.message);
                            window.location="error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        var eid = btoa("Something went wrong");
                        window.location="error.jsp?eid=" + eid;
                    });
                    return false;
                }
				
                function subscribeBooking(bodyTd, subscribe) {
                    var toReturn = null;
					var timeslot = scheduleData.timeslots[bodyTd.attr('value')];
					var data = {
						subscribedBooking: timeslot.bookingId,
						subscriptionStatus: subscribe?"Subscribe":"Unsubscribe"
					};
                    console.log("Submitting subscribe booking data: " + JSON.stringify(data));
                    //Create Booking AJAX
                    $.ajax({
                        type: 'POST',
                        async: false,
                        url: 'setSubscriptionStatus',
                        data: {jsonData: JSON.stringify(data)},
                        cache: false,
                        dataType: 'json'
                    }).done(function(response) {
                        if (!response.exception) {
                            toReturn = response;
                        } else {
                            var eid = btoa(response.message);
                            window.location = "error.jsp?eid=" + eid;
                        }
                    }).fail(function(error) {
                        alert("Oops. There was an error: " + JSON.stringify(error));
                    });
                    return toReturn;
                }

                //Function to make schedule based on GetScheduleAction response
                function renderSchedule() {
                    var tableClass = "scheduleTable:first";
                    var minTime = scheduleData.dayStartTime;
                    var maxTime = scheduleData.dayEndTime;

                    var timesArray = new Array();
                    for (var i = minTime; i < maxTime; i++) {
                        var timeVal = Date.parse(i + ":00:00");
                        timesArray.push(timeVal.toString("HH:mm:ss"));
                        timeVal.addMinutes(30);
                        timesArray.push(timeVal.toString("HH:mm:ss"));
                    }
                    
                    var datesArray = getDateArrayBetween(scheduleData.startDate, scheduleData.endDate, weekView);
                    //Append header names
					$("." + tableClass)
						.append(
							$(document.createElement('thead'))
								.append(
									$(document.createElement('tr'))
										.attr('id', 'scheduleHeader')
										.append($(document.createElement('td')))
										.append(function(){
											var $tdCollection = new Array();
											for (var i = 0; i < datesArray.length; i++) {
												$tdCollection.push(
													$(document.createElement('td'))
														.addClass('dateCol')
														.attr('id', 'col_' + (i + 1))
														.html(new Date(datesArray[i]).toString('dd MMM') + "<br/>" + new Date(datesArray[i]).toString('ddd'))
												);
											}
											return $tdCollection;
										})
								)
						);
					
					//Append body data 2.0
					$("." + tableClass)
						.append(function(){
							var $trCollection = new Array();
							for (var i = 0; i < timesArray.length; i++) {
								$trCollection.push(
									$(document.createElement('tr'))
										.append(i%2 === 0?
											$(document.createElement('td')) //Time display cell
											.addClass('timeDisplayCell')
											.attr('rowspan', '2')
											.html(timesArray[i].substring(0, 5))
											:false
										)
										.append(function(){
											var $tdCollection = new Array();
											for (var j = 0; j < datesArray.length; j++) {
												var datetime = new Date(datesArray[j]).toString("yyyy-MM-dd") + " " + timesArray[i];
												$tdCollection.push(
													$(document.createElement('td'))
														.addClass('tdCell')
														.addClass(i%2 === 0?'tdUpper':'tdLower')
														.attr('value', datetime)
														.height(25)
												);
											}
											return $tdCollection;
										})
								);
							}
							return $trCollection;
						});
					return false;
                }
				
				function renderTimeslots() {
					var timeslots = scheduleData.timeslots;
					var datesArray = weekView !== null?getDateArrayBetween(scheduleData.startDate, scheduleData.endDate, weekView):null;
					for (var key in timeslots) {
						if (timeslots.hasOwnProperty(key)) {
							var timeslot = timeslots[key];
							if (datesArray && (Date.parse(timeslot.datetime) < Date.parse(datesArray[0]) || Date.parse(timeslot.datetime) > Date.parse(datesArray[datesArray.length - 1]))) continue;
							var $tdCell = $('body').find('td.tdCell[value="' + timeslot.datetime + '"]');
							var $timeslot = $(document.createElement('div'))
								.addClass('timeslotCell')
								.attr('id', 'timeslot_' + timeslot.id)
								.attr('align', 'center')
								.attr('value', timeslot.datetime)
								.css ({
									height: ($tdCell.innerHeight() / 1.1 * (scheduleData.duration / 30)),
									width: $tdCell.outerWidth() / 1.1,
									position: 'absolute'
								})
								.offset({
									top: $tdCell.offset().top,
									left: $tdCell.offset().left
								})
								.addClass(timeslot.team?'bookedTimeslot':'unbookedTimeslot')
								.addClass(<%= activeRole.equals(Role.STUDENT) || activeRole.equals(Role.FACULTY)%> && !timeslot.available?'unavailableTimeslot':false)
								.addClass(<%= activeRole.equals(Role.TA) %> && timeslot.taId !== undefined?loggedInTa === timeslot.taId?'taChosenTimeslot':'otherTATimeslot':false)
								.append(timeslot.team?
									$(document.createElement('div'))
										.addClass('booking pendingBooking')
										.addClass(timeslot.status.toLowerCase() + 'Booking')
										.addClass(
											(<%= activeRole.equals(Role.FACULTY) %> && timeslot.isMyTeam)
											|| (<%= activeRole.equals(Role.STUDENT) %> && timeslot.team === teamName)
											|| (<%= activeRole.equals(Role.TA) %> && timeslot.taId !== undefined && loggedInTa === timeslot.taId)
											|| (<%= activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR) %>)
											|| timeslot.subscribedUsers && timeslot.subscribedUsers.indexOf(myEmail) !== -1
											?'myTeamBooking':false)
										.css ({
											height: ($tdCell.innerHeight() / 1.1 * (scheduleData.duration / 30)),
											width: $tdCell.outerWidth() / 1.1
										})
										.html(timeslot.team)
								:false)
								.append(!timeslot.team && timeslot.lastBookingWasRemoved?
									function(){
										var $removedDiv = $(document.createElement('div'));
										if (timeslot.lastBookingWasRemoved && timeslot.lastBookingStatus === 'rejected') {
											$removedDiv
													.addClass('rejectedBooking')
													.css ({
														height: ($tdCell.innerHeight() / 1.1 * (scheduleData.duration / 30)),
														width: $tdCell.outerWidth() / 1.1
													});
											makeTooltip($tdCell, 'Removed by ' + timeslot.lastBookingEditedBy);
										} else if (timeslot.lastBookingWasRemoved) {
											$removedDiv.addClass('deletedBookingOnTimeslot').addClass('fa fa-info-circle');
											makeTooltip($removedDiv, 'Removed by ' + timeslot.lastBookingEditedBy);
										}
										return $removedDiv;
									}
									:false
								);
							$('body').append($timeslot);
						}
					}
				}
                
                //Get dates between startDate and stopDate
                function getDateArrayBetween(startDate, stopDate, weekNum) {
                    var dateArray = new Array();
                    startDate = Date.parse(startDate);
                    stopDate = Date.parse(stopDate);
					var diffDays = Math.ceil(Math.abs(stopDate.getTime() - startDate.getTime()) / (1000 * 3600 * 24));
					maxWeekView = diffDays%7 === 0?(diffDays/7) + 1:Math.ceil(diffDays/7);
                    if (weekNum !== null) {
                        startDate.addWeeks(weekNum);
                        stopDate = startDate.clone().addWeeks(1).addDays(-1);
                    }
                    var currentDate = startDate;
                    while (currentDate <= stopDate) {
                        dateArray.push(currentDate.toString('yyyy-MM-dd'));
                        currentDate = new Date(currentDate).addDays(1);
                    }
                    return dateArray;
                }
				
				function initDragNDrop() {
					$(".unbookedTimeslot").each(function(){
						if ($(this).data('droppable')) $(this).droppable('destroy');
					});
					$(".unbookedTimeslot").droppable({
						tolerance: 'intersect',
						drop: function(event, ui) {
							var $booking = ui.draggable;
							$booking.draggable('option', 'revertDuration', 0);
							var $oldTimeslot = $booking.closest('.timeslotCell');
							var timeslot = scheduleData.timeslots[$oldTimeslot.attr('value')];
							var newDateTime = $(this).attr('value');
							var venue = timeslot.venue;
							var optionals = timeslot.optionals;
							bootbox.confirm({
								className : "bootbox-width",
								title: "Update Booking?",
								message: function(){
									var message = "Team: <b>" + timeslot.team + "</b><br/>";
									message += "Old Timeslot: <b style='color:red;'>" + Date.parse(timeslot.datetime).toString('dd-MMM-yy, HH:mm') + " - " + Date.parse(timeslot.datetime).addMinutes(scheduleData.duration).toString('HH:mm') + "</b><br/>";
									message += "New Timeslot: <b>" + Date.parse(newDateTime).toString('dd-MMM-yy, HH:mm') + " - " + Date.parse(newDateTime).addMinutes(scheduleData.duration).toString('HH:mm') + "</b><br/>";
									return message;
								},
								callback: function(result) {
									if (result) {
										var returnData = updateBooking($oldTimeslot, newDateTime, venue, optionals);
										if (returnData && returnData.success) {
											//Update teams json
											var team = null;
											for (var i = 0; i < teams.length; i++) {
												if (teams[i].teamName === timeslot.team) {
													team = teams[i];
													break;
												}
											}
											for (var i = 0; i < team.bookings.length; i++) {
												if (parseInt(team.bookings[i].scheduleId) === parseInt(scheduleData.id)) {
													team.bookings[i].datetime = Date.parse(returnData.booking.datetime).toString('dd MMM yyyy HH:mm');
													break;
												}
											}
											//Change page view
											var $newTimeslot = $("#timeslot_" + returnData.booking.id);
											$newTimeslot.removeClass('unbookedTimeslot');
											$newTimeslot.addClass('bookedTimeslot');
											scheduleData.timeslots[$newTimeslot.attr('value')] = returnData.booking;
											$oldTimeslot.removeClass('bookedTimeslot');
											$oldTimeslot.addClass('unbookedTimeslot');
											delete scheduleData.timeslots[$oldTimeslot.attr('value')];
											scheduleData.timeslots[$oldTimeslot.attr('value')] = {
												id: $oldTimeslot.attr('id').split("_")[1],
												venue: venue, 
												datetime: $oldTimeslot.attr('value')
											};
											$booking.detach();
											$newTimeslot.append($booking);
											setTimeout(function(){showNotification("INFO", $oldTimeslot, null);}, 500);
											initDragNDrop();
										} else {
											showNotification("INFO", $oldTimeslot, returnData.message);
										}
									}
								}
							});
						},
						accept: '.booking',
						hoverClass: 'bookingTimeslotHover'
					});
					
					$(".booking").each(function(){
						if ($(this).data('draggable')) $(this).draggable('destroy');
						if ($(this).children('i').length) $(this).children('i').remove();
						$(this).append($(document.createElement('i')).addClass('moveIcon fa fa-move fa-black'));
					});
					$(".booking").draggable({
						scroll: true,
						start: function(event, ui) {
							if ($(this).children('.popover').length) $(this).popover('hide');
						},
						drag: function(event, ui){
							var st = parseInt($(this).data("startingScrollTop"));
							if (
								!(/chrom(e|ium)/.test(navigator.userAgent.toLowerCase()) //Detects chrome
								|| (/safari/.test(navigator.userAgent.toLowerCase()))) //Detects safari
							) 
								ui.position.top -= $(window).scrollTop();
						},
						helper: function() {
							return $(this).clone().empty()
									.append(
										$.trim($(this).children().remove().end().text())
									)
									.append(
										$(document.createElement('i')).addClass('moveIcon fa fa-move fa-black')
									);
						},
						appendTo: 'body',
						containment: 'window'
					});
				}
				
				function initDashboards() {
					if (<%= activeRole.equals(Role.FACULTY) %>) {
						teams = JSON.parse('<s:property escape= "false" value= "allTeamsJson"/>');
						milestonesJson = JSON.parse('<s:property escape= "false" value= "milestonesJson"/>');
						var requiredAttendees = new Array();
						for (var i = 0; i < milestonesJson.length; i++) {
							if (milestonesJson[i].milestone.toLowerCase() === milestone.toLowerCase()) {
								for (var j = 0; j < milestonesJson[i].attendees.length; j++) {
									requiredAttendees.push(milestonesJson[i].attendees[j].toLowerCase());
								}
								break;
							}
						}
						teamsLoop: for (var i = 0; i < teams.length; i++) {
							var myRoles = teams[i].myRoles;
							for (var j = 0; j < myRoles.length; j++) {
								if (requiredAttendees.indexOf(myRoles[j]) !== -1) continue teamsLoop;
							}
							teams.splice(teams.indexOf(teams[i]), 1);
							--i;
						}
					}
					if ($('body').find('.dashboardPicker').length) return false;
					$('div.termPicker').after(
						$(document.createElement('div'))
							.addClass('indexItem pull-left dashboardPicker')
							.append(
								$(document.createElement('div'))
									.addClass('btn-group')
									.append(	
										$(document.createElement('a'))
											.addClass('btn btn-large dropdown-toggle')
											.attr('data-toggle', 'dropdown')
											.attr('href', '#')
											.append('<b>My Dashboard</b> <b class= "caret"></b>')
									)
									.append(
										$(document.createElement('ul'))
											.addClass('dropdown-menu')
											.append(
												$(document.createElement('li'))
													.append(
														$(document.createElement('a'))
															.attr('href', '#')
															.addClass('dashboardTeams')
															.append('Teams')
													)
											)
											.append(function() {
													if (<%= activeRole.equals(Role.ADMINISTRATOR)%>) {
														return $(document.createElement('li'))
															.append(
																$(document.createElement('a'))
																	.attr('href', 'taAvailability')
																	.addClass('dashboardSignups')
																	.append('TA Video Signups')
															);
													} else {
														return false;
													}
											})
									)
							)
					);
					
					$('.dashboardTeams').on('click', function(){
						showMyTeamsModal();
						return false;
					});
					
					function showMyTeamsModal() {
						var bookedTeamsPie = {"Teams with Bookings": 0, "Teams without Bookings": 0, "Teams with Pending Bookings": 0};
						bootbox.alert({
							title: <%=activeRole.equals(Role.FACULTY)%>?'My Teams' : 'Teams',
							message: function() {
								var $table =  $(document.createElement('table')).attr('id', 'myTeamsModalTable').addClass('modalTable').append(function(){
									if ($.isEmptyObject(teams)) {
										return $(document.createElement('tr')).append($(document.createElement('td')).html('You have no presentations to attend for this milestone'));
									}
									var $tParts = new Array();
									$tParts.push(
										$(document.createElement('thead')).append(
											$(document.createElement('tr'))
												.append($(document.createElement('th')).html('Team Name'))
												.append(<%=activeRole.equals(Role.FACULTY)%>?$(document.createElement('th')).html('My Role'):false)
												.append($(document.createElement('th')).html('Booking'))
										)
									);
									$tParts.push($(document.createElement('tbody')).append(function(){
										var $trs = new Array();
										for (var i = 0; i < teams.length; i++) {
											var team = teams[i];
											var $milestoneBooking = $(document.createElement('i')).addClass('fa fa-times').css('color', 'red').data('status', 'unbooked');
											for (var j = 0; j < team.bookings.length; j++) {
												if (parseInt(team.bookings[j].scheduleId) === parseInt(scheduleData.id)) {
													$milestoneBooking = $(document.createElement('span'))
														.addClass('memberName')
														.append(team.bookings[j].datetime + ' ')
														.append(team.bookings[j].bookingStatus === 'pending'?
															$(document.createElement('span')).html('(pending)')
															:$(document.createElement('i')).addClass('fa fa-check').css('color', '#A9DBA9')
														)
														.data('status', team.bookings[j].bookingStatus === 'pending'?'pending':'booked');
												}
											}
											if ($milestoneBooking.data('status') === 'unbooked') bookedTeamsPie["Teams without Bookings"]++; 
											else if ($milestoneBooking.data('status') === 'pending') bookedTeamsPie["Teams with Pending Bookings"]++;
											else bookedTeamsPie["Teams with Bookings"]++;
											$trs.push(
												$(document.createElement('tr'))
													.append(
														$(document.createElement('td'))
															.addClass('teamName')
															.attr('id', 'team_' + team.teamId)
															.append(
																$(document.createElement('a'))
																	.attr('href', function(){
																		var mailto = 'mailto:';
																		for (var j = 0; j < team.memberEmails.length; j++) {
																			mailto += team.memberEmails[j] + '; ';
																		}
																		mailto += '&body=Hi ' + team.teamName + ',%0D%0A%0D%0A';
																		return mailto;
																	})
																	.css('color', $milestoneBooking.is('.fa-times')?'red':false)
																	.append(team.teamName)
															)
													)
													.append(<%=activeRole.equals(Role.FACULTY)%>?
														$(document.createElement('td'))
															.append($(document.createElement('div')).addClass('memberList').append(function(){
																	var $spanArray = new Array();
																	for (var j = 0; j < team.myRoles.length; j++) {
																		$spanArray.push(
																			$(document.createElement('span')).addClass('memberName').append(team.myRoles[j])
																		);
																	}
																	return $spanArray;
																})
															)
														:false
													)
													.append(
														$(document.createElement('td')).append($milestoneBooking)
													)
											);
										}
										return $trs;
									}));
									return $tParts;
								});
								var $bookedTeamsPieDiv = $(document.createElement('div'))
									.attr('id', 'bookedTeamsPieDiv')
									.css({"height": "200px", "width": "400px"});
								var $modalDiv = $(document.createElement('div'))
									.addClass('modalDiv')
									.append($bookedTeamsPieDiv)
									.append($table);
								return $modalDiv;
							}
						});
						if ($.isEmptyObject(teams)) return false; //No teams for this milestone. Do not start datatables.
						
						var aoColumnsArray = (<%=activeRole.equals(Role.FACULTY)%>)? [null, null, {sType: 'datetime'}] : [null, {sType: 'datetime'}];
						var aaSortingArray = (<%=activeRole.equals(Role.FACULTY)%>)? [[2, 'asc']] : [[1, 'asc']];
						
						//Datatables
						$('.modal-body').find('#myTeamsModalTable').dataTable({
							aoColumns: aoColumnsArray,
							aaSorting: aaSortingArray,
							bPaginate: false,
							bJqueryUI: false,
							bLengthChange: true,
							bFilter: false,
							bSort: true,
							sDom: '<lft>'
						});
						
						//Pie chart
						var data = convertJsonToData(bookedTeamsPie);
						var piePlot = $.jqplot('bookedTeamsPieDiv', [data], 
							{
								seriesColors: ["#B8F79E", "#F7A8A8", "#F7F2A8"],
								seriesDefaults: {
									renderer: $.jqplot.PieRenderer,
									shadow: true,
									shadowAngle: 45,
									rendererOptions: {
										showDataLabels: true,
										dataLabels: 'value',
										dataLabelPositionFactor: 0.8,
										lineWidth: 5,
										highlightMouseOver: false
									}
								},
								grid: {
									drawGridLines: false,
									background: "#ffffff",
									borderColor: "#dddddd",
									shadow: false
								},
								legend: {
									show: true,
									location: 'e',
									fontSize: 12,
									border: "none",
									marginRight: 30
								}
							}
						);
					}
				}
				
				//Positioning fix
				$(window).resize(function(){
					repositionTimeslots();
				});
				
				function repositionTimeslots() {
					$('.timeslotCell').each(function(){
						var $timeslot = $(this);
						var $tdCell = $('.tdCell[value="' + $timeslot.attr('value') + '"]');
						$timeslot.offset({
							top: $tdCell.offset().top,
							left: $tdCell.offset().left
						});
					});
				}
                
                /*****************************
                 PLUGINS AND COMPONENTS
                 ****************************/
				 
				 /* JQPLOT */
				 function convertJsonToData(jsonData) {
					var data = [];
					for (var key in jsonData) {
						if (jsonData.hasOwnProperty(key)) {
							data.push([key, jsonData[key]]);
						}
					}
					return data;
				 }
                
                /* PINES NOTIFY */
                function showNotification(action, bodyTd, notificationMessage) {
					var timeslot = scheduleData.timeslots[bodyTd.attr('value')];
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
                    var dateToView = Date.parse(bodyTd.attr('value')).toString("dd MMM");
                    var startTimeToView = Date.parse(bodyTd.attr('value')).toString("HH:mm");
                    switch (action) {
                        case "SUCCESS":
                            if (!notificationMessage) opts.title = "Booked"; else opts.title = "Note";
                            if (!notificationMessage) opts.text = "Time: " + dateToView + " " + startTimeToView;
                            opts.type = "success";
                            break;
                        case "ERROR":
                            if (!notificationMessage || notificationMessage && timeslot.lastBookingStatus === 'deleted') opts.title = "Deleted"; else opts.title = "Rejected";
                            if (!notificationMessage) opts.text = "Time: " + dateToView + " " + startTimeToView;
                            opts.type = "error";
                            break;
                        case "INFO":
                            if (!notificationMessage) opts.title = "Updated"; else opts.title = "Note";
                            if (!notificationMessage) opts.text = "Time: " + dateToView + " " + startTimeToView;
                            opts.type = "info";
                            break;
                        case "WARNING":
                            $.pnotify_remove_all();
                            opts.title = "Note";
                            opts.type = "warning";
                            if (bodyTd.hasClass('existingTimeslot')){
                                opts.text += "<br/> Time: " + dateToView + " " + startTimeToView;
                                var id = scheduleData.timeslots[bodyTd.attr('value')].id;
                                $("#timeslot_" + id).children('.booking').effect('bounce', {distance: 50}, 'slow');
                                bodyTd.removeClass('existingTimeslot');
                            }
                            break;
                        default:
                            alert("Something went wrong");
                    }
                    $.pnotify(opts);
                }
				
				/* GENERIC PINES NOTIFY */
				function showBasicNotification(action, notificationMessage) {
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
                
                /* TOKEN INPUT */
                function appendTokenInput(booking){
                    booking.find('.optionalAttendees').tokenInput('destroy');
                    var opts = {
                        preventDuplicates: true,
                        theme: "facebook",
                        allowFreeTagging: true,
                        allowTabOut: true,
                        propertyToSearch: "name",
                        resultsLimit: 4,
                        hintText: "Enter name or email",
                        noResultsText: "Press [TAB] to add as email",
                        tokenFormatter: function(item) {
                            if (item && item.id) {
                                return "<li><p>" + item.id + "</p></li>";
                            } else if (item) {
                                return "<li><p>" + item.name + "</p></li>";
                            }
                        }
                    };
                    var timeslot = scheduleData.timeslots[booking.parents('.timeslotCell').attr('value')];
                    if (timeslot) {
                        //View Booking Data
                        opts.prePopulate = timeslot.optionals;
                        if ((<%= activeRole.equals(Role.FACULTY) %> && !timeslot.isMyTeam) ||(<%= activeRole.equals(Role.STUDENT) %> && timeslot.team !== teamName) || booking.is('.unavailableTimeslot') || <%= activeRole.equals(Role.TA) %>) {
                            opts.disabled= true;
                        }
                    }	
                    booking.find('.optionalAttendees').tokenInput(users, opts);
                }
				
				/*****************************
                 ICS FILE DOWNLOAD AJAX CALL
                 ****************************/
				 $('#downloadICSBtn').click(function(e){
					$.ajax({
						type: 'POST',
						data: {scheduleId: scheduleData.id}, 
						async: false,
						url: 'downloadICSFile'
					}).done(function(response) {
						$("#downloadICSBtn").button('reset');
						if (response.success) {
							window.location = response.downloadPath;
						} else {
							showBasicNotification("ERROR", response.message);
						}
					}).fail(function(response) {
						$("#downloadICSBtn").button('reset');
						showBasicNotification("WARNING", "Oops. Something went wrong. Please try again!");
					});
					return false;
				});
				//Initializing tool-tip for ICS Download Button due to limited support
				$('#downloadICSBtn').tooltip({
					title: 'Supported on Google Calendar',
					placement: 'bottom'
				});
            };
            
            /* POPOVER */
            function makePopover(container, title, content, customClass) {
                container.popover({
                    container: container,
                    trigger: 'manual',
                    html: true,
                    title: function(){
						if (!title) return false;
						return title + $(document.createElement('button')).addClass('close').append($(document.createElement('i')).addClass('fa fa-times fa-black')).outerHTML();
						
                    },
                    content: content,
                    placement: function(){
                        if ($('body').find('.tdCell[value="' + container.closest('.timeslotCell').attr('value') + '"]').parents("tr").children().index($('body').find('.tdCell[value="' + container.closest('.timeslotCell').attr('value') + '"]')) >= 7) {
                            return 'left';
                        } else {
                            return 'right';
                        }
                    },
					template: '<div class="popover ' + (customClass?customClass:'') + '"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
				});
            }
            
            /* TOOLTIP */
            function makeTooltip(container, title) {
                container.tooltip({
                    container: container,
                    html: true,
					trigger: 'hover',
                    title: title,
                    placement: function(){
                        if ($('body').find('.tdCell[value="' + container.closest('.timeslotCell').attr('value') + '"]').parents("tr").children().index($('body').find('.tdCell[value="' + container.closest('.timeslotCell').attr('value') + '"]')) >= 7) {
                            return 'left';
                        } else {
                            return 'right';
                        }
                    }
                });
            }

            addLoadEvent(viewScheduleLoad);
        </script>
    </body>
</html>
