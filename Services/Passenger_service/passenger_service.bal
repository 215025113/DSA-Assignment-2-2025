import ballerina/http;
import ballerina/log;
import ballerinax/mongodb;
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

listener kafka:Listener ticketListener = new (kafka:DEFAULT_URL, {
    groupId: "Tickets",
    topics: [
        "TicketRequests",
        "Routes",
        "Payments",
        "TicketStatus"
    ]
});

listener http:Listener passengerListener = new (8080);

mongodb:Client db = check new (env:getEnv("MONGO_URI"));
kafka:Producer ticketProducer = check new ({ bootstrapServers: env:getEnv("KAFKA_BOOTSTRAP") });

service /passenger on passengerListener {

    resource function post register(@http:Payload json user) returns json {
        check db->insert("transportdb", "users", user);
        return { message: "User registered successfully" };
    }

    resource function get tickets() returns json {
        var res = db->find("transportdb", "tickets");
        return res is stream<json, error> ? { tickets: res.toArray() } : { error: res.message() };
    }

    resource function post buy(@http:Payload json req) returns json {
        _ = check ticketProducer->send({
            topic: "ticket.requests",
            value: req.toJsonString()
        });
        return { message: "Ticket purchase request sent" };
    }
}