/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import javax.persistence.EntityManager;
import manager.ScheduleManager;
import manager.TermManager;
import model.Schedule;
import model.Term;
import org.hibernate.Session;
import org.hibernate.ejb.HibernateEntityManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class to put miscellaneous code
 * @author suresh
 */
public class MiscUtil {
	private static Logger logger = LoggerFactory.getLogger(MiscUtil.class);
	
	/**
	 * Name of the Persistence Unit used application-wide
	 */
	public static final String PERSISTENCE_UNIT = "scheduler";
	
	/**
	 * Boolean variable to check if the system is currently running in development mode
	 */
	public static final boolean DEV_MODE;
	
	static {
		DEV_MODE = Boolean.parseBoolean(getProperty("General", "DEV_MODE"));
		logger.info("DEV_MODE: " + DEV_MODE);
	}
	
	public static Term getActiveTerm(EntityManager em) {
		return TermManager.findByYearAndSemester(em, 2013, "Term 1");
	}
	
	public static Schedule getActiveSchedule(EntityManager em) {
		Term activeTerm = getActiveTerm(em);
		return ScheduleManager.findActiveByTerm(em, activeTerm);
	}
	
	public static String getProperty(String fileName, String propertyName) {
		try {
			Properties p = new Properties();	
			InputStream in = MiscUtil.class.getClassLoader().getResourceAsStream("Properties/" + fileName + ".properties");
			p.load(in);
			return p.getProperty(propertyName);
		} catch (IOException ex) {
			logger.error("Error reading properties file");
			logger.error(ex.getMessage());
		}
		
		return null;
	}
	
	public static void toggleTermRoleFilter(boolean activate, EntityManager em, Long termId) {
		 Session session;
		if (em instanceof HibernateEntityManager) {
			HibernateEntityManager hem = (HibernateEntityManager) em;
			session = hem.getSession();
		} else { return; }
		
		if (activate) {
			session.enableFilter("activeTermFilter").setParameter("termId", termId);
		} else {
			session.disableFilter("activeTermFilter");
		}
	}
}
