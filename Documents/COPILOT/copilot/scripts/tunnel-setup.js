import ngrok from 'ngrok';
import dotenv from 'dotenv';
dotenv.config();

(async()=>{
  const url = await ngrok.connect({
    addr: process.env.COPILOT_PORT,
    subdomain: process.env.TUNNEL_SUBDOMAIN
  });
  console.log(`� Tunnel URL: ${url}`);
})();