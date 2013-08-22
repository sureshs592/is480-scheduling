/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package userAction;

import com.opensymphony.xwork2.ActionSupport;
import constant.Role;
import java.util.ArrayList;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import model.Timeslot;
import org.apache.struts2.interceptor.ServletRequestAware;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Set;
import model.Booking;
import model.Team;
import model.role.Faculty;
import util.MiscUtil;

/**
 *
 * @author Prakhar
 */
public class ResponseAction extends ActionSupport implements ServletRequestAware {

    private HttpServletRequest request;
    private static Logger logger = LoggerFactory.getLogger(ResponseAction.class);
    private ArrayList<HashMap<String, String>> data = new ArrayList<HashMap<String, String>>();

    @Override
    public String execute() throws Exception {
        try {
            //EntityManager em = Persistence.createEntityManagerFactory(MiscUtil.PERSISTENCE_UNIT).createEntityManager();
            HttpSession session = request.getSession();
			
			Role activeRole = (Role) session.getAttribute("activeRole");
			if (activeRole.equals(Role.FACULTY)) {

				Faculty faculty = (Faculty) session.getAttribute("user");
				//Getting all the bookings for the faculty for the active term
				Set<Booking> bookingsList = faculty.getRequiredBookings();

				//Putting all the booking details for the user in a hash map to display it 
				if (bookingsList.size() > 0) {
					for (Booking b: bookingsList) {
						Timeslot timeslot = b.getTimeslot();
						
						//Getting all the timeslot and booking details
						HashMap<String, String> map = new HashMap<String, String>();
						//SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy HH:mm aa");
						SimpleDateFormat sdfForDate = new SimpleDateFormat("EEE, dd MMM yyyy");
						SimpleDateFormat sdfForTime = new SimpleDateFormat("HH:mm aa");
						String venue = timeslot.getVenue();
						Long timeslotId = timeslot.getId();
						Team team = b.getTeam();
						Long teamId = team.getId();
						String teamName = team.getTeamName();
						String milestoneName = timeslot.getSchedule().getMilestone().getName();
						String time = sdfForTime.format(timeslot.getStartTime()) + " - " + 
								sdfForTime.format(timeslot.getEndTime());
						String date = sdfForDate.format(timeslot.getStartTime());
						String myStatus = b.getResponseList().get(faculty).toString();
						
						//A user can only have 1 role in a team (Supervisor and Reviewer cannot be same for the same team)
						String userRole = null;
						if (team.getSupervisor().equals(faculty)) {
							userRole = "Supervisor";
						} else if (team.getReviewer1().equals(faculty) || team.getReviewer2().equals(faculty)) {
							userRole = "Reviewer";
						}

						map.put("timeslotId", String.valueOf(timeslotId));
						map.put("teamName", teamName);
						map.put("milestone", milestoneName);
						map.put("userRole", userRole);
						map.put("time", time);
						map.put("date", date);
						map.put("venue", venue);
						map.put("myStatus", myStatus);

						data.add(map);
					}
				}
				return SUCCESS;
			} else {
				request.setAttribute("error", "Oops. You're not authorized to access this page!");
				logger.error("User cannot access this page");
				return ERROR;
			}
        } catch (Exception e) {
            logger.error("Exception caught: " + e.getMessage());
            if (MiscUtil.DEV_MODE) {
                for (StackTraceElement s : e.getStackTrace()) {
                    logger.debug(s.toString());
                }
            }
            request.setAttribute("error", "Error with Response: Escalate to developers!");
            return ERROR;
        }
    }

    public ArrayList<HashMap<String, String>> getData() {
        return data;
    }

    public void setData(ArrayList<HashMap<String, String>> data) {
        this.data = data;
    }

    public void setServletRequest(HttpServletRequest hsr) {
        this.request = hsr;
    }
}  //end of class