import axios from 'axios';
import crypto from 'crypto';
import dotenv from 'dotenv';
dotenv.config();

// Google Cloud and Firebase connectivity verification
console.log('🔍 Verifying Google Cloud and Firebase configuration...');
console.log('Firebase Database URL:', process.env.FIREBASE_DATABASE_URL || 'Not configured');
console.log('Google Cloud Project ID:', process.env.GOOGLE_PROJECT_ID || 'Not configured');
console.log('Firebase API Key:', process.env.FIREBASE_API_KEY ? 'Configured' : 'Not configured');
console.log('GCP Service Account:', process.env.GOOGLE_APPLICATION_CREDENTIALS ? 'Configured' : 'Not configured');
console.log('');

(async()=>{
  const ts = `${Math.floor(Date.now()/1000)}`;
  const body = { text:'Hello Copilot', user:'test-user' };
  const base = `v0:${ts}:${JSON.stringify(body)}`;
  const sig = 'v0='+crypto.createHmac('sha256',process.env.SLACK_SIGNING_SECRET)
    .update(base).digest('hex');

  try {
    const r = await axios.post('http://localhost:3000/webhook', body, {
      headers:{
        'Content-Type':'application/json',
        'X-Slack-Request-Timestamp':ts,
        'X-Slack-Signature':sig
      }
    });
    console.log('Reply:',r.data.text);
  } catch (e) {
    console.error('Smoke test failed:',e.message);
    process.exit(1);
  }
})();