/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package model.dao;

import java.math.BigInteger;
import java.sql.Date;
import java.util.List;
import model.Team;
import model.Term;
import model.Timeslot;
import org.hibernate.Query;
import org.hibernate.Session;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import util.HibernateUtil;

/**
 *
 * @author Prakhar
 */
public class TimeslotStatusDAO {
    static final Logger logger = LoggerFactory.getLogger(TimeslotStatusDAO.class);
    static Session session = HibernateUtil.getSession();
    
}
