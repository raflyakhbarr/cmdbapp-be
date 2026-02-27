const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { Pool } = require('pg');

const pool = new Pool({
  host: String(process.env.DB_HOST),
  port: parseInt(process.env.DB_PORT),
  user: String(process.env.DB_USER),
  password: String(process.env.DB_PASSWORD),
  database: String(process.env.DB_NAME),
});

// New connection types to add
const newConnectionTypes = [
  { type_slug: 'backed_up_by', label: 'Backed Up By', description: 'Source item is backed up by target item', icon: 'refresh-cw', default_direction: 'backward', color: '#14b8a6' },
  { type_slug: 'hosted_on', label: 'Hosted On', description: 'Source item is hosted on target item (VM on physical server)', icon: 'server', default_direction: 'forward', color: '#6366f1' },
  { type_slug: 'hosting', label: 'Hosting', description: 'Source item hosts target item', icon: 'server', default_direction: 'backward', color: '#6366f1' },
  { type_slug: 'licensed_by', label: 'Licensed By', description: 'Source item uses license from target item', icon: 'key', default_direction: 'backward', color: '#eab308' },
  { type_slug: 'licensing', label: 'Licensing', description: 'Source item provides license to target item', icon: 'key', default_direction: 'forward', color: '#eab308' },
  { type_slug: 'part_of', label: 'Part Of', description: 'Source item is part of target item (component relationship)', icon: 'puzzle', default_direction: 'forward', color: '#a855f7' },
  { type_slug: 'comprised_of', label: 'Comprised Of', description: 'Source item is composed of target item', icon: 'puzzle', default_direction: 'backward', color: '#a855f7' },
  { type_slug: 'related_to', label: 'Related To', description: 'Source item is related to target item (general relationship)', icon: 'link', default_direction: 'bidirectional', color: '#94a3b8' },
  { type_slug: 'preceding', label: 'Preceding', description: 'Source item precedes target item in workflow', icon: 'arrow-up', default_direction: 'forward', color: '#f97316' },
  { type_slug: 'succeeding', label: 'Succeeding', description: 'Source item succeeds target item in workflow', icon: 'arrow-down', default_direction: 'backward', color: '#f97316' },
  { type_slug: 'encrypted_by', label: 'Encrypted By', description: 'Source item is encrypted by target item', icon: 'lock', default_direction: 'backward', color: '#be123c' },
  { type_slug: 'encrypting', label: 'Encrypting', description: 'Source item encrypts target item', icon: 'lock', default_direction: 'forward', color: '#be123c' },
  { type_slug: 'authenticated_by', label: 'Authenticated By', description: 'Source item is authenticated by target item', icon: 'shield-check', default_direction: 'backward', color: '#059669' },
  { type_slug: 'authenticating', label: 'Authenticating', description: 'Source item authenticates target item', icon: 'shield-check', default_direction: 'forward', color: '#059669' },
  { type_slug: 'monitoring', label: 'Monitoring', description: 'Source item monitors target item', icon: 'eye', default_direction: 'forward', color: '#ec4899' },
  { type_slug: 'monitored_by', label: 'Monitored By', description: 'Source item is monitored by target item', icon: 'eye', default_direction: 'backward', color: '#ec4899' },
  { type_slug: 'load_balanced_by', label: 'Load Balanced By', description: 'Source item is load balanced by target item', icon: 'scale', default_direction: 'backward', color: '#8b5cf6' },
  { type_slug: 'load_balancing', label: 'Load Balancing', description: 'Source item load balances target item', icon: 'scale', default_direction: 'forward', color: '#8b5cf6' },
  { type_slug: 'failing_over_to', label: 'Failing Over To', description: 'Source item fails over to target item', icon: 'zap', default_direction: 'forward', color: '#ef4444' },
  { type_slug: 'failover_from', label: 'Failover From', description: 'Source item is failover source for target item', icon: 'zap', default_direction: 'backward', color: '#ef4444' },
  { type_slug: 'replicating_to', label: 'Replicating To', description: 'Source item replicates data to target item', icon: 'database', default_direction: 'forward', color: '#06b6d4' },
  { type_slug: 'replicated_by', label: 'Replicated By', description: 'Source item is replicated by target item', icon: 'database', default_direction: 'backward', color: '#06b6d4' },
  { type_slug: 'proxying_for', label: 'Proxying For', description: 'Source item proxies requests for target item', icon: 'workflow', default_direction: 'forward', color: '#f59e0b' },
  { type_slug: 'proxied_by', label: 'Proxied By', description: 'Source item is proxied by target item', icon: 'workflow', default_direction: 'backward', color: '#f59e0b' },
  { type_slug: 'routed_through', label: 'Routed Through', description: 'Source item is routed through target item', icon: 'route', default_direction: 'forward', color: '#10b981' },
  { type_slug: 'routing', label: 'Routing', description: 'Source item routes target item', icon: 'route', default_direction: 'backward', color: '#10b981' },
];

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('Adding new connection types...');

    for (const type of newConnectionTypes) {
      try {
        // Add enum value
        await client.query(`ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS '${type.type_slug}'`);
        console.log(`✓ Added enum: ${type.type_slug}`);

        // Insert definition
        await client.query(`
          INSERT INTO connection_type_definitions (type_slug, label, description, icon, default_direction, color, show_arrow)
          VALUES ($1, $2, $3, $4, $5, $6, true)
          ON CONFLICT (type_slug) DO NOTHING
        `, [type.type_slug, type.label, type.description, type.icon, type.default_direction, type.color]);
        console.log(`✓ Added definition: ${type.label}`);
      } catch (err) {
        console.log(`  Skipped ${type.type_slug}: ${err.message}`);
      }
    }

    // Create index
    try {
      await client.query('CREATE INDEX IF NOT EXISTS idx_connections_type_workspace ON connections(connection_type, workspace_id)');
      console.log('✓ Created index');
    } catch (err) {
      console.log(`  Index skipped: ${err.message}`);
    }

    console.log('\n✓ Migration completed successfully!');
  } catch (err) {
    console.error('Migration failed:', err.message);
    console.error('Details:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
