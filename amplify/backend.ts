import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data } from './data/resource';
import { AttachIoTPolicy } from './functions/AttachIoTPolicy/resource';
import * as iam from "aws-cdk-lib/aws-iam"

/**
 * @see https://docs.amplify.aws/react/build-a-backend/ to add storage, functions, and more
 */
const backend = defineBackend({
  auth,
  data,
  AttachIoTPolicy
});


/**
 * Represents the Lambda function resource for attaching an IoT policy.
 * This Lambda function is part of the backend resources for the project.
 * 
 * @constant
 * @type {LambdaFunction}
 * @memberof backend.AttachIoTPolicy.resources
 */
const attachIoTPolicyLambda = backend.AttachIoTPolicy.resources.lambda

attachIoTPolicyLambda.addToRolePolicy(new iam.PolicyStatement({
  sid: "AllowAttachIoTPolicy",
  effect: iam.Effect.ALLOW,
  actions: [
    "iot:GetPolicy",
    "iot:AttachPolicy",
    "iot:AttachPrincipalPolicy",
    "cognito-identity:GetId",
    "cognito-identity:DescribeIdentity"
  ],
  resources: ["arn:aws:iot:us-east-2:996104940096:policy/IoT_Cognito_Users", '*'],
}))


/**
 * Represents the IAM role assigned to authenticated users.
 * 
 * This role is used to define the permissions and policies 
 * that authenticated users have within the AWS environment.
 * 
 * @constant {string} authRole - The IAM role for authenticated users.
 */
const authRole = backend.auth.resources.authenticatedUserIamRole

authRole.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName("AWSIoTDataAccess"))


