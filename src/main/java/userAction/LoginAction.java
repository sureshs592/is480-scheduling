/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package userAction;

import static com.opensymphony.xwork2.Action.SUCCESS;
import com.opensymphony.xwork2.ActionSupport;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import javax.persistence.EntityManager;
import javax.persistence.Persistence;
import javax.servlet.RequestDispatcher;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.xml.bind.DatatypeConverter;
import manager.RoleManager;
import manager.SettingsManager;
import manager.UserManager;
import model.Role;
import model.Term;
import model.User;
import org.apache.struts2.interceptor.ServletRequestAware;
import org.apache.struts2.interceptor.ServletResponseAware;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import systemAction.GetScheduleAction;
import util.MiscUtil;

/**
 *
 * @author Prakhar
 */
public class LoginAction extends ActionSupport implements ServletRequestAware, ServletResponseAware {

    //Request and Response
    private HttpServletRequest request;
    private static Logger logger = LoggerFactory.getLogger(LoginAction.class);
    private final boolean debugMode = true;
    private HttpServletResponse response;
    private List<Role> userRoles;
    private boolean isSupervisor;
    private boolean isReviewer;
    private boolean isAdmin;
    private boolean isStudent;
    private boolean isTA;
    // sorted in alphabetical order. ordering is important
    // when generating the signature
    private static final String[] keys = {
        "oauth_callback",
        "oauth_consumer_key",
        "oauth_nonce",
        "oauth_signature_method",
        "oauth_timestamp",
        "oauth_version",
        "smu_domain",
        "smu_fullname",
        "smu_groups",
        "smu_username"};
    private static final String SECRET_KEY = "psastest2012";

    public static String encode(String plain) {
        try {
            String encoded = URLEncoder.encode(plain, "UTF-8");

            return encoded.replace("*", "%2A")
                    .replace("+", "%20")
                    .replace("%7E", "~");
        } catch (Exception e) {
            e.printStackTrace(); // hopefully this wont happen
        }
        return "";
    }

