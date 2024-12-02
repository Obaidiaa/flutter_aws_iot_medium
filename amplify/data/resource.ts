import { type ClientSchema, a, defineData } from "@aws-amplify/backend";
import {AttachIoTPolicy} from "../functions/AttachIoTPolicy/resource";
const schema = a.schema({
  AttachIoTPolicy: a
  .query()
  .arguments({
    username: a.string(),
  })
  .returns(a.string())
  .handler(a.handler.function(AttachIoTPolicy)).authorization(allow => [allow.authenticated()]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: "userPool",
  },
});