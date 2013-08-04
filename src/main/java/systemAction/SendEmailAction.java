/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package systemAction;

import com.opensymphony.xwork2.ActionSupport;
import java.io.IOException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import manager.MilestoneManager;
import org.apache.struts2.interceptor.ServletRequestAware;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 *
 * @author User
 */
public class SendEmailAction extends ActionSupport implements ServletRequestAware{
    
    private HttpServletRequest request;
    private static Logger logger = LoggerFactory.getLogger(SendEmailAction.class);
    private final boolean debugMode = true;
    
    @Override
    public String execute() throws ServletException, IOException {
        try {
            //Code here
        } catch (Exception e) {
            logger.error("Exception caught: " + e.getMessage());
            if (debugMode) {
                for (StackTraceElement s : e.getStackTrace()) {
                    logger.debug(s.toString());
                }
            }
            request.setAttribute("error", "Error with SendEmail: Escalate to developers!");
            return ERROR;
        }
        return SUCCESS;
    }

    public HttpServletRequest getRequest() {
        return request;
    }

    public void setRequest(HttpServletRequest request) {
        this.request = request;
    }

    public void setServletRequest(HttpServletRequest hsr) {
        this.request = hsr;
    }
    
}
