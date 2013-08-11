/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package notification.email;

import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;
import model.Timeslot;
import model.User;

/**
 *
 * @author suresh
 */
public class ApprovedBookingEmail extends EmailTemplate{
	Timeslot t;
	User approver;
	
	public ApprovedBookingEmail(Timeslot t, User approver) {
		super("approved_booking.html");
		this.t = t;
		this.approver = approver;
	}

	@Override
	public String generateEmailSubject() {
		return t.getSchedule().getMilestone().getName() + " - Booking Approval";
	}

	@Override
	public Set<String> generateToAddressList() {
		Set<String> emails = new HashSet<String>();
		for (User u : t.getTeam().getMembers()) {
			emails.add(u.getUsername() + "@smu.edu.sg");
		}
		
		return emails;
	}

	@Override
	public Set<String> generateCCAddressList() {
		return null;
	}

	@Override
	public HashMap<String, String> prepareBodyData() {
		HashMap<String, String> map = new HashMap<String, String>();
		
		//Inserting milestone
		map.put("[MILESTONE]", t.getSchedule().getMilestone().getName());
		
		//Inserting approver name
		map.put("[APPROVER_NAME]", approver.getFullName());
		
		//Insert team name
		map.put("[TEAM_NAME]", t.getTeam().getTeamName());
		
		//Insert start date
		SimpleDateFormat dateFormat = new SimpleDateFormat("EEE, d MMM yyyy");
		map.put("[DATE]", dateFormat.format(t.getStartTime()));
		
		//Insert start and end time
		SimpleDateFormat timeFormat = new SimpleDateFormat("h:mm a");
		map.put("[START_TIME]", timeFormat.format(t.getStartTime()));
		map.put("[END_TIME]", timeFormat.format(t.getEndTime()));
		
		//Insert venue
		map.put("[VENUE]", t.getVenue());
		
		//Insert required attendees
		Set<User> userList = t.getStatusList().keySet();
		Iterator<User> iter = userList.iterator();
		StringBuilder result = new StringBuilder();
		
		int numBullet = 1;
		while (iter.hasNext()) {
			result.append(numBullet++).append(". ")
					.append(iter.next().getFullName());
			if (iter.hasNext()) {
				result.append("<br />");
			}
		}
		map.put("[REQUIRED_ATTENDEES]", result.toString());
		
		return map;
	}
	
}
