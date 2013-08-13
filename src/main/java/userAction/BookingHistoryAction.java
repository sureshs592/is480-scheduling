/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package userAction;

import static com.opensymphony.xwork2.Action.ERROR;
import static com.opensymphony.xwork2.Action.SUCCESS;
import com.opensymphony.xwork2.ActionSupport;
import java.util.ArrayList;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import model.Schedule;
import model.Timeslot;
import model.User;
import org.apache.struts2.interceptor.ServletRequestAware;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import constant.Status;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import javax.persistence.EntityManager;
import javax.persistence.EntityTransaction;
import javax.persistence.Persistence;
import javax.servlet.RequestDispatcher;
import manager.RoleManager;
import manager.ScheduleManager;
import manager.UserManager;
import model.Role;
import model.Team;
import model.Term;
import util.MiscUtil;

/**
 *
 * @author Prakhar
 */
public class BookingHistoryAction extends ActionSupport implements ServletRequestAware {

    private HttpServletRequest request;
    private static Logger logger = LoggerFactory.getLogger(BookingHistoryAction.class);
    private Long termId;
    private ArrayList<HashMap<String, Object>> data = new ArrayList<HashMap<String, Object>>();
    private HashMap<String, Object> json = new HashMap<String, Object>();

    @Override
    public String execute() throws Exception {
        try {
            EntityManager em = Persistence.createEntityManagerFactory(MiscUtil.PERSISTENCE_UNIT).createEntityManager();
            HttpSession session = request.getSession();
            //Getting the active role of the user
            String activeRole = (String) session.getAttribute("activeRole");

            //Checking user's role 
            if (activeRole.equalsIgnoreCase("Student") || activeRole.equalsIgnoreCase("Supervisor/Reviewer")
                    || activeRole.equalsIgnoreCase("TA")) {

                //Getting active term (to filter bookings by current term)
                Term term = MiscUtil.getActiveTerm(em);
                long activeTermId = term.getId();

                //Getting updated user object from session (this object is updated when booking status is updated)
				User oldUser = (User) session.getAttribute("user");
                String username = oldUser.getUsername();
				User user = UserManager.findByUsername(em, username);
				session.setAttribute("user", user);
				
				//Getting all the timeslots which the user is part of
                //This set includes all the timeslots the user has ever been ever part of (across semesters)
                Set<Timeslot> userTimeslots = user.getTimeslots();

                if (userTimeslots.size() > 0) {
                    List<Timeslot> filteredTimeslots = new ArrayList<Timeslot>();
                    //To get a filtered list of timeslots based on term (User will choose the term from UI)
                    if (termId != null) {
                        Iterator it = userTimeslots.iterator();
                        while (it.hasNext()) {
                            Timeslot timeslot = (Timeslot) it.next();
                            Team team = timeslot.getTeam();
                            if (team != null) {
                                if (termId == team.getTerm().getId()) {
                                    filteredTimeslots.add(timeslot);
                                }
                            }
                        }
                    } else {  //When user wants all the timeslots (Will only happen when user accesses the booking history page from navbar)
                        Iterator it = userTimeslots.iterator();
                        while (it.hasNext()) {
                            Timeslot timeslot = (Timeslot) it.next();
                            filteredTimeslots.add(timeslot);
                        }
                    }

                    //Iterating over the list and getting the necessary details
                    if (filteredTimeslots.size() > 0) {
                        for (Timeslot timeslot : filteredTimeslots) {
                            HashMap<String, Object> map = new HashMap<String, Object>();
							SimpleDateFormat sdfForDate = new SimpleDateFormat("EEE, dd MMM yyyy");
							SimpleDateFormat sdfForTime = new SimpleDateFormat("HH:mm aa");
							
							String venue = timeslot.getVenue();
                            String teamName = timeslot.getTeam().getTeamName();
                            //Getting the schedule based on timeslot (Each timeslot belongs to 1 unique schedule)
                            Schedule schedule = timeslot.getSchedule();
                            String milestoneName = "";
                            if (schedule != null) {
                                milestoneName = schedule.getMilestone().getName();
                            }
                            String date = sdfForDate.format(timeslot.getStartTime());
                            String time = sdfForTime.format(timeslot.getStartTime()) + " - " + 
									sdfForTime.format(timeslot.getEndTime());

                            //Only for supervisors/reviewers
                            if (activeRole.equalsIgnoreCase("Supervisor/Reviewer")) { 
                                String myStatus = timeslot.getStatusList().get(user).toString();
                                map.put("myStatus", myStatus);
                            }

							//Overall status (will be seen by both students and supervisor/reviewer)
							String overallBookingStatus = timeslot.getOverallBookingStatus().toString();
							map.put("overallBookingStatus", overallBookingStatus);
							
                            if (activeRole.equalsIgnoreCase("Student")) {
                                //Detailed status
                                List<HashMap<String, String>> individualStatusList = new ArrayList<HashMap<String, String>>();
                                HashMap<User, Status> members = null;
                                if (timeslot.getStatusList() != null) {
                                    members = timeslot.getStatusList();
                                    Iterator iter = members.keySet().iterator();
                                    while (iter.hasNext()) {
                                        HashMap<String, String> userMap = new HashMap<String, String>();
                                        User supervisorReviewer = (User) iter.next();
                                        Status status = members.get(supervisorReviewer);
                                        userMap.put("name", supervisorReviewer.getFullName());
                                        userMap.put("status", status.toString());

                                        individualStatusList.add(userMap);
                                    }
                                }
                                map.put("individualBookingStatus", individualStatusList);
                            }

                            map.put("teamName", teamName);
                            map.put("milestone", milestoneName);
                            map.put("date", date);
                            map.put("time", time);
                            map.put("venue", venue);

                            data.add(map);
                        }
                    }
                }
                json.put("success", true);
                return SUCCESS;
            } // Incorrect user role
            json.put("error", true);
            json.put("message", "You are not authorized to access this page!");
        } catch (Exception e) {
//            logger.error("Exception caught: " + e.getMessage());
//            if (MiscUtil.DEV_MODE) {
//                for (StackTraceElement s : e.getStackTrace()) {
//                    logger.debug(s.toString());
//                }
//            }
//            json.put("success", false);
//            json.put("message", "Error with BookingHistory: Escalate to developers!");
			request.setAttribute("error", "Error with BookingHistory: Escalate to developers!");
        }
        return ERROR;
    } //end of execute function

    public Long getTermId() {
        return termId;
    }

    public void setTermId(Long termId) {
        this.termId = termId;
    }

    public ArrayList<HashMap<String, Object>> getData() {
        return data;
    }

    public void setData(ArrayList<HashMap<String, Object>> data) {
        this.data = data;
    }

    public HashMap<String, Object> getJson() {
        return json;
    }

    public void setJson(HashMap<String, Object> json) {
        this.json = json;
    }

    public HttpServletRequest getRequest() {
        return request;
    }

    public void setServletRequest(HttpServletRequest hsr) {
        this.request = hsr;
    }
} //end of class