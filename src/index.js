'use strict';

const express = require('express');

// Constants
const PORT = 80;
const HOST = '0.0.0.0';
const NODE_ENV = process.env.NODE_ENV || "development";
// App
const app = express();
app.get('/', (req, res) => {
  res.send(`Hello World on ${NODE_ENV}`);
  console.log(`Request received on ${NODE_ENV}: ${req.url} by ${req.get('user-agent')} from ${req.ip}`);
});

app.listen(PORT, HOST);

console.log(`Running on http://${HOST}:${PORT} on ${NODE_ENV}`);