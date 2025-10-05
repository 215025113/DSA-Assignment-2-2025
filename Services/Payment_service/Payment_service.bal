import ballerina/log;
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

listener kafka:Listener ticketListener = new (kafka:DEFAULT_URL, {
    groupId: "Tickets",
    topics: [
        "TicketRequests",
        "Routes",
        "Payments",
        "TicketStatus"
    ]
});

service on paymentConsumer {
    resource function onMessage(kafka:ConsumerRecord[] records) {
        foreach var rec in records {
            io:println("Processing payment for: ", rec.value);
        }
    }
}