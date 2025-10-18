// Simple mock Copilot server for testing
import express from 'express';

const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/process', (req, res) => {
  const { prompt, context } = req.body;
  res.json({ 
    reply: `Mock Copilot response to: "${prompt}"`,
    timestamp: new Date().toISOString()
  });
});

const port = 4000;
app.listen(port, () => {
  console.log(`🤖 Mock Copilot running on port ${port}`);
});