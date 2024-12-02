// handler.ts

import AWS from 'aws-sdk';
import type { Schema } from "../../data/resource";

const iot = new AWS.Iot();

export const handler: Schema["AttachIoTPolicy"]["functionHandler"] = async (event) => {
  console.log(`EVENT: ${JSON.stringify(event)}`);

  const { username } = event.arguments;
  if (!username) {
    return JSON.stringify({ status: 400, message: 'Username is undefined' });
  }

  try {
    await attachIoTPolicy('IoT_Cognito_Users', username);
    return JSON.stringify({ status: 200, message: 'Policy attached successfully' });
  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : String(e);
    return JSON.stringify({ status: 400, message: errorMessage });
  }
};

async function attachIoTPolicy(policyName: string, identityId: string): Promise<string> {
  const iotParams: AWS.Iot.AttachPolicyRequest = {
    policyName,
    target: identityId,
  };
  console.log('Attaching policy with parameters:', iotParams);

  try {
    await iot.attachPolicy(iotParams).promise();
    console.log('Policy attached successfully');
    return 'Policy attached successfully';
  } catch (error) {
    console.error('Error attaching policy:', error);
    throw error;
  }
}
