const express = require('express');
const producer = require('./producer')

const router = express.Router();

router.post('/', async (req, res, next) => {
    if (!req.body.message) {
        console.error("Bad Request: Missing 'message' field. Body:", JSON.stringify(req.body));
        return res.status(400).json({ error: "Payload must contain a 'message' field" });
    }

    try {
        await producer.send('chunks', JSON.stringify(req.body.message), req.body.key);

        res.json({ success: true });
    } catch (err) {
        console.error("Kafka error:", err);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router
