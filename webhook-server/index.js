// FILEPATH: c:/Users/Lisa/smartsacco/webhook-server/index.js

const express = require('express');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const app = express();

app.use(express.json());

app.get('/test', (req, res) => {
  res.send('Test route working');
});

/**
 * Webhook endpoint to receive Mobile Money payment callbacks.
 * Saves callback data to Firestore collection 'momo_callbacks'.
 */
app.post('/momo-callback', async (req, res) => {
  try {
    const callbackData = req.body;
    const transactionId = callbackData.transactionId;

    if (!transactionId) {
      return res.status(400).send('Missing transactionId');
    }

    await db.collection('momo_callbacks').doc(transactionId).set(callbackData);

    console.log('Callback saved for transaction:', transactionId);
    res.status(200).send('Callback received');
  } catch (error) {
    console.error('Error saving callback:', error);
    res.status(500).send('Internal Server Error');
  }
});

/**
 * Retrieves a Mobile Money callback by transactionId from Firestore.
 * @param {string} req.params.transactionId - The transaction ID to look up.
 * @returns {object} JSON data of the callback or 404 if not found.
 */
app.get('/momo-callback/:transactionId', async (req, res) => {
  try {
    const transactionId = req.params.transactionId;
    const doc = await db.collection('momo_callbacks').doc(transactionId).get();

    if (!doc.exists) {
      return res.status(404).send('Transaction not found');
    }

    res.status(200).json(doc.data());
  } catch (error) {
    console.error('Error fetching callback:', error);
    res.status(500).send('Internal Server Error');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Webhook server listening on port ${PORT}`);
});