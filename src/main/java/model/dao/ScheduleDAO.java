/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package model.dao;

import java.math.BigInteger;
import java.text.SimpleDateFormat;
import java.util.Date;
import model.Schedule;
import org.hibernate.Query;
import org.hibernate.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import util.HibernateUtil;
import util.Milestone;

/**
 *
 * @author suresh
 */
public class ScheduleDAO {
	static final Logger logger = LoggerFactory.getLogger(ScheduleDAO.class);

    static Session session = HibernateUtil.getSession();

    public static void save(Schedule schedule) {
        session.beginTransaction();
        session.saveOrUpdate(schedule);
        session.getTransaction().commit();
        logger.info("Added schedule TermId:" + schedule.getId().getTermId()
				+ " Milestone: " + schedule.getId().getMilestone());
    }

    public static void update(Schedule schedule) {
        session.beginTransaction();
        session.update(schedule);
        session.getTransaction().commit();
        logger.info("Updated schedule TermId:" + schedule.getId().getTermId()
				+ " Milestone: " + schedule.getId().getMilestone());
    }

    public static void delete(Schedule schedule) {
        session.beginTransaction();
        session.delete(schedule);
        session.getTransaction().commit();
        logger.info("Deleted schedule TermId:" + schedule.getId().getTermId()
				+ " Milestone: " + schedule.getId().getMilestone());
    }

    public static Schedule findByScheduleId(BigInteger termId, Milestone milestone) {
        session.beginTransaction();
        Query query = session.createQuery("from Schedule where "
				+ "id.termId = :termId and id.milestone = :milestone");
        query.setParameter("termId", termId);
		query.setParameter("milestone", milestone);
        Schedule schedule = (Schedule) query.uniqueResult();
        session.getTransaction().commit();
        return schedule;
    }
    
}
