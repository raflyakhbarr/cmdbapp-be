const pool = require('./db');

async function testServicePropagation() {
  console.log('🧪 TESTING: Service Propagation');
  console.log('=' .repeat(80));

  try {
    const sourceServiceId = 59; // SS3
    const targetServiceId = 56; // TGIS1

    // Step 1: Check current status
    console.log('\n📊 STEP 1: Current Status');
    const currentStatusResult = await pool.query(
      'SELECT id, name, status FROM services WHERE id IN ($1, $2)',
      [sourceServiceId, targetServiceId]
    );

    for (const service of currentStatusResult.rows) {
      console.log(`  Service ${service.name} (ID: ${service.id}): ${service.status}`);
    }

    // Step 2: Set source to active first
    console.log('\n🔄 STEP 2: Setting SS3 to ACTIVE');
    await pool.query(
      'UPDATE services SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['active', sourceServiceId]
    );
    console.log('  ✅ SS3 set to ACTIVE');

    // Step 3: Verify both are active
    console.log('\n📊 STEP 3: Verification after setting to ACTIVE');
    const afterActiveResult = await pool.query(
      'SELECT id, name, status FROM services WHERE id IN ($1, $2)',
      [sourceServiceId, targetServiceId]
    );

    for (const service of afterActiveResult.rows) {
      console.log(`  Service ${service.name} (ID: ${service.id}): ${service.status}`);
    }

    // Step 4: Now test propagation by setting SS3 to inactive
    console.log('\n🧪 STEP 4: Testing Propagation - Setting SS3 to INACTIVE');

    // Import the serviceModel to use the actual updateServiceStatus function
    const serviceModel = require('./models/serviceModel');

    console.log('  🔄 Calling updateServiceStatus(59, "inactive")...');
    await serviceModel.updateServiceStatus(sourceServiceId, 'inactive');
    console.log('  ✅ updateServiceStatus completed');

    // Step 5: Check if propagation worked
    console.log('\n📊 STEP 5: Verification after propagation');
    const finalResult = await pool.query(
      'SELECT id, name, status FROM services WHERE id IN ($1, $2)',
      [sourceServiceId, targetServiceId]
    );

    let propagationWorked = false;
    for (const service of finalResult.rows) {
      console.log(`  Service ${service.name} (ID: ${service.id}): ${service.status}`);
      if (service.id === targetServiceId && service.status === 'inactive') {
        propagationWorked = true;
      }
    }

    console.log('\n' + '='.repeat(80));
    console.log('🎯 TEST RESULT:');
    console.log('=' .repeat(80));

    if (propagationWorked) {
      console.log('✅ SUCCESS! Propagation is working!');
      console.log('   SS3 was set to inactive and TGIS1 automatically became inactive too!');
      console.log('\n💡 The recursive propagation feature is working correctly.');
    } else {
      console.log('❌ FAILED! Propagation is not working!');
      console.log('   SS3 was set to inactive but TGIS1 remained active.');
      console.log('\n🔍 Check the console logs above for any error messages.');
      console.log('💡 Make sure the backend server is using the updated code.');
    }

    // Step 6: Reset for further testing
    console.log('\n🔄 STEP 6: Resetting SS3 back to ACTIVE for further testing');
    await pool.query(
      'UPDATE services SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['active', sourceServiceId]
    );
    console.log('  ✅ SS3 reset to ACTIVE');

    // Also reset TGIS1 if propagation worked
    if (propagationWorked) {
      await pool.query(
        'UPDATE services SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
        ['active', targetServiceId]
      );
      console.log('  ✅ TGIS1 reset to ACTIVE');
    }

    console.log('\n✅ Test completed! Ready for further testing.');

  } catch (error) {
    console.error('❌ ERROR during test:', error);
  } finally {
    pool.end();
  }
}

testServicePropagation();