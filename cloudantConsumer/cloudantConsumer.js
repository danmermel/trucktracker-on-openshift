// import the `Kafka` instance from the kafkajs library
const { Kafka } = require("kafkajs")
const topic = 'es-topic'
const BROKER0 = process.env.BROKER0
const BROKER1 = process.env.BROKER1
const BROKER2 = process.env.BROKER2
const BROKER3 = process.env.BROKER3
const BROKER4 = process.env.BROKER4
const BROKER5 = process.env.BROKER5
const USER_NAME = process.env.USER_NAME
const PASSWORD = process.env.PASSWORD
const API_KEY = process.env.API_KEY
const CLOUDANT_URL = process.env.CLOUDANT_URL


//create kafka object with access credentials
const kafka = new Kafka({
	clientId: 'my-app',
	brokers: [BROKER0, BROKER1, BROKER2, BROKER3, BROKER4, BROKER5],
	// authenticationTimeout: 1000,
	// reauthenticationThreshold: 10000,
	ssl: true,
	sasl: {
		mechanism: 'plain', // scram-sha-256 or scram-sha-512
		username: USER_NAME,
		password: PASSWORD
	},
})

//create cloudant object with access credentials
const { CloudantV1 } = require('@ibm-cloud/cloudant')

const { IamAuthenticator } = require('ibm-cloud-sdk-core');
const authenticator = new IamAuthenticator({
	apikey: API_KEY
});
const cloudant = new CloudantV1({
	authenticator: authenticator
});
cloudant.setServiceUrl(CLOUDANT_URL);

//create db if it doesn't exist already
const dbName = "trucktracker"
const createDb = cloudant
	.putDatabase({ db: dbName })
	.then((putDatabaseResult) => {
		if (putDatabaseResult.result.ok) {
			console.log(`"${dbName}" database created."`);
		}
	})
	.catch((err) => {
		if (err.code === 412) {
			console.log(
				'Cannot create "' + dbName + '" database, it already exists.'
			);
		}
	});

const consumer = kafka.consumer({ groupId: 'cloudant' })


const run = async () => {
	await consumer.connect()
	await consumer.subscribe({
		topic
		//, fromBeginning: true
	})
	await consumer.run({

			eachBatch: async ({ batch }) => {
				const batchSize = batch.rawMessages.length
				console.log("Received a batch of ", batchSize)
				batch.rawMessages = batch.rawMessages.map(function (d) {
					let retval = d.value.toString()
					//console.log(retval)
					retval = JSON.parse(retval)
					//console.log(retval)

					return retval

				})
				const bulkDocs = { docs: batch.rawMessages }

				const response = await cloudant.postBulkDocs({
					db: dbName,
					bulkDocs: bulkDocs
				})
				console.log("response is ", response)
				console.log("number of docs uploaded: ", batch.rawMessages.length)
			},

	})
}


run().catch(e => console.error(`[example/consumer] ${e.message}`, e))





