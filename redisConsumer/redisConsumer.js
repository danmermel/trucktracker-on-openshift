// import the `Kafka` instance from the kafkajs library
const { Kafka } = require("kafkajs")
const topic = 'es-topic'
const redis = require("redis")
const REDIS_CA = process.env.REDIS_CA  //gets the CA from the kubernetes secrets
const REDIS_URL = process.env.REDIS_URL  // gets URL from the kubernets secrets
const BROKER0 = process.env.BROKER0
const BROKER1 = process.env.BROKER1
const BROKER2 = process.env.BROKER2
const BROKER3 = process.env.BROKER3
const BROKER4 = process.env.BROKER4
const BROKER5 = process.env.BROKER5
const USER_NAME = process.env.USER_NAME
const PASSWORD = process.env.PASSWORD
 
//create Redis things

//redis
const ca = Buffer.from(REDIS_CA, 'base64').toString('utf-8')
//console.log(ca)
const redisClient = redis.createClient(REDIS_URL, { tls: { ca: ca } })

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

const consumer = kafka.consumer({ groupId: 'redis' })

const run = async () => {
  await consumer.connect()
  console.log("connected to kafka")
  //await redisClient.connect();
  //console.log("connected to Redis")


  await consumer.subscribe({ topic
							//, fromBeginning: true
						 })
  await consumer.run({
    eachBatch: async ({ batch }) => {
	  const batchSize = batch.rawMessages.length
      console.log("Received a batch of ", batchSize)
	  //first just turn the messages into a nice array of objects ready for anything!
	  batch.rawMessages = batch.rawMessages.map ( function (d) {
		  let retval = d.value.toString()
		  //console.log(retval)
		  retval = JSON.parse(retval)
		  //console.log(retval)
 
		  return retval

	  })
	  // assume that all items in array are in time order
	  // we want the latest object for each available truck id
      let redisObj = {}
	  for (var message of batch.rawMessages) {
		  //you should end up with an object with the latest value for each truck
		redisObj[message.truckId] = message
	  }
	  console.log(redisObj)
	  for (var truckId in redisObj) {
		  await redisClient.hset("trucks", truckId, JSON.stringify(redisObj[truckId]))
		  console.log("written to Redis: ", truckId)
	  }
    },
   })
}

run().catch(e => console.error(`[example/consumer] ${e.message}`, e))




