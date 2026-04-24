const pool = require('./db');

async function debugAllServiceConnections() {
  console.log('🔍 DEBUG: All Service-to-Service Connections');
  console.log('=' .repeat(80));

  try {
    // Get all service-to-service connections
    const connectionsResult = await pool.query(
      `SELECT stsc.*,
              s1.name as source_service_name, s1.status as source_service_status,
              s2.name as target_service_name, s2.status as target_service_status,
              ci.name as cmdb_item_name
       FROM service_to_service_connections stsc
       INNER JOIN services s1 ON stsc.source_service_id = s1.id
       INNER JOIN services s2 ON stsc.target_service_id = s2.id
       INNER JOIN cmdb_items ci ON stsc.cmdb_item_id = ci.id
       ORDER BY stsc.workspace_id, stsc.cmdb_item_id, stsc.created_at`
    );

    console.log(`\n📊 Total connections found: ${connectionsResult.rows.length}`);

    if (connectionsResult.rows.length === 0) {
      console.log('\n❌ No service-to-service connections found in database!');
      console.log('\n💡 This is why recursive propagation is not working!');
      console.log('\n📋 SOLUTION:');
      console.log('1. Create service-to-service connections via API or UI');
      console.log('2. Make sure to set propagation: "source_to_target" or "both"');
      console.log('\n🔧 Example API call:');
      console.log('POST /api/service-to-service-connections');
      console.log('Body: {');
      console.log('  cmdb_item_id: <CMDB_ITEM_ID>,');
      console.log('  source_service_id: <SOURCE_SERVICE_ID>,');
      console.log('  target_service_id: <TARGET_SERVICE_ID>,');
      console.log('  workspace_id: <WORKSPACE_ID>,');
      console.log('  connection_type: "consumed_by",');
      console.log('  direction: "forward",');
      console.log('  propagation: "source_to_target" ⭐ IMPORTANT!');
      console.log('}');
    } else {
      console.log('\n✅ Service-to-Service Connections Details:\n');

      for (let i = 0; i < connectionsResult.rows.length; i++) {
        const conn = connectionsResult.rows[i];
        console.log(`Connection ${i + 1} (ID: ${conn.id}):`);
        console.log(`  Workspace: ${conn.workspace_id}`);
        console.log(`  CMDB Item: ${conn.cmdb_item_name} (ID: ${conn.cmdb_item_id})`);
        console.log(`  Source: ${conn.source_service_name} (ID: ${conn.source_service_id}, Status: ${conn.source_service_status})`);
        console.log(`  Target: ${conn.target_service_name} (ID: ${conn.target_service_id}, Status: ${conn.target_service_status})`);
        console.log(`  Type: ${conn.connection_type}`);
        console.log(`  Direction: ${conn.direction}`);
        console.log(`  Propagation: ${conn.propagation} ${conn.propagation === 'source_to_target' || conn.propagation === 'both' ? '✅' : '❌'}`);

        // Check if propagation will work
        const propagationWorks = (conn.propagation === 'source_to_target' || conn.propagation === 'both');
        const targetCanBePropagated = conn.target_service_status === 'active';

        console.log(`  Will propagate: ${propagationWorks && targetCanBePropagated ? '✅ YES' : '❌ NO'}`);

        if (!propagationWorks) {
          console.log(`  ⚠️ ISSUE: Propagation is "${conn.propagation}"`);
          console.log(`     Fix: Set propagation to "source_to_target" or "both"`);
        }

        if (!targetCanBePropagated) {
          console.log(`  ⚠️ ISSUE: Target service status is "${conn.target_service_status}"`);
          console.log(`     Fix: Target service must be "active" to be propagated to`);
        }

        console.log('');
      }

      // Summary
      const validPropagationCount = connectionsResult.rows.filter(
        conn => conn.propagation === 'source_to_target' || conn.propagation === 'both'
      ).length;

      const activeTargetCount = connectionsResult.rows.filter(
        conn => conn.target_service_status === 'active'
      ).length;

      console.log('📋 SUMMARY:');
      console.log(`  Total connections: ${connectionsResult.rows.length}`);
      console.log(`  Connections with valid propagation: ${validPropagationCount}`);
      console.log(`  Connections with active targets: ${activeTargetCount}`);

      if (validPropagationCount === 0) {
        console.log('\n❌ CRITICAL: No connections have propagation enabled!');
        console.log('💡 Update connections to set propagation: "source_to_target"');
      } else if (activeTargetCount === 0) {
        console.log('\n⚠️ WARNING: All target services are not active!');
        console.log('💡 Set target services to "active" status first');
      } else {
        console.log('\n✅ Configuration looks good!');
        console.log('💡 Try updating a source service status to "inactive"');
      }
    }

    // Also show all available services
    console.log('\n' + '='.repeat(80));
    console.log('📋 Available Services:');
    console.log('=' .repeat(80));

    const servicesResult = await pool.query(
      `SELECT s.id, s.name, s.status, s.workspace_id, ci.name as cmdb_item_name
       FROM services s
       INNER JOIN cmdb_items ci ON s.cmdb_item_id = ci.id
       ORDER BY s.workspace_id, s.cmdb_item_id, s.name`
    );

    console.log(`\nFound ${servicesResult.rows.length} services:\n`);

    for (const service of servicesResult.rows) {
      console.log(`  Service ID: ${service.id}`);
      console.log(`  Name: ${service.name}`);
      console.log(`  Status: ${service.status}`);
      console.log(`  Workspace: ${service.workspace_id}`);
      console.log(`  CMDB Item: ${service.cmdb_item_name}`);
      console.log(`  ---`);
    }

  } catch (error) {
    console.error('❌ ERROR during debug:', error);
  } finally {
    pool.end(); // Close connection
  }
}

debugAllServiceConnections();
