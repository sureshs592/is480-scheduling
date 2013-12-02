/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package notification.email;

import java.io.File;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import model.Booking;
import model.User;

/**
 *
 * @author suresh
 */
public class ApprovedBookingEmail extends EmailTemplate{
	Booking b;
	User approver;
	
	public ApprovedBookingEmail(Booking b, User approver) {
		super("approved_booking.html");
		this.b = b;
		this.approver = approver;
	}

	@Override
	public String generateEmailSubject() {
		return generateBookingSubjectTitle(b, "Approved by " + approver.getFullName() + " ");
	}

	@Override
	public Set<String> generateToAddressList() {
		Set<String> emails = new HashSet<String>();
		for (User u : b.getTeam().getMembers()) {
			emails.add(u.getEmail());
		}
		
		return emails;
	}

	@Override
	public Set<String> generateCCAddressList() {
		Set<String> emails = new HashSet<String>();
		emails.add(approver.getEmail());
		return emails;
	}

	@Override
	public HashMap<String, String> prepareBodyData() {
		HashMap<String, String> map = new HashMap<String, String>();
		
		map = generateStandardDetails(b, map);
		
		//Inserting approver name
		map.put("[APPROVER_NAME]", approver.getFullName());
		
		return map;
	}

	@Override
	public File getFileAttachment() {
		return null;
	}

	@Override
	public String getFileAttachmentName() {
		return null;
	}
	
}
