/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package userAction;

import static com.opensymphony.xwork2.Action.ERROR;
import static com.opensymphony.xwork2.Action.SUCCESS;
import com.opensymphony.xwork2.ActionSupport;
import constant.Role;
import java.util.ArrayList;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts2.interceptor.ServletRequestAware;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.HashMap;
import javax.persistence.EntityManager;
import org.json.JSONObject;
import util.MiscUtil;

/**
 *
 * @author Prakhar
 */
public class UploadFileAction extends ActionSupport implements ServletRequestAware {

    private HttpServletRequest request;
    private static Logger logger = LoggerFactory.getLogger(UploadFileAction.class);
    private ArrayList<HashMap<String, Object>> data = new ArrayList<HashMap<String, Object>>();
    private HashMap<String, Object> json = new HashMap<String, Object>();

    @Override
    public String execute() throws Exception {
		EntityManager em = null;
        try {
            em = MiscUtil.getEntityManagerInstance();
            HttpSession session = request.getSession();
            //Getting the active role of the user
            Role activeRole = (Role) session.getAttribute("activeRole");
			
			//Checking role of the user
			if (activeRole.equals(Role.ADMINISTRATOR) || activeRole.equals(Role.COURSE_COORDINATOR)) {
				JSONObject inputData = new JSONObject(request.getParameter("jsonData"));
				long termId = inputData.getLong("termId");
			} else {
				request.setAttribute("error", "Oops. You're not authorized to access this page!");
				logger.error("User cannot access this page");
				return ERROR;
			}
			json.put("success", true);
			
		} catch (Exception e) {
           logger.error("Exception caught: " + e.getMessage());
            if (MiscUtil.DEV_MODE) {
                for (StackTraceElement s : e.getStackTrace()) {
                    logger.debug(s.toString());
                }
            }
            json.put("exception", true);
            json.put("message", "Error with UploadFileAction: Escalate to developers!");
        } finally {
			if (em != null && em.getTransaction().isActive()) em.getTransaction().rollback();
			if (em != null && em.isOpen()) em.close();
		}
		return SUCCESS;
    } //end of execute function

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