    @Override
    public String execute() throws Exception {
        try {
            EntityManager em = Persistence.createEntityManagerFactory(MiscUtil.PERSISTENCE_UNIT).createEntityManager();

            logger.info("Reached LoginAction");

            //return to login
            if (request.getParameter("oauth_callback") == null) {
                return "error";
            }

            //Set strings of parameters
            for (Object o : request.getParameterMap().keySet()) {
                logger.info("Parameter key: " + (String) o + ", value: " + request.getParameter((String) o));
            }

            //Get callback URL
            String callbackUrl = "http://" + request.getServerName() + ":" + request.getServerPort() + request.getRequestURI();
            String uri = "POST&" + encode(callbackUrl) + "&";
            String pairs = "";
            for (int i = 0; i < keys.length - 1; i++) {
                pairs += keys[i] + "=" + encode(request.getParameter(keys[i])) + "&";
            }

            //for-loop above stops before encoding the last key-value pair because
            // the last key-value pair doesnt need the trailing & character 
            pairs += keys[keys.length - 1] + "=" + encode(request.getParameter(keys[keys.length - 1]));
            uri += encode(pairs);

            // initialize the Mac object
            Mac mac = Mac.getInstance("HmacSHA1");
            SecretKey secretKey = new SecretKeySpec((SECRET_KEY + "&").getBytes(), mac.getAlgorithm());
            mac.init(secretKey);

            // generates the signature & retrieves server signature
            String generatedSignature = DatatypeConverter.printBase64Binary(mac.doFinal(uri.getBytes())).trim();
            String serverSignature = (request.getParameter("oauth_signature"));

            // gets the time when the server generates the signature
            long serverSignatureTime = Long.parseLong(request.getParameter("oauth_timestamp"));
            Calendar serverCal = Calendar.getInstance();
            serverCal.setTimeInMillis(serverSignatureTime);
            serverCal.setTimeInMillis(serverSignatureTime * 1000);

            // gets the current time in seconds
            Calendar clientCal = Calendar.getInstance();
            long currentTime = System.currentTimeMillis() / 1000;
            clientCal.setTimeInMillis(currentTime);
            clientCal.setTimeInMillis(currentTime * 1000);

            logger.info("Server signature: " + serverSignature);
            logger.info("Client signature: " + generatedSignature);
            logger.info("Server signature time * 1000: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(serverCal.getTime()));
            logger.info("Client signature time * 1000: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(clientCal.getTime()));

            HttpSession session = request.getSession();

            if (serverSignature.equals(generatedSignature)) {
                //Login successful

                //Check if user exists in our DB
                User user = UserManager.findByUsername(em, request.getParameter("smu_username"));
                if (user != null) {
                    //Welcome to the system
                    session.setAttribute("user", user);
                    session.setAttribute("fullname", request.getParameter("smu_fullname"));
                    session.setAttribute("groups", request.getParameter("smu_groups").split(","));
                    ArrayList<Term> activeTerms = SettingsManager.getActiveTerms(em);
                    session.setAttribute("currentActiveTerm", activeTerms.get(0));

                    //To check the user's role
                    isSupervisor = false;
                    isReviewer = false;
                    isStudent = false;
                    isAdmin = false;
                    isTA = false;

                    //Getting the users roles for active term
                    userRoles = new ArrayList<Role>();
                    Term activeTerm = activeTerms.get(0);
                    List<Role> activeRoles = RoleManager.getAllRolesByTerm(em, activeTerm);
                    for (Role role : activeRoles) {
                        List<User> listUsers = role.getUsers();
                        for (User userObj : listUsers) {
                            if (user.equals(userObj)) {
                                userRoles.add(role);
                            }
                        }
                    }

                    //This is not for the active term
                    //userRoles = user.getRoles();

                    if (userRoles != null && userRoles.size() > 0) {
                        for (Role role : userRoles) {
                            if (role.getName().equalsIgnoreCase("Supervisor")) {
                                isSupervisor = true;
                                session.setAttribute("isSupervisor", isSupervisor);
                            } else if (role.getName().equalsIgnoreCase("Reviewer")) {
                                isReviewer = true;
                                session.setAttribute("isReviewer", isReviewer);
                            } else if (role.getName().equalsIgnoreCase("Student")) {
                                isStudent = true;
                                session.setAttribute("isStudent", isStudent);
                            } else if (role.getName().equalsIgnoreCase("TA")) {
                                isTA = true;
                                session.setAttribute("isTA", isTA);
                            } else if (role.getName().equalsIgnoreCase("Administrator")) {
                                isAdmin = true;
                                session.setAttribute("isAdmin", isAdmin);
                            }
                        }
                    }
                    session.setAttribute("isSupervisor", isSupervisor);
                    session.setAttribute("isReviewer", isReviewer);
                    session.setAttribute("isStudent", isStudent);
                    session.setAttribute("isTA", isTA);
                    session.setAttribute("isAdmin", isAdmin);
                    session.setAttribute("userRoles", userRoles);  //Setting the list of roles for user
                } else {
                    //Kick user out
                    request.setAttribute("error", "Yo, understand you're from SMU, but you can't login here yo!");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                }
            } else {
                //Login unsuccessful
                logger.error("LOGIN - SOMETHING WENT WRONG");
            }

            //To check if user has multiple roles (If yes, redirect to another page)
            if (userRoles.size() > 1) {
                return "goToRoles";
            }
        } catch (Exception e) {
            logger.error("Exception caught: " + e.getMessage());
            if (debugMode) {
                for (StackTraceElement s : e.getStackTrace()) {
                    logger.debug(s.toString());
                }
            }
            request.setAttribute("error", "Error with Login: Escalate to developers!");
            return ERROR;
        }
        return SUCCESS;
    }

    public HttpServletRequest getServletRequest() {
        return request;
    }

    public HttpServletResponse getServletResponse() {
        return response;
    }

    public void setServletRequest(HttpServletRequest request) {
        this.request = request;
    }

    public void setServletResponse(HttpServletResponse response) {
        this.response = response;
    }

    public List<Role> getUserRoles() {
        return userRoles;
    }

    public void setUserRoles(List<Role> userRoles) {
        this.userRoles = userRoles;
    }

    public boolean isIsSupervisor() {
        return isSupervisor;
    }

    public void setIsSupervisor(boolean isSupervisor) {
        this.isSupervisor = isSupervisor;
    }

    public boolean isIsReviewer() {
        return isReviewer;
    }

    public void setIsReviewer(boolean isReviewer) {
        this.isReviewer = isReviewer;
    }

    public boolean isIsAdmin() {
        return isAdmin;
    }

    public void setIsAdmin(boolean isAdmin) {
        this.isAdmin = isAdmin;
    }

    public boolean isIsStudent() {
        return isStudent;
    }

    public void setIsStudent(boolean isStudent) {
        this.isStudent = isStudent;
    }

    public boolean isIsTA() {
        return isTA;
    }

    public void setIsTA(boolean isTA) {
        this.isTA = isTA;
    }
}
