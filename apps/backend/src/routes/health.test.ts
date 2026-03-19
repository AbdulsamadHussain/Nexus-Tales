import { afterAll, describe, expect, it } from "vitest";

import { buildApp } from "../app.js";

const app = buildApp();

afterAll(async () => {
  await app.close();
});

describe("GET /", () => {
  it("returns a basic service document", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/"
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      status: "ok",
      service: "nexus-tales-backend",
      endpoints: {
        health: "/v1/health",
        turns: "/v1/turns"
      }
    });
  });
});
