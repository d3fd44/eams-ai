const { Kafka } = require('kafkajs')

class Producer {

    #producer
    #kafka
    #is_connected

    constructor(client_id, brokers) {
        this.#kafka = new Kafka({
            clientId: client_id,
            brokers: brokers
        })
        this.#producer = this.#kafka.producer()
        this.#is_connected = false
    }

    async connect() {
        if (this.#is_connected) return

        try {
            await this.#producer.connect()
            this.#is_connected = true
            console.log("Kafka Producer Successfully Connected.")

        } catch (error) {
            console.error("producer could not connect to the kafka broker/s.", error)
        }
    }

    async disconnect() {
        await this.#producer.disconnect()
        this.#is_connected = false
    }

    async send(topic, message, key = null) {
        await this.connect();

        try {
            await this.#producer.send({
                topic: topic,
                messages: [{ key: key ? key.toString() : null, value: message }],
            });
            console.log(`message sent to "${topic}": ${message}`)
        } catch (error) {
            console.error("Failed to send message", error)
        }
    }
}


const producer = new Producer('chunks-producer', ['localhost:9092'])

module.exports = producer
