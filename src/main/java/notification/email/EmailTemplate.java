/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package notification.email;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map.Entry;
import java.util.Set;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import util.MiscUtil;

/**
 * Abstract class for sending standardized emails.
 * @author suresh
 */
public abstract class EmailTemplate {
	private static final String BASE_PATH;
	public String body;
	private static Logger logger = LoggerFactory.getLogger(EmailTemplate.class);
	
	static {
		BASE_PATH = MiscUtil.getProperty("General", "EMAIL_TEMPLATE_PATH");
	}
	
	public EmailTemplate(String fileName) {
		try {
			InputStream in = getClass().getClassLoader().getResourceAsStream(BASE_PATH + fileName);
			body = IOUtils.toString(in, "UTF-8");
		} catch (IOException ex) {
			logger.error("Could not read email template");
			logger.error(ex.getMessage());
		}
	}
	
	public void sendEmail() {
		Runnable r = new Runnable() {
			public void run() {
				MailSender.sendEmail(generateRecipientList(),
				generateEmailSubject(), generateEmailBody());
			}
		};
		Thread t = new Thread(r);
		t.start();
	}
	
	public String generateEmailBody() {
		HashMap<String, String> templateData = prepareBodyData();
		for (Entry<String, String> e : templateData.entrySet()) {
			body = body.replace(e.getKey(), e.getValue());
		}
		return body;
	}
	
	public abstract String generateEmailSubject();
	
	public abstract Set<String> generateRecipientList();
	
	public abstract HashMap<String, String> prepareBodyData();
	
}
