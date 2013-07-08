define([
    'jquery',
    'bootstrap'
], function($, bootstrap) {
    return {
        //Initialize function
        init: function() {
            console.log("index init");
            $("#welcomeText").on('click', function() {
                alert("Hello there!");
            });

            //KNOCKOUT STUFF
            var bookingModel = function(date, startTime, endTime, team) {
                var self = this; //caching so that it can be accessed later in a different context
//                this.id = ko.observable(id);
                this.date = ko.observable(date);
                this.startTime = ko.observable(startTime);
                this.endTime = ko.observable(endTime);
                this.team = ko.observable(team);

//                this.nameUpdate = ko.observable(false); //if the name is currently updated
//                this.usernameUpdate = ko.observable(false); //if the username is currently updated
//
//                //executed if the user clicks on the span for the student name
//                this.nameUpdating = function() {
//                    self.nameUpdate(true); //make nameUpdate equal to true
//                };
//
//                //executed if the user clicks on the span for the student username
//                this.usernameUpdating = function() {
//                    self.usernameUpdate(true); //make usernameUpdate equal to true
//                };

            };


            var bookingsModel = function() {
                var self = this; //cache the current context
//                this.user_name = ko.observable(""); //default value for the student name
//                this.user_username = ko.observable("");
//                this.user_name_focus = ko.observable(true); //if the student name text field has focus
                this.bookings = ko.observableArray([]);

//                //Create User
//                this.createUser = function() {
//                    if (self.validateUser()) { //if the validation succeeded
//                        console.log("Create clicked");
//                        //build the data to be submitted to the server
//
//                        //submit the data to the server        
//                        $.ajax({
//                            url: 'knockout',
//                            type: 'POST',
//                            data: {'name': this.user_name(), 'username': this.user_username(), 'action': 'insert'}
//                        }).done(function(id) {
//                            //push a new record to the student array
//                            console.log("Got response");
//                            self.users.push(new userModel(id, self.user_name(), self.user_username()));
//                            self.user_name(""); //empty the text field for the student name
//                            self.user_username("");
//                        }).fail(function(error) {
//                            console.log("Received an error");
//                        });
//
//                    } else { //if the validation fails
//                        alert("Name and username are required and username should be a number!");
//                    }
//                };
//
//                //Validate
//                this.validateUser = function() {
//                    if (self.user_name() !== "" && self.user_username() !== "") {
//                        return true;
//                    }
//                    return false;
//                };

                //Load records
                this.loadData = function() {
                    console.log("loading bookings");
                    //fetch existing student data from database
                    $.ajax({
                        url: 'loadBookings',
                        dataType: 'json'
                    }).done(function(data) {
                        var records = data.result;
                        console.log(data);
                        
                        for (var x in data.data) {
                            console.log(x);
//                            console.log(data[x][0].startTime);
                            //student details
//                            var id = records[x].id;
                            var date = data.data[x].date;
                            var startTime = data.data[x].startTime;
                            var endTime = data.data[x].endTime;
                            var team = data.data[x].team;

                            //push each of the student record to the observable array for 
                            //storing student data
                            self.bookings.push(new bookingModel(date, startTime, endTime, team));
                        }
                    }).fail(function(error) {
                        console.log("Bloody hell loading failed");
                    });
                };

                //DELETE
                this.removeBooking = function(user) {
                    $.ajax({
                        type: 'POST',
                        url: 'knockout',
                        data: {'action': 'delete', 'student_id': user.id()}
                    }).done(function(response) {
                        //remove the currently selected student from the array
                        self.users.remove(user);
                    }).fail(function(error) {

                    });
                };

                //UPDATE
                this.updateBooking = function(user) {
                    //get the student details
                    var id = user.id();
                    var name = user.name();
                    var username = user.username();

                    //build the data
                    var student = {'id': id, 'name': name, 'username': username};

                    //submit to server via POST
                    $.ajax({
                        type: 'POST',
                        url: 'knockout',
                        data: {'action': 'update', 'student': student}
                    });
                };

            };

            ko.applyBindings(new bookingsModel());


            $('#mileStoneTab a').on('click', function(e) {
                var id = $(this).attr('id');
                console.log("Clicked " + id);
                e.preventDefault();
                $(this).tab('show');

                //Content effects
                var contentId = $(this).attr('id') + "Content";
                console.log("Showing " + contentId);

                $(".tab-pane").removeClass("active in");
                $("#" + contentId).addClass("active in");
            });


        }
    };
});