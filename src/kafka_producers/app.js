const express = require('express')
const producerRouter = require('./routers.js')
const producer = require('./producer')

const app = express()
const port = 3000

app.use(express.json())

app.use('/log', producerRouter);

(async () => {
    console.log("Initializing Kafka Connection...")
    await producer.connect()
})()

const server = app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`)
})

const sigterm = async () => {
    console.log('\n Shutting down...')
    await producer.disconnect()
    server.close(() => { process.exit(0) })
}

process.on('SIGTERM', sigterm)
process.on('SIGINT', sigterm)
