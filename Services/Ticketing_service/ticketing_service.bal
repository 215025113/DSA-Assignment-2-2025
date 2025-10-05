import ballerina/http;
import ballerinax/kafka;
import ballerina/log;
import ballerinax/mongodb

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

listener http:Listener ticketListener = new (8080);
mongodb:Client db = check new (env:getEnv("MONGO_URI"));
kafka:Consumer ticketConsumer = check new ({
    bootstrapServers: env:getEnv("KAFKA_BOOTSTRAP"),
    groupId: "ticketing-service",
    topics: ["ticket.requests"]
});
kafka:Producer paymentProducer = check new ({ bootstrapServers: env:getEnv("KAFKA_BOOTSTRAP") });

service /ticketing on ticketListener {

    resource function get all() returns json {
        var res = db->find("transportdb", "tickets");
        return res is stream<json, error> ? { tickets: res.toArray() } : { error: res.message() };
    }
}

service on ticketConsumer {
    resource function onMessage(kafka:ConsumerRecord[] records) {
        foreach var r in records {
            json ticketReq = checkpanic r.value.cloneWithType(json);
            io:println("Received ticket request: ", ticketReq);
            checkpanic db->insert("transportdb", "tickets", ticketReq);
            _ = checkpanic paymentProducer->send({
                topic: "payments.processed",
                value: ticketReq.toJsonString()
            });
        }
    }
}