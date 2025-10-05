import ballerina/http;
import ballerinax/mongodb;
import ballerina/kafka;
import ballerina/time;

mongodb:ConnectionConfig mongoConfig = {
    connection: {
        host: "localhost",
        port: 27017,
        auth: {
            username: "";
            password: "",
            database: "Ticket"
        },
        options: {
            sslEnabled: false,
            serverSelectionTimeout: 5000
        }
    } 
};

mongodb:Client mongoClient = check new (mongoConfig);
string ticketCollection = "tickets";

listener http:Listener adminListener = new (8080);
mongodb:Client db = check new (mongoConfig);

service /admin on adminListener {

    resource function get report() returns json {
        var tickets = db->find("transportdb", "tickets");
        var users = db->find("transportdb", "users");
        return {
            totalUsers: users is stream<json, error> ? users.count() : 0,
            totalTickets: tickets is stream<json, error> ? tickets.count() : 0
        };
    }
}