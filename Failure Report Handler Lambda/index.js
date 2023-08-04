// index.js
const AWS = require("aws-sdk");
const sqs = new AWS.SQS();
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
    try {
        for (const record of event.Records) {
            const { body, receiptHandle } = record;

            // Assuming the message body is in JSON format
            const parsedBody = JSON.parse(body);

            await processMessage(parsedBody.Message);

            // Delete the processed message from the SQS queue
            await deleteMessage(receiptHandle);
        }

        return {
            statusCode: 200,
            body: "Message processing completed.",
        };
    } catch (error) {
        console.error("Error processing messages:", error);
        return {
            statusCode: 500,
            body: "Error processing messages.",
        };
    }
};

async function processMessage(message) {
    const { asset_id, failure_id, ...failureAttributes } = JSON.parse(message);
    const params = {
        TableName: `${process.env.ASSETS_TABLE}`, // Replace with your actual DynamoDB table name
        Item: {
            PartitionKey: `FAILURE_${asset_id}`,
            SortKey: `FAILURE_${failure_id}`,
            ...failureAttributes,
        },
    };

    try {
        await dynamoDB.put(params).promise();
    } catch (error) {
        console.error("Error putting item in DynamoDB:", error);
        throw error; // Throw the error so it can be caught by the calling function
    }
}

// Function to delete the message from the SQS queue
async function deleteMessage(receiptHandle) {
    const params = {
        QueueUrl: `${process.env.SQS_QUEUE_URL}`, // Replace with your actual SQS queue URL
        ReceiptHandle: receiptHandle,
    };

    try {
        await sqs.deleteMessage(params).promise();
        console.log("Message deleted successfully.");
    } catch (error) {
        console.error("Error deleting message:", error);
    }
}
