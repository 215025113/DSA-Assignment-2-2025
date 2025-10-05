import ballerina/http;
import ballerina/log;
import ballerinax/mongodb;
import ballerina/kafka;
import ballerina/time;
import ballerina/uuid;

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
type Ticket record {
    string ticketID;
    string userID;
    string tripID;
    float price;
    int quantity;
    boolean TicketStatus;
};

listener http:Listener transportListener = new (8080);
mongodb:Client db = check new (env:getEnv("MONGO_URI"));

service /transport on transportListener {
    resource function post route(@http:Payload json route) returns json {
        check db->insert("transportdb", "routes", route);
        return { message: "Route added" };
    }

    resource function get routes() returns json {
        var res = db->find("transportdb", "routes");
        return res is stream<json, error> ? { routes: res.toArray() } : { error: res.message() };
    }
}