import express from 'express';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs/promises';

// ES Module dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Shared Copilot Agent Server
 * Universal server configuration for all Perplexity spaces
 * Maintains consistent API and middleware across all deployments
 */

// Configuration from environment
const PORT = process.env.COPILOT_PORT || 4000;
const LOG_DIR = process.env.LOG_DIR || './logs';
const SPACE_NAME = process.env.SPACE_NAME || 'unknown-space';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

// Initialize Express app
const app = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${req.method} ${req.path} - Space: ${SPACE_NAME}`);
    
    // Log to file if LOG_DIR exists
    logToFile('access', `${timestamp} ${req.method} ${req.path} ${req.ip} - Space: ${SPACE_NAME}`);
    
    next();
});

// Ensure log directory exists
async function ensureLogDirectory() {
    try {
        await fs.mkdir(LOG_DIR, { recursive: true });
    } catch (error) {
        console.warn(`Could not create log directory: ${error.message}`);
    }
}

// Log to file helper
async function logToFile(type, message) {
    try {
        const logFile = path.join(LOG_DIR, `${type}.log`);
        await fs.appendFile(logFile, `${message}\n`);
    } catch (error) {
        // Fail silently for logging errors
    }
}

// Health check endpoint
app.get('/health', (req, res) => {
    const healthData = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        space: SPACE_NAME,
        port: PORT,
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        memory: process.memoryUsage(),
        pid: process.pid
    };
    
    res.json(healthData);
});

// Processing endpoint
app.post('/process', async (req, res) => {
    try {
        const { prompt, context = {} } = req.body;
        
        if (!prompt) {
            return res.status(400).json({ 
                error: 'Prompt is required',
                space: SPACE_NAME 
            });
        }
        
        // Log the processing request
        await logToFile('processing', `${new Date().toISOString()} Processing request - Space: ${SPACE_NAME}, Prompt length: ${prompt.length}`);
        
        // Mock AI response (replace with actual AI integration)
        const response = {
            id: generateId(),
            space: SPACE_NAME,
            timestamp: new Date().toISOString(),
            prompt: prompt.substring(0, 100) + (prompt.length > 100 ? '...' : ''),
            response: generateMockResponse(prompt),
            context: context,
            processingTime: Math.random() * 1000 + 500 // Mock processing time
        };
        
        // If OPENAI_API_KEY is provided, could integrate with OpenAI here
        if (OPENAI_API_KEY) {
            // TODO: Integrate with OpenAI API
            response.provider = 'openai';
        } else {
            response.provider = 'mock';
        }
        
        res.json(response);
        
    } catch (error) {
        console.error('Processing error:', error);
        await logToFile('error', `${new Date().toISOString()} Processing error - Space: ${SPACE_NAME}, Error: ${error.message}`);
        
        res.status(500).json({
            error: 'Internal server error',
            space: SPACE_NAME,
            timestamp: new Date().toISOString()
        });
    }
});

// Space information endpoint
app.get('/space', (req, res) => {
    res.json({
        name: SPACE_NAME,
        timestamp: new Date().toISOString(),
        server: {
            port: PORT,
            uptime: process.uptime(),
            version: '1.0.0'
        },
        capabilities: [
            'text-processing',
            'health-monitoring', 
            'audit-logging',
            'space-isolation'
        ]
    });
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
    const metrics = {
        space: SPACE_NAME,
        timestamp: new Date().toISOString(),
        system: {
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            cpu: process.cpuUsage(),
            pid: process.pid
        },
        performance: {
            // Mock metrics - replace with actual monitoring
            requestsPerSecond: Math.floor(Math.random() * 100),
            averageResponseTime: Math.floor(Math.random() * 200) + 50,
            errorRate: Math.random() * 5
        }
    };
    
    res.json(metrics);
});

// Mock response generator
function generateMockResponse(prompt) {
    const responses = [
        `Based on your input "${prompt.substring(0, 50)}...", here's my analysis from ${SPACE_NAME} space.`,
        `Processing your request in ${SPACE_NAME}. Here's what I found...`,
        `From the ${SPACE_NAME} space perspective, I can help you with that.`,
        `Analyzing your prompt in the context of ${SPACE_NAME} space...`
    ];
    
    return responses[Math.floor(Math.random() * responses.length)];
}

// Generate unique ID
function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substring(2);
}

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    logToFile('error', `${new Date().toISOString()} Unhandled error - Space: ${SPACE_NAME}, Error: ${error.message}, Stack: ${error.stack}`);
    
    res.status(500).json({
        error: 'Internal server error',
        space: SPACE_NAME,
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not found',
        space: SPACE_NAME,
        path: req.path,
        timestamp: new Date().toISOString()
    });
});

// Start server
async function startServer() {
    try {
        await ensureLogDirectory();
        
        app.listen(PORT, () => {
            console.log(`🚀 Copilot Agent Server started`);
            console.log(`📍 Space: ${SPACE_NAME}`);
            console.log(`🔗 Port: ${PORT}`);
            console.log(`📊 Health: http://localhost:${PORT}/health`);
            console.log(`📈 Metrics: http://localhost:${PORT}/metrics`);
            console.log(`📁 Logs: ${LOG_DIR}`);
            
            // Log server startup
            logToFile('system', `${new Date().toISOString()} Server started - Space: ${SPACE_NAME}, Port: ${PORT}, PID: ${process.pid}`);
        });
        
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down gracefully');
    logToFile('system', `${new Date().toISOString()} Server shutdown - Space: ${SPACE_NAME}`);
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('Received SIGINT, shutting down gracefully');
    logToFile('system', `${new Date().toISOString()} Server shutdown - Space: ${SPACE_NAME}`);
    process.exit(0);
});

// Start the server
startServer();

export default app;