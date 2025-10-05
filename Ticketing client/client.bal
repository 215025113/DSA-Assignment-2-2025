import ballerina/http;
import ballerina/kafka;
import ballerina/io;

const KAFKA_SERVER = "kafka:9092";

const REQUEST_TOPIC = "ticket.requests";
const NOTIFY_TOPIC = "notifications.events";

kafka:Producer ticketProducer = check new ({ bootstrapServers: KAFKA_SERVER });

kafka:Consumer notifyConsumer = check new ({
    bootstrapServers: KAFKA_SERVER,
    groupId: "passenger-group",
    topics: [NOTIFY_TOPIC],
    autoCommit: true
});

service /passenger on new http:Listener(9090) {

    resource function post ticket(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        string passenger = check payload.passenger.toString();
        string trip = check payload.trip.toString();

        string message = string `Ticket request from ${passenger} for trip ${trip}`;
        check ticketProducer->send({ topic: REQUEST_TOPIC, value: message.toBytes() });

        io:println("Ticket request sent -> ", message);
        check caller->respond({ "status": "sent", "message": message });
    }

    resource function get notifications(http:Caller caller) returns error? {
        var records = notifyConsumer->poll(3); 
        string[] notes = [];

        foreach var record in records {
            notes.push(record.value.toString());
        }

        check caller->respond(notes);
    }
}
