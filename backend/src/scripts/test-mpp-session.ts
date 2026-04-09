import * as mpp from '@stellar/mpp';
import * as mppxClient from 'mppx/client';
import * as mppxServer from 'mppx/server';

// Attempting subpath imports as per research
async function testImports() {
  console.log('--- MPP SDK EXPORT VERIFICATION ---');

  console.log('\n[Package: @stellar/mpp]');
  console.log('Exports:', Object.keys(mpp));

  try {
    const channelClient = await import('@stellar/mpp/channel/client');
    console.log('\n[Subpath: @stellar/mpp/channel/client]');
    console.log('Exports:', Object.keys(channelClient));
  } catch (e) {
    console.log('\n[Subpath: @stellar/mpp/channel/client] FAILED TO IMPORT');
  }

  try {
    const channelServer = await import('@stellar/mpp/channel/server');
    console.log('\n[Subpath: @stellar/mpp/channel/server]');
    console.log('Exports:', Object.keys(channelServer));
  } catch (e) {
    console.log('\n[Subpath: @stellar/mpp/channel/server] FAILED TO IMPORT');
  }

  console.log('\n[Package: mppx/client]');
  console.log('Exports:', Object.keys(mppxClient));

  console.log('\n[Package: mppx/server]');
  console.log('Exports:', Object.keys(mppxServer));

  console.log('\n--- CORE FUNCTION CHECK ---');
  // Checking for specific functions requested
  const checks = [
    { name: 'Mppx.create (client)', fn: mppxClient.Mppx?.create },
    { name: 'Mppx.create (server)', fn: mppxServer.Mppx?.create },
  ];

  checks.forEach(c => {
    console.log(`${c.name}: ${typeof c.fn === 'function' ? 'FOUND' : 'NOT FOUND'}`);
  });

}

testImports();
