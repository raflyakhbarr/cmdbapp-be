const pool = require('./db');

async function debugServicePropagation(serviceId) {
  console.log(`🔍 DEBUG: Checking service propagation for Service ID: ${serviceId}`);
  console.log('=' .repeat(60));

  try {
    // 1. Check if service exists
    const serviceResult = await pool.query(
      'SELECT * FROM services WHERE id = $1',
      [serviceId]
    );

    if (serviceResult.rows.length === 0) {
      console.log('❌ Service not found!');
      return;
    }

    const service = serviceResult.rows[0];
    console.log('✅ Service found:');
    console.log(`   ID: ${service.id}`);
    console.log(`   Name: ${service.name}`);
    console.log(`   Status: ${service.status}`);
    console.log(`   Workspace ID: ${service.workspace_id}`);
    console.log(`   CMDB Item ID: ${service.cmdb_item_id}`);

    // 2. Check if service has service items (for workspace_id detection)
    const serviceItemsResult = await pool.query(
      'SELECT DISTINCT workspace_id FROM service_items WHERE service_id = $1',
      [serviceId]
    );

    console.log(`\n📦 Service Items:`);
    if (serviceItemsResult.rows.length === 0) {
      console.log('   ⚠️ No service items found! This might prevent workspace_id detection.');
      console.log(`   Will use workspace_id from service: ${service.workspace_id}`);
    } else {
      console.log(`   ✅ Found service items in workspace: ${serviceItemsResult.rows[0].workspace_id}`);
    }

    const workspaceId = serviceItemsResult.rows.length > 0
      ? serviceItemsResult.rows[0].workspace_id
      : service.workspace_id;

    console.log(`   🎯 Using workspace_id: ${workspaceId}`);

    // 3. Check service-to-service connections
    const connectionsResult = await pool.query(
      `SELECT stsc.*, s1.name as source_service_name, s2.name as target_service_name
       FROM service_to_service_connections stsc
       INNER JOIN services s1 ON stsc.source_service_id = s1.id
       INNER JOIN services s2 ON stsc.target_service_id = s2.id
       WHERE stsc.source_service_id = $1 AND stsc.workspace_id = $2`,
      [serviceId, workspaceId]
    );

    console.log(`\n🔗 Service-to-Service Connections (as source):`);
    if (connectionsResult.rows.length === 0) {
      console.log('   ❌ No outgoing connections found!');
      console.log('   This is why propagation is not working!');
    } else {
      console.log(`   ✅ Found ${connectionsResult.rows.length} outgoing connection(s):`);

      for (const conn of connectionsResult.rows) {
        console.log(`\n   Connection ${conn.id}:`);
        console.log(`   - Source: ${conn.source_service_name} (ID: ${conn.source_service_id})`);
        console.log(`   - Target: ${conn.target_service_name} (ID: ${conn.target_service_id})`);
        console.log(`   - Connection Type: ${conn.connection_type}`);
        console.log(`   - Direction: ${conn.direction}`);
        console.log(`   - Propagation: ${conn.propagation} ⭐`);
        console.log(`   - Workspace ID: ${conn.workspace_id}`);

        // Check if propagation will happen
        const willPropagate = (conn.propagation === 'source_to_target' || conn.propagation === 'both');
        console.log(`   - Will propagate: ${willPropagate ? '✅ YES' : '❌ NO'}`);
      }
    }

    // 4. Check if there are connections where this service is the target
    const incomingConnectionsResult = await pool.query(
      `SELECT stsc.*, s1.name as source_service_name, s2.name as target_service_name
       FROM service_to_service_connections stsc
       INNER JOIN services s1 ON stsc.source_service_id = s1.id
       INNER JOIN services s2 ON stsc.target_service_id = s2.id
       WHERE stsc.target_service_id = $1 AND stsc.workspace_id = $2`,
      [serviceId, workspaceId]
    );

    console.log(`\n🔗 Service-to-Service Connections (as target):`);
    if (incomingConnectionsResult.rows.length === 0) {
      console.log('   ℹ️ No incoming connections found.');
    } else {
      console.log(`   ℹ️ Found ${incomingConnectionsResult.rows.length} incoming connection(s):`);

      for (const conn of incomingConnectionsResult.rows) {
        console.log(`\n   Connection ${conn.id}:`);
        console.log(`   - Source: ${conn.source_service_name} (ID: ${conn.source_service_id})`);
        console.log(`   - Target: ${conn.target_service_name} (ID: ${conn.target_service_id})`);
        console.log(`   - Connection Type: ${conn.connection_type}`);
        console.log(`   - Direction: ${conn.direction}`);
        console.log(`   - Propagation: ${conn.propagation} ⭐`);
      }
    }

    // 5. Get target service current status
    if (connectionsResult.rows.length > 0) {
      console.log(`\n🎯 Target Services Current Status:`);
      for (const conn of connectionsResult.rows) {
        const targetStatusResult = await pool.query(
          'SELECT id, name, status FROM services WHERE id = $1',
          [conn.target_service_id]
        );

        if (targetStatusResult.rows.length > 0) {
          const target = targetStatusResult.rows[0];
          console.log(`   - ${target.name} (ID: ${target.id}): Status = ${target.status}`);
          const willPropagate = (conn.propagation === 'source_to_target' || conn.propagation === 'both') && target.status === 'active';
          console.log(`     Will propagate if source becomes inactive: ${willPropagate ? '✅ YES' : '❌ NO'}`);
        }
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📋 SUMMARY:');
    console.log('=' .repeat(60));

    if (connectionsResult.rows.length === 0) {
      console.log('❌ ISSUE FOUND: No service-to-service connections exist!');
      console.log('💡 SOLUTION: Create service-to-service connections first:');
      console.log(`   POST /api/service-to-service-connections`);
      console.log(`   Body: {`);
      console.log(`     cmdb_item_id: ${service.cmdb_item_id},`);
      console.log(`     source_service_id: ${serviceId},`);
      console.log(`     target_service_id: <TARGET_SERVICE_ID>,`);
      console.log(`     workspace_id: ${workspaceId},`);
      console.log(`     connection_type: 'consumed_by',`);
      console.log(`     direction: 'forward',`);
      console.log(`     propagation: 'source_to_target' ⭐ IMPORTANT!`);
      console.log(`   }`);
    } else {
      const hasValidPropagation = connectionsResult.rows.some(
        conn => conn.propagation === 'source_to_target' || conn.propagation === 'both'
      );

      if (!hasValidPropagation) {
        console.log('❌ ISSUE FOUND: No connections have propagation enabled!');
        console.log('💡 SOLUTION: Update connection propagation settings:');
        console.log(`   PUT /api/service-to-service-connections/${connectionsResult.rows[0].id}`);
        console.log(`   Body: {`);
        console.log(`     propagation: 'source_to_target' ⭐ IMPORTANT!`);
        console.log(`   }`);
      } else {
        console.log('✅ Service-to-service connections exist with proper propagation!');
        console.log('💡 Next steps:');
        console.log(`   1. Update service status to 'inactive'`);
        console.log(`   2. Check console logs for propagation messages`);
        console.log(`   3. Verify target services are updated in database`);
      }
    }

  } catch (error) {
    console.error('❌ ERROR during debug:', error);
  } finally {
    pool.end(); // Close connection
  }
}

// Get service ID from command line
const serviceId = process.argv[2];

if (!serviceId) {
  console.log('Usage: node debug-propagation.js <service_id>');
  console.log('Example: node debug-propagation.js 123');
  process.exit(1);
}

debugServicePropagation(parseInt(serviceId));
