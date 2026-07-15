import { env } from './config/env.js';
// Importing firebase here initialises the Admin SDK at boot (fails fast if misconfigured).
import './config/firebase.js';
import { createApp } from './app.js';

const app = createApp();

const server = app.listen(env.port, () => {
  console.log(`✅ Savarun backend running on http://localhost:${env.port} [${env.nodeEnv}]`);
});

// Graceful shutdown.
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    console.log(`\n${signal} received — shutting down...`);
    server.close(() => process.exit(0));
  });
}

process.on('unhandledRejection', (reason) => {
  console.error('[unhandledRejection]', reason);
});
