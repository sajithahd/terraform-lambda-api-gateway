// Lambda function code


var AWS = require('aws-sdk');
var dynamo = new AWS.DynamoDB.DocumentClient();

module.exports.dbhandler = function (event, context, callback) {

    var operation = event.operation;

    if (event.tableName) {
        event.payload.TableName = event.tableName;
    }

    switch (operation) {
        case 'create':
            dynamo.put(event.payload, callback);
            break;
        case 'read':
            dynamo.get(event.payload, callback);
            break;
        default:
            callback('Unknown operation: ${operation}');
    }
};

module.exports.handler = async (event) => {
    console.log('Event: ', event);
    let responseMessage = 'Hello, World! Welcome to e-Store';

    if (event.queryStringParameters && event.queryStringParameters['name']) {
        responseMessage = 'Hello, ' + event.queryStringParameters['name'] + '!';
    }
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            message: responseMessage,
        }),
    }
}
