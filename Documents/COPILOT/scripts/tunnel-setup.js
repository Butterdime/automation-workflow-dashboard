import ngrok from 'ngrok';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

async function setupTunnel() {
  try {
    console.log('🚇 Setting up secure tunnel...');
    
    const port = process.env.COPILOT_PORT || 4000;
    const subdomain = process.env.TUNNEL_SUBDOMAIN;
    
    // Configure ngrok options
    const ngrokOptions = {
      addr: port,
      region: 'us', // Change as needed
    };
    
    // Add subdomain if provided
    if (subdomain) {
      ngrokOptions.subdomain = subdomain;
      console.log(`📍 Using subdomain: ${subdomain}`);
    }
    
    // Connect to ngrok
    const url = await ngrok.connect(ngrokOptions);
    
    console.log('✅ Tunnel established successfully!');
    console.log(`🌐 Public URL: ${url}`);
    console.log(`🔗 Local server: http://localhost:${port}`);
    
    // Update .env file with tunnel URL
    await updateEnvFile(url);
    
    // Keep the tunnel alive
    console.log('🔄 Tunnel is running... Press Ctrl+C to stop');
    
    // Handle graceful shutdown
    process.on('SIGINT', async () => {
      console.log('\n🛑 Shutting down tunnel...');
      await ngrok.disconnect();
      await ngrok.kill();
      console.log('✅ Tunnel closed');
      process.exit(0);
    });
    
    process.on('SIGTERM', async () => {
      console.log('\n🛑 Shutting down tunnel...');
      await ngrok.disconnect();
      await ngrok.kill();
      process.exit(0);
    });
    
  } catch (error) {
    console.error('❌ Failed to setup tunnel:', error.message);
    process.exit(1);
  }
}

async function updateEnvFile(tunnelUrl) {
  try {
    const envPath = path.join(process.cwd(), '.env');
    const copilotEnvPath = path.join(process.cwd(), 'copilot', '.env');
    
    // Update main .env file
    if (fs.existsSync(envPath)) {
      let envContent = fs.readFileSync(envPath, 'utf8');
      envContent = envContent.replace(
        /TUNNEL_URL=.*/,
        `TUNNEL_URL=${tunnelUrl}`
      );
      fs.writeFileSync(envPath, envContent);
    }
    
    // Update copilot/.env file
    if (fs.existsSync(copilotEnvPath)) {
      let envContent = fs.readFileSync(copilotEnvPath, 'utf8');
      envContent = envContent.replace(
        /TUNNEL_URL=.*/,
        `TUNNEL_URL=${tunnelUrl}`
      );
      fs.writeFileSync(copilotEnvPath, envContent);
    }
    
    console.log('📝 Environment files updated with tunnel URL');
  } catch (error) {
    console.warn('⚠️  Could not update .env files:', error.message);
  }
}

// Auto-start if run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  setupTunnel();
}

export { setupTunnel };